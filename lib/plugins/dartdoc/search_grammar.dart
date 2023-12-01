import 'package:petitparser/petitparser.dart';

import 'plugin.dart';

/// Parsed information about a search made for the [DartdocSearch] plugin.
class Search {
  /// The package this search is in, if this search is a search for an element.
  final String? package;

  /// The name being searched for.
  final String name;

  /// The type of this search.
  final SearchKind kind;

  /// Create a new [Search].
  const Search({required this.package, required this.name, required this.kind});

  @override
  String toString() => 'Search(kind: $kind, package: $package, name: $name)';
}

/// The type of a search.
enum SearchKind {
  /// A search for a single element in a package.
  elementLookup('!', true),

  /// A search for multiple elements in a package.
  elementSearch('?', true),

  /// A search for a single package on https://pub.dev.
  packageLookup(r'$', false),

  /// A search for multiple packages on https://pub.dev.
  packageSearch('&', false);

  /// Whether [Search]es of this type have a [Search.package].
  final bool hasPackage;

  /// The symbol used to trigger this search type.
  final String symbol;

  const SearchKind(this.symbol, this.hasPackage);
}

/// The grammar that describes searches made for [DartdocSearch] in a [String].
class SearchGrammar extends GrammarDefinition<List<Search>> {
  @override
  Parser<List<Search>> start() =>
      (ref1(search, true) | ref1(search, false) | any())
          .star()
          .map((matches) => matches.whereType<Search>().toList());

  /// Return a parser for a single search.
  ///
  /// If [withPackage] is `true`, the returned parser will only parse searches
  /// where [SearchKind.hasPackage] is `true`. Otherwise, it will only parse
  /// searches where [SearchKind.hasPackage] is `false`.
  Parser<Search> search(bool withPackage) => SequenceParser([
        // Search kind
        ref1(searchKind, withPackage),
        char('['),
        // Package prefix if available
        if (withPackage)
          SequenceParser([ref0(packageName), char('/')]).pick(0).optional(),

        // Package or element name
        // [withPackage] is false if the search itself is a package, so we only
        // allow package names here.
        if (withPackage) ref0(elementName) else ref0(packageName),
        char(']'),
      ]).map((value) => Search(
            kind: value[0]! as SearchKind,
            package: withPackage ? (value[2] as String?) ?? 'flutter' : null,
            name: (withPackage ? value[3] : value[2])! as String,
          ));

  /// Returns a parser that parses the name of a package.
  Parser<String> packageName() =>
      ChoiceParser([letter(), digit(), char('_')]).plusString();

  /// Returns a parser that parses the name of an element.
  Parser<String> elementName() => ChoiceParser([
        SequenceParser([char('['), ref0(elementName), char(']')]).flatten(),
        (char('[') | char(']')).neg(),
      ]).plusString();

  /// Returns a parser that parses [SearchKind]s based on [SearchKind.symbol].
  ///
  /// If [withPackage] is `true`, the returned parser will only parse
  /// [SearchKind]s where [SearchKind.hasPackage] is `true`. Otherwise, it will
  /// only parse [SearchKind]s where [SearchKind.hasPackage] is `false`.
  Parser<SearchKind> searchKind(bool withPackage) => ChoiceParser([
        for (final kind in SearchKind.values.where(
          (kind) => kind.hasPackage == withPackage,
        ))
          char(kind.symbol).map(
            (symbol) => SearchKind.values.singleWhere(
              (kind) => kind.symbol == symbol,
            ),
          )
      ]);
}
