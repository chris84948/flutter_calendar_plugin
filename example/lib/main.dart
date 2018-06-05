import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_calendar_plugin/FlutterCalendarPlugin.dart';
import 'package:flutter_calendar_plugin_example/EventDetail.dart';
import 'package:flutter_calendar_plugin_example/DialogEventDetail.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

class MyApp extends StatefulWidget {
  final List<EventItem> events = new List<EventItem>();
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Calendar> _calendars;

  void loadCalendars() async {
    FlutterCalendarPlugin.listAllCalendars().then((cals) {
      _calendars = cals;
    }).catchError((PlatformException error) {
      print(error);
    });
  }

  @override
  void initState() {
    super.initState();
    loadCalendars();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        home: new Scaffold(
      appBar: new AppBar(
        title: new Text('Plugin example app'),
      ),
      body: new ListView(
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(10.0),
            child: new RaisedButton(
                child: const Text("ADD EVENT"),
                onPressed: () => _addNewEvent()),
          ),
          new Column(
            children:
                widget.events.map((EventItem ei) => getEventItem(ei)).toList(),
          ),
        ],
      ),
    ));
  }

  Future _addNewEvent() async {
    final EventDetail startingEventDetail = EventDetail.empty(_calendars[0]);
    EventDetail eventDetail =
    await Navigator.of(context).push(new MaterialPageRoute<EventDetail>(
        builder: (BuildContext context) {
          return new DialogEventDetail(startingEventDetail, _calendars);
        },
        fullscreenDialog: true));

    int eventID = await FlutterCalendarPlugin.addCalendarEvent(
        eventDetail.title,
        eventDetail.startTime,
        description: eventDetail.description,
        location: eventDetail.location,
        durationInMins: eventDetail.durationInMins,
        allDay: eventDetail.allDay,
        addReminder: eventDetail.addReminder,
        reminderWarningInMins: eventDetail.reminderWarningInMins,
        reminderType: eventDetail.reminderType,
        calendarID: eventDetail.calendar.id);
    setState(() => widget.events.add(new EventItem(eventID, eventDetail)));
  }

  Future _updateEvent(final EventItem item) async {
    EventDetail eventDetail =
    await Navigator.of(context).push(new MaterialPageRoute<EventDetail>(
        builder: (BuildContext context) {
          return new DialogEventDetail(item.eventDetail, _calendars);
        },
        fullscreenDialog: true));

    await FlutterCalendarPlugin.updateCalendarEvent(
        item.eventID,
        title: eventDetail.title,
        startTime: eventDetail.startTime,
        description: eventDetail.description,
        location: eventDetail.location,
        durationInMins: eventDetail.durationInMins,
        allDay: eventDetail.allDay,
        addReminder: eventDetail.addReminder,
        reminderWarningInMins: eventDetail.reminderWarningInMins,
        reminderType: eventDetail.reminderType,
        calendarID: eventDetail.calendar.id);
    setState(() {
      item.eventDetail = eventDetail;
    });
  }

  Widget getEventItem(EventItem eventItem) {
    return new FlatButton(
      child: new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Row(
          children: <Widget>[
            new Expanded(
              flex: 2,
              child: new Text(eventItem.eventDetail.title),
            ),
            new Expanded(child: new Text(eventItem.eventID.toString())),
          ].toList(),
        ),
      ),
      onPressed: () async {
        DialogResponse response  = await itemClickedDialog(context, "What do you want to do?");
        if (response == DialogResponse.Delete) {
          await FlutterCalendarPlugin.deleteCalendarEvent(eventItem.eventID);
          setState(() => widget.events.remove(eventItem));
        } else if (response == DialogResponse.Update) {
          await _updateEvent(eventItem);
        }
      },
    );
  }

  Future<DialogResponse> itemClickedDialog(BuildContext context, String message) {
    return showDialog<DialogResponse>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(content: new Text(message), actions: <Widget>[
          new FlatButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(DialogResponse.Cancel);
              }),
          new FlatButton(
              child: const Text('UPDATE'),
              onPressed: () {
                Navigator.of(context).pop(DialogResponse.Update);
              }),
          new FlatButton(
              child: const Text('DELETE'),
              onPressed: () {
                Navigator.of(context).pop(DialogResponse.Delete);
              })
        ]);
      },
    );
  }
}

class EventItem {
  EventItem(this.eventID, this.eventDetail);

  int eventID;
  EventDetail eventDetail;
}

enum DialogResponse {
  Cancel,
  Update,
  Delete
}