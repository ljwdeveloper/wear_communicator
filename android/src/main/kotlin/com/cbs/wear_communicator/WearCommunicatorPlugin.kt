package com.cbs.wear_communicator

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import org.json.JSONObject

/** WearCommunicatorPlugin */
class WearCommunicatorPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(binding.binaryMessenger, "wear_communicator")
    eventChannel = EventChannel(binding.binaryMessenger, "wear_communicator_events")
    methodChannel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "sendMessage" -> {
        val message = call.argument<Map<String, Any>>("message")
        if (message != null) {
            sendMessageToWearable(message)
            result.success(null)
        } else {
            result.error("INVALID_ARGUMENT", "Message is null", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun sendMessageToWearable(message: Map<String, Any>) {
    try {
        // Example: Convert the message Map to JSON String for sending to the wearable device
        val jsonMessage = JSONObject(message).toString()
        // TODO: Replace with actual wearable API call to send the message
        Log.d("WearCommunicator", "Sending message to wearable: $jsonMessage")
    } catch (e: Exception) {
        Log.e("WearCommunicator", "Error sending message: ${e.localizedMessage}")
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    // Register listener for incoming messages
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  private fun notifyMessageReceived(message: String) {
    eventSink?.success(message)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
