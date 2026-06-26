import 'package:preference/types/enums.dart';

class Game {
  String player;
  String dealer;
  GameType type;
  Bonus? bonus;
  String? from;
  bool success;
  late Map<String, int> taken;
  late Map<String, bool> dark;
  Game({
    required this.player,
    required this.dealer,
    required this.type,
    required this.taken,
    required this.dark,
    this.from,
    this.bonus,
    this.success = false,
  });
}
