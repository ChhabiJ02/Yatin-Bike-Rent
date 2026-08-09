import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:street_bike_rental/services/rental_service.dart';

class ChallanEntryForm extends StatefulWidget {
  const ChallanEntryForm({super.key});

  @override
  State<ChallanEntryForm> createState() => _ChallanEntryFormState();
}

class _ChallanEntryFormState extends State<ChallanEntryForm> {
  final _formKey = GlobalKey<FormState>();

  final _licenseNoController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _chasisNoController = TextEditingController();
  final _engNoController = TextEditingController();

  bool _isSearching = false;
  String? _vehicleId;

  @override
  void dispose() {
    _licenseNoController.dispose();
    _vehicleNumberController.dispose();
    _vehicleNameController.dispose();
    _categoriesController.dispose();
    _descriptionController.dispose();
    _chasisNoController.dispose();
    _engNoController.dispose();
    super.dispose();
  }

  Future<void> _searchVehicle() async {
    if (_vehicleNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a vehicle number.')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _clearVehicleFields(clearNumber: false);
    });

    try {
      final vehicleDoc = await RentalService.findVehicleByNumber(
        _vehicleNumberController.text.trim(),
      );

      if (mounted) {
        if (vehicleDoc != null && vehicleDoc.exists) {
          _populateForm(vehicleDoc);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details loaded successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _populateForm(DocumentSnapshot<Map<String, dynamic>> vehicleDoc) {
    final data = vehicleDoc.data();
    if (data == null) return;

    _vehicleId = vehicleDoc.id;
    _vehicleNameController.text = data['name'] ?? data['vehicleName'] ?? '';
    _categoriesController.text = data['category'] ?? data['categories'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _chasisNoController.text = data['chasisNo'] ?? data['chassisNo'] ?? '';
    _engNoController.text = data['engNo'] ?? data['engineNo'] ?? '';
  }

  void _clearVehicleFields({bool clearNumber = true}) {
    if (clearNumber) _vehicleNumberController.clear();
    _vehicleId = null;
    _vehicleNameController.clear();
    _categoriesController.clear();
    _descriptionController.clear();
    _chasisNoController.clear();
    _engNoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Challan'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _licenseNoController,
                    decoration: InputDecoration(
                      labelText: 'License No.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Vehicle Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search row forced to maintain explicit height and responsive layout
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vehicleNumberController,
                            decoration: InputDecoration(
                              labelText: 'No',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _searchVehicle(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _searchVehicle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: _isSearching
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Enter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleNameController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoriesController,
                    decoration: InputDecoration(
                      labelText: 'Categories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _chasisNoController,
                    decoration: InputDecoration(
                      labelText: 'Chasis No.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _engNoController,
                    decoration: InputDecoration(
                      labelText: 'Eng No.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}