import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import 'transaction.dart';
import 'monthly_summary.dart';
import 'yearly_summary.dart';
import 'yearly_data.dart';
import 'monthly_data.dart';

part 'comprehensive_yearly_data.freezed.dart';
part 'comprehensive_yearly_data.g.dart';

/// Comprehensive data structure that combines yearly data and additional metadata
@freezed
class ComprehensiveYearlyData with _$ComprehensiveYearlyData {
  const factory ComprehensiveYearlyData({
    required int year,
    required YearlyData yearlyData,
    required DateTime generatedAt,
  }) = _ComprehensiveYearlyData;

  factory ComprehensiveYearlyData.fromJson(Map<String, dynamic> json) => 
      _$ComprehensiveYearlyDataFromJson(json);

  /// Generates comprehensive yearly data from YearlyData
  static ComprehensiveYearlyData generateFromYearlyData(
    YearlyData yearlyData,
  ) {
    return ComprehensiveYearlyData(
      year: yearlyData.year,
      yearlyData: yearlyData,
      generatedAt: DateTime.now(),
    );
  }
} 