// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../command_runner.dart';

/// The built-in help command that's added to every [CommandRunner].
///
/// This command displays help information for the various subcommands.
class HelpCommand<T> extends Command<T> {
  HelpCommand() {
    argParser.addFlag('all',
        abbr: 'a',
        defaultsTo: false,
        negatable: false,
        help: 'Prints help for every command and sub-command');
  }

  @override
  final name = "help";

  @override
  String get description =>
      "Display help information for ${runner.executableName}.";

  @override
  String get invocation => "${runner.executableName} help [command]";

  @override
  T run() {
    if (argResults['all']) {
      _printAllUsage();
      return null;
    }

    // Show the default help if no command was specified.
    if (argResults.rest.isEmpty) {
      runner.printUsage();
      return null;
    }

    // Walk the command tree to show help for the selected command or
    // subcommand.
    var commands = runner.commands;
    Command command;
    var commandString = runner.executableName;

    for (var name in argResults.rest) {
      if (commands.isEmpty) {
        command.usageException(
            'Command "$commandString" does not expect a subcommand.');
      }

      if (commands[name] == null) {
        if (command == null) {
          runner.usageException('Could not find a command named "$name".');
        }

        command.usageException(
            'Could not find a subcommand named "$name" for "$commandString".');
      }

      command = commands[name];
      commands = command.subcommands;
      commandString += " $name";
    }

    command.printUsage();
    return null;
  }

  void _printAllUsage() {
    final Iterable<MapEntry<String, Command>> topLevelCommands =
        runner.commands?.entries;
    if (topLevelCommands == null) {
      runner.printUsage();
      return;
    }
    final List<MapEntry<String, Command>> commandStack =
        new List<MapEntry<String, Command>>.from(topLevelCommands);
    runner.printUsage();
    while (commandStack.isNotEmpty) {
      final MapEntry<String, Command> command = commandStack.removeAt(0);
      if (command.value.subcommands != null) {
        commandStack.insertAll(0, command.value.subcommands.entries);
      }
      // TODO(zra): wrapText?
      print('\nCommand: ${command.key}');
      command.value.printUsage();
    }
  }
}
