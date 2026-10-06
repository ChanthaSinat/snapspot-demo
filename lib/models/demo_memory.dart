import 'place.dart';

/// Local sample content for the map prototype, not a verified user memory.
class DemoMemory {
  const DemoMemory({
    required this.id,
    required this.place,
    required this.photoAssetPath,
    required this.visitDate,
  });

  final String id;
  final Place place;
  final String photoAssetPath;
  final DateTime visitDate;

  factory DemoMemory.fromJson(
    Map<String, dynamic> json,
    Map<String, Place> placesById,
  ) {
    final placeId = json['placeId'] as String;
    final place = placesById[placeId];
    if (place == null) {
      throw FormatException('Unknown demo place: $placeId');
    }
    return DemoMemory(
      id: json['id'] as String,
      place: place,
      photoAssetPath: json['photoAssetPath'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
    );
  }
}
