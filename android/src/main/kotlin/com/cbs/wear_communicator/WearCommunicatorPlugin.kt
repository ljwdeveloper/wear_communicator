package com.cbs.wear_communicator

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.*

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
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private val tag = "WearCommunicator"
  private lateinit var context: Context

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
    startListeningForMessages()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    val messageClient = Wearable.getMessageClient(context)
    messageClient.removeListener{ event ->
      Log.d(tag, "Listener removed.")
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "sendMessage" -> {
        val message = call.argument<Map<String, Any>>("message")
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
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  // 이 메서드 통해서 현재의 디바이스 Node ID를 최신화한다.
  private fun sendMessageToConnected(message: Map<String, Any>) {
    val messageJson = JSONObject(message).toString()
    val targetNodeId = message["id"] as? String
    val nodeClient = Wearable.getNodeClient(context)
    nodeClient.connectedNodes.addOnCompleteListener { task ->
      if (!task.isSuccessful) {
        Log.e(tag, "Failed to get connected nodes: ${task.exception}")
        return@addOnCompleteListener
      }
      val nodes = task.result ?: emptyList()
      val targetNodes = if (targetNodeId != null) {
        nodes.filter { it.id == targetNodeId }
      } else {
        nodes
      }

      if(targetNodes.isEmpty()) {
        Log.w(tag, "No target node(s) matched for sending message.")
      }
      targetNodes.forEach { node ->
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
    if (eventSink != null) {
      Log.w(tag, "Event sink already active. Ignoring additional listener.")
      return
    }
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun startListeningForMessages() {
    val messageClient = Wearable.getMessageClient(context)
    messageClient.addListener { event ->
      val message = String(event.data)
      Log.d(tag, "Message received: $message")
      try {
        val messageMap = JSONObject(message).toMap()

        val targetId = messageMap["id"] as? String
        val myId = thisDeviceNodeId

        // 메시지가 특정 노드로 지정되었고, 그 노드가 현재 기기가 아니면 무시
        if (targetId != null && targetId != myId) {
          Log.d(tag, "Message target ($targetId) does not match local node ($myId). Ignoring.")
          return@addListener
        }
        eventSink?.success(messageMap)
      } catch (e: Exception) {
        Log.e(tag, "Failed to parse received message: $message", e)
      }
    }
  }

  private fun JSONObject.toMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    val keys = keys()
    while (keys.hasNext()) {
      val key = keys.next()
      map[key] = this.get(key)
    }
    return map
  }

  // 이 메서드 내에서 현재의 디바이스 Node ID를 로컬변수로 갱신한다.
  private fun getConnectedDevices(result: MethodChannel.Result) {
    val client = Wearable.getNodeClient(context)
    client.localNode
      .addOnSuccessListener { node ->
        thisDeviceNodeId = node.id
        Log.d(tag, "Local node (this device) ID: $thisDeviceNodeId")
      }
    client.connectedNodes
      .addOnSuccessListener { nodes ->
        val deviceList = nodes.map { node ->
        mapOf(
          "id" to node.id,
          "name" to node.displayName,
          "isNearby" to node.isNearby
        )
      }
      result.success(deviceList)
      }
      .addOnFailureListener { e ->
        Log.e(tag, "Failed to get connected nodes", e)
        result.error("GET_CONNECTED_FAILED", e.message, null)
      }
  }
}
