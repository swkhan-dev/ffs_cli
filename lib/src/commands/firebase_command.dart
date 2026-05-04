import 'dart:io';

import 'package:args/command_runner.dart';

import '../utils/fs.dart';
import '../utils/logger.dart';
import '../utils/shell.dart';

class FirebaseCommand extends Command<int> {
  FirebaseCommand() {
    argParser.addOption('project',
        help: 'Firebase project ID (passed to flutterfire configure).');
  }

  @override
  String get name => 'firebase';
  @override
  String get description =>
      'Configure Firebase for a Flutter project (wraps flutterfire CLI).';

  @override
  Future<int> run() async {
    final logger = Logger();
    final shell = Shell(logger: logger);
    if (!isFlutterProject()) {
      logger.error(
          'Run this from the root of a Flutter project (no pubspec.yaml found here).');
      return 78;
    }
    final project = argResults?['project'] as String?;
    return runInProject(
      projectDir: Directory.current.path,
      logger: logger,
      shell: shell,
      projectId: project,
    );
  }

  /// Reusable entry point so `ffs create --firebase` can call this without
  /// going through the command runner.
  static Future<int> runInProject({
    required String projectDir,
    required Logger logger,
    required Shell shell,
    String? projectId,
  }) async {
    if (!await shell.exists('flutterfire')) {
      logger.warn('flutterfire CLI not found. Installing it now...');
      final activate = await shell.run(
          'dart', ['pub', 'global', 'activate', 'flutterfire_cli']);
      if (activate != 0) {
        logger.error(
            'Failed to install flutterfire_cli. Install manually with: dart pub global activate flutterfire_cli');
        return activate;
      }
    }

    if (!await shell.exists('firebase')) {
      logger.warn(
          'Firebase CLI ("firebase") is not on PATH. Install via npm: npm i -g firebase-tools, then run "firebase login".');
      logger.warn(
          'Continuing — flutterfire configure will prompt you if it needs the CLI.');
    }

    logger.step('Adding Firebase Dart packages');
    final addCode = await shell.run(
      'flutter',
      ['pub', 'add', 'firebase_core'],
      workingDirectory: projectDir,
    );
    if (addCode != 0) return addCode;

    logger.step('Running flutterfire configure');
    final args = <String>['configure'];
    if (projectId != null) {
      args.addAll(['--project', projectId]);
    }
    final code = await shell.run('flutterfire', args,
        workingDirectory: projectDir);
    if (code != 0) {
      logger.warn(
          'flutterfire configure exited with code $code. You can retry it later: flutterfire configure');
      return code;
    }
    logger.success(
        'Firebase configured. Initialize it in main() with Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).');
    return 0;
  }
}
