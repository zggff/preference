import 'package:flutter/material.dart';
import 'package:preference/types/types.dart';
import 'dart:developer' as developer;

class AddGameDialog extends StatefulWidget {
  final GameState gameState;

  const AddGameDialog({super.key, required this.gameState});

  @override
  State<AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<AddGameDialog> {
  late Iterable<String> players;

  @override
  void initState() {
    super.initState();
    players = s.players.length == 3
        ? s.players.keys
        : s.players.keys.where((k) => k != s.dealer.current);
  }

  // _AddGameDialogState() {
  // print(widget);
  // }
  GameState get s => widget.gameState;

  GameType? gameType;
  String? player;
  String? from;
  Map<String, bool> dark = {};
  Map<String, int?> taken = {};
  String? error = "Заполните все поля";

  Widget _gameSelector() {
    // print(this);
    return DropdownButton<GameType>(
      hint: Text("тип"),
      value: gameType,
      items: GameType.values.map((value) {
        return DropdownMenuItem(value: value, child: Text(value.name));
      }).toList(),
      onChanged: (val) {
        player = null;
        gameType = val;
        if (gameType == GameType.raspas) {
          dark = Map.fromEntries(
            s.players.keys.map((val) => MapEntry(val, false)),
          );
          if (s.players.length == 4) {
            dark.remove(s.dealer.current);
          }
          taken = Map.fromEntries(
            s.players.keys.map((val) => MapEntry(val, null)),
          );
        } else {
          dark = {};
          taken = {};
        }
        if (gameType == GameType.neg || gameType == GameType.pos) {
          players = s.players.keys;
        }
        setState(() {});
      },
    );
  }

  Widget _playerSelector() {
    return DropdownButton<String>(
      hint: Text("игрок"),
      value: player,
      items: players.map((value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
      onChanged: (val) {
        dark = {val!: false};
        if (gameType! == GameType.misere ||
            gameType! == GameType.neg ||
            gameType! == GameType.pos) {
          taken = {val: null};
        } else if (gameType != GameType.raspas) {
          taken = Map.fromEntries(
            s.players.keys.map((val) => MapEntry(val, null)),
          );
          if (s.players.length == 4) {
            taken.remove(s.dealer.current);
          }
        }
        player = val;
        setState(() {});
      },
    );
  }

  Widget _darkTable() {
    return Table(
      children: [
        TableRow(
          children: [
            for (var k in dark.keys) Text(k, textAlign: TextAlign.center),
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
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _takenTable() {
    return Table(
      children: [
        TableRow(
          children: [
            for (var k in taken.keys) Text(k, textAlign: TextAlign.center),
          ],
        ),
        TableRow(
          children: [
            for (var k in taken.keys)
              DropdownButton(
                value: taken[k],
                items:
                    Iterable.generate(
                      (taken.length == 4 && k == s.dealer.current) ? 3 : 11,
                    ).map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text("$value"),
                      );
                    }).toList(),
                onChanged: (val) {
                  taken[k] = val ?? 0;
                  if (taken.values.any((c) => c == null)) {
                    error = "Заполните все поля";
                  } else if ((gameType != GameType.misere &&
                          gameType != GameType.neg &&
                          gameType != GameType.pos) &&
                      taken.values.fold(0, (a, b) => a + b!) != 10) {
                    error = "Не суммируется к десяти";
                  } else {
                    error = null;
                  }
                  setState(() {});
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _fromSelector() {
    return DropdownButton<String>(
      hint: Text("куплено"),
      value: from,
      items: players.map((value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
      onChanged: (val) {
        setState(() {
          from = val;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log("hello from widget");
    return AlertDialog(
      title: Text('Добавить игру', textAlign: TextAlign.center),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            children: [
              _gameSelector(),
              if (gameType != null && gameType! != GameType.raspas)
                _playerSelector(),
              if (gameType != null &&
                  gameType! != GameType.neg &&
                  gameType! != GameType.pos &&
                  dark.isNotEmpty)
                Text("Темнили:"),
              if (gameType != null &&
                  (gameType! == GameType.neg || gameType! == GameType.pos) &&
                  dark.isNotEmpty)
                Text("минус:"),
              if (gameType != null && dark.isNotEmpty) _darkTable(),
              if (taken.isNotEmpty) Text("Взяли:"),
              if (taken.isNotEmpty) _takenTable(),
              if (taken.isNotEmpty && ![GameType.raspas, GameType.neg, GameType.pos].contains(gameType)) Text("Куплено от:"),
              if (taken.isNotEmpty && ![GameType.raspas, GameType.neg, GameType.pos].contains(gameType)) _fromSelector(),
              if (taken.isNotEmpty && error != null)
                Text(error!, style: TextStyle(color: Colors.red, fontSize: 15)),
            ],
          );
        },
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        TextButton(
          child: Text('CANCEL'),
          onPressed: () {
            debugPrint("cancelled");

            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            if (error != null) {
              return;
            }
            var takenMod = Map.fromEntries(
              s.players.keys.map((k) => MapEntry(k, taken[k] ?? 0)),
            );
            s.updateGameState(player, gameType!, takenMod, dark, from);
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}
