// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yearly_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$YearlyDataImpl _$$YearlyDataImplFromJson(Map<String, dynamic> json) =>
    _$YearlyDataImpl(
      year: (json['year'] as num).toInt(),
      months: (json['months'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                int.parse(k), MonthlyData.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      summary: YearlySummary.fromJson(json['summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$YearlyDataImplToJson(_$YearlyDataImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'months': instance.months.map((k, e) => MapEntry(k.toString(), e)),
      'summary': instance.summary,
    };
