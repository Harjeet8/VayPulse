import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/app/theme.dart';
import 'package:phytosense_ai/widgets/phyto_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Page title keeps full width beside long status $brightness', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(theme: buildTheme(brightness, 'ta'), home: Scaffold(body: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3), disableAnimations: true),
        child: const SingleChildScrollView(child: Padding(padding: EdgeInsets.all(18), child: PhytoPageIntro(
          eyebrow: 'காலப்போக்கு', title: 'செடியின் மாற்றங்கள்', body: 'செடியின் நிலையையும் மண்ணையும் பாருங்கள்.', icon: Icons.timeline_rounded,
          trailing: PhytoStatusBadge(label: 'கருவி பதிவுகள்', icon: Icons.history, color: Colors.green),
        ))),
      ))));
      expect(tester.takeException(), isNull);
      final title = tester.getRect(find.text('செடியின் மாற்றங்கள்'));
      expect(title.left, 18);
      expect(title.width, greaterThan(250));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
