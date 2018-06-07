package com.chrisbjohnson.fluttercalendarplugin;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.CalendarContract;
import android.util.Log;

import java.text.ParseException;
import java.text.ParsePosition;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterCalendarPlugin
 */
public class FlutterCalendarPlugin implements MethodCallHandler, PluginRegistry.RequestPermissionsResultListener
{
  private static final int ADD_EVENT_REQUESTCODE = 1;
  private static final int UPDATE_EVENT_REQUESTCODE = 2;
  private static final int DELETE_EVENT_REQUESTCODE = 3;
  private static final int LIST_CALENDARS_REQUESTCODE = 4;
  private static final String[] REQUIRED_PERMISSIONS = new String[]{Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR};
  final String[] EVENT_PROJECTION = new String[]{
          CalendarContract.Calendars._ID,
          CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
  };
  private static final String CALENDER_EVENT_URI = "content://com.android.calendar/events";
  private static final String CALENDAR_REMINDER_URI = "content://com.android.calendar/reminders";
  private static final SimpleDateFormat DATEFORMAT = new SimpleDateFormat("yyyy-MM-dd' 'HH:mm");

  private PermissionCallback _permissionCallback;
  private Activity _activity;

  public static void registerWith(Registrar registrar)
  {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.chrisbjohnson.flutter_calendar_plugin");
    channel.setMethodCallHandler(new FlutterCalendarPlugin(registrar));
  }

  public FlutterCalendarPlugin(Registrar registrar)
  {
    _activity = registrar.activity();
    registrar.addRequestPermissionsResultListener(this);
  }

  @Override
  public boolean onRequestPermissionsResult(int requestCode,
                                            String[] permissions,
                                            int[] grantResults) {
    // If request is cancelled, the result arrays are empty.
    if (grantResults.length > 0
            && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
      _permissionCallback.granted(requestCode);
    } else {
      _permissionCallback.denied();
    }

    return true;
  }

