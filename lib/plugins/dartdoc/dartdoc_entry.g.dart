// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dartdoc_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DartdocEntry _$DartdocEntryFromJson(Map<String, dynamic> json) => DartdocEntry(
      name: json['name'] as String,
      qualifiedName: json['qualifiedName'] as String,
      href: json['href'] as String,
      type: _typeFromJson((json['kind'] as num).toInt()),
      description: json['desc'] as String,
      enclosedBy: json['enclosedBy'] == null
          ? null
          : DartdocEnclosedBy.fromJson(
              json['enclosedBy'] as Map<String, dynamic>),
    );

DartdocEnclosedBy _$DartdocEnclosedByFromJson(Map<String, dynamic> json) =>
    DartdocEnclosedBy(
      name: json['name'] as String,
      type: _typeFromJson((json['kind'] as num).toInt()),
    );
