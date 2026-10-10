import 'package:flutter/material.dart';

import '../data/resource_categories.dart';
import '../models/resource_category.dart';
import '../models/resource_query.dart';
import '../repositories/resource_repository.dart';
import '../widgets/category_card.dart';
import 'resource_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.repository, super.key});

  final ResourceRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _zipController = TextEditingController();
  final _zipFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _zipController.dispose();
    super.dispose();
  }

  String? _validateZip(String? value, {bool allowEmpty = false}) {
    final zipCode = value?.trim() ?? '';
    if (allowEmpty && zipCode.isEmpty) return null;
    if (!RegExp(r'^\d{5}$').hasMatch(zipCode)) {
      return 'Enter a five-digit ZIP code.';
    }
    return null;
  }

  void _openResults({ResourceCategory? category}) {
    final allowEmpty = category != null;
    final trimmedZip = _zipController.text.trim();
    final isValid = allowEmpty && trimmedZip.isEmpty
        ? true
        : _zipFormKey.currentState!.validate();

    if (!isValid || (!allowEmpty && trimmedZip.isEmpty)) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResourceListScreen(
          repository: widget.repository,
          query: ResourceQuery(
            category: category,
            zipCode: trimmedZip.isEmpty ? null : trimmedZip,
          ),
        ),
      ),
    );
  }

  void _openCategory(ResourceCategory category) {
    final validationMessage = _validateZip(
      _zipController.text,
      allowEmpty: true,
    );
    if (validationMessage != null) {
      _zipFormKey.currentState!.validate();
      return;
    }
    _openResults(category: category);
  }

  void _showLocationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device-location support will be added later.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text(
          'BridgePDX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF176B5B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('home-scroll-view'),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Find help near you',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search verified community resources throughout the Portland metro area.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _zipFormKey,
              child: TextFormField(
                key: const Key('zip-code-field'),
                controller: _zipController,
                validator: _validateZip,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  hintText: 'Enter a ZIP code',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: IconButton(
                    key: const Key('location-button'),
                    onPressed: _showLocationMessage,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Use my location',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _openResults(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('zip-search-button'),
                onPressed: _openResults,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What do you need?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resourceCategories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 200,
                  ),
                  itemBuilder: (context, index) {
                    final category = resourceCategories[index];
                    return CategoryCard(
                      category: category,
                      onTap: () => _openCategory(category),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              color: const Color(0xFFFFF3E0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF9A5B00),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If you are in immediate danger or experiencing an emergency, call 911.',
                        style: TextStyle(
                          color: Colors.brown.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
