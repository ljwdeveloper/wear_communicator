package com.cbs.wear_communicator

import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.net.Uri
import android.util.Log

import com.google.android.gms.wearable.*
import com.google.common.util.concurrent.*
import androidx.wear.remote.interactions.RemoteActivityHelper
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

import org.json.JSONObject

/** WearCommunicatorPlugin */
class WearCommunicatorPlugin: FlutterPlugin, MethodCallHandler, StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private var thisDeviceNodeId: String? = null
  private var packageName: String? = null
  private var className: String? = null
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private val tag = "WearCommunicatorPlugin"
  private lateinit var context: Context
  private var isDetachedFromEngine: Boolean = true
  private var isMessageListenerEmpty: Boolean = true

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "wear_communicator")
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "wear_communicator_event")
    methodChannel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
    context = flutterPluginBinding.applicationContext
    Wearable.getNodeClient(context).localNode
      .addOnSuccessListener { node ->
        thisDeviceNodeId = node.id
        Log.d(tag, "Local node (this device) ID: $thisDeviceNodeId")
      }
    isDetachedFromEngine = false
    if(isMessageListenerEmpty) {
      val messageClient = Wearable.getMessageClient(context)
      messageClient.addListener(messageListener)
      isMessageListenerEmpty = false
    }
    Log.d(tag, "onAttachedToEngine() finished.")
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    isDetachedFromEngine = true
    Log.d(tag, "onDetachedFromEngine() finished.")
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "setPackageNameClassName"->{
        val params = call.arguments as? Map<String, String>
        if (params != null) {
          setPackageNameClassName(result, params)
        } else {
          result.error("INVALID_ARGUMENTS", "Missing or malformed arguments", null)
        }
      }
      "launchCompanionApp"-> {
        val uri = call.arguments as? String
        if (uri != null) {
          launchCompanionApp(result, uri)
        } else {
          result.error("INVALID_ARGUMENT", "uriString is null", null)
        }
      }
      "sendMessage" -> {
        val message = call.arguments as? Map<String, String>
        if (message != null) {
          sendMessageToConnected(message)
          result.success(null)
        } else {
          result.error("INVALID_ARGUMENT", "Message is null", null)
        }
      }
      "getConnectedDevices" -> {
        getConnectedDevices(result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun setPackageNameClassName(result: MethodChannel.Result, params: Map<String,String>) {
    val pkg = params["packageName"]
    val cls = params["className"]
    if (pkg != null && cls != null) {
      packageName = pkg
      className = cls
      Log.d(tag, "Set packageName = $pkg, className = $cls")
      result.success(null)
    } else {
      result.error("INVALID_ARGUMENTS", "Missing packageName or className", null)
    }
  }

  private fun launchCompanionApp(result: MethodChannel.Result, uriString: String) {
    val uri = Uri.parse(uriString)  // 딥링크 또는 임의의 URI
    val intent = Intent(Intent.ACTION_VIEW).apply {
      data = uri
      addCategory(Intent.CATEGORY_BROWSABLE)
      flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    Log.d(tag, "launching companion app via URI $uri")
    val remoteActivityHelper = RemoteActivityHelper(context)
    val future = remoteActivityHelper.startRemoteActivity(intent, null)
    future.addListener({
      try {
        future.get()  // 성공 여부 확인
        Log.d(tag, "Successfully launched companion app via RemoteActivityHelper")
        result.success(true)
      } catch (e: Exception) {
        Log.e(tag, "Failed to launch companion app: ${e.message}", e)

        // 실패했을 경우 Play 스토어로 이동하는 딥링크 실행
        val playStoreIntent = Intent(Intent.ACTION_VIEW).apply {
          data = Uri.parse("https://play.google.com/store/apps/details?id=${context.packageName}")
          addCategory(Intent.CATEGORY_BROWSABLE)
          flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val fallbackFuture = remoteActivityHelper.startRemoteActivity(playStoreIntent, null)
        fallbackFuture.addListener({
          try {
            fallbackFuture.get()
            Log.d(tag, "Redirected to Play Store")
            result.success(false)
          } catch (storeEx: Exception) {
            Log.e(tag, "Failed to redirect to Play Store: ${storeEx.message}", storeEx)
            result.error("PLAY_STORE_FAIL", storeEx.message, null)
          }
        }, MoreExecutors.directExecutor())
      }
    }, MoreExecutors.directExecutor())
  }

  // 이 메서드는 모든 기기로 broadcast 한다.
  private fun sendMessageToConnected(message: Map<String, Any>) {
    val messageJson = JSONObject(message).toString()
    val nodeClient = Wearable.getNodeClient(context)
    nodeClient.connectedNodes.addOnCompleteListener { task ->
      if (!task.isSuccessful) {
        Log.e(tag, "Failed to get connected nodes: ${task.exception}")
        return@addOnCompleteListener
      }
      val nodes = task.result ?: emptyList()
      if (nodes.isEmpty()) {
        Log.w(tag, "No connected nodes available to send message.")
      }

      nodes.forEach { node ->
        val messageClient = Wearable.getMessageClient(context)
        messageClient.sendMessage(node.id, "/message", messageJson.toByteArray())
          .addOnCompleteListener { sendTask ->
            if (sendTask.isSuccessful) {
              Log.d(tag, "Message sent to ${node.displayName}: $messageJson")
            } else {
              Log.e(tag, "Failed to send message: ${sendTask.exception}")
            }
          }
      }
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    Log.d(tag, "WearCommunicatorPlugin.kt / onListen.")
    if (eventSink != null) {
      Log.w(tag, "Event sink already active. Ignoring additional listener.")
      return
    }
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    Log.d(tag, "WearCommunicatorPlugin.kt / onCancel.")
    eventSink = null
  }

  private val messageListener = MessageClient.OnMessageReceivedListener { event ->
    val message = String(event.data)
    Log.d(tag, "Message received: $message")
    try {
      val messageMap: Map<String, Any?> = JSONObject(message).toMap()
      val targetId = (messageMap["target"] as? Map<*, *>)?.get("id") as? String
      val myId = thisDeviceNodeId
      Log.d(tag, "listeningForMessages.. isDetachedFromEngine? $isDetachedFromEngine")
      if ((targetId == myId) && ((messageMap["messageType"] as? String)=="command") && isDetachedFromEngine){
        val play: Boolean? = (messageMap["play"] as? Boolean)
        startMediaService1(play)
      } else {
        eventSink?.success(messageMap)
      }
    } catch (e: Exception) {
      Log.e(tag, "Failed to parse received message: $message", e)
    }
  }

  private fun startMediaService1(play: Boolean?) {
    Log.d(tag, "startMediaService1() start.")
    if(packageName == null || className == null) return
    var browser: MediaBrowserCompat? = null
    browser = MediaBrowserCompat(
      context,
      ComponentName((packageName as String), (className as String)),
      object : MediaBrowserCompat.ConnectionCallback() {
        override fun onConnected() {
          browser?.let {
            val controller = MediaControllerCompat(context, it.sessionToken)
            // getLastCtrl 때문에 불필요?
            // if(play == true) {
            //   controller.transportControls.play()
            // }else {
            //   controller.transportControls.pause()
            // }
            Log.d(tag, "MediaBrowserCompat ${packageName}    ${className}\nconnected and issued play command")
          } ?: Log.e(tag, "MediaBrowserCompat is null on connected")
        }
        override fun onConnectionFailed() {
          Log.e(tag, "MediaBrowserCompat connection failed..")
        }
      },
      null
    )
    browser.connect()
    Log.d(tag, "startMediaService1() finished.")
  }

  private fun JSONObject.toMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = keys()
    while (keys.hasNext()) {
      val key = keys.next()
      val value = when (val v = this.get(key)) {
        is JSONObject -> v.toMap()
        is org.json.JSONArray -> v.toList()
        JSONObject.NULL -> null
        else -> v
      }
      map[key] = value
    }
    return map
  }

  private fun org.json.JSONArray.toList(): List<Any?> {
    val list = mutableListOf<Any?>()
    for (i in 0 until length()) {
      val value = when (val v = get(i)) {
        is JSONObject -> v.toMap()
        is org.json.JSONArray -> v.toList()
        JSONObject.NULL -> null
        else -> v
      }
      list.add(value)
    }
    return list
  }

  // 이 메서드 내에서 현재의 디바이스 Node ID를 로컬변수로 갱신한다.
  private fun getConnectedDevices(result: MethodChannel.Result) {
    val client = Wearable.getNodeClient(context)
    val deviceList = mutableListOf<Map<String, Any>>()
    client.localNode
      .addOnSuccessListener { localNode ->
        thisDeviceNodeId = localNode.id
        Log.d(tag, "Local node (this device) ID: $thisDeviceNodeId")
        val localDevice = mapOf(
          "id" to localNode.id,
          "name" to localNode.displayName,
        )
        deviceList.add(localDevice)
        client.connectedNodes
          .addOnSuccessListener { nodes ->
            val connectedDevices = nodes.map { node ->
              mapOf(
                "id" to node.id,
                "name" to node.displayName,
                "isNearby" to node.isNearby
              )
            }
            deviceList.addAll(connectedDevices)
            result.success(deviceList)
          }
          .addOnFailureListener { e ->
            Log.e(tag, "Failed to get connected nodes", e)
            result.error("GET_CONNECTED_FAILED", e.message, null)
          }
      }
      .addOnFailureListener { e ->
        // Log.e(tag, "Failed to get local node", e)
        result.error("GET_LOCAL_NODE_FAILED", e.message, null)
        // result.success([])
      }

  }
}
