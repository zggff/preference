import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:preference/pages/game_page.dart';
import 'package:preference/pages/start_page.dart';
import 'package:preference/pages/stats_page.dart';
import 'package:preference/types/types.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setMinimumSize(const Size(1000, 1200));
    // WindowManager.instance.setMaximumSize(
    //   const Size(1920, 1080),
    // ); // Maximum size of app
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.show();
    });
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.5),
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Padding(padding: EdgeInsets.all(30), child: StateApp()),
      ),
    );
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
    HardwareKeyboard.instance.addHandler(_keyboardCallback);
  }

  @override
  void dispose() {
    _pageController.dispose();
    HardwareKeyboard.instance.removeHandler(_keyboardCallback);
    super.dispose();
  }

  bool _keyboardCallback(KeyEvent e) {
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_pageController.offset < _pageController.position.maxScrollExtent) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_pageController.offset > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    return false;
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
        StartPage(
          state: state,
          onChange: (newState) {
            setState(() {
              state = newState;
            });
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        if (state != null) GamePage(state: state!),
        if (state != null) StatsPage(state: state!),
        MyPageWidget(color: Colors.red, text: 'Last page: go back'),
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
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
