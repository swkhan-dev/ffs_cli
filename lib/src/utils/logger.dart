import 'dart:io';

class Logger {
  Logger({this.color = true, this.verbose = false});

  final bool color;
  final bool verbose;

  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _cyan = '\x1B[36m';
  static const _gray = '\x1B[90m';
  static const _bold = '\x1B[1m';

  String _wrap(String code, String text) => color ? '$code$text$_reset' : text;

  void info(String msg) => stdout.writeln(msg);
  void success(String msg) => stdout.writeln(_wrap(_green, '✓ $msg'));
  void step(String msg) => stdout.writeln(_wrap(_cyan, '› $msg'));
  void warn(String msg) => stdout.writeln(_wrap(_yellow, '! $msg'));
  void error(String msg) => stderr.writeln(_wrap(_red, '✗ $msg'));
  void detail(String msg) => stdout.writeln(_wrap(_gray, '  $msg'));
  void heading(String msg) =>
      stdout.writeln(_wrap('$_bold$_blue', '\n== $msg ==\n'));
  void debug(String msg) {
    if (verbose) stdout.writeln(_wrap(_gray, '[debug] $msg'));
  }
}
