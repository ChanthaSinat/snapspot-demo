#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
simulator_id="${1:-28CD3F4F-1C92-492B-86C0-8DB9FB3E0486}"
flutter_bin="${FLUTTER_BIN:-/Users/chanthasinat/Develop/flutter/bin/flutter}"
xcrun simctl list devices available -j | python3 -c 'import json,sys; data=json.load(sys.stdin); wanted=sys.argv[1]; assert any(d["udid"]==wanted and d["state"]=="Booted" for ds in data["devices"].values() for d in ds), "Use an available booted test simulator"' "$simulator_id"
"$flutter_bin" build ios --simulator --debug --target=integration_test/local_photo_flow_test.dart --dart-define=NATIVE_PHOTO_TEST=true
xcrun simctl install "$simulator_id" build/ios/iphonesimulator/Runner.app
xcrun simctl addmedia "$simulator_id" test/fixtures/goloca-gps-test.jpg
"$flutter_bin" drive --use-application-binary=build/ios/iphonesimulator/Runner.app --driver=test_driver/integration_test.dart --target=integration_test/local_photo_flow_test.dart -d "$simulator_id"
