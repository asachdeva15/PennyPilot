// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yearly_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$YearlySummaryImpl _$$YearlySummaryImplFromJson(Map<String, dynamic> json) =>
    _$YearlySummaryImpl(
      year: (json['year'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (json['totalSavings'] as num?)?.toDouble() ?? 0.0,
      categoryTotals: (json['categoryTotals'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$YearlySummaryImplToJson(_$YearlySummaryImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'totalIncome': instance.totalIncome,
      'totalExpenses': instance.totalExpenses,
      'totalSavings': instance.totalSavings,
      'categoryTotals': instance.categoryTotals,
      'transactionCount': instance.transactionCount,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
