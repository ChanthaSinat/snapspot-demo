import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../config/mapbox_config.dart';
import '../../data/demo_map_config.dart';
import '../../models/demo_memory.dart';
import '../../models/place.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photo_marker.dart';
import '../memory_detail/memory_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locationService = LocationService();
  final _viewport = ViewportController();
  final _memoryByAnnotationId = <String, DemoMemory>{};
  late Future<List<DemoMemory>> _memories = _loadMemories();

  MapboxMap? _map;
  Cancelable? _pinTap;
  bool _mapReady = false;
  bool _locationBusy = false;
  bool _userFarFromDemo = false;
  LocationStatus _locationStatus = LocationStatus.notRequested;
  String? _mapError;
  String? _pinError;
  DemoMemory? _selectedMemory;

  Future<List<DemoMemory>> _loadMemories() async {
    final placeJson = jsonDecode(
      await rootBundle.loadString('lib/data/demo_places.json'),
    ) as List<dynamic>;
    final places = {
      for (final row in placeJson)
        (row as Map<String, dynamic>)['id'] as String: Place.fromJson(row),
    };
    final memoryJson = jsonDecode(
      await rootBundle.loadString('lib/data/demo_memories.json'),
    ) as List<dynamic>;
    return memoryJson
        .map((row) => DemoMemory.fromJson(row as Map<String, dynamic>, places))
        .toList();
  }

  void _openDetail(DemoMemory memory) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryDetailScreen(memory: memory),
      ),
    );
  }

  Future<void> _onMapLoaded(List<DemoMemory> memories) async {
    if (_mapReady || !mounted) return;
    setState(() {
      _mapReady = true;
      _mapError = null;
    });
    final map = _map;
    if (map == null) return;
    try {
      final manager = await map.annotations.createPointAnnotationManager();
      await manager.setIconAllowOverlap(true);
      _pinTap = manager.tapEvents(
        onTap: (annotation) {
          final memory = _memoryByAnnotationId[annotation.id];
          if (mounted && memory != null) {
            setState(() => _selectedMemory = memory);
          }
        },
      );
      for (final memory in memories) {
        final marker = await PhotoMarker.imageFor(memory.photoAssetPath);
        if (!mounted) {
          return;
        }
        final annotation = await manager.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                memory.place.longitude,
                memory.place.latitude,
              ),
            ),
            image: marker,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: 1.0,
          ),
        );
        _memoryByAnnotationId[annotation.id] = memory;
      }
    } catch (error) {
      debugPrint('Could not load demo photo pins: $error');
      if (mounted) {
        setState(() => _pinError = 'Demo photo pins could not load.');
      }
    }
  }

  Future<void> _refreshLocation({required bool requestPermission}) async {
    if (_locationBusy) {
      return;
    }
    setState(() => _locationBusy = true);
    final result = await _locationService.currentPosition(
      requestPermission: requestPermission,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _locationBusy = false;
      _locationStatus = result.status;
    });
    final position = result.position;
    if (position == null) {
      return;
    }

    try {
      await _map?.location.updateSettings(
        LocationComponentSettings(enabled: true),
      );
    } catch (error) {
      debugPrint('Could not show the user location puck: $error');
    }
    _viewport.moveTo(
      CameraViewportState(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 15.5,
      ),
      transition: const FlyViewportTransition(
        duration: Duration(milliseconds: 900),
      ),
    );
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      DemoMapConfig.latitude,
      DemoMapConfig.longitude,
    );
    if (mounted) {
      setState(() => _userFarFromDemo = distance > 2500);
    }
  }

  void _showDemoPins() {
    _viewport.moveTo(
      CameraViewportState(
        center: Point(
          coordinates: Position(
            DemoMapConfig.longitude,
            DemoMapConfig.latitude,
          ),
        ),
        zoom: DemoMapConfig.zoom,
      ),
      transition: const FlyViewportTransition(
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  String? get _locationMessage => switch (_locationStatus) {
    LocationStatus.notRequested => 'Tap location to center the map.',
    LocationStatus.granted => null,
    LocationStatus.denied => 'Location denied. Showing demo places.',
    LocationStatus.deniedForever => 'Location blocked. Enable it in Settings.',
    LocationStatus.servicesDisabled => 'Location Services are off.',
    LocationStatus.unavailable => 'Location unavailable. Showing demo places.',
  };

  @override
  void dispose() {
    _pinTap?.cancel();
    _viewport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DemoMemory>>(
        future: _memories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _centerMessage(
              'Could not load bundled demo memories.',
              action: TextButton(
                onPressed: () => setState(() => _memories = _loadMemories()),
                child: const Text('Try again'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final memories = snapshot.data!;
          if (!MapboxConfig.isConfigured) {
            return _missingTokenView(memories);
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: MapWidget(
                  styleUri: MapboxStyles.LIGHT,
                  viewport: CameraViewportState(
                    center: Point(
                      coordinates: Position(
                        DemoMapConfig.longitude,
                        DemoMapConfig.latitude,
                      ),
                    ),
                    zoom: DemoMapConfig.zoom,
                  ),
                  viewportController: _viewport,
                  onMapCreated: (map) {
                    _map = map;
                    _refreshLocation(requestPermission: true);
                  },
                  onMapLoadedListener: (_) => _onMapLoaded(memories),
                  onMapLoadErrorListener: (event) {
                    debugPrint('Mapbox map load error: ${event.message}');
                    if (mounted && !_mapReady) {
                      setState(
                        () => _mapError = 'Map could not load. Check your public token and network.',
                      );
                    }
                  },
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const _MapLabel('My photo map'),
                        const Spacer(),
                        if (_userFarFromDemo)
                          TextButton.icon(
                            onPressed: _showDemoPins,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Demo pins'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_mapReady || _mapError != null)
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _mapError ?? 'Loading map…',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (_pinError != null)
                Positioned(
                  top: 78,
                  left: 16,
                  right: 16,
                  child: _MapLabel(_pinError!),
                ),
              if (_selectedMemory != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 92,
                  child: _memoryPreview(_selectedMemory!),
                ),
              if (_locationMessage != null || _locationBusy)
                Positioned(
                  left: 16,
                  right: 82,
                  bottom: 27,
                  child: _locationNotice(),
                ),
              Positioned(
                right: 16,
                bottom: 24,
                child: SafeArea(
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    tooltip: 'Recenter on my location',
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    onPressed: _locationBusy
                        ? null
                        : () => _refreshLocation(requestPermission: true),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _locationNotice() {
    final canOpenSettings =
        _locationStatus == LocationStatus.deniedForever ||
        _locationStatus == LocationStatus.servicesDisabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (_locationBusy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (_locationBusy) const SizedBox(width: 8),
            Expanded(
              child: Text(
                _locationBusy ? 'Finding your location…' : _locationMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (canOpenSettings)
              TextButton(
                onPressed: () =>
                    _locationStatus == LocationStatus.servicesDisabled
                    ? _locationService.openLocationSettings()
                    : _locationService.openAppSettings(),
                child: const Text('Settings'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _memoryPreview(DemoMemory memory) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(memory),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  memory.photoAssetPath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DEMO MEMORY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      memory.place.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${memory.place.category} · ${MaterialLocalizations.of(context).formatMediumDate(memory.visitDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'View memory',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.forest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _missingTokenView(List<DemoMemory> memories) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Text(
            'MY PHOTO MAP',
            style: TextStyle(
              color: AppColors.forest,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Every place has a story.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'A few moments from Phnom Penh, ready for the map.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 170,
              child: Row(
                children: [
                  for (final memory in memories.take(3))
                    Expanded(
                      child: Image.asset(
                        memory.photoAssetPath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: AppColors.softGreen),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map_outlined, color: AppColors.forest),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapbox token needed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Run with a public token using --dart-define=ACCESS_TOKEN=pk.your_public_token to show the live map.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('Demo memories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final memory in memories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openDetail(memory),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            memory.photoAssetPath,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 72,
                              height: 72,
                              child: Icon(Icons.image_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memory.place.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${memory.place.category} · ${MaterialLocalizations.of(context).formatMediumDate(memory.visitDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.forest,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _centerMessage(String message, {Widget? action}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Text(message), ?action],
    ),
  );
}

class _MapLabel extends StatelessWidget {
  const _MapLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
