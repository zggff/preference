import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:format/format.dart';

enum Bonus {
  bird(2),
  bomb(4);

  final int mult;
  const Bonus(this.mult);
}

enum GameType {
  raspas(name: "распасы", maxPlayer: 0, points: 1),
  game6(name: "шестерная", minPlayer: 6, minVist: 4, points: 1),
  game7(name: "семерная", minPlayer: 7, minVist: 2, points: 2),
  game8(name: "восьмерная", minPlayer: 8, minVist: 1, points: 3),
  game9(name: "девятерная", minPlayer: 9, minVist: 1, points: 4),
  game10(name: "десятерная", minPlayer: 10, minVist: 0, points: 5),
  misere(name: "мизер", maxPlayer: 0, points: 5);

  final String name;
  final int minPlayer;
  final int maxPlayer;
  final int minVist;
  final int points;
  const GameType({
    required this.name,
    this.minPlayer = 0,
    this.maxPlayer = 10,
    this.minVist = 0,
    this.points = 1,
  });
}

class Game {
  String player;
  String dealer;
  GameType type;
  Bonus? bonus;
  bool success;
  late Map<String, int> taken;
  late Map<String, bool> dark;
  Game(
      {required this.player,
      required this.dealer,
      required this.type,
      required this.taken,
      required this.dark,
      this.bonus,
      this.success = false});
}

class Player {
  String name;
  int pos = 0;
  int neg = 0;

  List<Bonus> bonuses;
  int bonusesSpent;
  int raspasDealed;
  Map<(GameType, bool), int> playedGames = {};
  late Map<String, int> vist = {};
  Player(this.name, Iterable<String> names)
      : bonuses = [],
        bonusesSpent = 0,
        raspasDealed = 0 {
    for (var type in GameType.values.skip(1)) {
      playedGames[(type, false)] = 0;
      playedGames[(type, true)] = 0;
    }
    vist = Map.fromEntries(
        names.where((n) => n != name).map((n) => MapEntry(n, 0)));
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

  void addRaspas() {
    raspasDealed++;
    if (raspasDealed % 3 == 0) {
      neg += 10;
    }
  }

  void addVist(String other, int val) => vist[other] = vist[other]! + val;
  void addPos(int val) => pos += val;
  void addNeg(int val) => neg += val;
}

class Dealer implements Iterator {
  Dealer({required this.list});
  List<String> list;
  int i = 0;

  @override
  get current => list[i];

  @override
  bool moveNext() {
    i = (i + 1) % list.length;
    return true;
  }

  bool movePrev() {
    i = (i + list.length - 1) % list.length;
    return true;
  }
}

class GameState {
  List<Game> games = [];

  late Map<String, Player> players;
  late Dealer dealer;
  late Map<String, int> res;
  int dealerConsequitive = 0;

  GameState(List<String> names, String dealerName) {
    assert(names.length == 3 || names.length == 4);
    players = Map.fromEntries(
        names.map((name) => MapEntry(name, Player(name, names))));
    res = Map.fromEntries(names.map((name) => MapEntry(name, 0)));
    dealer = Dealer(list: names);
    while (dealer.current != dealerName) {
      dealer.moveNext();
    }
  }

  GameState.withDealer(List<String> names) : this(names, names.first);

  void calculateRes() {
    var maxPos =
        players.values.map((p) => p.pos).reduce((acc, p) => acc > p ? acc : p);
    Map<String, int> additional =
        players.map((k, v) => MapEntry(k, (v.neg + maxPos - players[k]!.pos)));
    var minNeg = additional.values.reduce((acc, v) => acc < v ? acc : v);
    additional.updateAll((k, v) => (v - minNeg));
    // debugPrint("--------");
    // debugPrint("{}".format(additional.entries));
    additional.updateAll((k, v) => v * 10 ~/ (additional.length));
    // debugPrint("{}".format(additional.entries));

    var newVist = players.map((key, val) {
      var vist = val.vist.map((k, v) => MapEntry(k, v + additional[k]!));
      return MapEntry(key, vist);
    });
    // debugPrint("{}".format(newVist.entries));

    var newDiff = newVist.map((key, val) {
      var diff = val.map((k, v) => MapEntry(k, v - newVist[k]![key]!));
      return MapEntry(key, diff);
    });
    res = newDiff
        .map((k, v) => MapEntry(k, v.values.reduce((acc, v) => acc + v)));
  }

