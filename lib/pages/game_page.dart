import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:format/format.dart';
import 'package:preference/game_painter.dart';
import 'package:preference/types/types.dart';
import 'package:preference/widgets/add_game_dialog.dart';
import 'package:preference/widgets/player_info_dialog.dart';

class GamePage extends StatefulWidget {
  final GameState state;
  const GamePage({super.key, required this.state});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  GameState get s => widget.state;

  Matrix4 rotMatrix = Matrix4.identity();
  late Map<String, bool> displayGamesByPlayer;
  late Map<String, bool> displayGamesByDealer;
  late Map<GameType, bool> displayGamesByType;
  var orientation = true;
  var rotation = 0;

  void resetGame() {
    displayGamesByPlayer =
        Map.fromEntries(s.players.keys.map((name) => MapEntry(name, true)));
    displayGamesByDealer =
        Map.fromEntries(s.players.keys.map((name) => MapEntry(name, true)));
    displayGamesByType =
        Map.fromEntries(GameType.values.map((t) => MapEntry(t, true)));
  }

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  Future<void> displayPlayerInfo(BuildContext context, String name) async {
    await showDialog(
        context: context,
        builder: (_) => PlayerInfoDialog(
              gameState: s,
              name: name,
            ));
  }

  Future<void> showAddGameDialog(BuildContext context) async {
    final bool? gameWasAdded = await showDialog<bool>(
      context: context,
      builder: (context) => AddGameDialog(gameState: s),
    );
    if (gameWasAdded == true) {
      setState(() {});
    }
  }

