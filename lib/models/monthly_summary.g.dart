// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MonthlySummaryImpl _$$MonthlySummaryImplFromJson(Map<String, dynamic> json) =>
    _$MonthlySummaryImpl(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (json['totalSavings'] as num?)?.toDouble() ?? 0.0,
      categoryTotals: (json['categoryTotals'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MonthlySummaryImplToJson(
        _$MonthlySummaryImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'totalIncome': instance.totalIncome,
      'totalExpenses': instance.totalExpenses,
      'totalSavings': instance.totalSavings,
      'categoryTotals': instance.categoryTotals,
      'transactionCount': instance.transactionCount,
    };
