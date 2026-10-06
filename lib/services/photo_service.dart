import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'place_matcher.dart';

class LocalPhoto {
  const LocalPhoto(this.asset, this.latitude, this.longitude);
  final AssetEntity asset;
  final double? latitude;
  final double? longitude;
  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      PlaceMatcher.validCoordinates(latitude!, longitude!);
}

class PhotoService {
  static const permission = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: true,
    ),
  );
  Future<PermissionState> requestAccess() =>
      PhotoManager.requestPermissionExtend(requestOption: permission);
  Future<PermissionState> access() =>
      PhotoManager.getPermissionState(requestOption: permission);
  Future<List<LocalPhoto>> page(int page) async {
    if (!(await access()).hasAccess) return [];
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];
    final assets = await albums.first.getAssetListPaged(page: page, size: 40);
    final result = <LocalPhoto>[];
    for (final asset in assets) {
      try {
        final gps = await asset.latlngAsync().timeout(
          const Duration(seconds: 5),
        );
        result.add(LocalPhoto(asset, gps?.latitude, gps?.longitude));
      } catch (_) {
        result.add(LocalPhoto(asset, null, null));
      }
    }
    return result;
  }

  static Future<Uint8List?> thumbnail(String id) async {
    try {
      final state = await PhotoManager.getPermissionState(
        requestOption: permission,
      );
      if (!state.hasAccess) return null;
      final asset = await AssetEntity.fromId(id);
      if (asset == null || !await asset.isLocallyAvailable()) return null;
      return await asset
          .thumbnailDataWithSize(const ThumbnailSize(600, 600))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }
}
