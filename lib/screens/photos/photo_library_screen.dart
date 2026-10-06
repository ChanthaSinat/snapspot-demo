import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/place.dart';
import '../../services/database_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/local_photo_view.dart';
import '../verification/verification_screen.dart';

class PhotoLibraryScreen extends StatefulWidget {
  const PhotoLibraryScreen({
    super.key,
    required this.places,
    required this.database,
  });
  final List<Place> places;
  final DatabaseService database;
  @override
  State<PhotoLibraryScreen> createState() => _PhotoLibraryScreenState();
}

class _PhotoLibraryScreenState extends State<PhotoLibraryScreen>
    with WidgetsBindingObserver {
  final _service = PhotoService();
  final _photos = <LocalPhoto>[];
  final _confirmed = <String>{};
  PermissionState? _permission;
  bool _busy = false;
  bool _more = true;
  bool _started = false;
  int _page = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started && !_busy) {
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false, bool request = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _started = true;
    });
    try {
      final permission = request
          ? await _service.requestAccess()
          : await _service.access();
      final confirmed = await widget.database.all();
      final page = reset ? 0 : _page;
      final photos = permission.hasAccess
          ? await _service.page(page)
          : <LocalPhoto>[];
      if (!mounted) return;
      setState(() {
        _permission = permission;
        if (reset) _photos.clear();
        _photos.addAll(photos);
        _page = page + 1;
        _more = photos.length == 40;
        _confirmed
          ..clear()
          ..addAll(confirmed.map((m) => m.photoAssetId));
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not read photos. Check permission and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(LocalPhoto photo) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          photo: photo,
          places: widget.places,
          database: widget.database,
        ),
      ),
    );
    if (mounted && result == true) {
      setState(() => _confirmed.add(photo.asset.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add photo memories')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose what you share with your map.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'Allow selected photos or your library. We read accessible image dates and GPS only when you open this screen. Nothing is uploaded. Photos without GPS cannot be matched. Download cloud-only photos in Photos first.',
          ),
          const SizedBox(height: 16),
          if (!_started)
            FilledButton(
              onPressed: () => _load(reset: true, request: true),
              child: const Text('Choose photo access'),
            ),
          if (_permission != null && !_permission!.hasAccess) ...[
            const Text(
              'Photo access is unavailable. In Settings, open Apps → Place Memory Map → Photos to allow selected photos. You can still use the map.',
            ),
            TextButton(
              onPressed: PhotoManager.openSetting,
              child: const Text('Open Settings'),
            ),
          ],
          if (_permission == PermissionState.limited)
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await PhotoManager.presentLimited(
                        type: RequestType.image,
                      );
                      if (mounted) await _load(reset: true);
                    },
              child: const Text('Manage selected photos'),
            ),
          if (_started)
            TextButton(
              onPressed: _busy ? null : () => _load(reset: true),
              child: const Text('Refresh photos'),
            ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_started &&
              !_busy &&
              _photos.isEmpty &&
              _permission?.hasAccess == true)
            const Text(
              'No accessible images. Add photos to this device or update your selected photos.',
            ),
          for (final photo in _photos)
            Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LocalPhotoView(assetId: photo.asset.id, size: 52),
                ),
                title: Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(photo.asset.createDateTime),
                ),
                subtitle: Text(
                  _confirmed.contains(photo.asset.id)
                      ? 'Already saved'
                      : photo.hasLocation
                      ? 'Location available · Tap to verify'
                      : 'No GPS metadata · Cannot match',
                ),
                onTap:
                    _busy ||
                        !photo.hasLocation ||
                        _confirmed.contains(photo.asset.id)
                    ? null
                    : () => _verify(photo),
              ),
            ),
          if (_more && _photos.isNotEmpty)
            OutlinedButton(
              onPressed: _busy ? null : _load,
              child: const Text('Load more'),
            ),
        ],
      ),
    ),
  );
}
