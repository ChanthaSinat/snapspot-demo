import 'package:flutter/material.dart';

import '../../models/memory.dart';
import '../../models/place.dart';
import '../../services/photo_service.dart';
import '../../services/place_matcher.dart';
import '../../services/database_service.dart';
import '../../widgets/local_photo_view.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.photo,
    required this.places,
    required this.database,
  });
  final LocalPhoto photo;
  final List<Place> places;
  final DatabaseService database;
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Place? _selected;
  bool _busy = false;
  String? _error;
  late final _suggestions = widget.photo.hasLocation
      ? PlaceMatcher().match(
          widget.photo.latitude!,
          widget.photo.longitude!,
          widget.places,
        )
      : <PlaceSuggestion>[];
  @override
  void initState() {
    super.initState();
    if (_suggestions.isNotEmpty) _selected = _suggestions.first.place;
  }

  Future<void> _confirm() async {
    final place = _selected;
    if (place == null || _busy || !widget.photo.hasLocation) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await PhotoService.thumbnail(widget.photo.asset.id) == null) {
        throw StateError('Photo unavailable');
      }
      await widget.database.confirm(
        Memory(
          id: widget.photo.asset.id,
          placeId: place.id,
          photoAssetId: widget.photo.asset.id,
          photoDate: widget.photo.asset.createDateTime,
          photoLatitude: widget.photo.latitude!,
          photoLongitude: widget.photo.longitude!,
          verified: true,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. Check photo access and available storage, then retry.';
        });
      }
    }
  }

  Future<void> _choose() async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 420,
          child: ListView(
            children: [
              const ListTile(
                title: Text('Choose from the demo catalog'),
                subtitle: Text(
                  'These are illustrative venues. Confirm only if the place is correct.',
                ),
              ),
              for (final place in widget.places)
                ListTile(
                  title: Text(place.name),
                  subtitle: Text(place.category),
                  onTap: () => Navigator.pop(context, place),
                ),
            ],
          ),
        ),
      ),
    );
    if (mounted && place != null) setState(() => _selected = place);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify a memory')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LocalPhotoView(assetId: widget.photo.asset.id, size: 280),
          ),
          const SizedBox(height: 20),
          Text(
            MaterialLocalizations.of(context)
                .formatFullDate(widget.photo.asset.createDateTime),
          ),
          const SizedBox(height: 12),
          Text(
            'Were you at this place?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'GPS is a clue, not proof. Only your confirmation saves this memory.',
          ),
          if (_suggestions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No nearby demo venue within 300 m. Choose a catalog place only if you recognize it, or skip.',
              ),
            ),
          for (final suggestion in _suggestions)
            ListTile(
              leading: Icon(
                _selected?.id == suggestion.place.id
                    ? Icons.check_circle
                    : Icons.circle_outlined,
              ),
              title: Text(suggestion.place.name),
              subtitle: Text(
                '${suggestion.distanceMeters.round()} m from photo location',
              ),
              onTap: _busy
                  ? null
                  : () => setState(() => _selected = suggestion.place),
            ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('Selected: ${_selected!.name}'),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: _selected == null || _busy ? null : _confirm,
            child: Text(_busy ? 'Saving…' : 'Confirm place'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : _choose,
            child: const Text('Choose another place'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
        ],
      ),
    ),
  );
}
