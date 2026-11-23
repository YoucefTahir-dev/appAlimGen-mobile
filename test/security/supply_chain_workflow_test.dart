import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workflows = Directory('.github/workflows');

  test('all GitHub Actions are pinned to immutable commits', () {
    final action = RegExp(r'^\s*uses:\s*[^@\s]+@([^\s#]+)', multiLine: true);
    final failures = <String>[];
    for (final file in workflows.listSync().whereType<File>()) {
      final content = file.readAsStringSync();
      for (final match in action.allMatches(content)) {
        final reference = match.group(1)!;
        if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(reference)) {
          failures.add('${file.path}: $reference');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('workflows use read-only default repository permissions', () {
    final failures = <String>[];
    for (final file in workflows.listSync().whereType<File>()) {
      final content = file.readAsStringSync();
      if (!RegExp(
        r'^permissions:\s*\n\s+contents:\s+read\s*$',
        multiLine: true,
      ).hasMatch(content)) {
        failures.add(file.path);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('release signing never falls back to the debug key', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('validateReleaseSigning'));
    expect(gradle, contains('ANDROID_KEYSTORE_PATH'));
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
  });
}
