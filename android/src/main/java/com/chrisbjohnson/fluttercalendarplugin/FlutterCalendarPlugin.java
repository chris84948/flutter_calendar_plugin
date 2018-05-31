package com.chrisbjohnson.fluttercalendarplugin;

import android.Manifest;
import android.app.Activity;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import java.text.ParseException;
import java.text.SimpleDateFormat;

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
  private static final String[] REQUIRED_PERMISSIONS = new String[]{Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR};
  private static final String CALENDER_EVENT_URI = "content://com.android.calendar/events";

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
        result.success(getResultFromRequestCode(requestCode, call));
      }

      @Override
      public void denied()
      {
        result.success(-1);
      }
    };

    int requestCode = getRequestCodeFromMethodName(call.method);

    // Make sure we have calendar permissions before trying anything else
    if (!areCalendarPermissionsValid())
      _activity.requestPermissions(REQUIRED_PERMISSIONS, requestCode);
    else
      result.success(getResultFromRequestCode(requestCode, call));
  }

  private int getResultFromRequestCode(int requestCode, MethodCall call) {
    if (requestCode == ADD_EVENT_REQUESTCODE)
      return (int)addCalendarEvent();
    else if (requestCode == UPDATE_EVENT_REQUESTCODE)
      return updateCalendarEvent(((Integer)(call.argument("eventID"))).longValue());
    else if (requestCode == DELETE_EVENT_REQUESTCODE)
      return deleteCalendarEvent(((Integer)(call.argument("eventID"))).longValue());
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
      default:
        return 4;
    }
  }

  private boolean areCalendarPermissionsValid() {
    return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            _activity.checkSelfPermission(REQUIRED_PERMISSIONS[0]) == PackageManager.PERMISSION_GRANTED;
  }

  public long addCalendarEvent() {
    String dtStart = "2018-06-10 19:30";
    SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd' 'HH:mm");
    long milliseconds = 0;
    try { milliseconds = format.parse(dtStart).getTime(); } catch (ParseException e) { }

    return addAppointmentsToCalender(_activity,
            "Test Event",
            "Testing out sending an appointment from Android",
            "2807 Virginia Ave S",
            0,
            milliseconds,
            true);
  }

  public long addAppointmentsToCalender(Activity curActivity,
                                        String title,
                                        String desc,
                                        String place,
                                        int status,
                                        long startDate,
                                        boolean needReminder) {
    long eventID = -1;
    try {
      ContentValues eventValues = new ContentValues();
      eventValues.put("calendar_id", 1); // id, We need to choose from
      // our mobile for primary its 1
      eventValues.put("title", title);
      eventValues.put("description", desc);
      eventValues.put("eventLocation", place);

      long endDate = startDate + 1000 * 10 * 10; // For next 10min
      eventValues.put("dtstart", startDate);
      eventValues.put("dtend", endDate);

      // values.put("allDay", 1); //If it is bithday alarm or such
      // kind (which should remind me for whole day) 0 for false, 1
      // for true
      eventValues.put("eventStatus", status); // This information is
      // sufficient for most
      // entries tentative (0),
      // confirmed (1) or canceled
      // (2):
      eventValues.put("eventTimezone", "UTC/GMT +5:30");
      /*
       * Comment below visibility and transparency column to avoid
       * java.lang.IllegalArgumentException column visibility is invalid
       * error
       */
      // eventValues.put("allDay", 1);
      // eventValues.put("visibility", 0); // visibility to default (0),
      // confidential (1), private
      // (2), or public (3):
      // eventValues.put("transparency", 0); // You can control whether
      // an event consumes time
      // opaque (0) or transparent (1).

      eventValues.put("hasAlarm", 1); // 0 for false, 1 for true

      Uri eventUri = curActivity.getApplicationContext()
              .getContentResolver()
              .insert(Uri.parse(CALENDER_EVENT_URI), eventValues);
      eventID = Long.parseLong(eventUri.getLastPathSegment());

      if (needReminder) {
        /***************** Event: Reminder(with alert) Adding reminder to event ***********        ********/

        String reminderUriString = "content://com.android.calendar/reminders";
        ContentValues reminderValues = new ContentValues();
        reminderValues.put("event_id", eventID);
        reminderValues.put("minutes", 5); // Default value of the
        // system. Minutes is a integer
        reminderValues.put("method", 1); // Alert Methods: Default(0),
        // Alert(1), Email(2),SMS(3)

        Uri reminderUri = curActivity.getApplicationContext()
                .getContentResolver()
                .insert(Uri.parse(reminderUriString), reminderValues);
      }

    } catch (Exception ex) {
      Log.i("CalendarTest","Error in adding event on calendar" + ex.getMessage());
    }

    return eventID;

  }

  private int updateCalendarEvent(long eventID) {
    ContentValues event = new ContentValues();

    event.put("title", "Changed Event Title");

    Uri eventsUri = Uri.parse(CALENDER_EVENT_URI);
    Uri eventUri = ContentUris.withAppendedId(eventsUri, eventID);

    return _activity.getContentResolver().update(eventUri, event, null, null);
  }

  public int deleteCalendarEvent(long eventID) {
    Uri deleteUri = ContentUris.withAppendedId(Uri.parse(CALENDER_EVENT_URI), eventID);
    return _activity.getContentResolver().delete(deleteUri, null, null);
  }
}
