// DEPRECATED: Transportation details are now saved inside Challan/T customer entry.
// This file is kept for backward compatibility only - it does nothing now.
// Use lib/screens/challan_entry_screen.dart instead.

import 'package:flutter/material.dart';

class TransportationForm extends StatelessWidget {
  const TransportationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transportation Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Transportation details are now captured inside Challan entries.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}