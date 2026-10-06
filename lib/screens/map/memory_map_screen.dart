import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../config/mapbox_config.dart';
import '../../data/demo_map_config.dart';
import '../../models/memory.dart';
import '../../models/place.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/local_photo_view.dart';
import '../../widgets/photo_marker.dart';
import '../photos/photo_library_screen.dart';
import 'map_screen.dart';

class PlaceMemories {
  const PlaceMemories(this.place, this.memories);
  final Place place;
  final List<Memory> memories;
  int get visitCount => memories
      .map((m) => '${m.photoDate.year}-${m.photoDate.month}-${m.photoDate.day}')
      .toSet()
      .length;
  static List<PlaceMemories> group(List<Memory> memories, List<Place> places) {
    final result = <PlaceMemories>[];
    for (final place in places) {
      final rows =
          memories.where((m) => m.verified && m.placeId == place.id).toList()
            ..sort((a, b) => b.photoDate.compareTo(a.photoDate));
      if (rows.isNotEmpty) result.add(PlaceMemories(place, rows));
    }
    return result;
  }
}

class MemoryMapScreen extends StatefulWidget {
  const MemoryMapScreen({super.key, this.database});
  final DatabaseService? database;
  @override
  State<MemoryMapScreen> createState() => _MemoryMapScreenState();
}

