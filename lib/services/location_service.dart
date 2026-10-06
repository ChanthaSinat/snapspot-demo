import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  notRequested,
  granted,
  denied,
  deniedForever,
  servicesDisabled,
  unavailable,
}

class LocationResult {
  const LocationResult(this.status, {this.position});

  final LocationStatus status;
  final Position? position;
}

class LocationService {
  /// Gets one foreground position. A native prompt is shown only when asked.
  Future<LocationResult> currentPosition({
    required bool requestPermission,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.servicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return LocationResult(
          requestPermission
              ? LocationStatus.denied
              : LocationStatus.notRequested,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.unableToDetermine) {
        return const LocationResult(LocationStatus.unavailable);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(LocationStatus.granted, position: position);
    } on LocationServiceDisabledException {
      return const LocationResult(LocationStatus.servicesDisabled);
    } on PermissionDeniedException {
      return const LocationResult(LocationStatus.denied);
    } catch (_) {
      return const LocationResult(LocationStatus.unavailable);
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
