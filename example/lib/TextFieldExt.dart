import 'package:flutter/material.dart';

class TextFieldExt extends StatefulWidget {
  final double paddingLeft, paddingTop, paddingRight, paddingBottom;
  final TextInputType keyboardType;
  final String header, initialValue;
  final ValueChanged<String> textChanged;

  TextFieldExt(
      {this.initialValue,
      this.textChanged,
      this.header,
      this.keyboardType = TextInputType.text,
      this.paddingLeft = 10.0,
      this.paddingTop = 0.0,
      this.paddingRight = 10.0,
      this.paddingBottom = 10.0});

  @override
  State<StatefulWidget> createState() => new _TextFieldExtState();
}

class _TextFieldExtState extends State<TextFieldExt> {
  TextEditingController _controller;

  @override
  void initState() {
    _controller = new TextEditingController(text: widget.initialValue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: new EdgeInsets.fromLTRB(widget.paddingLeft, widget.paddingTop,
          widget.paddingRight, widget.paddingBottom),
      child: new TextField(
        controller: _controller,
        maxLines: widget.keyboardType == TextInputType.multiline ? null : 1,
        decoration: new InputDecoration(
          labelText: widget.header,
        ),
        onChanged: widget.textChanged,
        keyboardType: widget.keyboardType,
      ),
    );
  }
}
