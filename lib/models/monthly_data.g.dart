// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MonthlyDataImpl _$$MonthlyDataImplFromJson(Map<String, dynamic> json) =>
    _$MonthlyDataImpl(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      summary: MonthlySummary.fromJson(json['summary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MonthlyDataImplToJson(_$MonthlyDataImpl instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'transactions': instance.transactions,
      'summary': instance.summary,
    };
