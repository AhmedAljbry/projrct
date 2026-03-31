class HslChannel {
  const HslChannel({
    required this.h,
    required this.s,
    required this.l,
  });

  const HslChannel.zero()
      : h = 0,
        s = 0,
        l = 0;

  final double h;
  final double s;
  final double l;

  HslChannel copyWith({
    double? h,
    double? s,
    double? l,
  }) {
    return HslChannel(
      h: h ?? this.h,
      s: s ?? this.s,
      l: l ?? this.l,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'h': h,
      's': s,
      'l': l,
    };
  }

  factory HslChannel.fromMap(Map<String, dynamic> map) {
    return HslChannel(
      h: _asDouble(map['h']),
      s: _asDouble(map['s']),
      l: _asDouble(map['l']),
    );
  }
}

class HslProfile {
  const HslProfile({
    required this.red,
    required this.orange,
    required this.yellow,
    required this.green,
    required this.aqua,
    required this.blue,
    required this.purple,
    required this.magenta,
  });

  const HslProfile.zero()
      : red = const HslChannel.zero(),
        orange = const HslChannel.zero(),
        yellow = const HslChannel.zero(),
        green = const HslChannel.zero(),
        aqua = const HslChannel.zero(),
        blue = const HslChannel.zero(),
        purple = const HslChannel.zero(),
        magenta = const HslChannel.zero();

  final HslChannel red;
  final HslChannel orange;
  final HslChannel yellow;
  final HslChannel green;
  final HslChannel aqua;
  final HslChannel blue;
  final HslChannel purple;
  final HslChannel magenta;

  HslProfile copyWith({
    HslChannel? red,
    HslChannel? orange,
    HslChannel? yellow,
    HslChannel? green,
    HslChannel? aqua,
    HslChannel? blue,
    HslChannel? purple,
    HslChannel? magenta,
  }) {
    return HslProfile(
      red: red ?? this.red,
      orange: orange ?? this.orange,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      aqua: aqua ?? this.aqua,
      blue: blue ?? this.blue,
      purple: purple ?? this.purple,
      magenta: magenta ?? this.magenta,
    );
  }

  HslChannel channelByName(String channel) {
    switch (channel) {
      case 'red':
        return red;
      case 'orange':
        return orange;
      case 'yellow':
        return yellow;
      case 'green':
        return green;
      case 'aqua':
        return aqua;
      case 'blue':
        return blue;
      case 'purple':
        return purple;
      case 'magenta':
        return magenta;
      default:
        return const HslChannel.zero();
    }
  }

  HslProfile withChannel(String channel, HslChannel value) {
    switch (channel) {
      case 'red':
        return copyWith(red: value);
      case 'orange':
        return copyWith(orange: value);
      case 'yellow':
        return copyWith(yellow: value);
      case 'green':
        return copyWith(green: value);
      case 'aqua':
        return copyWith(aqua: value);
      case 'blue':
        return copyWith(blue: value);
      case 'purple':
        return copyWith(purple: value);
      case 'magenta':
        return copyWith(magenta: value);
      default:
        return this;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'red': red.toMap(),
      'orange': orange.toMap(),
      'yellow': yellow.toMap(),
      'green': green.toMap(),
      'aqua': aqua.toMap(),
      'blue': blue.toMap(),
      'purple': purple.toMap(),
      'magenta': magenta.toMap(),
    };
  }

  factory HslProfile.fromMap(Map<String, dynamic> map) {
    return HslProfile(
      red: HslChannel.fromMap(
        (map['red'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      orange: HslChannel.fromMap(
        (map['orange'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      yellow: HslChannel.fromMap(
        (map['yellow'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      green: HslChannel.fromMap(
        (map['green'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      aqua: HslChannel.fromMap(
        (map['aqua'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      blue: HslChannel.fromMap(
        (map['blue'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      purple: HslChannel.fromMap(
        (map['purple'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
      magenta: HslChannel.fromMap(
        (map['magenta'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      ),
    );
  }
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}
