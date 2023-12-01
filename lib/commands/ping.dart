import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

/// Displays the client's latency metrics. Can be used as a simple connectivity
/// test.
final ping = ChatCommand(
  'ping',
  'Check the bot is online',
  id('ping', (ChatContext context) async {
    String formatDuration(Duration d) {
      final ms = d.inMicroseconds / Duration.microsecondsPerMillisecond;
      return '${ms.toStringAsFixed(3)}ms';
    }

    final http = formatDuration(context.client.httpHandler.latency);
    final gateway = formatDuration(context.client.gateway.latency);

    await context.respond(
      MessageBuilder(content: 'Pong!\n*HTTP: $http, Gateway: $gateway*'),
    );
  }),
);
