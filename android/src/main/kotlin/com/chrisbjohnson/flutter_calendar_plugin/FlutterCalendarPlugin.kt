package com.chrisbjohnson.flutter_calendar_plugin

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.TimeZone


/** FlutterCalendarPlugin */
class FlutterCalendarPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  private lateinit var activity: Activity 
  private lateinit var context: Context
  private lateinit var channel: MethodChannel
  private var activeResult: Result? = null
  private var activeMethodCall: MethodCall? = null

  companion object {
    private const val ADD_EVENT_REQUESTCODE = 1;
    private const val UPDATE_EVENT_REQUESTCODE = 2;
    private const val DELETE_EVENT_REQUESTCODE = 3;
    private const val LIST_CALENDARS_REQUESTCODE = 4;
    private const val GET_PLATFORM_VERSION_REQUESTCODE = 5;
    val EVENT_PROJECTION = arrayOf(
      CalendarContract.Calendars._ID,
      CalendarContract.Calendars.CALENDAR_DISPLAY_NAME
    )
    private const val CALENDER_EVENT_URI = "content://com.android.calendar/events"
    private const val CALENDAR_REMINDER_URI = "content://com.android.calendar/reminders"
    private val DATEFORMAT: SimpleDateFormat = SimpleDateFormat("yyyy-MM-dd' 'HH:mm")
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_calendar_plugin")
    channel.setMethodCallHandler(this)

    context = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity;
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() { }
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { }
  override fun onDetachedFromActivityForConfigChanges() { }

  override fun onMethodCall(call: MethodCall, result: Result) {
    activeResult = result
    activeMethodCall = call

    if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED) {
      callMethodWithPermissions(getRequestCode(call.method))
    } else {
      ActivityCompat.requestPermissions(activity,
                                        arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
                                        getRequestCode(call.method))
    }
  }

  override fun onRequestPermissionsResult(requestCode: Int,
                                         permissions: Array<out String>,
                                         grantResults: IntArray): Boolean {
    if (requestCode > 0 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
      callMethodWithPermissions(requestCode)
    } else {
      activeResult?.error("PERMISSIONS", "Calendar permissions denied by user.", null)
    }

    return true
  }

  private fun getRequestCode(methodName: String) : Int {
    if (methodName == "getPlatformVersion") {
      return GET_PLATFORM_VERSION_REQUESTCODE
    } else if (methodName == "listAllCalendars") {
      return LIST_CALENDARS_REQUESTCODE
    } else if (methodName == "addCalendarEvent") {
      return ADD_EVENT_REQUESTCODE
    } else if (methodName == "updateCalendarEvent") {
      return UPDATE_EVENT_REQUESTCODE
    } else if (methodName == "deleteCalendarEvent") {
      return DELETE_EVENT_REQUESTCODE
    } else {
      return -1
    }
  }

  private fun callMethodWithPermissions(requestCode: Int) {
    try {
      if (activeMethodCall == null) {
        return
      }

      if (requestCode == GET_PLATFORM_VERSION_REQUESTCODE) {
        activeResult?.success(getPlatformVersion())
      } else if (requestCode == LIST_CALENDARS_REQUESTCODE) {
        activeResult?.success(listAllCalendars())
      } else if (requestCode == ADD_EVENT_REQUESTCODE) {
        activeResult?.success(addCalendarEvent(activeMethodCall!!))
      } else if (requestCode == UPDATE_EVENT_REQUESTCODE) {
        activeResult?.success(updateCalendarEvent(activeMethodCall!!))
      } else if (requestCode == DELETE_EVENT_REQUESTCODE) {
        activeResult?.success(deleteCalendarEvent(activeMethodCall!!.argument<String>("eventID")!!))
      } else {
        activeResult?.error("METHOD", "$requestCode request code does not exist", null)
      }

    } catch (e: Exception) {
      activeResult?.error("CALENDAR", e.message, null)
    }
  }

  private fun getPlatformVersion() : String {
    return "Android ${android.os.Build.VERSION.RELEASE}"
  }

  private fun listAllCalendars() : Map<String, String> {
    val calendars  = mutableMapOf<String, String>()
    val uri: Uri = CalendarContract.Calendars.CONTENT_URI;

    val cursor: Cursor? = activity.applicationContext.contentResolver.query(uri, EVENT_PROJECTION, null, null, null)
    while (cursor?.moveToNext() == true) {
      calendars[cursor.getLong(0).toString()] = cursor.getString(1);
    }
    cursor?.close()

    return calendars;
  }

  private fun addCalendarEvent(call: MethodCall) : String {
    val eventValues = ContentValues()
    eventValues.put("calendar_id", call.argument("calendarID") as String?)
    eventValues.put("title", call.argument("title") as String?)
    eventValues.put("eventTimezone", TimeZone.getDefault().id)
    eventValues.put("hasAttendeeData", false)

    val cal: Calendar = Calendar.getInstance()
    cal.setTime(DATEFORMAT.parse(call.argument("startTime") as String?))

    if (call.hasArgument("allDay")) {
      cal.set(Calendar.HOUR_OF_DAY, 0)
      cal.set(Calendar.MINUTE, 0)
      eventValues.put("dtstart", cal.getTimeInMillis())
      eventValues.put("dtend", cal.getTimeInMillis())
      eventValues.put("allDay", 1)
    } else {
      eventValues.put("dtstart", cal.getTimeInMillis())
      val endDate: Long =
        cal.getTimeInMillis() + 1000 * 60 * call.argument<Int>("durationInMins")!!
      eventValues.put("dtend", endDate)
    }

    if (call.hasArgument("description")) eventValues.put(
      "description",
      call.argument("description") as String?
    )

    if (call.hasArgument("location")) eventValues.put(
      "eventLocation",
      call.argument("location") as String?
    )

    val addReminder = call.hasArgument("addReminder")
    if (addReminder) {
      eventValues.put("hasAlarm", 1)
    }

    val eventID: String? = activity.applicationContext.contentResolver.insert(Uri.parse(CALENDER_EVENT_URI), eventValues)?.lastPathSegment

    if (addReminder) {
      val reminderValues = ContentValues()
      reminderValues.put("event_id", eventID)
      reminderValues.put("minutes", call.argument<Int>("reminderWarningInMins")!!)
      // Alert Methods: Default(0), Alert(1), Email(2), SMS(3)
      reminderValues.put("method", call.argument<Int>("reminderType")!!)
      activity.applicationContext.contentResolver.insert(Uri.parse(CALENDAR_REMINDER_URI), reminderValues)
    }

    return eventID!!
  }

  private fun updateCalendarEvent(call: MethodCall) : Int {
    val eventValues = ContentValues()

    if (call.hasArgument("calendarID")) eventValues.put(
      "calendar_id",
      call.argument("calendarID") as String?
    )

    if (call.hasArgument("title")) eventValues.put("title", call.argument("title") as String?)

    if (call.hasArgument("startTime")) {
      val cal = Calendar.getInstance()
      cal.setTime(DATEFORMAT.parse(call.argument("startTime") as String?))
      if (call.hasArgument("allDay")) {
        cal[Calendar.HOUR_OF_DAY] = 0
        cal[Calendar.MINUTE] = 0
        eventValues.put("dtstart", cal.getTimeInMillis())
        eventValues.put("dtend", cal.getTimeInMillis())
        eventValues.put("allDay", 1)
      } else {
        eventValues.put("dtstart", cal.getTimeInMillis())
        val endDate = cal.getTimeInMillis() + 1000 * 60 * call.argument<Int>("durationInMins")!!
        eventValues.put("dtend", endDate)
      }
    }

    if (call.hasArgument("description")) eventValues.put(
      "description",
      call.argument("description") as String?
    )

    if (call.hasArgument("location")) eventValues.put(
      "eventLocation",
      call.argument("location") as String?
    )

    val addReminder = call.hasArgument("addReminder")
    if (addReminder) {
      eventValues.put("hasAlarm", 1)
    }

    val eventID = call.argument("eventID") as String?

    // Delete all old reminders
    activity.applicationContext.contentResolver.delete(Uri.parse(CALENDAR_REMINDER_URI), "event_id=?", arrayOf(eventID))

    if (addReminder) {
      val reminderValues = ContentValues()
      reminderValues.put("event_id", eventID)
      reminderValues.put("minutes", call.argument<Int>("reminderWarningInMins")!!)
      // Alert Methods: Default(0), Alert(1), Email(2), SMS(3)
      reminderValues.put("method", call.argument<Int>("reminderType")!!)
      activity.applicationContext.contentResolver.insert(Uri.parse(CALENDAR_REMINDER_URI), reminderValues)
    }

    val eventUri = ContentUris.withAppendedId(Uri.parse(CALENDER_EVENT_URI), eventID!!.toLong())
    return activity.contentResolver.update(eventUri, eventValues, null, null)
  }

  private fun deleteCalendarEvent(eventID: String) : Int {
    // Delete all old reminders
    activity.applicationContext.contentResolver.delete(Uri.parse(CALENDAR_REMINDER_URI), "event_id=?", arrayOf<String>(eventID))

    val deleteUri = ContentUris.withAppendedId(Uri.parse(CALENDER_EVENT_URI), eventID.toLong())
    return activity.contentResolver.delete(deleteUri, null, null)
  }
}
