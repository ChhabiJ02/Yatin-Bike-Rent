import 'package:flutter/material.dart';

class ResponsiveButtonBar extends StatelessWidget {
  final List<Widget> children;

  const ResponsiveButtonBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: children,
    );
  }
}
