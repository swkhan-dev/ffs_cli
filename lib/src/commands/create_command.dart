import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../templates/architectures.dart';
import '../utils/fs.dart';
import '../utils/logger.dart';
import '../utils/shell.dart';
import 'firebase_command.dart';
import 'supabase_command.dart';

class CreateCommand extends Command<int> {
  CreateCommand() {
    argParser
      ..addOption(
        'arch',
        abbr: 'a',
        help: 'Architecture to scaffold.',
        allowed: Architecture.values.map((a) => a.id).toList(),
        allowedHelp: {
          for (final a in Architecture.values) a.id: a.description,
        },
        defaultsTo: Architecture.mvvm.id,
      )
      ..addOption(
        'org',
        help: 'Organization in reverse-domain form (e.g. com.example).',
        defaultsTo: 'com.example',
      )
      ..addOption(
        'description',
        help: 'Project description.',
        defaultsTo: 'A new Flutter project scaffolded by ffs.',
      )
      ..addMultiOption(
        'platforms',
        help: 'Comma-separated platforms to enable.',
        defaultsTo: ['android', 'ios', 'web'],
      )
      ..addFlag('firebase',
          help: 'Run flutterfire configure after creation.',
          negatable: false)
      ..addFlag('supabase',
          help: 'Scaffold Supabase config + client after creation.',
          negatable: false)
      ..addFlag('overwrite',
          help: 'Overwrite the target directory if it exists.',
          negatable: false);
  }

  @override
  String get name => 'create';
  @override
  String get description =>
      'Create a new Flutter project with an architecture preset.';
  @override
  String get invocation => 'ffs create <project_name> [options]';

  @override
  Future<int> run() async {
    final logger = Logger();
    final shell = Shell(logger: logger);

    final rest = argResults!.rest;
    if (rest.isEmpty) {
      logger.error('Missing project name.\nUsage: $invocation');
      return 64;
    }
    final rawName = rest.first;
    final projectName = toSnakeCase(rawName);
    final arch = Architecture.fromId(argResults!['arch'] as String)!;
    final org = argResults!['org'] as String;
    final description = argResults!['description'] as String;
    final platforms =
        (argResults!['platforms'] as List<String>).where((s) => s.isNotEmpty).toList();
    final addFirebase = argResults!['firebase'] as bool;
    final addSupabase = argResults!['supabase'] as bool;
    final overwrite = argResults!['overwrite'] as bool;

    final projectDir = p.join(Directory.current.path, projectName);
    final dir = Directory(projectDir);
    if (dir.existsSync()) {
      if (!overwrite) {
        logger.error(
            'Directory "$projectName" already exists. Use --overwrite to replace it.');
        return 73;
      }
      logger.warn('Removing existing directory $projectDir');
      dir.deleteSync(recursive: true);
    }

    if (!await shell.exists('flutter')) {
      logger.error(
          'Flutter is not on PATH. Install it from https://docs.flutter.dev/get-started/install.');
      return 127;
    }

    logger.heading('Creating Flutter project: $projectName');
    logger.detail('Org:          $org');
    logger.detail('Architecture: ${arch.id} — ${arch.description}');
    logger.detail('Platforms:    ${platforms.join(', ')}');

    logger.step('Running flutter create');
    final createCode = await shell.run('flutter', [
      'create',
      '--org', org,
      '--description', description,
      '--platforms', platforms.join(','),
      projectName,
    ]);
    if (createCode != 0) {
      logger.error('flutter create failed (exit $createCode).');
      return createCode;
    }

    logger.step('Scaffolding ${arch.id} architecture');
    scaffoldArchitecture(projectDir, projectName, arch);
    cleanupDefaults(projectDir);
    logger.success('Architecture scaffolded.');

    if (addFirebase) {
      logger.step('Setting up Firebase');
      final code = await FirebaseCommand.runInProject(
        projectDir: projectDir,
        logger: logger,
        shell: shell,
      );
      if (code != 0) {
        logger.warn('Firebase setup did not complete (exit $code).');
      }
    }

    if (addSupabase) {
      logger.step('Setting up Supabase');
      SupabaseCommand.scaffold(
        projectDir: projectDir,
        packageName: projectName,
        logger: logger,
      );
    }

    logger.heading('Done');
    logger.success('Project ready at $projectDir');
    logger.info('Next steps:');
    logger.info('  cd $projectName');
    logger.info('  flutter pub get');
    logger.info('  flutter run');
    return 0;
  }
}
