import 'package:flutter/material.dart';

import 'package:preference/pages/game_page.dart';
import 'package:preference/pages/start_page.dart';
import 'package:preference/pages/stats_page.dart';
import 'package:preference/types/types.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.5)),
        home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Padding(padding: EdgeInsets.all(30), child: StateApp())));
  }
}

class StateApp extends StatefulWidget {
  const StateApp({super.key});

  @override
  State<StateApp> createState() => _StateAppState();
}

class _StateAppState extends State<StateApp> {
  final PageController _pageController = PageController(initialPage: 0);

  GameState? state;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {});
        // Optional: Track which page you are currently on
      },
      children: [
        StartPage(state: state, onChange: (newState) {
          setState(() {
            state = newState;
          });
          _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        }),
        if (state != null) GamePage(state: state!),
        if (state != null) StatsPage(state: state!),
        MyPageWidget(color: Colors.red, text: 'Page 1: Sewipe Ledt!'),
      ],
    );
  }
}

class MyPageWidget extends StatelessWidget {
  final Color color;
  final String text;

  const MyPageWidget({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
