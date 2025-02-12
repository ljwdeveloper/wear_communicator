import Flutter
import WatchConnectivity

public class WearCommunicatorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, WCSessionDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private let session: WCSession = WCSession.default
    private let tag = "WearCommunicator"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = WearCommunicatorPlugin()

        instance.methodChannel = FlutterMethodChannel(name: "wear_communicator", binaryMessenger: registrar.messenger())
        instance.eventChannel = FlutterEventChannel(name: "wear_communicator_events", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        instance.eventChannel?.setStreamHandler(instance)

        if WCSession.isSupported() {
            instance.session.delegate = instance
            instance.session.activate()
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "sendMessage":
            if let args = call.arguments as? [String: Any] {
                sendMessageToConnected(message: args)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Message is null", details: nil))
            }
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func sendMessageToConnected(message: [String: Any]) {
        if session.isReachable {
            do {
                let data = try JSONSerialization.data(withJSONObject: message, options: [])
                let jsonString = String(data: data, encoding: .utf8) ?? "{}"
                
                session.sendMessage(["message": jsonString], replyHandler: nil) { error in
                    print("\(self.tag) - Failed to send message: \(error.localizedDescription)")
                }
                print("\(self.tag) - Message sent: \(jsonString)")
            } catch {
                print("\(self.tag) - JSON serialization error: \(error.localizedDescription)")
            }
        } else {
            print("\(self.tag) - Session is not reachable")
        }
    }

    // MARK: - Watch Connectivity Delegate

    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let jsonString = message["message"] as? String {
            do {
                if let jsonData = jsonString.data(using: .utf8),
                   let messageMap = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    eventSink?(messageMap)
                    print("\(tag) - Received message: \(messageMap)")
                }
            } catch {
                print("\(tag) - Failed to parse received message: \(error.localizedDescription)")
            }
        }
    }

    // MARK: @objc - Flutter Stream Handler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - WCSession Lifecycle

    public func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("\(tag) - WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("\(tag) - WCSession activated with state: \(state.rawValue)")
        }
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(tag) - WCSession did become inactive")
    }

    public func sessionDidDeactivate(_ session: WCSession) {
        print("\(tag) - WCSession did deactivate, reactivating session...")
        session.activate()
    }
    #endif
}
