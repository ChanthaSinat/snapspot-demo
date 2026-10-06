import 'package:flutter_test/flutter_test.dart';
import 'package:place_memory_map/widgets/photo_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'photo pin renders from an asset and falls back if it is missing',
    () async {
      final photoPin = await PhotoMarker.imageFor(
        'assets/demo_photos/coffee.png',
        memoryCount: 2,
      );
      final fallbackPin = await PhotoMarker.imageFor(
        'assets/demo_photos/missing.png',
      );

      expect(photoPin.length, greaterThan(1000));
      expect(fallbackPin.length, greaterThan(1000));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