  @Override
  public void onMethodCall(final MethodCall call, final Result result)
  {
    _permissionCallback = new PermissionCallback()
    {
      @Override
      public void granted(int requestCode)
      {
        try {
          result.success(getResultFromRequestCode(requestCode, call));
        } catch (Exception ex) {
          result.error("CALENDAR", ex.getMessage(), null);
        }
      }

      @Override
      public void denied()
      {
        result.error("PERMISSIONS", "Calendar permissions denied by user.", null);
      }
    };

    int requestCode = getRequestCodeFromMethodName(call.method);

    // Make sure we have calendar permissions before trying anything else
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            _activity.checkSelfPermission(REQUIRED_PERMISSIONS[0]) != PackageManager.PERMISSION_GRANTED) {
      _activity.requestPermissions(REQUIRED_PERMISSIONS, requestCode);
    } else {
      try {
        result.success(getResultFromRequestCode(requestCode, call));
      } catch (Exception ex) {
        result.error("CALENDAR", ex.getMessage(), null);
      }
    }
  }

  private Object getResultFromRequestCode(int requestCode, MethodCall call) throws ParseException {
    if (requestCode == ADD_EVENT_REQUESTCODE)
      return addCalendarEvent(call);
    else if (requestCode == UPDATE_EVENT_REQUESTCODE)
      return updateCalendarEvent(call);
    else if (requestCode == DELETE_EVENT_REQUESTCODE)
      return deleteCalendarEvent((String)call.argument("eventID"));
    else if (requestCode == LIST_CALENDARS_REQUESTCODE)
      return listAllCalendars();
    else
        return -2;
  }

  private int getRequestCodeFromMethodName(String methodName) {
    switch (methodName) {
      case "addCalendarEvent":
        return ADD_EVENT_REQUESTCODE;
      case "updateCalendarEvent":
        return UPDATE_EVENT_REQUESTCODE;
      case "deleteCalendarEvent":
        return DELETE_EVENT_REQUESTCODE;
      case "listAllCalendars":
        return LIST_CALENDARS_REQUESTCODE;
      default:
        return 5;
    }
  }

  @TargetApi(Build.VERSION_CODES.JELLY_BEAN)
  @SuppressWarnings({"MissingPermission"})
  public Map<String, String> listAllCalendars() {
    Map<String, String> calendars = new HashMap<>();

    final Uri uri = CalendarContract.Calendars.CONTENT_URI;
    Cursor cursor = _activity.getApplicationContext()
                             .getContentResolver()
                             .query(uri, EVENT_PROJECTION, null, null, null);

    while (cursor.moveToNext())
      calendars.put(Long.toString(cursor.getLong(0)), cursor.getString(1));

    return calendars;
  }

  public String addCalendarEvent(MethodCall call) throws ParseException {
      ContentValues eventValues = new ContentValues();
      eventValues.put("calendar_id", (String)call.argument("calendarID"));
      eventValues.put("title", (String)call.argument("title"));
      eventValues.put("eventTimezone", TimeZone.getDefault().getID());
      eventValues.put("hasAttendeeData", false);

      Calendar cal = Calendar.getInstance();
      cal.setTime(DATEFORMAT.parse((String)call.argument("startTime")));

      if (call.hasArgument("allDay")) {
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        eventValues.put("dtstart", cal.getTimeInMillis());
        eventValues.put("dtend", cal.getTimeInMillis());
        eventValues.put("allDay", 1);
      } else {
        eventValues.put("dtstart", cal.getTimeInMillis());
        long endDate = cal.getTimeInMillis() + (1000 * 60 * (int)call.argument("durationInMins"));
        eventValues.put("dtend", endDate);
      }

      if (call.hasArgument("description"))
        eventValues.put("description", (String)call.argument("description"));

      if (call.hasArgument("location"))
        eventValues.put("eventLocation", (String)call.argument("location"));

      boolean addReminder = call.hasArgument("addReminder");
      if (addReminder) {
        eventValues.put("hasAlarm", 1);
      }

      Uri eventUri = _activity.getApplicationContext()
                              .getContentResolver()
                              .insert(Uri.parse(CALENDER_EVENT_URI), eventValues);
      String eventID = eventUri.getLastPathSegment();

      if (addReminder) {
        ContentValues reminderValues = new ContentValues();
        reminderValues.put("event_id", eventID);
        reminderValues.put("minutes", (int)call.argument("reminderWarningInMins"));
        // Alert Methods: Default(0), Alert(1), Email(2), SMS(3)
        reminderValues.put("method", (int)call.argument("reminderType"));

        _activity.getApplicationContext()
                 .getContentResolver()
                 .insert(Uri.parse(CALENDAR_REMINDER_URI), reminderValues);
      }

      return eventID;
  }

  private int updateCalendarEvent(MethodCall call) throws ParseException {
      ContentValues eventValues = new ContentValues();

      if (call.hasArgument("calendarID"))
        eventValues.put("calendar_id", (String)call.argument("calendarID"));

      if (call.hasArgument("title"))
        eventValues.put("title", (String)call.argument("title"));

      if (call.hasArgument("startTime")) {
        Calendar cal = Calendar.getInstance();
        cal.setTime(DATEFORMAT.parse((String)call.argument("startTime")));

        if (call.hasArgument("allDay")) {
          cal.set(Calendar.HOUR_OF_DAY, 0);
          cal.set(Calendar.MINUTE, 0);
          eventValues.put("dtstart", cal.getTimeInMillis());
          eventValues.put("dtend", cal.getTimeInMillis());
          eventValues.put("allDay", 1);
        } else {
          eventValues.put("dtstart", cal.getTimeInMillis());
          long endDate = cal.getTimeInMillis() + (1000 * 60 * (int)call.argument("durationInMins"));
          eventValues.put("dtend", endDate);
        }
      }

      if (call.hasArgument("description"))
        eventValues.put("description", (String)call.argument("description"));

      if (call.hasArgument("location"))
        eventValues.put("eventLocation", (String)call.argument("location"));

      boolean addReminder = call.hasArgument("addReminder");
      if (addReminder) {
        eventValues.put("hasAlarm", 1);
      }

      String eventID = (String)call.argument("eventID");

      // Delete all old reminders
      _activity.getApplicationContext()
               .getContentResolver()
               .delete(Uri.parse(CALENDAR_REMINDER_URI), "event_id=?", new String[] { eventID });

      if (addReminder) {
        ContentValues reminderValues = new ContentValues();
        reminderValues.put("event_id", eventID);
        reminderValues.put("minutes", (int)call.argument("reminderWarningInMins"));
        // Alert Methods: Default(0), Alert(1), Email(2), SMS(3)
        reminderValues.put("method", (int)call.argument("reminderType"));

        _activity.getApplicationContext()
                .getContentResolver()
                .insert(Uri.parse(CALENDAR_REMINDER_URI), reminderValues);
      }

      Uri eventUri = ContentUris.withAppendedId(Uri.parse(CALENDER_EVENT_URI), Long.parseLong(eventID));
      return _activity.getContentResolver().update(eventUri, eventValues, null, null);
  }

  public int deleteCalendarEvent(String eventID) {
    // Delete all old reminders
    _activity.getApplicationContext()
             .getContentResolver()
             .delete(Uri.parse(CALENDAR_REMINDER_URI), "event_id=?", new String[] { eventID });

    Uri deleteUri = ContentUris.withAppendedId(Uri.parse(CALENDER_EVENT_URI), Long.parseLong(eventID));
    return _activity.getContentResolver().delete(deleteUri, null, null);
  }
}
