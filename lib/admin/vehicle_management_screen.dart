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
              final name = data['name'] ?? 'N/A';
              final no = data['no'] ?? '';
              final number = data['number'] ?? 'N/A';
              final type = data['type'] ?? 'N/A';
              final isAvailable = data['available'] as bool? ?? false;

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
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('No: $no, Plate: $number'),
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
    final noController = TextEditingController(text: data?['no'] ?? '');
    final nameController = TextEditingController(text: data?['name']);
    final numberController = TextEditingController(text: data?['number']);
    final hourlyRateController =
        TextEditingController(text: data?['hourlyRate']?.toString());
    final dailyRateController =
        TextEditingController(text: data?['dailyRate']?.toString());

    String? type = data?['type'] ?? 'Bike';
    final categoryController =
        TextEditingController(text: data?['category'] ?? '');
    final chasisNoController =
        TextEditingController(text: data?['chasisNo'] ?? '');
    final engNoController =
        TextEditingController(text: data?['engNo'] ?? '');
    String? fuelType = data?['fuelType'] ?? 'Petrol';

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
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(labelText: 'Number Plate'),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a number plate' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: ['Bike', 'Scooter']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) => setState(() => type = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: chasisNoController,
                        decoration: const InputDecoration(labelText: 'Chasis No.'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: engNoController,
                        decoration: const InputDecoration(labelText: 'Engine No.'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: fuelType,
                        decoration:
                            const InputDecoration(labelText: 'Fuel Type'),
                        items: ['Petrol', 'Electric']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) => setState(() => fuelType = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: hourlyRateController,
                        decoration:
                            const InputDecoration(labelText: 'Hourly Rate'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter an hourly rate' : null,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
                  final vehicleData = {
                    'no': noController.text,
                    'name': nameController.text,
                    'number': numberController.text,
                    'type': type!,
                    'hourlyRate': int.parse(hourlyRateController.text),
                    'dailyRate': int.parse(dailyRateController.text),
                    'category': categoryController.text,
                    'chasisNo': chasisNoController.text,
                    'engNo': engNoController.text,
                    'fuelType': fuelType!,
                  };

                  if (isEditing) {
                    await RentalService.updateVehicle(
                      vehicleId: vehicleDoc.id,
                      no: vehicleData['no'] as String,
                      name: vehicleData['name'] as String,
                      number: vehicleData['number'] as String,
                      type: vehicleData['type'] as String,
                      hourlyRate: vehicleData['hourlyRate'] as int,
                      dailyRate: vehicleData['dailyRate'] as int,
                      category: vehicleData['category'] as String,
                      chasisNo: vehicleData['chasisNo'] as String,
                      engNo: vehicleData['engNo'] as String,
                      fuelType: vehicleData['fuelType'] as String,
                    );
                  } else {
                    await RentalService.addVehicle(
                      no: vehicleData['no'] as String,
                      name: vehicleData['name'] as String,
                      number: vehicleData['number'] as String,
                      type: vehicleData['type'] as String,
                      hourlyRate: vehicleData['hourlyRate'] as int,
                      dailyRate: vehicleData['dailyRate'] as int,
                      category: vehicleData['category'] as String,
                      chasisNo: vehicleData['chasisNo'] as String,
                      engNo: vehicleData['engNo'] as String,
                      fuelType: vehicleData['fuelType'] as String,
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

class _VehicleForm extends StatefulWidget {
  final DocumentSnapshot? vehicleDoc;
  const _VehicleForm() : vehicleDoc = null;

  @override
  State<_VehicleForm> createState() => __VehicleFormState();
}

class __VehicleFormState extends State<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _dailyRateController;
  String _type = 'Bike';
  String _fuelType = 'Petrol';

  @override
  void initState() {
    super.initState();
    final data = widget.vehicleDoc?.data() as Map<String, dynamic>?;
    _nameController = TextEditingController(text: data?['name']);
    _numberController = TextEditingController(text: data?['number']);
    _hourlyRateController =
        TextEditingController(text: data?['hourlyRate']?.toString());
    _dailyRateController =
        TextEditingController(text: data?['dailyRate']?.toString());
    _type = data?['type'] ?? 'Bike';
    _fuelType = data?['fuelType'] ?? 'Petrol';
  }

  @override
  Widget build(BuildContext context) {
    // This widget is complex and would be built out here.
    // For brevity, the form logic is kept within the dialog in _showVehicleForm.
    return const SizedBox.shrink();
  }
}