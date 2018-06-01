import 'package:flutter/material.dart';
import 'package:flutter_calendar_plugin_example/EventDetail.dart';
import 'package:flutter_calendar_plugin_example/TextFieldExt.dart';
import 'package:flutter_calendar_plugin_example/DateTimePicker.dart';
import 'package:flutter_calendar_plugin/FlutterCalendarPlugin.dart';

class DialogEventDetail extends StatefulWidget {
  final EventDetail eventDetail;
  final List<Calendar> calendars;

  DialogEventDetail(this.eventDetail, this.calendars);

  @override
  _DialogEventDetailState createState() => new _DialogEventDetailState();
}

class _DialogEventDetailState extends State<DialogEventDetail> {
  bool _canSave = false;

  void _setCanSave(bool save) {
    if (save != _canSave) setState(() => _canSave = save);
  }

  @override
  void initState() {
    super.initState();
    _setCanSave(widget.eventDetail.title.isNotEmpty);

  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return new Scaffold(
      appBar: new AppBar(title: new Text('Add New Event'), actions: <Widget>[
        new FlatButton(
            child: new Text('SAVE',
                style: theme.textTheme.body1.copyWith(
                    color: _canSave
                        ? Colors.white
                        : new Color.fromRGBO(255, 255, 255, 0.5))),
            onPressed: _canSave
                ? () {
                    Navigator.of(context).pop(widget.eventDetail);
                  }
                : null)
      ]),
      body: new Form(
        child: new ListView(
          children: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: new DropdownButton<Calendar>(
                    items: widget.calendars.map((Calendar value) {
                      return new DropdownMenuItem<Calendar>(
                          value: value,
                          child: new Text(value.toString()));
                    }).toList(),
                    onChanged: (Calendar value) {
                      if (value != widget.eventDetail.calendar)
                        setState(() => widget.eventDetail.calendar =
                            widget.calendars.firstWhere((Calendar c) => c.id == value.id));
                    },
                    value: widget.eventDetail.calendar)),
            new TextFieldExt(
              initialValue: widget.eventDetail.title,
              header: 'Title',
              textChanged: (String text) {
                widget.eventDetail.title = text;
                _setCanSave(widget.eventDetail.title.isNotEmpty);
              },
            ),
            new Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
              child: new DateTimePicker(
                labelText: 'Start Time',
                selectedDate: widget.eventDetail.startTime,
                selectDate: (DateTime date) {
                  setState(() {
                    widget.eventDetail.startTime = date;
                  });
                },
              ),
            ),
            new TextFieldExt(
              initialValue: widget.eventDetail.description,
              header: 'Description',
              textChanged: (text) => widget.eventDetail.description = text,
            ),
            new TextFieldExt(
              initialValue: widget.eventDetail.location,
              header: 'Location',
              textChanged: (text) => widget.eventDetail.location = text,
            ),
            new SwitchListTile(
                title: new Text("All Day?"),
                value: widget.eventDetail.allDay ?? false,
                onChanged: (val) =>
                    setState(() => widget.eventDetail.allDay = val)),
            (widget.eventDetail.allDay ?? false)
                ? new Container()
                : new TextFieldExt(
                    initialValue: widget.eventDetail.durationInMins.toString(),
                    header: 'Duration in Minutes',
                    keyboardType: TextInputType.number,
                    textChanged: (text) =>
                        widget.eventDetail.durationInMins = int.parse(text)),
            new SwitchListTile(
                title: new Text("Add Reminder?"),
                value: widget.eventDetail.addReminder ?? false,
                onChanged: (val) =>
                    setState(() => widget.eventDetail.addReminder = val)),
            (widget.eventDetail.addReminder ?? false)
                ? new TextFieldExt(
                    initialValue:
                        widget.eventDetail.reminderWarningInMins.toString(),
                    header: 'Reminder Warning in Minutes',
                    keyboardType: TextInputType.number,
                    textChanged: (text) => widget
                        .eventDetail.reminderWarningInMins = int.parse(text),
                  )
                : new Container(),
            (widget.eventDetail.addReminder ?? false)
                ? new Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                    child: new DropdownButton(
                        items: ReminderType.values.map((ReminderType value) {
                          return new DropdownMenuItem<String>(
                              value: value.toString(),
                              child: new Text(value.toString()));
                        }).toList(),
                        onChanged: (String value) {
                          if (value !=
                              widget.eventDetail.reminderType.toString())
                            setState(() => widget.eventDetail.reminderType =
                                ReminderType.values
                                    .firstWhere((e) => e.toString() == value));
                        },
                        value: widget.eventDetail.reminderType.toString()))
                : new Container(),
          ].toList(),
        ),
      ),
    );
  }
}
