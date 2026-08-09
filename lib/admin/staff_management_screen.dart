import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(18.0),
        child: UserRoleManager(),
      ),
    );
  }
}

class UserRoleManager extends StatelessWidget {
  const UserRoleManager({super.key});

  static const _roles = ['Customer', 'Staff', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.softCard(
        bgColor: Colors.white, // This is now a valid parameter
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.manage_accounts, color: AppColors.ember),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'User Roles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Only admins can promote users to Staff or Admin.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: AuthService.usersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Could not load users.',
                  style: TextStyle(color: Colors.red),
                );
              }

              final users = snapshot.data?.docs ?? [];
              if (users.isEmpty) {
                return const Text(
                  'No users registered yet.',
                  style: TextStyle(color: AppColors.muted),
                );
              }

              return Column(
                children: users.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String?)?.trim();
                  final email = (data['email'] as String?)?.trim();
                  final currentRole = data['role'] as String? ?? 'Customer';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.ember.withAlpha(30),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.ember,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name?.isNotEmpty == true ? name! : 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                email?.isNotEmpty == true ? email! : doc.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _roles.contains(currentRole) ? currentRole : 'Customer',
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(14),
                          items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                          onChanged: (role) async {
                            if (role == null || role == currentRole) return;
                            await AuthService.updateUserRole(uid: doc.id, role: role);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Role updated to $role.')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}