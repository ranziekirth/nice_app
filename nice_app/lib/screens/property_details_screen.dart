// lib/screens/property_details_screen.dart
import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late final TextEditingController _addressController;
  bool _saving = false;
  bool _savedJustNow = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: AppData.propertyAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _addressController.text.trim();
    if (value.isEmpty) return;

    setState(() => _saving = true);
    await AppData.updatePropertyAddress(value);
    if (!mounted) return;

    setState(() {
      _saving = false;
      _savedJustNow = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedJustNow = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(
                title: 'Property Details', showBack: true, centered: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Property Address',
                            style: AppText.cardTitle),
                        const SizedBox(height: 6),
                        const Text(
                          'Shown on every receipt generated for tenants.',
                          style: AppText.cardSubtitle,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                              hintText:
                                  'e.g. Blk 400 Barangay 123, Caloocan City'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                        if (_savedJustNow) ...[
                          const SizedBox(height: 10),
                          const Text('Address updated.',
                              style: TextStyle(
                                  color: AppColors.paidGreen,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
