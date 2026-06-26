import 'package:flutter/material.dart';
import 'package:preference/types/types.dart';
import 'package:format/format.dart';

class PlayerInfoDialog extends StatelessWidget {
  static const severityColor = [
    Colors.black,
    Colors.green,
    Colors.orange,
    Colors.red
  ];

  final GameState gameState;
  final String name;

  const PlayerInfoDialog({super.key, required this.gameState, required this.name});

  GameState get s => gameState;
  @override
  Widget build(BuildContext context) {
    var severityColor = [Colors.black, Colors.green, Colors.orange, Colors.red];
    getText(id) {
      var n = s.players[name]!.playedGames[id]!;
      return Text(
        "{}".format(n),
        textAlign: TextAlign.center,
        textScaler: TextScaler.linear(1.5),
        style: TextStyle(color: severityColor[n % 4]),
      );
    }

    return Dialog(
      child: Padding(
          padding: EdgeInsets.all(20),
          child: SizedBox(
              height: 550,
              child: Column(spacing: 20, children: [
                Text(
                  name,
                  textScaler: TextScaler.linear(2),
                ),
                Text(
                  "Распасы сданы: {} раз".format(s.players[name]!.raspasDealed),
                  style: TextStyle(
                      color: severityColor[
                          (s.players[name]!.raspasDealed) % 3 + 1]),
                ),
                Table(
                  border: TableBorder.all(width: 1),
                  children: [
                    TableRow(children: [
                      Container(),
                      TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Icon(Icons.add, size: 30)),
                      TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Icon(Icons.remove, size: 30)),
                    ]),
                    for (var type
                        in GameType.values.where((t) => t != GameType.raspas))
                      TableRow(children: [
                        TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.middle,
                            child: Text(
                              type.name,
                              textAlign: TextAlign.center,
                              textScaler: TextScaler.linear(1.2),
                            )),
                        getText((type, true)),
                        getText((type, false)),
                      ])
                  ],
                )
              ]))),
    );
  }
}
