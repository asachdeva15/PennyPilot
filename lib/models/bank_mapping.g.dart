// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BankMapping _$BankMappingFromJson(Map<String, dynamic> json) => BankMapping(
      bankName: json['bankName'] as String,
      headerRowIndex: (json['headerRowIndex'] as num).toInt(),
      dateColumn: json['dateColumn'] as String?,
      descriptionColumn: json['descriptionColumn'] as String?,
      amountColumn: json['amountColumn'] as String?,
      debitColumn: json['debitColumn'] as String?,
      creditColumn: json['creditColumn'] as String?,
      delimiter: json['delimiter'] as String?,
      dateFormatType:
          $enumDecodeNullable(_$DateFormatTypeEnumMap, json['dateFormatType']),
      amountMappingType: $enumDecodeNullable(
              _$AmountMappingTypeEnumMap, json['amountMappingType']) ??
          AmountMappingType.single,
    );

Map<String, dynamic> _$BankMappingToJson(BankMapping instance) =>
    <String, dynamic>{
      'bankName': instance.bankName,
      'headerRowIndex': instance.headerRowIndex,
      'dateColumn': instance.dateColumn,
      'descriptionColumn': instance.descriptionColumn,
      'amountColumn': instance.amountColumn,
      'debitColumn': instance.debitColumn,
      'creditColumn': instance.creditColumn,
      'delimiter': instance.delimiter,
      'dateFormatType': _$DateFormatTypeEnumMap[instance.dateFormatType],
      'amountMappingType':
          _$AmountMappingTypeEnumMap[instance.amountMappingType]!,
    };

const _$DateFormatTypeEnumMap = {
  DateFormatType.iso: 'iso',
  DateFormatType.mmddyyyy: 'mmddyyyy',
  DateFormatType.ddmmyyyy: 'ddmmyyyy',
  DateFormatType.yyyymmdd: 'yyyymmdd',
};

const _$AmountMappingTypeEnumMap = {
  AmountMappingType.single: 'single',
  AmountMappingType.separate: 'separate',
};
