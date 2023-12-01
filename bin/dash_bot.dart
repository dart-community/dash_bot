import 'dart:io';

import 'package:dash_bot/commands/ping.dart';
import 'package:dash_bot/commands/show_lint.dart';
import 'package:dash_bot/converters/linter_rules.dart';
import 'package:dash_bot/plugins/dartdoc/plugin.dart';
import 'package:dash_bot/plugins/status.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

const botPrefixEnv = 'BOT_PREFIX';
const botTokenEnv = 'BOT_TOKEN';

void main() async {
  final botToken = Platform.environment[botTokenEnv];
  if (botToken == null) {
    throw Exception(
      'A Discord bot token must be provided using the $botTokenEnv environment'
      ' variable',
    );
  }

  final botPrefix = Platform.environment[botPrefixEnv];

  final commands = CommandsPlugin(
    prefix: botPrefix == null ? null : (_) => botPrefix,
  );

  commands
    ..addConverter(await createLinterRuleConverter())
    ..addCommand(showLint)
    ..addCommand(ping);

  await Nyxx.connectGateway(
    botToken,
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
