import 'package:flutter/material.dart';

class UserAppBarTitle extends StatelessWidget {
  const UserAppBarTitle({super.key, required this.fallbackTitle});

  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    return Text(
      fallbackTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
