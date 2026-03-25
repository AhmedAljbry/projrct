class IdGenerator {
  IdGenerator._();

  static int _seed = DateTime.now().microsecondsSinceEpoch;

  static String next(String prefix) {
    _seed += 1;
    return '$prefix$_seed';
  }
}
