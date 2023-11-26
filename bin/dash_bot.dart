import 'dart:io';

import 'package:dash_bot/commands/show_lint.dart';
import 'package:dash_bot/converters/linter_rules.dart';
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
    ..addCommand(showLint);

  Flags<GatewayIntents> intents = GatewayIntents.allUnprivileged;
  if (hasPrefix) {
    intents |= GatewayIntents.messageContent;
  }

  await Nyxx.connectGateway(
    Platform.environment['TOKEN']!,
    intents,
    options: GatewayClientOptions(plugins: [
      logging,
      cliIntegration,
      commands,
      pagination,
    ]),
  );
}
