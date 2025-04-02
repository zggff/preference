import 'package:format/format.dart';
import 'package:flutter/material.dart';

import 'package:preference/game_painter.dart';
import 'package:preference/types.dart';

import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.5)),
        home: MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Matrix4 rotMatrix = Matrix4.identity();
  late Map<String, bool> displayGamesByPlayer;
  late Map<String, bool> displayGamesByDealer;
  late Map<GameType, bool> displayGamesByType;
  late GameState s;
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

  _MainPageState() {
    s = GameState.withDealer(["М", "Я", "Л"]);
    resetGame();
  }

  Future<void> displayPlayerInfo(BuildContext context, String name) async {
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

    return showDialog(
        context: context,
        builder: (context) {
          // Navigator()
          return Dialog(
            child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                    height: 500,
                    child: Column(spacing: 20, children: [
                      Text(
                        name,
                        textScaler: TextScaler.linear(2),
                      ),
                      Text(
                        "Распасы сданы: {} раз"
                            .format(s.players[name]!.raspasDealed),
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
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Icon(Icons.add, size: 30)),
                            TableCell(
                                verticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                child: Icon(Icons.remove, size: 30)),
                          ]),
                          for (var type in GameType.values
                              .where((t) => t != GameType.raspas))
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
        });
  }

  Future<void> resetConfirmationDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          List<String>? names = s.players.keys.toList();
          String? dealer = names.first;
          TextEditingController namesTextFieldController =
              TextEditingController(text: s.players.keys.join(" "));
          return AlertDialog(
            title: Text("начать игру заново?"),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState2) {
              return SizedBox(
                  height: 200,
                  child: Column(children: [
                    TextField(
                      textCapitalization: TextCapitalization.characters,
                      controller: namesTextFieldController,
                      decoration:
                          InputDecoration(hintText: "Text Field in Dialog"),
                      onChanged: (_) {
                        names = namesTextFieldController.text
                            .split(" ")
                            .where((c) => c.isNotEmpty)
                            .toList();
                        if (names == null ||
                            names!.length < 3 ||
                            names!.length > 4 ||
                            Set.from(names!).length != names!.length) {
                          names = null;
                          return;
                        }
                        dealer = names!.first;
                        setState2(() {});
                      },
                    ),
                    if (names != null)
                      DropdownButton(
                          hint: Text("тип"),
                          value: dealer,
                          items: names!.map((value) {
                            return DropdownMenuItem(
                                value: value, child: Text(value));
                          }).toList(),
                          onChanged: (val) {
                            dealer = val!;
                            setState2(() {});
                          }),
                  ]));
            }),
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
                  if (names == null) {
                    return;
                  }
                  s = GameState(names!, dealer!);
                  resetGame();

                  setState(() {});
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  Future<void> addGameDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        // var list = ["распасы", "игра", "мизер"];
        GameType? gameType;
        String? player;
        Iterable<String> players = s.players.length == 3
            ? s.players.keys
            : s.players.keys.where((k) => k != s.dealer.current);

        Map<String, bool> dark = {};
        Map<String, int?> taken = {};
        // Map<String, int> taken =
        //     Map.fromEntries(s.players.keys.map((val) => MapEntry(val, 0)));
        String? error = "Заполните все поля";

        return AlertDialog(
          title: Text('Добавить игру', textAlign: TextAlign.center),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Column(children: [
              DropdownButton<GameType>(
                  hint: Text("тип"),
                  value: gameType,
                  items: GameType.values.map((value) {
                    return DropdownMenuItem(
                        value: value, child: Text(value.name));
                  }).toList(),
                  onChanged: (val) {
                    player = null;
                    gameType = val;
                    if (gameType == GameType.raspas) {
                      dark = Map.fromEntries(
                          s.players.keys.map((val) => MapEntry(val, false)));
                      if (s.players.length == 4) {
                        dark.remove(s.dealer.current);
                      }
                      taken = Map.fromEntries(
                          s.players.keys.map((val) => MapEntry(val, null)));
                    } else {
                      dark = {};
                      taken = {};
                    }
                    setState(() {});
                  }),
              // Text("Играли (если не распасы)"),
              if (gameType != null && gameType! != GameType.raspas)
                DropdownButton<String>(
                    hint: Text("игрок"),
                    value: player,
                    items: players.map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) {
                      dark = {val!: false};
                      if (gameType! == GameType.misere) {
                        taken = {val: null};
                      } else if (gameType != GameType.raspas) {
                        taken = Map.fromEntries(
                            s.players.keys.map((val) => MapEntry(val, null)));
                        if (s.players.length == 4) {
                          taken.remove(s.dealer.current);
                        }
                      }
                      player = val;
                      setState(() {});
                    }),
              if (dark.isNotEmpty) Text("Темнили:"),
              if (dark.isNotEmpty)
                Table(children: [
                  TableRow(
                    children: [
                      for (var k in dark.keys)
                        Text(
                          k,
                          textAlign: TextAlign.center,
                        )
                    ],
                  ),
                  TableRow(
                    children: [
                      for (var k in dark.keys)
                        Checkbox(
                            value: dark[k],
                            onChanged: (_) {
                              setState(() {
                                dark[k] = !dark[k]!;
                              });
                            })
                    ],
                  )
                ]),
              if (taken.isNotEmpty) Text("Взяли:"),
              if (taken.isNotEmpty)
                Table(
                  children: [
                    TableRow(children: [
                      for (var k in taken.keys)
                        Text(
                          k,
                          textAlign: TextAlign.center,
                        )
                    ]),
                    TableRow(
                      children: [
                        for (var k in taken.keys)
                          DropdownButton(
                              value: taken[k],
                              items: Iterable.generate((taken.length == 4 &&
                                          k == s.dealer.current)
                                      ? 3
                                      : 11)
                                  .map((value) {
                                return DropdownMenuItem<int>(
                                    value: value, child: Text("$value"));
                              }).toList(),
                              onChanged: (val) {
                                taken[k] = val ?? 0;
                                if (taken.values.any((c) => c == null)) {
                                  error = "Заполните все поля";
                                } else if (gameType != GameType.misere &&
                                    taken.values.fold(0, (a, b) => a + b!) !=
                                        10) {
                                  error = "Не суммируется к десяти";
                                } else {
                                  error = null;
                                }
                                setState(() {});
                              }),
                      ],
                    )
                  ],
                ),
              if (taken.isNotEmpty && error != null)
                Text(
                  error!,
                  style: TextStyle(color: Colors.red, fontSize: 15),
                )
            ]);
          }),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                if (error != null) {
                  return;
                }
                var takenMod = Map.fromEntries(
                    s.players.keys.map((k) => MapEntry(k, taken[k] ?? 0)));
                s.updateGameState(player, gameType!, takenMod, dark);
                setState(() {});
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
          padding: EdgeInsets.all(30),
          child: Row(spacing: 10, children: [
            Expanded(
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

                // list display
                Expanded(
                  flex: 12,
                  child: ListView(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "[{}]".format(game.dealer),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w300),
                                              textScaler:
                                                  TextScaler.linear(1.5),
                                            ),
                                            Text(
                                              "{}".format(game.type.name),
                                              textScaler:
                                                  TextScaler.linear(1.5),
                                              style: TextStyle(
                                                  fontWeight: game.type ==
                                                              GameType.raspas ||
                                                          !game.dark[
                                                              game.player]!
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                  color: game.type ==
                                                          GameType.raspas
                                                      ? Colors.black
                                                      : game.success
                                                          ? Colors.green
                                                          : Colors.red),
                                            ),
                                            Text(
                                              "{}".format(
                                                  game.type == GameType.raspas
                                                      ? " "
                                                      : game.player),
                                              textScaler:
                                                  TextScaler.linear(1.5),
                                            ),
                                          ]),
                                      () {
                                        var taken = Map.from(game.taken);
                                        if (game.type == GameType.misere) {
                                          taken.removeWhere(
                                              (k, _) => k != game.player);
                                        } else if (game.type !=
                                                GameType.raspas &&
                                            game.taken.length == 4) {
                                          taken.removeWhere(
                                              (k, _) => k == game.dealer);
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
                                        Text("{}".format(
                                            game.bonus! == Bonus.bird
                                                ? "на птичке"
                                                : "на бомбочке")),
                                    ])),
                              ))
                    ],
                  ),
                ),
                Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          color: Colors.green,
                          width: 70,
                          height: 70,
                          child: Center(
                              child: TextButton(
                                  onPressed: () {
                                    s.recalculate();
                                    s.calculateRes();
                                    setState(() {});
                                  },
                                  child: Text(
                                    "{}".format(s.games.length),
                                    style: TextStyle(
                                        fontSize: 40, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ))),
                        ),
                        Container(
                            width: 70,
                            height: 70,
                            color: Colors.blue,
                            child: Center(
                                child: IconButton(
                              icon: Icon(Icons.remove),
                              iconSize: 60,
                              color: Colors.white,
                              onPressed: () {
                                resetConfirmationDialog(context);
                              },
                            ))),
                        Container(
                            width: 70,
                            height: 70,
                            color: Colors.blue,
                            child: Center(
                                child: IconButton(
                              icon: Icon(Icons.add),
                              iconSize: 60,
                              color: Colors.white,
                              onPressed: () {
                                addGameDialog(context);
                              },
                            ))),
                        Container(
                            width: 70,
                            height: 70,
                            color: Colors.blue,
                            child: Center(
                                child: IconButton(
                              icon: Icon(Icons.restore),
                              iconSize: 50,
                              color: Colors.white,
                              onPressed: () {
                                removeLastConfirmationDialog(context);
                                setState(() {});
                              },
                            ))),
                      ],
                    )),
              ],
            )),
            Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    rotMatrix.rotateZ(-90 * math.pi / 180);
                    rotation = (rotation + 1) % 4;
                    setState(() {});
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
                ))
          ])),
    );
  }
}
