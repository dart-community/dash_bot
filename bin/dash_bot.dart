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
    // We have our own error handler that logs errors
    options: const CommandsOptions(logErrors: false),
  );

  commands
    ..addConverter(await createLinterRuleConverter())
    ..addCommand(showLint)
    ..addCommand(ping);

  pagination.onDisallowedUse.listen((event) async {
    await event.interaction.respond(
      isEphemeral: true,
      MessageBuilder(
        content: 'Sorry, changing pages is reserved for the user who ran the'
            ' command. Run the same command yourself if you want to paginate'
            ' through the output.',
      ),
    );
  });

  pagination.onUnhandledInteraction.listen((event) async {
    await event.interaction.respond(
      isEphemeral: true,
      MessageBuilder(
        content: 'Sorry, these controls no longer work. Run the command again'
            ' to get working controls.',
      ),
    );
  });

  commands.onCommandError.listen((error) async {
    // Check the error was thrown from a context we can respond to
    // (an `InteractiveContext`).
    if (error case ContextualException(:final InteractiveContext context)) {
      if (error is BadInputException) {
        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(
            content:
                'Invalid input. Check your command arguments and try again.',
          ),
        );
      } else if (error is UnhandledInteractionException) {
        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(
            content: 'Sorry, this component no longer works.'
                ' Try running the command again.',
          ),
        );
      } else if (error is CheckFailedException) {
        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(
            content: "Sorry, you can't use this command right now.",
          ),
        );
      } else if (error is UncaughtException) {
        final exception = error.exception;

        // TODO(abitofevrything): Add specific responses for specific errors as
        // we encounter them.

        await context.respond(
          level: ResponseLevel.hint,
          MessageBuilder(
            content: 'An unknown error occurred while running your command.'
                ' Try running the command again.',
          ),
        );

        commands.logger.shout(
          'Unhandled user-facing exception',
          exception,
          error.stackTrace,
        );
      }
    } else {
      commands.logger.warning('Unhandled exception', error, error.stackTrace);
    }
  });

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
