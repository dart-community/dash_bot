// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linter_rules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinterRule _$LinterRuleFromJson(Map<String, dynamic> json) => LinterRule(
      name: json['name'] as String,
      description: json['description'] as String,
      group: json['group'] as String,
      state: json['state'] as String,
      incompatible: (json['incompatible'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sets: (json['sets'] as List<dynamic>).map((e) => e as String).toList(),
      fixStatus: json['fixStatus'] as String,
      details: json['details'] as String,
      sinceDartSdk: json['sinceDartSdk'] as String,
    );
