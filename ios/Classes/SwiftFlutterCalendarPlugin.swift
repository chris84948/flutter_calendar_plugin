import Flutter
import UIKit
import EventKit
    
public class SwiftFlutterCalendarPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_calendar_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCalendarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  // public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

  //   let eventStore = EKEventStore();
  //   if (!getPermissions(eventStore, call)) {
  //     result(FlutterError.init(code: "PERMISSIONS", message: "Calendar permissions denied by user.", details: nil));
  //   }
  // }

  // func getPermissions(_ eventStore: EKEventStore) -> Bool {
  //   let semaphore = DispatchSemaphore(value: 1);
  //   switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) {
  //     case .Authorized:
  //       return true;

  //     case .Denied:
  //       return false;

  //     case .NotDetermined:
  //       Bool permissionsGranted = false;
  //       eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion:
  //         {[weak self] (granted: Bool, error: NSError!) -> Void in
  //           permissionsGranted = granted;
  //           semaphore.signal(); // Release the semaphore wait
  //       });
  //       semaphore.wait(); // Waiting for response from permissions request
  //       return permissionsGranted;

  //     default:
  //       return false;
  //   }
  // }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let eventStore = EKEventStore();
    checkPermissionThenGetResult(eventStore, call));
  }

  func checkPermissionThenGetResult(_ eventStore: EKEventStore, _ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
    bool permissionGranted = false;
    switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) {
      case .Authorized:
        onPermissionReturn(eventStore, call, true, result: result);

      case .Denied:
        onPermissionReturn(eventStore, call, false, result: result);

      case .NotDetermined:
        Bool permissionsGranted = false;
        eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion:
          {[weak self] (granted: Bool, error: NSError!) -> Void in
            onPermissionReturn(eventStore, call, granted, result: result);
        });

      default:
        onPermissionReturn(eventStore, call, false, result: result);
    }

    onPermissionReturn(eventStore, call, permissionGranted, result: result);
  }

  func onPermissionReturn(_ eventStore: EKEventStore, _ call: FlutterMethodCall, _ permissionGranted: Bool, result: @escaping FlutterResult) {
    do {

      if (permissionGranted) {
        try result(handleRequest(call, eventStore));
      } else {
        result(FlutterError.init(code: "PERMISSIONS", message: "Calendar permissions denied by user.", details: nil));
      }

    } catch is Error {
      result(FlutterError.init(code: "CALENDAR", message: "Calendar error occurred.", details: nil));
    }
  }

  func handleRequest(_ call: FlutterMethodCall, _ eventStore: EKEventStore) -> FlutterResult {
    if ("listAllCalendars" == call.method) {
      return listAllCalendars(eventStore: EKEventStore);

    } else if ("addCalendarEvent" == call.method) {
      return addCalendarEvent(call: FlutterMethodCall, eventStore: EKEventStore);

    } else if ("updateCalendarEvent" == call.method) {
      return updateCalendarEvent(call: FlutterMethodCall, eventStore: EKEventStore);

    } else if ("deleteCalendarEvent" == call.method) {
      return deleteCalendarEvent(call: FlutterMethodCall, eventStore: EKEventStore);

    } else {
      throw Error;
    }
  }

  func listAllCalendars(eventStore: EKEventStore) -> Dictionary<Int, String> {

    /*
    var calendarMap = [Int: String];
    
    let calendars = eventStore.calendars(for: EKEntityTypeEvent) as! [EKCalendar]
    for calendar in calendars {
      calendarMap[calendar.calendarIdentifier] = calendar.title;
    }

    return calendarMap;
    */

    var calendars = [String: String];
    calendars["1"] = "Client Calendar";
    calendars["2"] = "Shared";
    calendars["3"] = "chris84948@gmail.com";

    return calendars;
  }

  func addCalendarEvent(call: FlutterMethodCall, eventStore: EKEventStore) -> Int {
    /*
    let args = call.arguments as? [String: Any];
    
    var event = EKEvent(eventStore: eventStore);
    event.calendar = eventStore.calendar(withIdentifier: (args["calendarID"] as String));
      
    var dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm";
    var startDate = dateFormatter.date(from: (args["startTime"] as String));

    event.title = args["title"] as String;
    
    if (args["allDay"] != nil) {
      event.startDate = startDate;
      event.endDate = startDate;
      event.allDay = true;
    } else {
      event.startDate = startDate;
      event.endDate = startDate.dateByAddingTimeInterval(60 * (args["durationInMins"] as Int));
    }
    
    if (args["description"] != nil) {
      event.notes = args["description"] as String;
    }

    if (args["location"] != nil && (args["location"] as String) != "") {
      event.structuredLocation = EKStructuredLocation(title: (args["location"] as String));
    }

    if (args["addReminder"] == true) {
      event.addAlarm(EKAlarm(relativeOffset: TimeInterval(60 * (args["reminderWarningInMins"] as Int))));
    }

    var error: NSError?
    let result = store.saveEvent(event, span: EKSpanThisEvent, error: &error)
      
    if (result == true) {
      return event.eventIdentifier;
    } else {
      if let theError = error {
        println("An error occured \(theError)")
      }
    }
    */

    return 0;
  }

  func updateCalendarEvent(call: FlutterMethodCall, eventStore: EKEventStore) -> Int {
    /*
    let args = call.arguments as? [String: Any];
    
    var event = EKEvent(withIdentifier: (args["eventID"] as String));

    if (let calendarID = args["calendarID"] as String) {
      event.calendar = eventStore.calendar(withIdentifier: calendarID);
    }

    if (let title = args["title"] as String) {
      event.title = title;
    }  

    var dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm";
    var startDate : NSDate? = nil;

    if (let startTime = args["startTime"] as String) {
      startDate = dateFormatter.date(from: startTime);
    
      if (args["allDay"] != nil) {
        event.startDate = startDate;
        event.endDate = startDate;
        event.allDay = true;
      } else {
        event.startDate = startDate;
        event.endDate = startDate.dateByAddingTimeInterval(60 * (args["durationInMins"] as Int));
      }
    }
    
    if (args["description"] != nil) {
      event.notes = args["description"] as String;
    }

    if (args["location"] != nil && (args["location"] as String) != "") {
      event.structuredLocation = EKStructuredLocation(title: (args["location"] as String));
    }

    if (args["addReminder"]) {
      event.alarms = nil;
      event.addAlarm(EKAlarm(relativeOffset: TimeInterval(60 * (args["reminderWarningInMins"] as Int))));
    }

    var error: NSError?
    let result = store.saveEvent(event, span: EKSpanThisEvent, error: &error)
      
    if (result == true) {
      return event.eventIdentifier;
    } else {
      if let theError = error {
        println("An error occured \(theError)")
      }
    }

    */
    return 1;
  }

  func deleteCalendarEvent(call: FlutterMethodCall, eventStore: EKEventStore) -> Int {
    /*
    let args = call.arguments as? [String: Any];

    var event = EKEvent(withIdentifier: (args["eventID"] as String));
    eventStore.removeEvent(event, span:EKSpanThisEvent error:nil);
    */

    return 2;
  }
}