  void popGame() {
    if (games.isEmpty) {
      return;
    }
    while (dealer.current != games.last.dealer) {
      dealer.moveNext();
    }
    games.removeLast();
    if (players.length == 4) {
      dealerConsequitive = games.reversed
              .takeWhile((g) =>
                  g.type == GameType.raspas && g.dealer == dealer.current)
              .length %
          3;
    }
    recalculate();
    calculateRes();
  }

  void updateGameState(String? player, GameType gameType,
      Map<String, int> taken, Map<String, bool> dark) {
    assert(!(gameType != GameType.raspas && player == null));

    player = player ?? "";

    games.add(Game(
        player: player,
        type: gameType,
        taken: taken,
        dark: dark,
        dealer: dealer.current));

    recalculate();
    calculateRes();
    if (players.length == 4 && gameType == GameType.raspas) {
      dealerConsequitive++;
      if (dealerConsequitive < 3) {
        return;
      }
    }
    dealerConsequitive = 0;
    dealer.moveNext();
  }

  void recalculate() {
    int raspasCount = 1;
    players = players.map((n, m) => MapEntry(n, Player(n, players.keys)));
    for (var game in games) {
      if (game.type == GameType.raspas) {
        if (raspasCount == 1) {
          players[game.dealer]!.addRaspas();
        }
        if (raspasCount == 3 && players.length == 4) {
          players[game.dealer]!.addNeg(10);
        }

        int mult = players.length == 3 ? raspasCount : 2;
        raspasCount = raspasCount % 3 + 1;

        var minTaken =
            game.taken.values.reduce((cur, next) => cur < next ? cur : next);
        for (var name in players.keys) {
          players[name]!
              .bonuses
              .add((game.dark[name] ?? false) ? Bonus.bomb : Bonus.bird);
          if (game.taken[name] == 0) {
            players[name]!.addPos(mult);
          } else {
            var increase = (game.taken[name]! - minTaken) * mult;
            players[name]!.addNeg(increase);
          }
        }
        continue;
      }
      raspasCount = 1;
      var play = players[game.player]!;
      var each = (game.dark[game.player]! ? 2 : 1) *
          play.getBonus() *
          game.type.points;
      var playerTook = game.taken[game.player]!;
      if (play.getBonus() > 1) {
        game.bonus = play.bonuses.last;
      }

      if (playerTook > game.type.maxPlayer ||
          playerTook < game.type.minPlayer) {
        var dist = math.min((playerTook - game.type.maxPlayer).abs(),
            (game.type.minPlayer - playerTook).abs());
        var increase = each * dist;
        play.addNeg(increase);
        play.addGame(game.type, false);
      } else {
        play.addPos(each);
        play.popBonus();
        play.addGame(game.type, true);
        game.success = true;
      }

      var others = game.taken.keys.where((name) => name != game.player);
      if (players.length == 4) {
        others = others.where((name) => name != game.dealer);
      }
      for (var k in others) {
        var increase = each * game.taken[k]!;
        players[k]!.addVist(game.player, increase);
        if (10 - playerTook >= game.type.minVist) {
          continue;
        }
        if (game.taken[k]! < (game.type.minVist / 2).ceil()) {
          double dist = game.type.minVist / 2 - game.taken[k]!;
          if (game.type == GameType.game8) {
            dist = 0.5;
          }
          var increase = (each * dist).floor();
          players[k]!.addNeg(increase);
        }
      }
    }
  }
}
