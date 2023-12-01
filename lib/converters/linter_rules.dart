import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

part 'linter_rules.g.dart';

/// Creates a converter for lint rules from https://dart.dev/tools/linter-rules.
Future<SimpleConverter<LinterRule>> createLinterRuleConverter() async {
  return SimpleConverter.fixed(
    elements: await _fetchLinterRules(),
    stringify: (rule) => rule.name,
  );
}

Future<List<LinterRule>> _fetchLinterRules() async {
  final url = Uri.https(
    'raw.githubusercontent.com',
    '/dart-lang/site-www/main/src/_data/linter_rules.json',
  );

  final data = await http.runWithClient(
    () => http.get(url),
    () => RetryClient(
      http.Client(),
      retries: 3,
      when: (response) => response.statusCode != 200,
    ),
  );

  // If we didn't successfully get the linter rules,
  // fall back to an empty list.
  if (data.statusCode != 200) {
    return [];
  }

  return (jsonDecode(utf8.decode(data.bodyBytes)) as List)
      .cast<Map<String, Object?>>()
      .map(LinterRule.fromJson)
      .toList(growable: false);
}

/// Information about a Dart linter rule.
@JsonSerializable(createToJson: false)
class LinterRule {
  /// The name of this rule.
  final String name;

  /// A description of this rule.
  final String description;

  /// The type of rule this is.
  ///
  /// Can be one of "errors", "pub" or "style".
  final String group;

  /// The current state of this rule.
  ///
  /// Can be one of "stable", "deprecated", "experimental" or "removed".
  final String state;

  /// A list of the names of other linter rules this rule is incompatible with.
  final List<String> incompatible;

  /// A list of pre-defined rule sets this rule belongs to.
  ///
  /// Can contain "core", "recommended" and "flutter".
  final List<String> sets;

  /// Whether this lint rule has a quick fix available.
  ///
  /// Can be one of "hasFix", "noFix", "needsFix", "needsEvaluation", or
  /// "unregistered".
  final String fixStatus;

  /// A longer explanation of what this rule does and why it exists.
  ///
  /// Can contain code samples, motivation or simply further details in markdown
  /// format.
  final String details;

  /// The version of Dart in which this rule was created.
  final String sinceDartSdk;

  /// Create a new [LinterRule].
  LinterRule({
    required this.name,
    required this.description,
    required this.group,
    required this.state,
    required this.incompatible,
    required this.sets,
    required this.fixStatus,
    required this.details,
    required this.sinceDartSdk,
  });

  /// Parse a [LinterRule] from a JSON map.
  factory LinterRule.fromJson(Map<String, Object?> json) =>
      _$LinterRuleFromJson(json);
}
