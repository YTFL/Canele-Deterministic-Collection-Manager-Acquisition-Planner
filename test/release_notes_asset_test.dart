import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RELEASE_NOTES.md is accessible via rootBundle', () async {
    final content = await rootBundle.loadString('RELEASE_NOTES.md');
    expect(content.contains('# Canelé'), isTrue);
    expect(content.contains('Release Date:'), isTrue);
  });
}
