import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0F8A4B);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text('Customer Management'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 💡 Direct Stream Without Rigid Query
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // 💡 Safe Filtering: Check role case-insensitively or show all if role is missing
          final customers = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role']?.toString().toLowerCase().trim();
            final userType = data['type']?.toString().toLowerCase().trim();

            // Include if role is customer, user, client, OR if no specific role is defined
            return role == 'customer' ||
                role == 'user' ||
                role == 'client' ||
                userType == 'customer' ||
                role == null ||
                role.isEmpty;
          }).toList();

          if (customers.isEmpty) {
            return const Center(
              child: Text(
                'No customers found in database.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final user = customers[index].data() as Map<String, dynamic>;
              final name = user['name'] ?? user['displayName'] ?? user['username'] ?? 'Customer #${index + 1}';
              final email = user['email'] ?? 'No email provided';
              final phone = user['phone'] ?? user['mobile'] ?? user['phoneNumber'] ?? 'No phone';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: primaryGreen),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: $email', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('Phone: $phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}