import 'dart:io';

import 'package:dash_bot/commands/ping.dart';
import 'package:dash_bot/commands/show_lint.dart';
import 'package:dash_bot/converters/linter_rules.dart';
import 'package:dash_bot/plugins/dartdoc/plugin.dart';
import 'package:dash_bot/plugins/status.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

void main() async {
  final hasPrefix = Platform.environment.containsKey('PREFIX');

  final commands = CommandsPlugin(
    prefix: hasPrefix ? (_) => Platform.environment['PREFIX']! : null,
  );

  commands
    ..addConverter(await createLinterRuleConverter())
    ..addCommand(showLint)
    ..addCommand(ping);

  await Nyxx.connectGateway(
    Platform.environment['TOKEN']!,
    GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
    options: GatewayClientOptions(plugins: [
      logging,
      cliIntegration,
      commands,
      pagination,
      DartdocSearch(),
      StatusRotate(),
    ]),
  );
}
