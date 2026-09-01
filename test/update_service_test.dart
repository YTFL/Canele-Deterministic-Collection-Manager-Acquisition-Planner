import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/app_update_model.dart';
import 'package:canele/services/update_service.dart';

void main() {
  group('AppUpdate Model Tests', () {
    test('fromJson and toJson deserialization & serialization', () {
      final json = {
        'version': '1.2.0',
        'buildNumber': 5,
        'changelog': 'Bug fixes and performance improvements',
      };

      final update = AppUpdate.fromJson(json);
      expect(update.version, '1.2.0');
      expect(update.buildNumber, 5);
      expect(update.changelog, 'Bug fixes and performance improvements');

      final serialized = update.toJson();
      expect(serialized['version'], '1.2.0');
      expect(serialized['buildNumber'], 5);
      expect(serialized['changelog'], 'Bug fixes and performance improvements');
    });

    test('fromJson handles string build numbers and missing fields', () {
      final jsonWithStringBuild = {
        'version': '2.0.1',
        'buildNumber': '12',
      };

      final update = AppUpdate.fromJson(jsonWithStringBuild);
      expect(update.version, '2.0.1');
      expect(update.buildNumber, 12);
      expect(update.changelog, '');
    });

    test('compareVersions correctly identifies greater, lesser, and equal versions', () {
      expect(AppUpdate.compareVersions('1.0.1', '1.0.0'), 1);
      expect(AppUpdate.compareVersions('1.0.0', '1.0.1'), -1);
      expect(AppUpdate.compareVersions('1.0.0', '1.0.0'), 0);
      expect(AppUpdate.compareVersions('2.0.0', '1.9.9'), 1);
      expect(AppUpdate.compareVersions('1.2', '1.2.0'), 0);
      expect(AppUpdate.compareVersions('1.2.1', '1.2'), 1);
      expect(AppUpdate.compareVersions('1.0.0+5', '1.0.0+2'), 0); // compareVersions compares semantic numbers
    });

    test('isNewerThan compares version and build number properly', () {
      final update1 = AppUpdate(version: '1.0.1', buildNumber: 1, changelog: '');
      expect(update1.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 10), isTrue);

      final update2 = AppUpdate(version: '1.0.0', buildNumber: 5, changelog: '');
      expect(update2.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 4), isTrue);
      expect(update2.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 5), isFalse);
      expect(update2.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 6), isFalse);

      final update3 = AppUpdate(version: '0.9.9', buildNumber: 99, changelog: '');
      expect(update3.isNewerThan(currentVersion: '1.0.0', currentBuildNumber: 1), isFalse);
    });
  });

  group('UpdateService Release Notes Sanitization Tests', () {
    test('sanitizeReleaseNotes strips top heading metadata and dividers', () {
      const rawMarkdown = '''
# Release v1.1.0
Build 2
---
### Added
- Added automatic update checking.
- Added animated progress bar.

---
For full history see changelog.md
''';

      final sanitized = UpdateService.sanitizeReleaseNotes(rawMarkdown);
      expect(sanitized.contains('# Release v1.1.0'), isFalse);
      expect(sanitized.contains('For full history'), isFalse);
      expect(sanitized.contains('### Added'), isTrue);
      expect(sanitized.contains('Added automatic update checking.'), isTrue);
    });

    test('sanitizeReleaseNotes removes installation section', () {
      const rawMarkdown = '''
### ✨ Features
- Added offline backup export.

## 📦 Installation
Download APK from releases page.

### 🐛 Bug Fixes
- Fixed theme glitch on startup.
''';

      final sanitized = UpdateService.sanitizeReleaseNotes(rawMarkdown);
      expect(sanitized.contains('## 📦 Installation'), isFalse);
      expect(sanitized.contains('Download APK from releases page.'), isFalse);
      expect(sanitized.contains('### ✨ Features'), isTrue);
      expect(sanitized.contains('### 🐛 Bug Fixes'), isTrue);
    });
  });
}
