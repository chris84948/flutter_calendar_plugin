import 'package:flutter/services.dart';
import 'package:flutter_calendar_plugin/calendar.dart';
import 'package:flutter_calendar_plugin/reminder_type.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:intl/intl.dart';

class FlutterCalendarPlugin extends PlatformInterface {
  final dateFormat = DateFormat("yyyy-MM-dd HH:mm");
  final methodChannel = const MethodChannel('flutter_calendar_plugin');
  static final Object _token = Object();

  FlutterCalendarPlugin() : super(token: _token);

  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return '$version test 4';
  }

  Future<List<Calendar>> listAllCalendars() async {
    final Map<dynamic, dynamic> result =
        await methodChannel.invokeMethod('listAllCalendars');
    return result.entries.map((r) => Calendar(r.key, r.value)).toList();
  }

  Future<String> addCalendarEvent(String title, DateTime startTime,
      {String? calendarID,
      String? description,
      String? location,
      int? durationInMins,
      bool? allDay,
      bool? addReminder,
      int? reminderWarningInMins,
      ReminderType? reminderType}) async {
    var args = <String, dynamic>{};

    args["title"] = title;
    args["startTime"] = dateFormat.format(startTime);
    args["calendarID"] = calendarID ?? "1";

    if (description != null && description != "") {
      args["description"] = description;
    }

    if (location != null && location != "") {
      args["location"] = location;
    }

    // Have to pick one of these two options
    if (allDay != null && allDay) {
      args["allDay"] = allDay;
    } else if (durationInMins != null && durationInMins > 0) {
      args["durationInMins"] = durationInMins;
    }

    if (addReminder != null && addReminder) {
      args["addReminder"] = addReminder;
      args["reminderWarningInMins"] = reminderWarningInMins ?? 30;
      args["reminderType"] = reminderType?.index ?? ReminderType.alert.index;
    }

    return await methodChannel.invokeMethod('addCalendarEvent', args);
  }

  Future updateCalendarEvent(String eventID,
      {String? calendarID,
      String? title,
      DateTime? startTime,
      String? description,
      String? location,
      int? durationInMins,
      bool? allDay,
      bool? addReminder,
      int? reminderWarningInMins,
      ReminderType? reminderType}) async {
    var args = <String, dynamic>{};

    args["eventID"] = eventID;

    if (calendarID != null) {
      args["calendarID"] = calendarID;
    }

    if (title != null && title != "") {
      args["title"] = title;
    }

    if (startTime != null) {
      args["startTime"] = dateFormat.format(startTime);
    }

    if (description != null && description != "") {
      args["description"] = description;
    }

    if (location != null && location != "") {
      args["location"] = location;
    }

    if (allDay != null) {
      args["allDay"] = allDay;
    }

    if (durationInMins != null) {
      args["durationInMins"] = durationInMins;
    }

    if (addReminder != null) {
      args["addReminder"] = addReminder;
      args["reminderWarningInMins"] = reminderWarningInMins ?? 30;
      args["reminderType"] = reminderType?.index ?? ReminderType.alert.index;
    }

    await methodChannel.invokeMethod('updateCalendarEvent', args);
  }

  Future deleteCalendarEvent(String eventID) async {
    await methodChannel.invokeMethod('deleteCalendarEvent', <String, String>{
      'eventID': eventID,
    });
  }
}
