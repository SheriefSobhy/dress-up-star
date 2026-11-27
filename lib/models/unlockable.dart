/// Something that can be a Star Shop item: clothes and room things.
abstract mixin class Unlockable {
  /// Unique over all clothes and room things (it is saved when unlocked).
  String get id;

  /// Stars needed to unlock it (0: free from the start).
  int get price;

  /// A Star Shop item (locked until bought with stars).
  bool get isSpecial => price > 0;
}
