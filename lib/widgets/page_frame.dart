import 'package:flutter/material.dart';

import 'live_motion.dart';

class PageFrame extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final ScrollPhysics physics;

  const PageFrame({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(18, 8, 18, 32),
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final minimumHorizontal = constraints.maxWidth >= 1000
              ? 32.0
              : constraints.maxWidth >= 600
                  ? 24.0
                  : 16.0;
          final resolvedPadding = padding.copyWith(
            left: padding.left < minimumHorizontal
                ? minimumHorizontal
                : padding.left,
            right: padding.right < minimumHorizontal
                ? minimumHorizontal
                : padding.right,
            top: padding.top < 10 ? 10 : padding.top,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: resolvedPadding,
                physics: physics,
                children: [
                  for (var index = 0; index < children.length; index++)
                    MotionEntrance(
                      key: ValueKey<String>(
                        'page-motion-$index-${children[index].runtimeType}',
                      ),
                      index: index,
                      child: children[index],
                    ),
                ],
              ),
            ),
          );
        },
      );
}
