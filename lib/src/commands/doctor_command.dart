import 'package:args/command_runner.dart';

import '../utils/logger.dart';
import '../utils/shell.dart';

class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';
  @override
  String get description =>
      'Check that ffs-related toolchains are installed and reachable.';

  @override
  Future<int> run() async {
    final logger = Logger();
    final shell = Shell(logger: logger);

    logger.heading('ffs doctor');

    final checks = <_Check>[
      _Check('flutter', ['--version'], required: true),
      _Check('dart', ['--version'], required: true),
      _Check('flutterfire', ['--version'],
          required: false,
          fixHint: 'dart pub global activate flutterfire_cli'),
      _Check('firebase', ['--version'],
          required: false, fixHint: 'npm install -g firebase-tools'),
      _Check('node', ['--version'],
          required: false, fixHint: 'install Node.js for firebase CLI'),
      _Check('git', ['--version'], required: false),
    ];

    var allRequiredOk = true;
    for (final c in checks) {
      final exists = await shell.exists(c.executable);
      if (!exists) {
        if (c.required) {
          allRequiredOk = false;
          logger.error('${c.executable} — not found (required)');
        } else {
          logger.warn('${c.executable} — not found (optional)');
        }
        if (c.fixHint != null) logger.detail('install: ${c.fixHint}');
        continue;
      }
      final result = await shell.capture(c.executable, c.args);
      final firstLine =
          result.stdout.split('\n').firstWhere((l) => l.trim().isNotEmpty,
              orElse: () => result.stderr.split('\n').firstWhere(
                    (l) => l.trim().isNotEmpty,
                    orElse: () => '',
                  ));
      logger.success('${c.executable} — ${firstLine.trim()}');
    }

    if (!allRequiredOk) {
      logger.error('\nSome required tools are missing.');
      return 1;
    }
    logger.info('\nAll required tools found.');
    return 0;
  }
}

class _Check {
  _Check(this.executable, this.args, {required this.required, this.fixHint});
  final String executable;
  final List<String> args;
  final bool required;
  final String? fixHint;
}
