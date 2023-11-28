import 'package:json_annotation/json_annotation.dart';

part 'dartdoc_entry.g.dart';

/// An element in a public API documented by dartdoc.
///
/// Corresponds to the objects in the `index.json` file of a dartdoc website.
@JsonSerializable(createToJson: false)
class DartdocEntry {
  /// The name of this entry.
  final String name;

  /// The fully qualified name of this entry.
  @JsonKey(name: 'qualifiedName')
  final String qualifiedName;

  /// The location of the documentation page for this entry.
  final String href;

  /// The type of this entity.
  ///
  /// {@template element_type}
  /// See https://pub.dev/documentation/dartdoc/latest/dartdoc/Kind.html for a
  /// list of possible values.
  /// {@endtemplate}
  @JsonKey(fromJson: _typeFromJson, name: 'kind')
  final String type;

  /// A short description of this entry.
  @JsonKey(name: 'desc')
  final String description;

  /// The element that encloses the element this entry describes.
  @JsonKey(required: false, name: 'enclosedBy')
  final DartdocEnclosedBy? enclosedBy;

  /// Create a new [DartdocEntry].
  DartdocEntry({
    required this.name,
    required this.qualifiedName,
    required this.href,
    required this.type,
    required this.description,
    required this.enclosedBy,
  });

  /// Parse a [DartdocEntry] from a JSON map.
  factory DartdocEntry.fromJson(Map<String, dynamic> json) =>
      _$DartdocEntryFromJson(json);
}

/// Information about the enclosing element of a [DartdocEntry].
@JsonSerializable(createToJson: false)
class DartdocEnclosedBy {
  /// The name of this element.
  final String name;

  /// The type of this element.
  ///
  /// {@macro element_type}
  @JsonKey(fromJson: _typeFromJson, name: 'kind')
  final String type;

  /// Create a new [DartdocEnclosedBy].
  DartdocEnclosedBy({
    required this.name,
    required this.type,
  });

  /// Parse a [DartdocEnclosedBy] from a JSON map.
  factory DartdocEnclosedBy.fromJson(Map<String, dynamic> json) =>
      _$DartdocEnclosedByFromJson(json);
}

String _typeFromJson(int kind) {
  const types = [
    // https://pub.dev/documentation/dartdoc/latest/dartdoc/Kind.html
    'accessor',
    'constant',
    'constructor',
    'class',
    'dynamic',
    'enum',
    'extension',
    'extensionType',
    'function',
    'library',
    'method',
    'mixin',
    'never',
    'package',
    'parameter',
    'prefix',
    'property',
    'sdk',
    'topic',
    'topLevelConstant',
    'topLevelProperty',
    'typedef',
    'typeParameter',
  ];

  if (kind >= 0 && kind < types.length) {
    return types[kind];
  }

  return 'unknown';
}
