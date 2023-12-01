import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:recase/recase.dart';

import '../converters/linter_rules.dart';

/// Renders information about a lint, similar to the pages at
/// https://dart.dev/tools/linter-rules, to a Discord channel.
final showLint = ChatCommand(
  'show-lint',
  'Shows information about a lint rule',
  id('show-lint', (ChatContext context, LinterRule rule) async {
    final buffer = StringBuffer();

    buffer.writeln('## ${rule.name}');

    final tags = [
      ...rule.sets,
      if (rule.fixStatus == 'hasFix') 'Has Fix',
      if (rule.state != 'stable') rule.state.titleCase,
    ];
    if (tags.isNotEmpty) {
      buffer
        ..write('**')
        ..write(tags.map((e) => '[$e]').join(' '))
        ..writeln('**');
    }

    buffer
      ..writeln()
      ..writeln(rule.description)
      ..writeln()
      ..writeln('*Available since: ${rule.sinceDartSdk}*');
    if (rule.incompatible.isNotEmpty) {
      buffer.writeln('*Incompatible with: ${rule.incompatible.join(', ')}*');
    }

    buffer
      ..writeln('### Details')
      ..writeln(rule.details);

    final content = buffer.toString();
    // Maximum length of a single message is 2000.
    if (content.length < 2000) {
      await context.respond(MessageBuilder(content: content));
    } else {
      await context.respond(await pagination.split(
        content,
        userId: context.user.id,
      ));
    }
  }),
);
