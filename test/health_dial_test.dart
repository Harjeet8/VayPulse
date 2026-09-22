import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/widgets/verdant_care_hero.dart';

Widget dial(double? score, {bool reduced = true}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      backgroundColor: const Color(0xFF173E32),
      body: Center(child: HealthArc(score: score, compact: true, statusColor: Colors.red)),
    ),
  ),
);

void main() {
  testWidgets('full colour scale stays visible at low and high scores', (tester) async {
    for (final score in [0.0, 33.0, 100.0]) {
      final boundary = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: Center(child: RepaintBoundary(
          key: boundary,
          child: HealthArc(score: score, compact: true, statusColor: Colors.red),
        ))),
      )));
      await tester.pump();
      await tester.runAsync(() async {
        final picture = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 1);
        final pixels = (await picture.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        // Two points away from the moving marker: terracotta left, leaf green right.
        final left = (64 * picture.width + 18) * 4;
        final right = (64 * picture.width + 114) * 4;
        expect(pixels.getUint8(left), greaterThan(pixels.getUint8(left + 1)));
        expect(pixels.getUint8(right + 1), greaterThan(pixels.getUint8(right)));
        picture.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('losing a reading immediately removes coloured live marker', (tester) async {
    await tester.pumpWidget(dial(92, reduced: false));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('92'), findsOneWidget);
    await tester.pumpWidget(dial(null, reduced: false));
    expect(find.byKey(const ValueKey('health-dial-unavailable')), findsOneWidget);
    expect(find.byKey(const ValueKey('health-dial-available')), findsNothing);
    expect(find.text('92'), findsNothing);
    expect(find.text('WAITING'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('invalid readings stay unavailable instead of becoming healthy or zero', (tester) async {
    for (final score in [double.nan, double.infinity, -1.0, 101.0]) {
      await tester.pumpWidget(dial(score));
      expect(find.text('—'), findsOneWidget);
      expect(find.byKey(const ValueKey('health-dial-available')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
