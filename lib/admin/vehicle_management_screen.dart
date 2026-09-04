import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/rental_service.dart';
import '../theme/app_theme.dart';

class VehicleManagementScreen extends StatelessWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: RentalService.vehiclesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No vehicles found. Add one to get started!',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final data = vehicle.data() as Map<String, dynamic>;
              final no = data['no'] ?? '';
              final name = data['name'] ?? '';
              final number = data['number'] ?? '';
              final isAvailable = data['available'] as bool? ?? false;

              String displayText = no;
              if (name.isNotEmpty && !no.contains(name)) {
                displayText = '$no $name';
              }
              if (number.isNotEmpty && !displayText.contains(number)) {
                displayText = '$displayText ($number)';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shadowColor: AppColors.ink.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        (isAvailable ? AppColors.mint : AppColors.ember)
                            .withAlpha(30),
                    child: Icon(
                      Icons.pedal_bike,
                      color: isAvailable ? AppColors.mint : AppColors.ember,
                    ),
                  ),
                  title: Text(
                    'No: $displayText',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.sky),
                        onPressed: () =>
                            _showVehicleForm(context, vehicleDoc: vehicle),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400),
                        onPressed: () => _deleteVehicle(context, vehicle.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleForm(context),
        backgroundColor: AppColors.ember,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteVehicle(BuildContext context, String vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RentalService.deleteVehicle(vehicleId);
    }
  }

  void _showVehicleForm(BuildContext context,
      {DocumentSnapshot? vehicleDoc}) {
    final isEditing = vehicleDoc != null;
    final data = vehicleDoc?.data() as Map<String, dynamic>?;

    final formKey = GlobalKey<FormState>();
    final vehicleName = data?['name'] ?? '';
    final vehicleNumber = data?['number'] ?? '';
    String combinedNo = data?['no'] ?? '';
    if (vehicleName.isNotEmpty) {
      combinedNo = '${data?['no'] ?? ''} $vehicleName';
    }
    if (vehicleNumber.isNotEmpty) {
      combinedNo = '$combinedNo ($vehicleNumber)';
    }
    final noController = TextEditingController(text: combinedNo);
    final dailyRateController =
        TextEditingController(text: data?['dailyRate']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: noController,
                        decoration: const InputDecoration(labelText: 'No.'),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a vehicle number' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dailyRateController,
                        decoration:
                            const InputDecoration(labelText: 'Daily Rate'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a daily rate' : null,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (isEditing) {
                    await RentalService.updateVehicle(
                      vehicleId: vehicleDoc.id,
                      no: noController.text,
                      dailyRate: int.parse(dailyRateController.text),
                    );
                  } else {
                    await RentalService.addVehicle(
                      no: noController.text,
                      dailyRate: int.parse(dailyRateController.text),
                    );
                  }
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