class _MemoryMapScreenState extends State<MemoryMapScreen>
    with WidgetsBindingObserver {
  late final _database = widget.database ?? DatabaseService();
  final _location = LocationService();
  final _viewport = ViewportController();
  List<Place> _places = [];
  List<PlaceMemories> _groups = [];
  MapboxMap? _map;
  Cancelable? _tap;
  Timer? _timeout;
  bool _loading = true;
  bool _ready = false;
  bool _locationBusy = false;
  String? _error;
  String? _mapError;
  String? _locationMessage;
  int _revision = 0;
  int _loadSequence = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeout?.cancel();
    _tap?.cancel();
    _viewport.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sequence = ++_loadSequence;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = jsonDecode(
        await rootBundle.loadString('lib/data/demo_places.json'),
      ) as List;
      final places = rows
          .map((r) => Place.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      final memories = await _database.all();
      if (!mounted || sequence != _loadSequence) return;
      _tap?.cancel();
      _timeout?.cancel();
      setState(() {
        _places = places;
        _groups = PlaceMemories.group(memories, places);
        _loading = false;
        _ready = false;
        _mapError = null;
        _map = null;
        _revision++;
      });
    } catch (_) {
      if (mounted && sequence == _loadSequence) {
        setState(() {
          _loading = false;
          _error = 'Could not open your local memories. Check storage and try again.';
        });
      }
    }
  }

  Future<void> _addPhotos() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PhotoLibraryScreen(places: _places, database: _database),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _installPins(int revision) async {
    if (_ready || !mounted || revision != _revision) return;
    final map = _map;
    if (map == null) return;
    _timeout?.cancel();
    setState(() {
      _ready = true;
      _mapError = null;
    });
    try {
      final manager = await map.annotations.createPointAnnotationManager();
      if (!mounted || revision != _revision) return;
      final groups = <String, PlaceMemories>{};
      _tap = manager.tapEvents(
        onTap: (pin) {
          final group = groups[pin.id];
          if (mounted && group != null) _detail(group);
        },
      );
      await manager.setIconAllowOverlap(true);
      for (final group in _groups) {
        Uint8List? bytes;
        for (final memory in group.memories.take(5)) {
          bytes = await PhotoService.thumbnail(memory.photoAssetId);
          if (bytes != null) break;
        }
        final image = await PhotoMarker.imageFor(
          '',
          photoBytes: bytes,
          memoryCount: group.memories.length,
        );
        if (!mounted || revision != _revision) return;
        final pin = await manager.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                group.place.longitude,
                group.place.latitude,
              ),
            ),
            image: image,
            iconAnchor: IconAnchor.BOTTOM,
          ),
        );
        groups[pin.id] = group;
      }
      if (_groups.isNotEmpty) {
        final place = _groups.first.place;
        _viewport.moveTo(
          CameraViewportState(
            center: Point(
              coordinates: Position(place.longitude, place.latitude),
            ),
            zoom: 14,
          ),
        );
      }
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(
          () => _mapError = 'Photo pins could not load. Your memories are still available in the list.',
        );
      }
    }
  }

  Future<void> _recenter() async {
    if (_locationBusy) return;
    setState(() => _locationBusy = true);
    final result = await _location.currentPosition(requestPermission: true);
    if (!mounted) return;
    setState(() {
      _locationBusy = false;
      _locationMessage = switch (result.status) {
        LocationStatus.granted => null,
        LocationStatus.deniedForever =>
          'Location blocked. Enable it in Settings.',
        LocationStatus.servicesDisabled => 'Location Services are off.',
        LocationStatus.denied => 'Location declined. Your memories still work.',
        _ => 'Location unavailable. Try again later.',
      };
    });
    if (result.position != null) {
      final position = result.position!;
      _viewport.moveTo(
        CameraViewportState(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.5,
        ),
      );
      // One-shot recenter only: no continuous SDK location puck or stream.
    }
    if (result.status == LocationStatus.deniedForever ||
        result.status == LocationStatus.servicesDisabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationMessage!),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => result.status == LocationStatus.servicesDisabled
                ? _location.openLocationSettings()
                : _location.openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _detail(PlaceMemories group) async {
    bool changed = false;
    final rows = List<Memory>.of(group.memories);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .8,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  group.place.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${PlaceMemories(group.place, rows).visitCount} visit days · ${rows.length} confirmed photos',
                ),
                const Text(
                  'Visits are grouped by the photo date on this device.',
                ),
                const SizedBox(height: 16),
                for (final memory in rows)
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalPhotoView(assetId: memory.photoAssetId, size: 250),
                        ListTile(
                          title: Text(
                            MaterialLocalizations.of(context)
                                .formatFullDate(memory.photoDate),
                          ),
                          subtitle: const Text('Confirmed by you'),
                          trailing: IconButton(
                            tooltip: 'Remove memory',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await _database.remove(memory.id);
                                changed = true;
                                if (context.mounted) {
                                  update(() => rows.remove(memory));
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not remove memory. Try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (rows.isEmpty)
                  const Text(
                    'No memories at this place. Original photos remain in your library.',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && changed) await _load();
  }

  void _list() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        children: [
          const ListTile(title: Text('Your confirmed places')),
          for (final group in _groups)
            ListTile(
              title: Text(group.place.name),
              subtitle: Text(
                '${group.visitCount} visit days · ${group.memories.length} photos',
              ),
              onTap: () {
                Navigator.pop(context);
                _detail(group);
              },
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final revision = _revision;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My memory map'),
        actions: [
          IconButton(
            tooltip: 'Sample preview',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Refresh memories',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ],
              ),
            )
          : Stack(
              children: [
                if (MapboxConfig.isConfigured)
                  Positioned.fill(
                    child: MapWidget(
                      key: ValueKey(revision),
                      styleUri: MapboxStyles.LIGHT,
                      viewportController: _viewport,
                      viewport: CameraViewportState(
                        center: Point(
                          coordinates: Position(
                            DemoMapConfig.longitude,
                            DemoMapConfig.latitude,
                          ),
                        ),
                        zoom: DemoMapConfig.zoom,
                      ),
                      onMapCreated: (map) {
                        if (!mounted || revision != _revision) return;
                        _map = map;
                        _timeout?.cancel();
                        _timeout = Timer(const Duration(seconds: 20), () {
                          if (mounted && !_ready && revision == _revision) {
                            setState(
                              () => _mapError = 'Map is taking too long. Check the network and map token, then refresh.',
                            );
                          }
                        });
                      },
                      onMapLoadedListener: (_) => _installPins(revision),
                      onMapLoadErrorListener: (_) {
                        if (mounted && revision == _revision) {
                          setState(
                            () => _mapError = 'Map unavailable. Check the network and map token, then refresh.',
                          );
                        }
                      },
                    ),
                  ),
                if (!MapboxConfig.isConfigured)
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(Icons.map_outlined, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'Mapbox token needed',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'You can add, verify, and view local memories while map setup is pending. See README for secure setup.',
                      ),
                      const SizedBox(height: 24),
                      for (final group in _groups)
                        ListTile(
                          title: Text(group.place.name),
                          subtitle: Text(
                            '${group.visitCount} visit days · ${group.memories.length} photos',
                          ),
                          onTap: () => _detail(group),
                        ),
                    ],
                  ),
                if (_groups.isEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Your map starts with a photo. Add photos and confirm a place to save your first memory.',
                        ),
                      ),
                    ),
                  ),
                if (MapboxConfig.isConfigured && (!_ready || _mapError != null))
                  Align(
                    alignment: Alignment.topCenter,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_mapError ?? 'Loading map…'),
                      ),
                    ),
                  ),
                if (_locationMessage != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 10,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_locationMessage!),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading || _error != null ? null : _addPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add photos'),
                ),
              ),
              IconButton(
                tooltip: 'View places',
                onPressed: _groups.isEmpty ? null : _list,
                icon: const Icon(Icons.list),
              ),
              IconButton(
                tooltip: 'My location',
                onPressed: _locationBusy || !MapboxConfig.isConfigured
                    ? null
                    : _recenter,
                icon: _locationBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
