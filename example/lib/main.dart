import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_plugin/flutter_calendar_plugin.dart';

void main() => runApp(new MaterialApp(home: new MyApp()));

class MyApp extends StatefulWidget {
  final List<EventItem> events = new List<EventItem>();
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    int eventID = await FlutterCalendarPlugin.addCalendarEvent();
    setState(() => widget.events.add(new EventItem("New Event", eventID)));
  }

  Widget getEventItem(EventItem eventItem) {
    return new FlatButton(
      child: new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Row(
          children: <Widget>[
            new Expanded(
              flex: 2,
              child: new Text(eventItem.name),
            ),
            new Expanded(child: new Text(eventItem.eventID.toString())),
          ].toList(),
        ),
      ),
      onPressed: () async {
        bool delete = await deleteItemDialog(context, "Delete this event?");
        if (delete) {
          await FlutterCalendarPlugin.deleteCalendarEvent(eventItem.eventID);
          setState(() => widget.events.remove(eventItem));
        }
      },
    );
  }

  Future<bool> deleteItemDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(content: new Text(message), actions: <Widget>[
          new FlatButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(false);
              }),
          new FlatButton(
              child: const Text('DELETE'),
              onPressed: () {
                Navigator.of(context).pop(true);
              })
        ]);
      },
    );
  }
}

class EventItem {
  EventItem(this.name, this.eventID);

  int eventID;
  String name;
}
