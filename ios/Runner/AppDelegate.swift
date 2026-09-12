import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    IosReminderNotifications.register(messenger: engineBridge.applicationRegistrar.messenger())
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}

enum IosReminderNotifications {
  static let channelName = "anshow/ios_reminders"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "request":
        request(result: result)
      case "schedule":
        schedule(call.arguments, result: result)
      case "show":
        show(call.arguments, result: result)
      case "cancel":
        cancel(call.arguments, result: result)
      case "cancelAll":
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func request(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(code: "permission", message: error.localizedDescription, details: nil))
          return
        }
        result(granted)
      }
    }
  }

  private static func schedule(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let map = arguments as? [String: Any],
          let id = map["id"] as? Int,
          let body = map["body"] as? String else {
      result(FlutterError(code: "args", message: "Missing reminder arguments", details: nil))
      return
    }

    let seconds = (map["seconds"] as? Double) ?? 1
    addRequest(
      id: id,
      body: body,
      delay: max(seconds, 1),
      result: result
    )
  }

  private static func show(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let map = arguments as? [String: Any],
          let id = map["id"] as? Int,
          let body = map["body"] as? String else {
      result(FlutterError(code: "args", message: "Missing reminder arguments", details: nil))
      return
    }
    addRequest(id: id, body: body, delay: 1, result: result)
  }

  private static func cancel(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let map = arguments as? [String: Any], let id = map["id"] as? Int else {
      result(FlutterError(code: "args", message: "Missing reminder id", details: nil))
      return
    }
    let identifier = "anshow-\(id)"
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [identifier])
    center.removeDeliveredNotifications(withIdentifiers: [identifier])
    result(nil)
  }

  private static func addRequest(
    id: Int,
    body: String,
    delay: TimeInterval,
    result: @escaping FlutterResult
  ) {
    let content = UNMutableNotificationContent()
    content.title = "AnShow Anime show"
    content.body = body
    content.sound = .default
    content.badge = 1
    if #available(iOS 15.0, *) {
      content.interruptionLevel = .active
    }

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
    let request = UNNotificationRequest(identifier: "anshow-\(id)", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(code: "schedule", message: error.localizedDescription, details: nil))
        } else {
          result(true)
        }
      }
    }
  }
}
