import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:petitparser/petitparser.dart';

import 'dartdoc_entry.dart';
import 'search_grammar.dart';

/// Returns the Levenshtein distance between two [String]s.
///
/// Adapted from https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
int _lehvenstein(String s, String t) {
  final m = s.length;
  final n = t.length;

  var v0 = Uint8ClampedList(n + 1);
  var v1 = Uint8ClampedList(n + 1);

  for (var i = 0; i <= n; i++) {
    v0[i] = i;
  }

  for (var i = 0; i <= m - 1; i++) {
    var previousV1 = v1[0] = i + 1;
    var previousV0 = v0[0];

    for (var j = 0; j <= n - 1; j++) {
      var substitutionCost = previousV0 + 1;
      if (s[i] == t[j]) {
        substitutionCost--;
      }

      previousV0 = v0[j + 1];

      final deletionCost = previousV0;
      final insertionCost = previousV1;

      var minInsertionDeletion =
          deletionCost < insertionCost ? deletionCost : insertionCost;
      minInsertionDeletion++;

      final overallMin = substitutionCost < minInsertionDeletion
          ? substitutionCost
          : minInsertionDeletion;

      previousV1 = overallMin;
      v1[j + 1] = previousV1;
    }

    (v0, v1) = (v1, v0);
  }

  return v0[n];
}

/// Listens for search requests in messages sent in a Discord channel, processes
/// them, and sends the results back to the channel.
///
/// Searches can be embedded in any text message and their syntax is as follows:
/// - `![Name]` or `![package/Name]`: Return the documentation for `Name` in
///   Flutter's or `package`'s API documentation.
/// - `?[Name]` or `?[package/Name]`: Search for `Name` in Flutter's or
///   `package`'s API documentation.
/// - `\$[name]`: Return the pub.dev page for the package `name`.
/// - `&[name]`: Search pub.dev for `name`.
class DartdocSearch extends NyxxPlugin<NyxxGateway> {
  /// The time after which cached documentation entries are considered to have
  /// expired and require refreshing.
  static const expireDuration = Duration(hours: 1);

  @override
  String get name => 'DartdocSearch';

  final _documentationCache = <String, (DateTime, List<DartdocEntry>)>{};
  late final Timer _flutterCacheTimer;

  /// Create a new [DartdocSearch] and begin populating the documentation cache
  /// with Flutter's documentation.
  DartdocSearch() {
    // Fetching the flutter cache index takes quite a long time (as it is a very
    // large package) and it is probably the most commonly used package, so we
    // eagerly update the cache before it expires.
    //
    // Other packages are fetched and updated as needed.
    _flutterCacheTimer = Timer.periodic(
      expireDuration * 0.9,
      (_) => unawaited(getEntries('flutter')),
    );

    // Kick off an initial load immediately
    unawaited(getEntries('flutter'));
  }

  /// Return a record of `(url, entries)` for the given `package`.
  ///
  /// `url` is the URL relative to which the [DartdocEntry.href] should be
  /// resolved.
  /// `entries` is a list of [DartdocEntry] in the package's documentation.
  Future<(String, List<DartdocEntry>)> getEntries(String package) async {
    final trimmedPackage = package.toLowerCase().trim();
    final now = DateTime.timestamp();

    final urlBase = trimmedPackage == 'flutter' || trimmedPackage == 'dart'
        ? 'https://api.flutter.dev/flutter/'
        : 'https://pub.dev/documentation/$trimmedPackage/latest/';

    if (_documentationCache[trimmedPackage] case (final time, final entries)
        when time.isAfter(now.add(-expireDuration))) {
      return (urlBase, entries);
    }

    final url = '${urlBase}index.json';

    logger.info('Updating documentation cache for $trimmedPackage');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return (urlBase, const <DartdocEntry>[]);

    final content = jsonDecode(utf8.decode(response.bodyBytes)) as List;

    final entries = [
      for (final map in content.cast<Map<String, dynamic>>())
        if (!map.containsKey('__PACKAGE_ORDER__')) DartdocEntry.fromJson(map),
    ];

    _documentationCache[trimmedPackage] = (now, entries);
    return (urlBase, entries);
  }

  final _searchCache = <String, (DateTime, List<String>)>{};

  /// Search for packages based on [query] on https://pub.dev.
  Future<List<String>> searchPackages(String query) async {
    final trimmedQuery = query.toLowerCase().trim();

    // Most common case.
    if (trimmedQuery == 'flutter') return ['flutter'];

    // A cache isn't really needed here (since the most common case by far is
    // hard coded above) but it avoids triggering multiple requests when a
    // package's documentation is referenced multiple times in one message.
    final now = DateTime.timestamp();
    if (_searchCache[trimmedQuery] case (final time, final packages)
        when time.isAfter(now.add(-expireDuration))) {
      return packages;
    }

    final response = await http.get(
      Uri.https('pub.dev', '/api/search', {'q': trimmedQuery}),
    );
    if (response.statusCode != 200) return const [];

    final content = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    final results = (content['packages'] as List)
        .cast<Map<String, Object?>>()
        .map((e) => e['package'] as String)
        .toList(growable: false);

    _searchCache[trimmedQuery] = (now, results);
    return results;
  }

