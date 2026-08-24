import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

import '../models/leaf_screening_result.dart';

class LeafScreeningException implements Exception {
  final String messageKey;

  const LeafScreeningException(this.messageKey);
}

class LeafScreeningService {
  static Future<LeafScreeningResult> analyze(Uint8List bytes) async {
    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) {
      throw const LeafScreeningException('leaf_image_invalid');
    }
    if (decoded.width < 160 || decoded.height < 160) {
      throw const LeafScreeningException('leaf_image_too_small');
    }
    final image = decoded.width > 360
        ? image_lib.copyResize(decoded, width: 360)
        : decoded;
    var green = 0;
    var yellow = 0;
    var brown = 0;
    var usefulPixels = 0;
    var sampledPixels = 0;
    var darkPixels = 0;
    var brightPixels = 0;
    var centerPlantPixels = 0;
    var centerPixels = 0;
    var brightnessTotal = 0.0;
    var brightnessSquaredTotal = 0.0;

    for (var y = 0; y < image.height; y += 2) {
      for (var x = 0; x < image.width; x += 2) {
        sampledPixels++;
        final pixel = image.getPixel(x, y);
        final red = pixel.r.toDouble();
        final greenChannel = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        final brightness = (red + greenChannel + blue) / 3;
        brightnessTotal += brightness;
        brightnessSquaredTotal += brightness * brightness;
        if (brightness < 35) darkPixels++;
        if (brightness > 235) brightPixels++;
        if (brightness < 22 || brightness > 245) continue;
        usefulPixels++;
        final maximum =
            [red, greenChannel, blue].reduce((a, b) => a > b ? a : b);
        final minimum =
            [red, greenChannel, blue].reduce((a, b) => a < b ? a : b);
        final saturated = maximum - minimum > 24;
        var plantLike = false;
        if (saturated &&
            greenChannel > red * 1.06 &&
            greenChannel > blue * 1.1) {
          green++;
          plantLike = true;
        } else if (saturated &&
            red > 105 &&
            greenChannel > 75 &&
            blue < 145 &&
            red > blue * 1.18) {
          yellow++;
          plantLike = true;
        } else if (saturated &&
            red > 58 &&
            red > greenChannel * 1.12 &&
            greenChannel < 165 &&
            blue < 135) {
          brown++;
          plantLike = true;
        }
        final inCenter = x >= image.width * 0.18 &&
            x <= image.width * 0.82 &&
            y >= image.height * 0.18 &&
            y <= image.height * 0.82;
        if (inCenter) {
          centerPixels++;
          if (plantLike) centerPlantPixels++;
        }
      }
    }
    if (usefulPixels < 500) {
      throw const LeafScreeningException('leaf_image_no_detail');
    }
    final meanBrightness = brightnessTotal / sampledPixels;
    final brightnessVariance = brightnessSquaredTotal / sampledPixels -
        meanBrightness * meanBrightness;
    if (darkPixels / sampledPixels > 0.72 || meanBrightness < 48) {
      throw const LeafScreeningException('leaf_image_too_dark');
    }
    if (brightPixels / sampledPixels > 0.72 || meanBrightness > 225) {
      throw const LeafScreeningException('leaf_image_too_bright');
    }
    if (brightnessVariance < 110) {
      throw const LeafScreeningException('leaf_image_no_detail');
    }
    final greenRatio = green / usefulPixels;
    final yellowRatio = yellow / usefulPixels;
    final brownRatio = brown / usefulPixels;
    final plantRatio = (green + yellow + brown) / usefulPixels;
    final centerPlantRatio =
        centerPixels == 0 ? 0 : centerPlantPixels / centerPixels;
    if (plantRatio < 0.09 || centerPlantRatio < 0.1) {
      throw const LeafScreeningException('leaf_image_no_leaf');
    }

    String riskKey;
    String explanationKey;
    String actionKey;
    int confidence;
    if (plantRatio < 0.16) {
      riskKey = 'leaf_result_retake';
      explanationKey = 'leaf_result_retake_body';
      actionKey = 'leaf_action_retake';
      confidence = 52;
    } else if (brownRatio >= 0.1) {
      riskKey = 'leaf_result_spot_risk';
      explanationKey = 'leaf_result_spot_risk_body';
      actionKey = 'leaf_action_spot';
      confidence = (62 + brownRatio * 120).clamp(62, 88).round();
    } else if (yellowRatio >= 0.2) {
      riskKey = 'leaf_result_yellowing';
      explanationKey = 'leaf_result_yellowing_body';
      actionKey = 'leaf_action_yellowing';
      confidence = (60 + yellowRatio * 100).clamp(60, 86).round();
    } else {
      riskKey = 'leaf_result_low_risk';
      explanationKey = 'leaf_result_low_risk_body';
      actionKey = 'leaf_action_monitor';
      confidence = (68 + greenRatio * 22).clamp(68, 90).round();
    }
    return LeafScreeningResult(
      riskKey: riskKey,
      explanationKey: explanationKey,
      actionKey: actionKey,
      confidence: confidence,
      greenPercent: greenRatio * 100,
      yellowPercent: yellowRatio * 100,
      brownPercent: brownRatio * 100,
      screenedAt: DateTime.now(),
    );
  }
}
