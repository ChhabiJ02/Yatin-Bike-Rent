import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AppSettingsMenu extends StatelessWidget {
  const AppSettingsMenu({super.key});

  Future<void> _showProfileMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final user = AuthService.currentUser;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: StreamBuilder(
              stream: AuthService.currentUserProfileStream(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = (data?['name'] as String?)?.trim();
                final role = (data?['role'] as String?)?.trim();
                final email = user?.email ?? (data?['email'] as String?) ?? '';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Text(
                            (name?.isNotEmpty == true
                                    ? name!
                                    : email.isNotEmpty
                                    ? email
                                    : 'U')
                                .characters
                                .first
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name?.isNotEmpty == true ? name! : 'Profile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (role?.isNotEmpty == true)
                                Text(
                                  role!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await _confirmLogout(context);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    await AuthService.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => _showProfileMenu(context),
    );
  }
}
