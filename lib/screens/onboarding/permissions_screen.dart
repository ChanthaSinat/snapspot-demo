import '../../services/database_service.dart';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../map/memory_map_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key, this.database});

  final DatabaseService? database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Text(
              'You stay in control.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'A personal map should feel personal. Here is what the app uses and when.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),
            const _AccessCard(
              icon: Icons.photo_library_outlined,
              title: 'Your photos',
              description: 'Choose accessible photos with location information, then confirm a place. Only confirmed memories are saved locally.',
              footnote: 'Requested only when you tap Add photos',
            ),
            const SizedBox(height: 14),
            const _AccessCard(
              icon: Icons.my_location_outlined,
              title: 'Current location',
              description: 'Used only while the app is open to center the map. You can decline and still add and view your memories.',
              footnote: 'Optional · While Using the App',
            ),
            const SizedBox(height: 24),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: AppColors.forest, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photos and memories stay on this device.',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
          child: FilledButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => MemoryMapScreen(database: database),
              ),
              (_) => false,
            ),
            child: const Text('Open map'),
          ),
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.footnote,
  });

  final IconData icon;
  final String title;
  final String description;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.forest),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              footnote.toUpperCase(),
              style: const TextStyle(
                color: AppColors.forest,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
