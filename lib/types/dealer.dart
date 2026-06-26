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
