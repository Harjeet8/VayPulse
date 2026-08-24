import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: padding,
            physics: physics,
            children: children,
          ),
        ),
      );
}
