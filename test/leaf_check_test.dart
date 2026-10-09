import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/ml/leaf_classifier.dart';
import 'package:phytosense_ai/ml/plant_disease_catalog.dart';

void main() {
  final labels = (jsonDecode(
          File('assets/ml/plant_disease_labels.json').readAsStringSync()) as List)
      .cast<String>();

  List<double> probs(Map<String, double> set) {
    final p = List<double>.filled(labels.length, 0);
    set.forEach((k, v) => p[labels.indexOf(k)] = v);
    return p;
  }

  test('labels file has 38 classes and every class has a catalog entry', () {
    expect(labels.length, 38);
    for (final l in labels) {
      expect(PlantDiseaseCatalog.condition(l), isNotNull, reason: l);
      expect(PlantDiseaseCatalog.cropForLabel(l), isNotNull, reason: l);
    }
  });

  test('every offered crop has healthy + at least one disease', () {
    for (final crop in PlantDiseaseCatalog.supportedCrops) {
      final mine =
          PlantDiseaseCatalog.conditions.where((c) => c.cropKey == crop.key);
      expect(mine.any((c) => c.healthy), isTrue, reason: crop.key);
      expect(mine.any((c) => !c.healthy), isTrue, reason: crop.key);
    }
  });

  test('confident disease, with top 3 from the chosen crop only', () {
    final d = LeafClassifier.diagnose(
        probs({
          'Tomato___Early_blight': 0.82,
          'Tomato___Target_Spot': 0.09,
          'Potato___Early_blight': 0.05,
          'Tomato___Healthy': 0.04,
        }),
        labels,
        'tomato');
    expect(d.verdict, LeafVerdict.confident);
    expect(d.best!.conditionKey, 'early_blight');
    expect(d.top3.every((e) => e.$1.cropKey == 'tomato'), isTrue);
    expect(d.resultKey, 'early_blight');
  });

  test('below 60% says Not sure instead of a disease name', () {
    final d = LeafClassifier.diagnose(
        probs({'Tomato___Early_blight': 0.55, 'Tomato___Late_blight': 0.40}),
        labels,
        'tomato');
    expect(d.verdict, LeafVerdict.unsure);
    expect(d.best, isNull);
    expect(d.resultKey, 'unsure');
  });

  test('a clearly different crop is called out, not forced into the pick', () {
    final d = LeafClassifier.diagnose(
        probs({'Grape___Black_rot': 0.9, 'Tomato___Healthy': 0.1}),
        labels,
        'tomato');
    expect(d.verdict, LeafVerdict.otherCrop);
    expect(d.looksLike!.key, 'grape');
  });

  test('healthy leaf', () {
    final d = LeafClassifier.diagnose(
        probs({'Potato___Healthy': 0.97}), labels, 'potato');
    expect(d.verdict, LeafVerdict.confident);
    expect(d.best!.healthy, isTrue);
  });

  test('unsupported crops never get a guess', () {
    final d = LeafClassifier.diagnose(
        probs({'Tomato___Healthy': 0.99}), labels, 'rice');
    expect(d.verdict, LeafVerdict.unsupportedCrop);
    expect(PlantDiseaseCatalog.crop('rice'), isNull);
  });

  test('every condition has 2-3 advice lines in both languages', () {
    for (final c in PlantDiseaseCatalog.conditions) {
      for (final ta in [false, true]) {
        final lines = PlantDiseaseCatalog.advice(c, tamil: ta);
        expect(lines.length, inInclusiveRange(2, 3), reason: c.label);
      }
    }
  });
}
