import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/fs.dart';
import '../utils/logger.dart';
import '../utils/shell.dart';

class SupabaseCommand extends Command<int> {
  SupabaseCommand() {
    argParser
      ..addOption('url', help: 'Supabase project URL.')
      ..addOption('anon-key', help: 'Supabase anon key.');
  }

  @override
  String get name => 'supabase';
  @override
  String get description =>
      'Add Supabase to a Flutter project (config + Dart client).';

  @override
  Future<int> run() async {
    final logger = Logger();
    final shell = Shell(logger: logger);

    if (!isFlutterProject()) {
      logger.error('Run this from the root of a Flutter project.');
      return 78;
    }

    final pkg = readPubspecName();
    if (pkg == null) {
      logger.error('Could not read package name from pubspec.yaml.');
      return 78;
    }

    logger.step('Adding supabase_flutter dependency');
    final addCode =
        await shell.run('flutter', ['pub', 'add', 'supabase_flutter']);
    if (addCode != 0) return addCode;

    scaffold(
      projectDir: Directory.current.path,
      packageName: pkg,
      logger: logger,
      url: argResults?['url'] as String?,
      anonKey: argResults?['anon-key'] as String?,
    );

    return 0;
  }

  /// Static so `ffs create --supabase` can scaffold without a CommandRunner
  /// instance.
  static void scaffold({
    required String projectDir,
    required String packageName,
    required Logger logger,
    String? url,
    String? anonKey,
  }) {
    final envFile = File(p.join(projectDir, '.env'));
    if (!envFile.existsSync()) {
      writeFile(
        envFile.path,
        'SUPABASE_URL=${url ?? 'https://YOUR-PROJECT.supabase.co'}\n'
        'SUPABASE_ANON_KEY=${anonKey ?? 'YOUR-ANON-KEY'}\n',
      );
      logger.detail('wrote .env (placeholder values — fill these in)');
    }

    final gitignore = File(p.join(projectDir, '.gitignore'));
    if (gitignore.existsSync()) {
      final lines = gitignore.readAsStringSync();
      if (!lines.contains('.env')) {
        gitignore.writeAsStringSync('${lines.trimRight()}\n.env\n');
        logger.detail('appended .env to .gitignore');
      }
    }

    final configPath =
        p.join(projectDir, 'lib', 'core', 'supabase', 'supabase_config.dart');
    writeFile(configPath, _supabaseConfig);
    logger.detail('wrote ${p.relative(configPath, from: projectDir)}');

    logger.success('Supabase scaffolded.');
    logger.info(
        'In main(): await SupabaseConfig.init(); before runApp(). Pass values via --dart-define-from-file=.env or hard-code in SupabaseConfig.');
  }
}

const _supabaseConfig = r'''
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper around Supabase initialization. Reads URL + anon key either from
/// --dart-define-from-file=.env (recommended) or via the named parameters.
class SupabaseConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> init({String? url, String? anonKey}) async {
    final resolvedUrl = url ?? _envUrl;
    final resolvedKey = anonKey ?? _envAnonKey;

    assert(resolvedUrl.isNotEmpty,
        'SUPABASE_URL is empty — pass via --dart-define-from-file=.env or set it explicitly.');
    assert(resolvedKey.isNotEmpty, 'SUPABASE_ANON_KEY is empty.');

    await Supabase.initialize(url: resolvedUrl, anonKey: resolvedKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
''';
