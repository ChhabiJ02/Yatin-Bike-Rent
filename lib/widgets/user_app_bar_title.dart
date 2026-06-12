import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class UserAppBarTitle extends StatelessWidget {
  const UserAppBarTitle({super.key, required this.fallbackTitle});

  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.currentUserProfileStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] as String?)?.trim();
        final displayName = name?.isNotEmpty == true
            ? '$fallbackTitle - $name'
            : fallbackTitle;

        return Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}
