import 'dart:io';

import 'package:flutter/material.dart';
import 'package:preference/services/saver.dart';
import 'package:preference/types/game_state.dart';
import 'package:preference/widgets/confirmation_dialog.dart';

class StartPage extends StatefulWidget {
  final void Function(GameState) onChange;
  final GameState? state;
  const StartPage({super.key, required this.onChange, required this.state});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  List<String>? names;
  String? dealer;

  List<FileSystemEntity> games = [];
  late TextEditingController namesTextFieldController;

  Future<void> _loadGames() async {
    final gamesList = await GameStorage.getiOSFileList();
    gamesList.sort((a, b) => b.path.compareTo(a.path));
    setState(() {
      games = gamesList;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGames();

    namesTextFieldController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    namesTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: Column(
          children: [
            Expanded(flex: 3, child: _gameCreator(context)),
            Expanded(flex: 11, child: _gameList()),
            if (widget.state != null)
              Expanded(flex: 2, child: _gameSaver(context)),
          ],
        ),
      ),
    );
  }

  Widget _frame(BuildContext context, Widget child) {
    return Container(
      margin: EdgeInsetsDirectional.all(10.0),
      height: 100,
      width: 500,
      color: Colors.lightBlue,
      child: child,
    );
  }

  Widget _gameListRow(int i, FileSystemEntity file) {
    var filename = file.path.split("/").last;
    var name = filename.replaceFirstMapped('.json', (_) => '');
    return Row(
      children: [
        Expanded(
          flex: 9,
          child: TextButton(
            onPressed: () async {
              final loadedState = await GameStorage.openGame(file);
              if (loadedState != null) {
                widget.onChange(loadedState);
              }
            },
            child: Text("[$i] $name"),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadiusDirectional.all(Radius.circular(10)),
            ),

            child: IconButton(
              onPressed: () async {
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) =>
                      ConfirmationDialog("удалить игру?"),
                );
                if (confirm) {
                  await GameStorage.removeGame(file);
                  await _loadGames();
                }
              },
              icon: Text("✖", textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gameList() {
    if (games.isEmpty) {
      return Text("no games");
    }
    return SizedBox(
      height: 400,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 5.0),
        children: [
          for (var (i, game) in games.indexed)
            Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 5.0),
              child: Container(
                color: Colors.black12,
                child: Padding(
                  padding: EdgeInsetsGeometry.all(5.0),
                  child: _gameListRow(i, game),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gameSaver(BuildContext context) {
    return _frame(
      context,
      TextButton(
        child: const Text(
          'сохранить игру',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () async {
          if (widget.state == null) return;
          final success = await GameStorage.saveGame(widget.state!);
          if (success && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('сохранено')));
            await _loadGames();
          }
        },
      ),
    );
  }

  Widget _gameCreator(BuildContext context) {
    return Column(
      children: [
        TextField(
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          controller: namesTextFieldController,
          decoration: const InputDecoration(hintText: "Создание новой игры"),
          onChanged: (_) {
            var nn = namesTextFieldController.text
                .split(" ")
                .where((c) => c.isNotEmpty)
                .toList();
            if (nn.length < 3 ||
                nn.length > 4 ||
                Set.from(nn).length != nn.length) {
              setState(() {
                names = null;
              });
            } else {
              setState(() {
                names = nn;
              });
            }
          },
        ),
        if (names != null)
          DropdownButton(
            hint: const Text("сдающий"),
            value: dealer,
            items: names!.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) {
              dealer = val!;
              setState(() {});
            },
          ),
        if (dealer != null)
          TextButton(
            child: const Text('Создать новую игру'),
            onPressed: () {
              if (names == null) return;
              widget.onChange(GameState(names!, dealer!));
            },
          ),
      ],
    );
  }
}
