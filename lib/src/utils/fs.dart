import 'dart:io';

import 'package:path/path.dart' as p;

/// Write [content] to [path], creating parent directories as needed.
File writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  return file;
}

/// Whether the current working directory looks like a Flutter project.
bool isFlutterProject([String? dir]) {
  final root = dir ?? Directory.current.path;
  final pubspec = File(p.join(root, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;
  return pubspec.readAsStringSync().contains('flutter:');
}

/// Reads the project name from a pubspec.yaml at [dir].
String? readPubspecName([String? dir]) {
  final root = dir ?? Directory.current.path;
  final pubspec = File(p.join(root, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return null;
  for (final line in pubspec.readAsLinesSync()) {
    final m = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (m != null) return m.group(1);
  }
  return null;
}

/// Convert any case to snake_case (suitable for Dart filenames).
String toSnakeCase(String input) {
  return input
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)}_${m.group(2)}')
      .replaceAll(RegExp(r'[\s\-]+'), '_')
      .toLowerCase();
}

/// Convert any case to PascalCase (suitable for Dart class names).
String toPascalCase(String input) {
  final parts = toSnakeCase(input).split('_').where((e) => e.isNotEmpty);
  return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join();
}
