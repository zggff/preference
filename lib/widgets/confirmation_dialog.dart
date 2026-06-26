import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String text;
  const ConfirmationDialog(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(text),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        TextButton(
          child: Text('Нет'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: Text('Да'),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}