  Future<void> removeLastConfirmationDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("удалить последнюю игру?"),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: <Widget>[
              TextButton(
                child: Text('Нет'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('Да'),
                onPressed: () {
                  s.popGame();
                  setState(() {});
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  Widget _buildGameList() {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 5),
      children: [
        for (var game in s.games)
          if (displayGamesByDealer[game.dealer]! &&
              (displayGamesByPlayer[game.player] ?? true) &&
              displayGamesByType[game.type]!)
            Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Container(
                  color: Colors.black12,
                  child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Column(spacing: 5, children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "[{}]".format(game.dealer),
                                style: TextStyle(fontWeight: FontWeight.w300),
                                textScaler: TextScaler.linear(1.5),
                              ),
                              Text(
                                "{}".format(game.type.name),
                                textScaler: TextScaler.linear(1.5),
                                style: TextStyle(
                                    fontWeight: game.type == GameType.raspas ||
                                            !game.dark[game.player]!
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: game.type == GameType.raspas
                                        ? Colors.black
                                        : game.success
                                            ? Colors.green
                                            : Colors.red),
                              ),
                              Text(
                                "{}".format(game.type == GameType.raspas
                                    ? " "
                                    : game.player),
                                textScaler: TextScaler.linear(1.5),
                              ),
                            ]),
                        () {
                          var taken = Map.from(game.taken);
                          if (game.type == GameType.misere ||
                              game.type == GameType.neg) {
                            taken.removeWhere((k, _) => k != game.player);
                          } else if (game.type != GameType.raspas &&
                              game.taken.length == 4) {
                            taken.removeWhere((k, _) => k == game.dealer);
                          }
                          return Table(
                            border: TableBorder.all(),
                            children: [
                              TableRow(children: [
                                for (var name in taken.keys)
                                  Center(
                                      child: Text(
                                    name,
                                  ))
                              ]),
                              TableRow(children: [
                                for (var val in taken.values)
                                  Center(
                                      child: Text(
                                    "{}".format(val),
                                  ))
                              ])
                            ],
                          );
                        }(),
                        if (game.bonus != null)
                          Text("{}".format(game.bonus! == Bonus.bird
                              ? "на птичке"
                              : "на бомбочке")),
                      ])),
                ))
      ],
    );
  }

  Widget _buildControlPanel() {
    return Expanded(
        flex: 11,
        child: Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 22, horizontal: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    flex: 5,
                    child: Table(
                      border: TableBorder.all(),
                      children: [
                        TableRow(children: [
                          TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Icon(Icons.search)),
                          for (var name in displayGamesByPlayer.keys)
                            TableCell(
                                child: TextButton(
                                    onPressed: () {
                                      displayPlayerInfo(context, name);
                                    },
                                    child: Text(
                                      name,
                                    )))
                        ]),
                        TableRow(children: [
                          TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: TextButton(
                                  onPressed: () {
                                    var sel = displayGamesByDealer.values
                                        .any((k) => k);
                                    displayGamesByDealer
                                        .updateAll((k, v) => !sel);
                                    setState(() {});
                                  },
                                  child: Icon(
                                    Icons.autorenew,
                                    size: 30,
                                  ))),
                          for (var name in displayGamesByDealer.keys)
                            TableCell(
                                child: Checkbox(
                                    value: displayGamesByDealer[name],
                                    onChanged: (change) {
                                      displayGamesByDealer[name] = change!;
                                      setState(() {});
                                    }))
                        ]),
                        TableRow(children: [
                          TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: TextButton(
                                  onPressed: () {
                                    var sel = displayGamesByPlayer.values
                                        .any((k) => k);
                                    displayGamesByPlayer
                                        .updateAll((k, v) => !sel);
                                    setState(() {});
                                  },
                                  child: Icon(
                                    Icons.rule,
                                    size: 30,
                                  ))),
                          for (var name in displayGamesByPlayer.keys)
                            TableCell(
                                child: Checkbox(
                                    value: displayGamesByPlayer[name],
                                    onChanged: (change) {
                                      displayGamesByPlayer[name] = change!;
                                      setState(() {});
                                    }))
                        ]),
                      ],
                    )),
                Expanded(
                    flex: 3,
                    child: Table(
                      border: TableBorder.all(),
                      children: [
                        TableRow(children: [
                          TableCell(
                              child: TextButton(
                                  onPressed: () {
                                    var sel =
                                        displayGamesByType.values.any((k) => k);
                                    displayGamesByType
                                        .updateAll((k, v) => !sel);
                                    setState(() {});
                                  },
                                  child: Icon(Icons.refresh, size: 30))),
                          for (var k in displayGamesByType.keys)
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Text("{}".format(k.short),
                                    textAlign: TextAlign.center)),
                        ]),
                        TableRow(children: [
                          TableCell(child: Container()),
                          for (var k in displayGamesByType.keys)
                            TableCell(
                                child: Checkbox(
                                    value: displayGamesByType[k],
                                    onChanged: (change) {
                                      displayGamesByType[k] =
                                          !displayGamesByType[k]!;
                                      setState(() {});
                                    })),
                        ])
                      ],
                    )),
                Expanded(
                  flex: 1,
                  child: () {
                    var games = s.games.where((game) =>
                        displayGamesByDealer[game.dealer]! &&
                        (displayGamesByPlayer[game.player] ?? true) &&
                        displayGamesByType[game.type]!);
                    var gamesPos = games.where(
                        (game) => game.type != GameType.raspas && game.success);
                    var gamesNeg = games.where((game) =>
                        game.type != GameType.raspas && !game.success);
                    var raspasCount =
                        games.length - gamesPos.length - gamesNeg.length;

                    return RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black, fontSize: 25),
                        text: "{} = ".format(games.length),
                        children: [
                          TextSpan(
                              text: "{}".format(gamesPos.length),
                              style: TextStyle(color: Colors.green)),
                          TextSpan(text: " + "),
                          TextSpan(
                              text: "{}".format(gamesNeg.length),
                              style: TextStyle(color: Colors.red)),
                          if (raspasCount > 0) TextSpan(text: " + "),
                          if (raspasCount > 0)
                            TextSpan(
                                text: "{}".format(raspasCount),
                                style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }(),
                ),
                Expanded(
                  flex: 14,
                  child: _buildGameList(),
                ),
              ],
            )));
  }

  var _dragStart = 0.0;
  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
            flex: 20,
            child: GestureDetector(
              onVerticalDragStart: (det) {
                _dragStart = det.globalPosition.dy;
              },
              onVerticalDragEnd: (det) {
                var dist = det.globalPosition.dy - _dragStart;
                if (dist < 0) {
                  showAddGameDialog(context);
                } else {
                  removeLastConfirmationDialog(context);
                }
              },
              onTap: () {
                setState(() {
                  rotMatrix.rotateZ(-90 * math.pi / 180);
                  rotation = (rotation + 1) % 4;
                });
              },
              onLongPress: () {
                setState(() {
                  orientation = !orientation;
                });
              },
              child: Transform(
                  alignment: FractionalOffset.center,
                  transform: rotMatrix,
                  child: ClipRect(
                    child: CustomPaint(
                        painter: Game3Painter(s, orientation, rotation),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                        )),
                  )),
            )),
        _buildControlPanel(),
      ],
    );
  }
}
