import 'dart:io';

import 'package:test/test.dart';

Stream<File> listGeneratedFilesInLib() => Directory('lib')
    .list(recursive: true)
    .where((entity) => entity is File)
    .cast<File>()
    .where((file) => file.path.endsWith('.g.dart'));

void main() {
  test(
    'generated files are up to date',
    timeout: Timeout.parse('10m'),
    () async {
      final originalContents = {
        await for (final file in listGeneratedFilesInLib())
          file.path: await file.readAsString(),
      };

      final buildResult = Process.runSync(Platform.resolvedExecutable,
          ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
      expect(buildResult.exitCode, 0);

      final updatedContents = {
        await for (final file in listGeneratedFilesInLib())
          file.path: await file.readAsString(),
      };

      for (final originalPath in originalContents.keys) {
        // File was deleted by build
        expect(updatedContents, contains(originalPath));
      }

      for (final updatedPath in updatedContents.keys) {
        // File was created by build
        expect(originalContents, contains(updatedPath));
      }

      for (final MapEntry(key: path, value: originalContent)
          in originalContents.entries) {
        final updatedContent = updatedContents[path]!;

        // File was modified by build
        expect(originalContent, equals(updatedContent));
      }
    },
  );
}
