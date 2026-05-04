import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/fs.dart';
import '../utils/logger.dart';

/// Detects which architecture a project is using by inspecting `lib/`.
enum ProjectArch { simple, mvvm, clean, unknown }

ProjectArch _detect(String projectDir) {
  final lib = Directory(p.join(projectDir, 'lib'));
  if (!lib.existsSync()) return ProjectArch.unknown;
  final featuresDir = Directory(p.join(lib.path, 'features'));
  if (!featuresDir.existsSync()) return ProjectArch.unknown;

  // Probe by looking for marker files inside any existing feature folder.
  for (final entity in featuresDir.listSync()) {
    if (entity is! Directory) continue;
    if (Directory(p.join(entity.path, 'domain')).existsSync()) {
      return ProjectArch.clean;
    }
    if (Directory(p.join(entity.path, 'view_models')).existsSync()) {
      return ProjectArch.mvvm;
    }
  }
  return ProjectArch.simple;
}

class AddCommand extends Command<int> {
  AddCommand() {
    addSubcommand(_AddFeatureCommand());
  }

  @override
  String get name => 'add';
  @override
  String get description => 'Add things to an existing project (e.g. feature).';
}

class _AddFeatureCommand extends Command<int> {
  @override
  String get name => 'feature';
  @override
  String get description =>
      'Generate a new feature module matching the project architecture.';
  @override
  String get invocation => 'ffs add feature <name>';

  @override
  Future<int> run() async {
    final logger = Logger();
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      logger.error('Missing feature name.\nUsage: $invocation');
      return 64;
    }

    final projectDir = Directory.current.path;
    if (!isFlutterProject(projectDir)) {
      logger.error('Not a Flutter project (no pubspec.yaml with flutter:).');
      return 78;
    }
    final pkg = readPubspecName(projectDir);
    if (pkg == null) {
      logger.error('Could not read package name from pubspec.yaml.');
      return 78;
    }

    final featureSnake = toSnakeCase(rest.first);
    final featurePascal = toPascalCase(rest.first);
    final arch = _detect(projectDir);

    final featureRoot =
        p.join(projectDir, 'lib', 'features', featureSnake);
    if (Directory(featureRoot).existsSync()) {
      logger.error(
          'Feature "$featureSnake" already exists at lib/features/$featureSnake.');
      return 73;
    }

    logger.heading('Adding feature: $featureSnake');
    logger.detail('Architecture detected: ${arch.name}');

    switch (arch) {
      case ProjectArch.clean:
        _scaffoldCleanFeature(featureRoot, pkg, featureSnake, featurePascal);
      case ProjectArch.mvvm:
        _scaffoldMvvmFeature(featureRoot, pkg, featureSnake, featurePascal);
      case ProjectArch.simple:
      case ProjectArch.unknown:
        _scaffoldSimpleFeature(featureRoot, pkg, featureSnake, featurePascal);
    }

    logger.success('Feature ready at lib/features/$featureSnake');
    return 0;
  }

  void _scaffoldSimpleFeature(
      String root, String pkg, String snake, String pascal) {
    writeFile(p.join(root, '${snake}_page.dart'), '''
import 'package:flutter/material.dart';

class ${pascal}Page extends StatelessWidget {
  const ${pascal}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: const Center(child: Text('$pascal')),
    );
  }
}
''');
  }

  void _scaffoldMvvmFeature(
      String root, String pkg, String snake, String pascal) {
    writeFile(p.join(root, 'models', '${snake}_model.dart'), '''
class ${pascal}Model {
  const ${pascal}Model();
}
''');
    writeFile(p.join(root, 'view_models', '${snake}_view_model.dart'), '''
import 'package:$pkg/core/base/base_view_model.dart';

class ${pascal}ViewModel extends BaseViewModel {
  // TODO: state and methods
}
''');
    writeFile(p.join(root, 'views', '${snake}_view.dart'), '''
import 'package:flutter/material.dart';
import 'package:$pkg/features/$snake/view_models/${snake}_view_model.dart';

class ${pascal}View extends StatefulWidget {
  const ${pascal}View({super.key});

  @override
  State<${pascal}View> createState() => _${pascal}ViewState();
}

class _${pascal}ViewState extends State<${pascal}View> {
  final _vm = ${pascal}ViewModel();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: const Center(child: Text('$pascal')),
    );
  }
}
''');
  }

  void _scaffoldCleanFeature(
      String root, String pkg, String snake, String pascal) {
    writeFile(p.join(root, 'domain', 'entities', '$snake.dart'), '''
class $pascal {
  const $pascal();
}
''');
    writeFile(
        p.join(root, 'domain', 'repositories', '${snake}_repository.dart'), '''
import 'package:$pkg/features/$snake/domain/entities/$snake.dart';

abstract class ${pascal}Repository {
  Future<$pascal> fetch();
}
''');
    writeFile(
        p.join(root, 'domain', 'usecases', 'get_$snake.dart'), '''
import 'package:$pkg/core/usecase/usecase.dart';
import 'package:$pkg/features/$snake/domain/entities/$snake.dart';
import 'package:$pkg/features/$snake/domain/repositories/${snake}_repository.dart';

class Get$pascal implements UseCase<$pascal, NoParams> {
  Get$pascal(this.repository);
  final ${pascal}Repository repository;

  @override
  Future<$pascal> call(NoParams params) => repository.fetch();
}
''');
    writeFile(
        p.join(root, 'data', 'repositories', '${snake}_repository_impl.dart'),
        '''
import 'package:$pkg/features/$snake/domain/entities/$snake.dart';
import 'package:$pkg/features/$snake/domain/repositories/${snake}_repository.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  @override
  Future<$pascal> fetch() async => const $pascal();
}
''');
    writeFile(
        p.join(root, 'presentation', 'controllers', '${snake}_controller.dart'),
        '''
import 'package:flutter/foundation.dart';
import 'package:$pkg/core/usecase/usecase.dart';
import 'package:$pkg/features/$snake/domain/entities/$snake.dart';
import 'package:$pkg/features/$snake/domain/usecases/get_$snake.dart';

class ${pascal}Controller extends ChangeNotifier {
  ${pascal}Controller(this._get$pascal);

  final Get$pascal _get$pascal;
  $pascal? _value;
  $pascal? get value => _value;

  Future<void> load() async {
    _value = await _get$pascal(const NoParams());
    notifyListeners();
  }
}
''');
    writeFile(
        p.join(root, 'presentation', 'pages', '${snake}_page.dart'), '''
import 'package:flutter/material.dart';
import 'package:$pkg/features/$snake/presentation/controllers/${snake}_controller.dart';

class ${pascal}Page extends StatelessWidget {
  const ${pascal}Page({super.key, required this.controller});
  final ${pascal}Controller controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: const Center(child: Text('$pascal')),
    );
  }
}
''');
  }
}
