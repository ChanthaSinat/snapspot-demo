import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_memory_map/services/location_service.dart';

class TestLocationPlatform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  int permissionRequests = 0;
  int positionRequests = 0;
  bool failPosition = false;
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return requestedPermission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    settings = locationSettings;
    if (failPosition) throw TimeoutException('No fix');
    return Position(
      longitude: 104.92,
      latitude: 11.55,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late TestLocationPlatform platform;
  late GeolocatorPlatform original;
  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = TestLocationPlatform();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test(
    'no permission prompt or position read without an explicit request',
    () async {
      final result = await LocationService().currentPosition(
        requestPermission: false,
      );
      expect(result.status, LocationStatus.notRequested);
      expect(platform.permissionRequests, 0);
      expect(platform.positionRequests, 0);
    },
  );
  test(
    'explicit consent requests one foreground position with a timeout',
    () async {
      final result = await LocationService().currentPosition(
        requestPermission: true,
      );
      expect(result.status, LocationStatus.granted);
      expect(result.position?.latitude, 11.55);
      expect(platform.permissionRequests, 1);
      expect(platform.positionRequests, 1);
      expect(platform.settings?.timeLimit, const Duration(seconds: 12));
    },
  );
  test('disabled services and permanent denial never read position', () async {
    platform.enabled = false;
    expect(
      (await LocationService().currentPosition(requestPermission: true)).status,
      LocationStatus.servicesDisabled,
    );
    platform.enabled = true;
    platform.permission = LocationPermission.deniedForever;
    expect(
      (await LocationService().currentPosition(requestPermission: true)).status,
      LocationStatus.deniedForever,
    );
    expect(platform.permissionRequests, 0);
    expect(platform.positionRequests, 0);
  });
  test(
    'declining and a timed-out position produce usable fallback states',
    () async {
      platform.requestedPermission = LocationPermission.denied;
      expect(
        (await LocationService().currentPosition(requestPermission: true))
            .status,
        LocationStatus.denied,
      );
      expect(platform.positionRequests, 0);
      platform.permission = LocationPermission.whileInUse;
      platform.failPosition = true;
      expect(
        (await LocationService().currentPosition(requestPermission: false))
            .status,
        LocationStatus.unavailable,
      );
    },
  );
}
