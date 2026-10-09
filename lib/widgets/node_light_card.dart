import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/node_light_control.dart';

String _t(BuildContext context, String en, String ta) =>
    FarmerLanguage.isTamil(context) ? ta : en;

/// On / Off / Auto, brightness and "Find my node" for the node's light.
class NodeLightCard extends StatefulWidget {
  const NodeLightCard({super.key});

  @override
  State<NodeLightCard> createState() => _NodeLightCardState();
}

class _NodeLightCardState extends State<NodeLightCard> {
  NodeLightControl? control;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (control == null) {
      control = NodeLightControl(AppScope.of(context).settings);
      unawaited(control!.load());
    }
  }

  @override
  void dispose() {
    control?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = control!;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final on = c.mode == NodeLightMode.on;
        final status = switch (c.mode) {
          NodeLightMode.on => _t(context, 'On at ${c.brightness}% brightness',
              '${c.brightness}% ஒளியில் எரிகிறது'),
          NodeLightMode.off => _t(context, 'Off', 'அணைக்கப்பட்டது'),
          NodeLightMode.auto => _t(context, 'Auto — the node controls the light',
              'தானியங்கி — கருவியே விளக்கைக் கட்டுப்படுத்தும்'),
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Semantics(
                  button: true,
                  label: on
                      ? _t(context, 'Turn light off', 'விளக்கை அணை')
                      : _t(context, 'Turn light on', 'விளக்கை எரிய விடு'),
                  child: GestureDetector(
                    key: const Key('node-light-toggle'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      c.setMode(on ? NodeLightMode.off : NodeLightMode.on);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on
                            ? Color.lerp(Colors.amber.shade200, Colors.amber,
                                c.brightness / 100)
                            : scheme.surfaceContainerHighest,
                        boxShadow: on
                            ? [
                                BoxShadow(
                                    color: Colors.amber
                                        .withValues(alpha: 0.25 + c.brightness / 250),
                                    blurRadius: 10 + c.brightness / 4,
                                    spreadRadius: 1)
                              ]
                            : const [],
                      ),
                      child: Icon(
                          c.locating
                              ? Icons.wifi_tethering_rounded
                              : on
                                  ? Icons.lightbulb_rounded
                                  : Icons.lightbulb_outline_rounded,
                          size: 34,
                          color: on ? Colors.brown.shade800 : scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_t(context, 'Node light', 'கருவி விளக்கு'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(status, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<NodeLightMode>(
                  segments: [
                    ButtonSegment(
                        value: NodeLightMode.on,
                        icon: const Icon(Icons.light_mode_rounded),
                        label: Text(_t(context, 'On', 'ஆன்'))),
                    ButtonSegment(
                        value: NodeLightMode.off,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(_t(context, 'Off', 'ஆஃப்'))),
                    ButtonSegment(
                        value: NodeLightMode.auto,
                        icon: const Icon(Icons.auto_mode_rounded),
                        label: Text(_t(context, 'Auto', 'தானியங்கி'))),
                  ],
                  selected: {c.mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => c.setMode(s.first),
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.brightness_low_rounded, size: 20),
                Expanded(
                  child: Slider(
                    key: const Key('node-light-brightness'),
                    min: 5,
                    max: 100,
                    divisions: 19,
                    value: c.brightness.toDouble(),
                    label: '${c.brightness}%',
                    // Drag only moves the slider; one command on release.
                    onChanged: c.previewBrightness,
                    onChangeEnd: c.commitBrightness,
                  ),
                ),
                const Icon(Icons.brightness_high_rounded, size: 20),
              ]),
              Row(children: [
                TextButton.icon(
                  key: const Key('node-light-locate'),
                  onPressed: c.locate,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(_t(context, 'Find my node', 'கருவியைக் கண்டறி')),
                ),
                const Spacer(),
                Flexible(child: _DeliveryPill(control: c)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _DeliveryPill extends StatelessWidget {
  final NodeLightControl control;
  const _DeliveryPill({required this.control});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, text, color) = switch (control.delivery) {
      NodeLightDelivery.idle => (
          Icons.touch_app_outlined,
          _t(context, 'Tap the light to switch', 'மாற்ற விளக்கைத் தொடவும்'),
          scheme.onSurfaceVariant
        ),
      NodeLightDelivery.sending => (
          Icons.sync_rounded,
          _t(context, 'Sending…', 'அனுப்புகிறது…'),
          scheme.onSurfaceVariant
        ),
      NodeLightDelivery.confirmed => (
          Icons.check_circle_rounded,
          _t(context, '✓ Done', '✓ முடிந்தது'),
          scheme.primary
        ),
      NodeLightDelivery.queued => (
          Icons.cloud_done_outlined,
          _t(context, 'Sent — node will apply within ~10 s',
              'அனுப்பப்பட்டது — ~10 வினாடிகளில் கருவி மாற்றும்'),
          scheme.tertiary
        ),
      NodeLightDelivery.failed => (
          Icons.portable_wifi_off_rounded,
          _t(context, 'Node not reachable', 'கருவியை அணுக முடியவில்லை'),
          scheme.error
        ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(control.delivery),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                key: const Key('node-light-delivery'),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ),
        ]),
      ),
    );
  }
}
