import 'package:preference/types/enums.dart';

class Player {
  String name;
  int pos = 0;
  int neg = 0;

  List<Bonus> bonuses;
  int bonusesSpent;
  int raspasDealedCnt;
  int raspasDealed;
  int raspasOffset;
  Map<(GameType, bool), int> playedGames = {};
  late Map<String, int> vist = {};

  Player(this.name, Iterable<String> names)
    : bonuses = [],
      bonusesSpent = 0,
      raspasDealedCnt = 3,
      raspasOffset = 0,
      raspasDealed = 0 {
    for (var type in GameType.values.skip(1)) {
      playedGames[(type, false)] = 0;
      playedGames[(type, true)] = 0;
    }
    vist = Map.fromEntries(
      names.where((n) => n != name).map((n) => MapEntry(n, 0)),
    );
  }

  Player.deepCopy(Player other)
    : name = other.name,
      pos = other.pos,
      neg = other.neg,
      bonuses = List.from(other.bonuses),
      bonusesSpent = other.bonusesSpent,
      raspasDealedCnt = other.raspasDealedCnt,
      raspasDealed = other.raspasDealed,
      raspasOffset = other.raspasOffset,
      playedGames = Map.fromEntries(
        other.playedGames.entries.map((e) => MapEntry(e.key, e.value)),
      ),
      vist = Map.fromEntries(
        other.vist.entries.map((e) => MapEntry(e.key, e.value)),
      );

  Player copy() {
    return Player.deepCopy(this);
  }

  void addToList(List l, int val) {
    var last = l.isNotEmpty ? l.last : 0;
    if (val > 0) {
      l.add(last + val);
    }
  }

  int getBonus() {
    if (bonuses.length > bonusesSpent) {
      return bonuses[bonusesSpent].mult;
    }
    return 1;
  }

  void popBonus() {
    if (bonuses.length > bonusesSpent) {
      bonusesSpent++;
    }
  }

  void addGame(GameType gameType, bool success) {
    playedGames[(gameType, success)] = playedGames[(gameType, success)]! + 1;
    if (playedGames[(gameType, success)]! % 4 == 0) {
      neg += 10;
    }
  }

  void addRaspas({bool decrease = false}) {
    raspasDealed++;
    if ((raspasDealed - raspasOffset) % raspasDealedCnt == 0) {
      if (decrease && raspasDealedCnt > 1) {
        raspasDealedCnt -= 1;
      }
      raspasOffset = raspasDealed;
      neg += 10;
    }
  }

  void addVist(String other, int val) => vist[other] = vist[other]! + val;
  void addPos(int val) => pos += val;
  void addNeg(int val) => neg += val;
}
