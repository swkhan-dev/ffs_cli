import 'dart:io';

import 'package:args/command_runner.dart';

import 'src/commands/add_command.dart';
import 'src/commands/create_command.dart';
import 'src/commands/doctor_command.dart';
import 'src/commands/firebase_command.dart';
import 'src/commands/supabase_command.dart';
import 'src/version.dart';

class FfsRunner extends CommandRunner<int> {
  FfsRunner()
      : super(
          'ffs',
          'Flutter Foundation Scaffold — create Flutter projects with architecture, Firebase, and Supabase wired up in one shot.',
        ) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the ffs version.',
    );

    addCommand(CreateCommand());
    addCommand(AddCommand());
    addCommand(FirebaseCommand());
    addCommand(SupabaseCommand());
    addCommand(DoctorCommand());
  }

  @override
  Future<int?> run(Iterable<String> args) async {
    final list = args.toList();
    if (list.contains('--version') || list.contains('-v')) {
      print('ffs $ffsVersion');
      return 0;
    }
    try {
      final result = await super.run(list);
      return result ?? 0;
    } on UsageException catch (e) {
      stderr.writeln(e);
      return 64;
    }
  }
}
