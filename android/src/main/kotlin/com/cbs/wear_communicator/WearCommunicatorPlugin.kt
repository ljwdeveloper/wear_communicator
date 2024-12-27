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
import io.flutter.plugin.common.MethodChannel.Result

import org.json.JSONObject

/** WearCommunicatorPlugin */
class WearCommunicatorPlugin: FlutterPlugin, MethodCallHandler, StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  private val tag = "WearCommunicator"
  private lateinit var context: Context


  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "wear_communicator")
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "wear_communicator_events")
    methodChannel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
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
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun sendMessageToConnected(message: Map<String, Any>) {
    val messageJson = JSONObject(message).toString()
    val nodeClient = Wearable.getNodeClient(context)
    nodeClient.connectedNodes.addOnCompleteListener { task ->
      if (task.isSuccessful) {
        val nodes = task.result
        nodes?.forEach { node ->
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
      } else {
        Log.e(tag, "Failed to get connected nodes: ${task.exception}")
      }
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    startListeningForMessages()
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

}
