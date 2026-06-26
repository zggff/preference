enum Bonus {
  bird(2),
  bomb(4);

  final int mult;
  const Bonus(this.mult);
}

enum GameType {
  raspas(name: "распасы", maxPlayer: 0, points: 1, short: "Р"),
  game6(name: "шестерная", minPlayer: 6, minVist: 4, points: 1, short: "6"),
  game7(name: "семерная", minPlayer: 7, minVist: 2, points: 2, short: "7"),
  game8(name: "восьмерная", minPlayer: 8, minVist: 1, points: 3, short: "8"),
  game9(name: "девятерная", minPlayer: 9, minVist: 1, points: 4, short: "9"),
  game10(name: "десятерная", minPlayer: 10, minVist: 0, points: 5, short: "10"),
  misere(name: "мизер", maxPlayer: 0, points: 5, short: "М"),
  neg(name: "гора", maxPlayer: 0, points: 1, short: "-"),
  pos(name: "пуля", maxPlayer: 0, points: 1, short: "+");

  final String name;
  final int minPlayer;
  final int maxPlayer;
  final int minVist;
  final int points;
  final String short;
  const GameType({
    required this.name,
    required this.short,
    this.minPlayer = 0,
    this.maxPlayer = 10,
    this.minVist = 0,
    this.points = 1,
  });
}
