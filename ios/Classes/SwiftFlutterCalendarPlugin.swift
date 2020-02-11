import Flutter
import UIKit
import EventKit

public class SwiftFlutterCalendarPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.chrisbjohnson.flutter_calendar_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCalendarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  let _eventStore = EKEventStore()

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    requestPermissions(call, result);
  }

  private func requestPermissions(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let status = EKEventStore.authorizationStatus(for: .event)

    if(status == EKAuthorizationStatus.authorized) {  // Granted Permission
      onPermissionReturn(call, true, result: result);
    } else if (status == EKAuthorizationStatus.notDetermined) { // Request Permission
      _eventStore.requestAccess(to: .event, completion: {
        (accessGranted: Bool, error: Error?) in
          self.onPermissionReturn(call, accessGranted, result: result);
        })
    } else if (status == EKAuthorizationStatus.denied) {  // Denied permission
      showEventsAcessDeniedAlert(call, result);
    }
  }

  func showEventsAcessDeniedAlert(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let alertController = UIAlertController(title: "Doula Life Calendar Permission",
                                            message: "The calendar permission was not authorized. Please enable it in Settings to continue.",
                                            preferredStyle: .alert);

    let settingsAction = UIAlertAction(title: "Settings", style: .default) {
      (alertAction) in
      // This jumps to the settings area
      if let appSettings = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.openURL(appSettings)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: {
                (success) in
                // We're back from our trip to the settings page, check permissions again and repond appropriately
                let status = EKEventStore.authorizationStatus(for: .event);
                self.onPermissionReturn(call, status == EKAuthorizationStatus.authorized, result: result);
            })
        } else {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.openURL(appSettings);
            }
        };
      }
    }
    alertController.addAction(settingsAction);

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
      (alertAction) in
        self.onPermissionReturn(call, false, result: result);
    }
    alertController.addAction(cancelAction);

    var topController = UIApplication.shared.keyWindow!.rootViewController as! UIViewController
    while ((topController.presentedViewController) != nil) {
        topController = topController.presentedViewController!;
    }
    topController.present(alertController, animated: true, completion: nil);
  }

  func onPermissionReturn(_ call: FlutterMethodCall, _ permissionGranted: Bool, result: @escaping FlutterResult) {
    if (permissionGranted) {
      if ("listAllCalendars" == call.method) {
        return listAllCalendars(result);
      } else if ("addCalendarEvent" == call.method) {
        addCalendarEvent(call, result);
      } else if ("updateCalendarEvent" == call.method) {
        updateCalendarEvent(call, result);
      } else if ("deleteCalendarEvent" == call.method) {
        deleteCalendarEvent(call, result);
      } else {
        result(FlutterError.init(code: "METHOD", message: "Method does not exist.", details: nil));
      }
    } else {
      result(FlutterError.init(code: "PERMISSIONS", message: "Calendar permissions denied by user.", details: nil));
    }
  }

  func listAllCalendars(_ result: @escaping FlutterResult) {
    var calendarMap = Dictionary<String, String>();

    let calendars = _eventStore.calendars(for: EKEntityType.event)
    for calendar in calendars {
      if (!calendar.calendarIdentifier.isEmpty) {
        calendarMap[calendar.calendarIdentifier] = calendar.title;
      }
    }

    result(calendarMap);
  }

  func addCalendarEvent(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any];

    let event = EKEvent(eventStore: _eventStore);
    event.calendar = _eventStore.calendar(withIdentifier: (args!["calendarID"] as! String));

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm";
    let startDate = dateFormatter.date(from: (args!["startTime"] as! String));

    event.title = args!["title"] as! String;

    if (args!["allDay"] != nil) {
      event.startDate = startDate;
      event.endDate = startDate;
      event.isAllDay = true;
    } else {
      event.startDate = startDate;
      event.endDate = startDate?.addingTimeInterval(60.0 * Double(args!["durationInMins"] as! Int));
    }

    if (args!["description"] != nil) {
      event.notes = args!["description"] as? String;
    }

    if (args!["location"] != nil && (args!["location"] as! String) != "") {
      if #available(iOS 9.0, *) {
        event.structuredLocation = EKStructuredLocation(title: (args!["location"] as! String))
      }
    }

    if (args!["addReminder"] != nil && (args!["addReminder"] as! Bool) == true) {
      event.addAlarm(EKAlarm(relativeOffset: TimeInterval(-60 * (args!["reminderWarningInMins"] as! Int))));
    }

    do {
      try _eventStore.save(event, span: EKSpan.futureEvents)
      result(event.eventIdentifier)
    } catch {
      _eventStore.reset()
      result(FlutterError(code: "CALENDAR", message: error.localizedDescription, details: nil))
    }
  }

  func updateCalendarEvent(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any];

    let event = _eventStore.event(withIdentifier: (args!["eventID"] as! String));

    let calendarID = args!["calendarID"] as! String;
    event?.calendar = _eventStore.calendar(withIdentifier: calendarID);

    let title = args!["title"] as! String;
    event?.title = title;

    let dateFormatter = DateFormatter();
    dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm";
    var startDate : Date? = nil;

    let startTime = args!["startTime"] as! String
    startDate = dateFormatter.date(from: startTime);

    if (args!["allDay"] != nil) {
      event?.startDate = startDate;
      event?.endDate = startDate;
      event?.isAllDay = true;
    } else {
      event?.startDate = startDate;
      event?.endDate = startDate?.addingTimeInterval(60.0 * Double(args!["durationInMins"] as! Int));
    }

    if (args!["description"] != nil) {
      event?.notes = args!["description"] as? String;
    }

    if (args!["location"] != nil && (args!["location"] as! String) != "") {
      if #available(iOS 9.0, *) {
        event?.structuredLocation = EKStructuredLocation(title: (args!["location"] as! String))
      } else {
        // Fallback on earlier versions
      };
    }

    event?.alarms = nil;
    if ((args!["addReminder"] as! Bool) == true) {
      event?.addAlarm(EKAlarm(relativeOffset: TimeInterval(-60 * (args!["reminderWarningInMins"] as! Int))));
    }

    do {
      try _eventStore.save(event!, span: EKSpan.futureEvents)
      result(event?.eventIdentifier)
    } catch {
      _eventStore.reset()
      result(FlutterError(code: "CALENDAR", message: error.localizedDescription, details: nil))
    }
  }

  func deleteCalendarEvent(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any];

    if let event = _eventStore.event(withIdentifier: (args!["eventID"] as! String)) {
      do {
        try _eventStore.remove(event, span: EKSpan.futureEvents);
        result(true);
      } catch {
        _eventStore.reset()
        result(FlutterError(code: "CALENDAR", message: error.localizedDescription, details: nil))
      }
    }
  }
}
