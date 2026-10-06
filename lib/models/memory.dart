class Memory {
  const Memory({
    required this.id,
    required this.placeId,
    required this.photoAssetId,
    required this.photoDate,
    required this.photoLatitude,
    required this.photoLongitude,
    required this.verified,
    required this.createdAt,
  });

  final String id;
  final String placeId;
  final String photoAssetId;
  final DateTime photoDate;
  final double photoLatitude;
  final double photoLongitude;
  final bool verified;
  final DateTime createdAt;
  Map<String, Object?> toMap() => {
    'id': id,
    'placeId': placeId,
    'photoAssetId': photoAssetId,
    'photoDate': photoDate.toIso8601String(),
    'photoLatitude': photoLatitude,
    'photoLongitude': photoLongitude,
    'verified': verified ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };
  factory Memory.fromMap(Map<String, Object?> row) => Memory(
    id: row['id'] as String,
    placeId: row['placeId'] as String,
    photoAssetId: row['photoAssetId'] as String,
    photoDate: DateTime.parse(row['photoDate'] as String),
    photoLatitude: (row['photoLatitude'] as num).toDouble(),
    photoLongitude: (row['photoLongitude'] as num).toDouble(),
    verified: row['verified'] == 1,
    createdAt: DateTime.parse(row['createdAt'] as String),
  );
}
