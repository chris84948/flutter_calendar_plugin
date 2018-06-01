import 'package:flutter_calendar_plugin/FlutterCalendarPlugin.dart';

class EventDetail {
  String title;
  String description;
  String location;

  DateTime startTime;
  int durationInMins;
  bool allDay;

  bool addReminder;
  int reminderWarningInMins;
  ReminderType reminderType;
  Calendar calendar;

  EventDetail(this.title,
      this.startTime,
      this.calendar,
      { this.description,
        this.location,
        this.durationInMins,
        this.allDay,
        this.addReminder,
        this.reminderWarningInMins,
        this.reminderType });

  EventDetail.empty(this.calendar) {
    this.title = "";
    this.startTime = new DateTime.now();
    this.durationInMins = 60;
    this.reminderWarningInMins = 60;
    this.reminderType = ReminderType.alert;
  }
}