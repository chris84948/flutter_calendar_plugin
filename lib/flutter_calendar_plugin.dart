import 'dart:async';

import 'package:flutter/services.dart';

class FlutterCalendarPlugin {
  static const MethodChannel _channel =
      const MethodChannel('com.chrisbjohnson.flutter_calendar_plugin');

  static Future<int> addCalendarEvent() async {
    final int eventID = await _channel.invokeMethod('addCalendarEvent');
    return eventID;
  }

  static Future<int> updateCalendarEvent(int eventID) async {
    int rowsChanged = await _channel.invokeMethod('updateCalendarEvent', <String, dynamic>{ 'eventID': eventID, });
    return rowsChanged;
  }

  static Future<int> deleteCalendarEvent(int eventID) async {
    int rowsChanged = await _channel.invokeMethod('deleteCalendarEvent', <String, dynamic>{ 'eventID': eventID, });
    return rowsChanged;
  }
}