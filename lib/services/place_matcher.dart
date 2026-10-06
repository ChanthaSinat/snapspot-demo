import 'dart:math';

import '../models/place.dart';

class PlaceSuggestion {
  const PlaceSuggestion(this.place, this.distanceMeters);
  final Place place;
  final double distanceMeters;
}

class PlaceMatcher {
  static bool validCoordinates(double lat, double lon) =>
      lat.isFinite &&
      lon.isFinite &&
      lat.abs() <= 90 &&
      lon.abs() <= 180 &&
      !(lat == 0 && lon == 0);

  static double distance(double lat, double lon, Place place) {
    const r = 6371000.0;
    double radians(double n) => n * pi / 180;
    final a =
        pow(sin(radians(place.latitude - lat) / 2), 2) +
        cos(radians(lat)) *
            cos(radians(place.latitude)) *
            pow(sin(radians(place.longitude - lon) / 2), 2);
    return 2 * r * asin(sqrt(a.clamp(0, 1)));
  }

  List<PlaceSuggestion> match(
    double lat,
    double lon,
    List<Place> places, {
    double radiusMeters = 300,
  }) {
    if (!validCoordinates(lat, lon)) return [];
    final matches = places
        .where((p) => validCoordinates(p.latitude, p.longitude))
        .map((p) => PlaceSuggestion(p, distance(lat, lon, p)))
        .where((p) => p.distanceMeters <= radiusMeters)
        .toList();
    matches.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return matches;
  }
}
