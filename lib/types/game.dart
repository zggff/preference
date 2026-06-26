import 'package:preference/types/enums.dart';

class Game {
  String player;
  String dealer;
  GameType type;
  Bonus? bonus;
  bool success;
  late Map<String, int> taken;
  late Map<String, bool> dark;
  Game({
    required this.player,
    required this.dealer,
    required this.type,
    required this.taken,
    required this.dark,
    this.bonus,
    this.success = false,
  });

  Map<String, dynamic> toJson() => {
    'player': player,
    'dealer': dealer,
    'type': type.name,
    'bonus': bonus?.name,
    'success': success,
    'taken': taken,
    'dark': dark,
  };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    player: json['player'] as String,
    dealer: json['dealer'] as String,
    type: GameType.values.byName(json['type'] as String),
    taken: Map<String, int>.from(json['taken'] as Map),
    dark: Map<String, bool>.from(json['dark'] as Map),
    bonus: json['bonus'] != null
        ? Bonus.values.byName(json['bonus'] as String)
        : null,
    success: json['success'] as bool? ?? false,
  );
}
