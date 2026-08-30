import 'package:flutter/material.dart';

class HealthRing extends StatelessWidget {
  final double score;
  final double size;
  final String label;
  final Color? color;
  final Color? textColor;

  const HealthRing({
    super.key,
    required this.score,
    this.size = 118,
    this.label = 'Health',
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = color ??
        (score >= 75
            ? Theme.of(context).colorScheme.primary
            : score >= 45
                ? Colors.orange
                : Theme.of(context).colorScheme.error);
    final fixedScaleMedia = MediaQuery.of(context).copyWith(
      textScaler: TextScaler.noScaling,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '$label ${score.round()}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: score.clamp(0, 100).toDouble()),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 720),
        curve: Curves.easeOutCubic,
        builder: (context, animatedScore, _) => SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: size,
                child: CircularProgressIndicator(
                  value: (animatedScore / 100).clamp(0, 1).toDouble(),
                  strokeWidth: size < 90 ? 7 : 10,
                  color: ringColor,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(size < 90 ? 13 : 21),
                child: MediaQuery(
                  data: fixedScaleMedia,
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: size < 90
                          ? Text(
                              '${animatedScore.round()}',
                              style: TextStyle(
                                fontSize: 25,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${animatedScore.round()}',
                                  style: TextStyle(
                                    fontSize: 31,
                                    height: 0.95,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
