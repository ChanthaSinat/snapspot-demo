import 'package:flutter/material.dart';

import '../models/place.dart';

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.place, required this.onTap});

  final Place place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.place_outlined),
        title: Text(place.name),
        subtitle: Text('${place.category} · Example place'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
