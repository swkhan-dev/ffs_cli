import 'dart:io';

import 'package:ffs_cli/ffs_cli.dart';

Future<void> main(List<String> arguments) async {
  final code = await FfsRunner().run(arguments);
  exit(code ?? 0);
}
