import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'plant_disease_catalog.dart';

/// On-device leaf disease check. Nothing leaves the phone.
///
/// Model: MobileNetV2 fine-tuned on PlantVillage (38 classes), by S.M Hassan,
/// MIT licence (https://huggingface.co/rarfileexe/Plant-Disease-Detector),
/// converted to float16 TFLite for this app.
///
/// Preprocessing is inside the model (it rescales to [-1, 1] itself), so the
/// input is plain RGB pixel values 0-255 as float32, shape [1, 224, 224, 3].
/// Do NOT normalise again.
class LeafClassifier {
  LeafClassifier._();

  static const modelAsset = 'assets/ml/plant_disease_mnv2_f16.tflite';
  static const labelsAsset = 'assets/ml/plant_disease_labels.json';
  static const licenseAsset = 'assets/ml/MODEL_LICENSE.txt';
  static const inputSize = 224;

  /// Below this, the app says "Not sure" instead of naming a condition.
  static const minConfidence = 0.60;

  static Uint8List? _model;
  static List<String>? _labels;
  static bool _licenseAdded = false;

  /// Shows the model's MIT licence on Flutter's licence page.
  static void registerLicense() {
    if (_licenseAdded) return;
    _licenseAdded = true;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
          const ['VayPulse leaf model (Plant Disease Detector, S.M Hassan)'],
          await rootBundle.loadString(licenseAsset));
    });
  }

  static Future<List<String>> labels() async => _labels ??=
      (jsonDecode(await rootBundle.loadString(labelsAsset)) as List)
          .cast<String>();

  /// Runs the model in a background isolate so the UI never freezes.
  static Future<LeafRun> run(Uint8List photoBytes) async {
    final model = _model ??=
        (await rootBundle.load(modelAsset)).buffer.asUint8List();
    final names = await labels();
    final result = await Isolate.run(() => _infer(model, photoBytes));
    if (result.probs.length != names.length) {
      throw StateError(
          'Model output ${result.probs.length} != labels ${names.length}');
    }
    return LeafRun(result.probs, names, result.thumbnail);
  }

  static ({List<double> probs, Uint8List thumbnail}) _infer(
      Uint8List model, Uint8List photo) {
    final decoded = img.decodeImage(photo);
    if (decoded == null) throw const FormatException('Not an image');
    final upright = img.bakeOrientation(decoded);
    final input = preprocess(upright);
    final thumb = img.encodeJpg(
        img.copyResize(squareCrop(upright), width: 120, height: 120),
        quality: 70);

    final interpreter = Interpreter.fromBuffer(model);
    try {
      interpreter.allocateTensors();
      interpreter.getInputTensor(0).data = input.buffer.asUint8List();
      interpreter.invoke();
      final raw = interpreter.getOutputTensor(0).data;
      final view = ByteData.sublistView(raw);
      final probs = List<double>.generate(raw.lengthInBytes ~/ 4,
          (i) => view.getFloat32(i * 4, Endian.little));
      return (probs: probs, thumbnail: Uint8List.fromList(thumb));
    } finally {
      interpreter.close();
    }
  }

  /// Centre square, so the leaf is not stretched (PlantVillage images are
  /// square).
  static img.Image squareCrop(img.Image image) {
    final side = image.width < image.height ? image.width : image.height;
    return img.copyCrop(image,
        x: (image.width - side) ~/ 2,
        y: (image.height - side) ~/ 2,
        width: side,
        height: side);
  }

  /// RGB, 224x224, float32 values 0-255 (model normalises internally).
  static Float32List preprocess(img.Image image) {
    final resized = img.copyResize(squareCrop(image),
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear);
    final out = Float32List(inputSize * inputSize * 3);
    var i = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        out[i++] = p.r.toDouble();
        out[i++] = p.g.toDouble();
        out[i++] = p.b.toDouble();
      }
    }
    return out;
  }

  /// Applies the honesty rules to the raw model output for the crop the
  /// farmer picked.
  static LeafDiagnosis diagnose(
      List<double> probs, List<String> labels, String cropKey) {
    final crop = PlantDiseaseCatalog.crop(cropKey);
    if (crop == null) {
      return LeafDiagnosis(cropKey, LeafVerdict.unsupportedCrop, const [], 0);
    }
    final order = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final inCrop = order
        .where((i) => labels[i].startsWith(crop.labelPrefix))
        .map((i) => (PlantDiseaseCatalog.condition(labels[i]), probs[i]))
        .where((e) => e.$1 != null)
        .map((e) => (e.$1!, e.$2))
        .toList();
    final top3 = inCrop.take(3).toList();
    final best = top3.isEmpty ? 0.0 : top3.first.$2;

    // The photo clearly looks like a different crop.
    final overall = order.first;
    final overallCrop = PlantDiseaseCatalog.cropForLabel(labels[overall]);
    if (overallCrop != null &&
        overallCrop.key != crop.key &&
        probs[overall] >= minConfidence) {
      return LeafDiagnosis(cropKey, LeafVerdict.otherCrop, top3, best,
          looksLike: overallCrop);
    }
    if (best < minConfidence) {
      return LeafDiagnosis(cropKey, LeafVerdict.unsure, top3, best);
    }
    return LeafDiagnosis(cropKey, LeafVerdict.confident, top3, best);
  }
}

class LeafRun {
  final List<double> probs;
  final List<String> labels;
  final Uint8List thumbnail;
  const LeafRun(this.probs, this.labels, this.thumbnail);
}

enum LeafVerdict { confident, unsure, otherCrop, unsupportedCrop }

class LeafDiagnosis {
  final String cropKey;
  final LeafVerdict verdict;
  final List<(ConditionInfo, double)> top3;
  final double confidence;
  final CropInfo? looksLike;
  const LeafDiagnosis(this.cropKey, this.verdict, this.top3, this.confidence,
      {this.looksLike});

  ConditionInfo? get best =>
      verdict == LeafVerdict.confident && top3.isNotEmpty ? top3.first.$1 : null;

  /// Short text result stored in history and sent with the label event.
  String get resultKey => switch (verdict) {
        LeafVerdict.confident => best!.conditionKey,
        LeafVerdict.unsure => 'unsure',
        LeafVerdict.otherCrop => 'other_crop',
        LeafVerdict.unsupportedCrop => 'unsupported_crop',
      };
}
