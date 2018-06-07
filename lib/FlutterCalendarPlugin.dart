import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

enum ReminderType { system_default, alert, email, sms }

class Calendar {
  String id;
  String name;

  Calendar(this.id, this.name);

  @override
  String toString() => name;
}

class FlutterCalendarPlugin {
  static final DateFormat _dateFormat = new DateFormat("yyyy-MM-dd HH:mm");

  static const MethodChannel _channel =
      const MethodChannel('com.chrisbjohnson.flutter_calendar_plugin');

  static Future<List<Calendar>> listAllCalendars() async {
    dynamic result = await _channel.invokeMethod('listAllCalendars');
    final Map<dynamic, dynamic> calendars = result;
    List<Calendar> calendarItems = [];
    calendars.forEach((id, name) => calendarItems.add(new Calendar(id, name)));
    return calendarItems;
  }

  static Future<String> addCalendarEvent(String title, DateTime startTime,
      {String calendarID,
      String description,
      String location,
      int durationInMins,
      bool allDay,
      bool addReminder,
      int reminderWarningInMins,
      ReminderType reminderType}) async {
    var args = new Map<String, dynamic>();

    args["title"] = title;
    args["startTime"] = _dateFormat.format(startTime);
    args["calendarID"] = calendarID ?? "1";

    if (description != null && description != "")
      args["description"] = description;

    if (location != null && location != "") args["location"] = location;

    // Have to pick one of these two options
    if (allDay != null && allDay)
      args["allDay"] = allDay;
    else if (durationInMins != null && durationInMins > 0)
      args["durationInMins"] = durationInMins;

    if (addReminder != null && addReminder) {
      args["addReminder"] = addReminder;
      args["reminderWarningInMins"] = reminderWarningInMins ?? 30;
      args["reminderType"] = reminderType?.index ?? ReminderType.alert.index;
    }

    return await _channel.invokeMethod('addCalendarEvent', args);
  }

  static Future updateCalendarEvent(String eventID,
      {String calendarID,
      String title,
      DateTime startTime,
      String description,
      String location,
      int durationInMins,
      bool allDay,
      bool addReminder,
      int reminderWarningInMins,
      ReminderType reminderType}) async {
    var args = new Map<String, dynamic>();

    args["eventID"] = eventID;

    if (calendarID != null) args["calendarID"] = calendarID;

    if (title != null && title != "") args["title"] = title;

    if (startTime != null) args["startTime"] = _dateFormat.format(startTime);

    if (description != null && description != "")
      args["description"] = description;

    if (location != null && location != "") args["location"] = location;

    if (allDay != null) args["allDay"] = allDay;

    if (durationInMins != null) args["durationInMins"] = durationInMins;

    if (addReminder != null) {
      args["addReminder"] = addReminder;
      args["reminderWarningInMins"] = reminderWarningInMins ?? 30;
      args["reminderType"] = reminderType?.index ?? ReminderType.alert.index;
    }

    int result = await _channel.invokeMethod('updateCalendarEvent', args);
    return result;
  }

  static Future deleteCalendarEvent(String eventID) async {
    await _channel.invokeMethod('deleteCalendarEvent', <String, dynamic>{
      'eventID': eventID,
    });
  }
}