  /// Returns a list containing the same elements as [entries], but sorting
  /// according to how relevant they are to [query].
  ///
  /// Elements most relevant to [query] appear first in the returned list.
  Future<List<DartdocEntry>> sortByQuery(
    String query,
    List<DartdocEntry> entries, {
    required bool byName,
  }) {
    return Isolate.run(() {
      final results = List.of(entries.map(
        (e) => (
          _lehvenstein(
            query,
            (byName ? e.name : e.qualifiedName).toLowerCase(),
          ),
          e,
        ),
      ));

      double getWeight(String type) => switch (type) {
            // Make classes more likely to appear than constructors or
            // libraries with the same name.
            'class' => 1.1,
            _ => 1,
          };

      // +1 so that exact matches (distance of 0) still get weighted.
      results.sort(
        (a, b) => ((a.$1 + 1) / getWeight(a.$2.type))
            .compareTo((b.$1 + 1) / getWeight(b.$2.type)),
      );
      return List.of(results.map((e) => e.$2));
    });
  }

  @override
  void afterConnect(NyxxGateway client) {
    final parser = SearchGrammar().build<List<Search>>();

    Future<void> handle(Search search, MessageCreateEvent event) async {
      switch (search.kind) {
        case SearchKind.elementLookup:
        case SearchKind.elementSearch:
          final matchingPackages = await searchPackages(search.package!);

          if (matchingPackages.isEmpty) {
            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              embeds: [
                EmbedBuilder(
                  color: const DiscordColor.fromRgb(255, 0, 0),
                  title: 'Package Not Found',
                  description: search.package!,
                ),
              ],
            ));
            break;
          }

          final package = matchingPackages.first;

          final (urlBase, entries) = await getEntries(package);

          final useNamePattern = RegExp(r'^([A-Za-z$_A-Za-z0-9$_]*?)$');
          final query = search.name;
          final byName = useNamePattern.hasMatch(search.name);

          final results = await sortByQuery(
            query.toLowerCase(),
            entries,
            byName: byName,
          );

          if (results.isEmpty) {
            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              embeds: [
                EmbedBuilder(
                  color: const DiscordColor.fromRgb(255, 0, 0),
                  title: 'Not Found',
                  description: search.name,
                ),
              ],
            ));
            break;
          }

          if (search.kind == SearchKind.elementLookup) {
            final topEntry = results.first;

            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              content: '$urlBase${topEntry.href}',
            ));
          } else {
            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              embeds: [
                EmbedBuilder(
                  title: 'Pub Search Results - ${search.name}',
                  fields: [
                    for (final result in results)
                      EmbedFieldBuilder(
                        name: '${result.type} ${result.name} '
                            '- ${result.enclosedBy?.type ?? package}',
                        value: '$urlBase${result.href}',
                        isInline: false,
                      ),
                  ],
                ),
              ],
            ));
          }
        case SearchKind.packageLookup:
        case SearchKind.packageSearch:
          final results = await searchPackages(search.name);

          if (results.isEmpty) {
            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              embeds: [
                EmbedBuilder(
                  color: const DiscordColor.fromRgb(255, 0, 0),
                  title: 'Not Found',
                  description: search.name,
                ),
              ],
            ));
            break;
          }

          if (search.kind == SearchKind.packageLookup) {
            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              content: 'https://pub.dev/packages/${results.first}',
            ));
          } else {
            await event.message.channel.sendMessage(MessageBuilder(
              replyId: event.message.id,
              allowedMentions: AllowedMentions(repliedUser: false),
              embeds: [
                EmbedBuilder(
                  title: 'Pub Search Results - ${search.name}',
                  fields: [
                    for (final result in results.take(10))
                      EmbedFieldBuilder(
                        name: result,
                        value: 'https://pub.dev/packages/$result',
                        isInline: false,
                      ),
                  ],
                ),
              ],
            ));
          }
      }
    }

    client.onMessageCreate.listen((event) async {
      if (parser.parse(event.message.content) case Success(:final value)) {
        for (final search in value) {
          if (event.message.author case User(isBot: false)) {
            await handle(search, event);
          }
        }
      }
    });
  }

  @override
  void afterClose() {
    _flutterCacheTimer.cancel();
  }
}
