import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatelessWidget {
  final String labelText;
  final ValueChanged<DateTime> selectDate;
  final DateFormat dateFormat = new DateFormat("yyyy-MM-dd HH:mm");
  DateTime selectedDate;

  DateTimePicker(
      {Key key,
        this.labelText,
        this.selectedDate,
        this.selectDate})
      : super(key: key);

  Future<Null> _selectDate(BuildContext context) async {
    DateTime pickedDate = new DateTime.now();

    pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? new DateTime.now(),
        firstDate: new DateTime(2000),
        lastDate: new DateTime(2101));

    if (pickedDate != null && pickedDate != selectedDate)
      selectedDate = pickedDate;

    final TimeOfDay pickedTime = await showTimePicker(
      context: context,
      initialTime: new TimeOfDay.now(),
    );

    if (pickedTime != null)
      selectedDate = new DateTime(pickedDate.year, pickedDate.month,
          pickedDate.day, pickedTime.hour, pickedTime.minute);

    selectDate(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        new Expanded(
          child: new InputDropdown(
            labelText: labelText,
            valueText: getDateString(),
            onPressed: () {
              _selectDate(context);
            },
          ),
        ),
      ],
    );
  }

  String getDateString() {
    if (selectedDate == null)
      return "Not Set";
    else
      return dateFormat.format(selectedDate);
  }
}

class InputDropdown extends StatelessWidget {
  const InputDropdown({
    Key key,
    this.child,
    this.labelText,
    this.valueText,
    this.onPressed }) : super(key: key);

  final String labelText;
  final String valueText;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      onTap: onPressed,
      child: new InputDecorator(
        decoration: new InputDecoration(
          labelText: labelText,
        ),
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text(valueText),
            new Icon(Icons.arrow_drop_down,
                color: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade700 : Colors.white70
            ),
          ],
        ),
      ),
    );
  }
}