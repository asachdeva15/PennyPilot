// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comprehensive_yearly_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ComprehensiveYearlyDataImpl _$$ComprehensiveYearlyDataImplFromJson(
        Map<String, dynamic> json) =>
    _$ComprehensiveYearlyDataImpl(
      year: (json['year'] as num).toInt(),
      yearlyData:
          YearlyData.fromJson(json['yearlyData'] as Map<String, dynamic>),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$$ComprehensiveYearlyDataImplToJson(
        _$ComprehensiveYearlyDataImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'yearlyData': instance.yearlyData,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
