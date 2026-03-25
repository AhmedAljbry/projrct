/*
import 'package:flutter/material.dart';

class MultiSampleStyleBuilder {
  const MultiSampleStyleBuilder();

  MultiSampleStyleProfile build({
    required String name,
    required List<WeightedStyleSample> samples,
  }) {
    if (samples.isEmpty) {
      return MultiSampleStyleProfile(
        name: name,
        samples: samples,
        compositeStyle: StyleProfile.empty(name: name),
      );
    }
    final totalWeight = samples.fold<double>(0, (sum, item) => sum + item.weight).clamp(0.001, 9999);
    var current = samples.first.profile;
    final blender = const StyleBlendEngine();
    for (var index = 1; index < samples.length; index++) {
      final sample = samples[index];
      final ratio = clampUnit(sample.weight / totalWeight);
      current = blender.blend(
        StyleBlendProfile(
          primaryStyle: current,
          secondaryStyle: sample.profile,
          ratio: ratio,
        ),
      );
    }
    final dominant = samples.where((item) => item.dominant).toList();
    if (dominant.isNotEmpty) {
      current = blender.blend(
        StyleBlendProfile(
          primaryStyle: current,
          secondaryStyle: dominant.first.profile,
          ratio: 0.28,
        ),
      );
    }
    return MultiSampleStyleProfile(
      name: name,
      samples: samples,
      compositeStyle: current.copyWith(name: name),
    );
  }
}
*/
