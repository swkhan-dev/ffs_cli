import 'dart:io';

import 'logger.dart';

class ShellResult {
  ShellResult(this.exitCode, this.stdout, this.stderr);
  final int exitCode;
  final String stdout;
  final String stderr;
  bool get ok => exitCode == 0;
}

class Shell {
  Shell({Logger? logger}) : logger = logger ?? Logger();
  final Logger logger;

  /// Whether [exe] is available on PATH. Cross-platform via `where` on Windows
  /// and `which` elsewhere.
  Future<bool> exists(String exe) async {
    final probe = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(probe, [exe], runInShell: true);
    return result.exitCode == 0;
  }

  /// Runs a command and streams its output to the terminal in real time.
  /// Returns the final exit code.
  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool stream = true,
  }) async {
    logger.debug('exec: $executable ${arguments.join(' ')}'
        '${workingDirectory != null ? ' (cwd=$workingDirectory)' : ''}');

    final proc = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: true,
      mode: stream ? ProcessStartMode.inheritStdio : ProcessStartMode.normal,
    );
    return proc.exitCode;
  }

  /// Runs a command and captures its output. Use for commands whose output you
  /// need to parse (e.g. `flutter --version`).
  Future<ShellResult> capture(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    logger.debug('capture: $executable ${arguments.join(' ')}');
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    return ShellResult(
      result.exitCode,
      result.stdout.toString(),
      result.stderr.toString(),
    );
  }
}
