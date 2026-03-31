class CurveProfile {
  const CurveProfile({
    required this.master,
    required this.red,
    required this.green,
    required this.blue,
  });

  factory CurveProfile.identity() {
    const curve = <double>[0, 0.25, 0.5, 0.75, 1];
    return const CurveProfile(
      master: curve,
      red: curve,
      green: curve,
      blue: curve,
    );
  }

  factory CurveProfile.zeroDelta() {
    const curve = <double>[0, 0, 0, 0, 0];
    return const CurveProfile(
      master: curve,
      red: curve,
      green: curve,
      blue: curve,
    );
  }

  final List<double> master;
  final List<double> red;
  final List<double> green;
  final List<double> blue;

  CurveProfile copyWith({
    List<double>? master,
    List<double>? red,
    List<double>? green,
    List<double>? blue,
  }) {
    return CurveProfile(
      master: master ?? this.master,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'master': master,
      'red': red,
      'green': green,
      'blue': blue,
    };
  }

  factory CurveProfile.fromMap(Map<String, dynamic> map) {
    return CurveProfile(
      master: _toDoubleList(map['master']),
      red: _toDoubleList(map['red']),
      green: _toDoubleList(map['green']),
      blue: _toDoubleList(map['blue']),
    );
  }
}

List<double> _toDoubleList(dynamic value) {
  final list = (value as List<dynamic>? ?? const <dynamic>[])
      .map((item) => (item as num).toDouble())
      .toList(growable: false);
  if (list.isEmpty) {
    return const <double>[0, 0.25, 0.5, 0.75, 1];
  }
  return list;
}
