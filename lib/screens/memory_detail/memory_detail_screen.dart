import 'package:flutter/material.dart';

import '../../models/demo_memory.dart';
import '../../theme/app_theme.dart';

class MemoryDetailScreen extends StatelessWidget {
  const MemoryDetailScreen({super.key, required this.memory});

  final DemoMemory memory;

  @override
  Widget build(BuildContext context) {
    final place = memory.place;
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(memory.visitDate);
    return Scaffold(
      appBar: AppBar(title: const Text('Place memories')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 1.12,
            child: Image.asset(
              memory.photoAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.softGreen,
                child: Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 60),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      place.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  place.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Visited $date',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),
                Text(
                  '1 demo memory at this place',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'A place for the moments you want to remember.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: AppColors.forest,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This is a bundled sample photo, not a saved or verified visit.',
                          style: TextStyle(color: AppColors.ink, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
