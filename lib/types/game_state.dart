import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:preference/types/dealer.dart';
import 'package:preference/types/enums.dart';
import 'package:preference/types/game.dart';
import 'package:preference/types/player.dart';

class GameState {
  List<Game> games = [];
  late String _starter;
  late Map<String, Player> players;
  late Dealer dealer;
  late Map<String, List<int>> _resHistory;
  late Map<String, int> res;
  int dealerConsequitive = 0;

  Map<String, List<int>> get resHistory => _resHistory;

  void _saveHistory() {
    res.forEach((key, value) {
      _resHistory[key]!.add(value);
    });
  }

  void _popHistory() {
    _resHistory.forEach((key, value) {
      value.removeLast();
    });
  }

  GameState(List<String> names, String dealerName) {
    assert(names.length == 3 || names.length == 4);
    players = Map.fromEntries(
      names.map((name) => MapEntry(name, Player(name, names))),
    );

    _starter = dealerName;
    res = Map.fromEntries(names.map((name) => MapEntry(name, 0)));
    _resHistory = Map.fromEntries(names.map((name) => MapEntry(name, [0])));
    dealer = Dealer(list: names);
    while (dealer.current != dealerName) {
      dealer.moveNext();
    }
  }

  GameState.withDealer(List<String> names) : this(names, names.first);

  void reset(List<String> names, String dealerName) {
    var s = GameState(names, dealerName);
    games.clear();
    res.clear();
    dealerConsequitive = 0;
    players = s.players;
    dealer = s.dealer;
  }

  void _calculateRes() {
    var maxPos = players.values
        .map((p) => p.pos)
        .reduce((acc, p) => acc > p ? acc : p);
    Map<String, int> additional = players.map(
      (k, v) => MapEntry(k, (v.neg + maxPos - players[k]!.pos)),
    );
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
    res = newDiff.map(
      (k, v) => MapEntry(k, v.values.reduce((acc, v) => acc + v)),
    );
  }

  void popGame() {
    if (games.isEmpty) {
      return;
    }
    while (dealer.current != games.last.dealer) {
      dealer.moveNext();
    }
    games.removeLast();
    _popHistory();
    if (players.length == 4) {
      dealerConsequitive =
          games.reversed
              .takeWhile(
                (g) => g.type == GameType.raspas && g.dealer == dealer.current,
              )
              .length %
          3;
    }
    _recalculate();
    _calculateRes();
  }

  void updateGameState(
    String? player,
    GameType gameType,
    Map<String, int> taken,
    Map<String, bool> dark,
    String? from,
  ) {
    assert(!(gameType != GameType.raspas && player == null));

    player = player ?? "";

    games.add(
      Game(
        player: player,
        type: gameType,
        taken: taken,
        dark: dark,
        dealer: dealer.current,
        from: from,
      ),
    );

    _recalculate();
    _calculateRes();
    _saveHistory();
    if (players.length == 4 && gameType == GameType.raspas) {
      dealerConsequitive++;
      if (dealerConsequitive < 3) {
        return;
      }
    }
    dealerConsequitive = 0;
    if (gameType != GameType.neg && gameType != GameType.pos) {
      dealer.moveNext();
    }
  }

  void _recalculate() {
    int raspasCount = 1;
    players = players.map((n, m) => MapEntry(n, Player(n, players.keys)));
    for (var game in games) {
      if (game.type == GameType.neg) {
        var mult = (game.dark[game.player]! ? -1 : 1);
        players[game.player]!.addNeg(game.taken[game.player]! * mult);
        game.success = false;
        continue;
      }
      if (game.type == GameType.pos) {
        var mult = (game.dark[game.player]! ? -1 : 1);
        players[game.player]!.addPos(game.taken[game.player]! * mult);
        game.success = true;
        continue;
      }

      if (game.type == GameType.raspas) {
        if (raspasCount == 1) {
          players[game.dealer]!.addRaspas(decrease: true);
        }
        if (raspasCount == 3 && players.length == 4) {
          players[game.dealer]!.addNeg(10);
        }

        int mult = players.length == 3 ? raspasCount : 2;
        raspasCount = raspasCount % 3 + 1;

        var minTaken = game.taken.values.reduce(
          (cur, next) => cur < next ? cur : next,
        );
        for (var name in players.keys) {
          players[name]!.bonuses.add(
            (game.dark[name] ?? false) ? Bonus.bomb : Bonus.bird,
          );
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
      var other = players[game.from];

      var each =
          (game.dark[game.player]! ? 2 : 1) *
          play.getBonus() *
          game.type.points;
      var playerTook = game.taken[game.player]!;
      if (play.getBonus() > 1) {
        game.bonus = play.bonuses[play.bonusesSpent];
      }

      if (playerTook > game.type.maxPlayer ||
          playerTook < game.type.minPlayer) {
        var dist = math.min(
          (playerTook - game.type.maxPlayer).abs(),
          (game.type.minPlayer - playerTook).abs(),
        );
        var increase = each * dist;
        if (other != null) {
          play.addNeg((increase / 2).ceil());
          other.addNeg((increase / 2).floor());
        } else {
          play.addNeg(increase);
        }
        play.addGame(game.type, false);
      } else {
        if (other != null) {
          play.addPos((each / 2).ceil());
          other.addPos((each / 2).floor());
        } else {
          play.addPos(each);
        }
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
        double shouldTake = game.type.minVist / 2;
        if (game.taken[k]! < shouldTake) {
          double dist = math.min(
            shouldTake - game.taken[k]!,
            game.type.minVist.toDouble() - (10 - playerTook),
          );
          var increase = (each * dist).floor();
          players[k]!.addNeg(increase);
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'players': players.keys.toList(),
    'dealer': _starter,
    'games': games
        .map(
          (g) => {
            'player': g.player,
            'type': EnumName(g.type).name,
            'taken': g.taken,
            'dark': g.dark,
            'from': g.from,
          },
        )
        .toList(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final names = List<String>.from(json['players']);
    final dealer = json['dealer'] as String;
    final state = GameState(names, dealer);
    final games = (json['games'] as List).map((g) => g as Map<String, dynamic>);
    for (var game in games) {
      state.updateGameState(
        game['player'],
        GameType.values.byName(game['type']),
        game['taken'].cast<String, int>(),
        game['dark'].cast<String, bool>(),
        game['from'],
      );
    }
    return state;
  }
}
