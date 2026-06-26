import 'package:flutter/material.dart';
import 'package:preference/services/saver.dart';
import 'package:preference/types/game_state.dart';

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
  late TextEditingController namesTextFieldController;

  @override
  void initState() {
    super.initState();
    namesTextFieldController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    namesTextFieldController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {}

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: Column(
          children: [
            _gameLoader(context),
            const Divider(thickness: 2, color: Colors.grey, height: 1),
            _gameSaver(context),
            const Divider(thickness: 2, color: Colors.grey, height: 1),
            _gameCreator(context),
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

  Widget _gameLoader(BuildContext context) {
    return _frame(
      context,
      TextButton(
        child: const Text(
          'загрузить игру',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () async {
          final loadedState = await GameStorage.openGameWithSelection();
          if (loadedState != null) {
            widget.onChange(loadedState);
          }
        },
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
          final success = await GameStorage.saveGameWithSelection(
            widget.state!,
          );
          if (success && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('сохранено')));
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
