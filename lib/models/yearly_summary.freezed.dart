// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'yearly_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

YearlySummary _$YearlySummaryFromJson(Map<String, dynamic> json) {
  return _YearlySummary.fromJson(json);
}

/// @nodoc
mixin _$YearlySummary {
  int get year => throw _privateConstructorUsedError;

  /// Total income for the year (positive values)
  double get totalIncome => throw _privateConstructorUsedError;

  /// Total expenses for the year (positive values, although expenses are negative in transactions)
  double get totalExpenses => throw _privateConstructorUsedError;

  /// Total savings for the year (income - expenses)
  double get totalSavings => throw _privateConstructorUsedError;

  /// Total spending by category for the year
  Map<String, double> get categoryTotals => throw _privateConstructorUsedError;

  /// Number of transactions in this year
  int get transactionCount => throw _privateConstructorUsedError;

  /// The last updated timestamp
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Serializes this YearlySummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of YearlySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $YearlySummaryCopyWith<YearlySummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $YearlySummaryCopyWith<$Res> {
  factory $YearlySummaryCopyWith(
          YearlySummary value, $Res Function(YearlySummary) then) =
      _$YearlySummaryCopyWithImpl<$Res, YearlySummary>;
  @useResult
  $Res call(
      {int year,
      double totalIncome,
      double totalExpenses,
      double totalSavings,
      Map<String, double> categoryTotals,
      int transactionCount,
      DateTime? lastUpdated});
}

/// @nodoc
class _$YearlySummaryCopyWithImpl<$Res, $Val extends YearlySummary>
    implements $YearlySummaryCopyWith<$Res> {
  _$YearlySummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of YearlySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? totalSavings = null,
    Object? categoryTotals = null,
    Object? transactionCount = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_value.copyWith(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      totalIncome: null == totalIncome
          ? _value.totalIncome
          : totalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      totalExpenses: null == totalExpenses
          ? _value.totalExpenses
          : totalExpenses // ignore: cast_nullable_to_non_nullable
              as double,
      totalSavings: null == totalSavings
          ? _value.totalSavings
          : totalSavings // ignore: cast_nullable_to_non_nullable
              as double,
      categoryTotals: null == categoryTotals
          ? _value.categoryTotals
          : categoryTotals // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      transactionCount: null == transactionCount
          ? _value.transactionCount
          : transactionCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$YearlySummaryImplCopyWith<$Res>
    implements $YearlySummaryCopyWith<$Res> {
  factory _$$YearlySummaryImplCopyWith(
          _$YearlySummaryImpl value, $Res Function(_$YearlySummaryImpl) then) =
      __$$YearlySummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int year,
      double totalIncome,
      double totalExpenses,
      double totalSavings,
      Map<String, double> categoryTotals,
      int transactionCount,
      DateTime? lastUpdated});
}

/// @nodoc
class __$$YearlySummaryImplCopyWithImpl<$Res>
    extends _$YearlySummaryCopyWithImpl<$Res, _$YearlySummaryImpl>
    implements _$$YearlySummaryImplCopyWith<$Res> {
  __$$YearlySummaryImplCopyWithImpl(
      _$YearlySummaryImpl _value, $Res Function(_$YearlySummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of YearlySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? totalSavings = null,
    Object? categoryTotals = null,
    Object? transactionCount = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(_$YearlySummaryImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      totalIncome: null == totalIncome
          ? _value.totalIncome
          : totalIncome // ignore: cast_nullable_to_non_nullable
              as double,
      totalExpenses: null == totalExpenses
          ? _value.totalExpenses
          : totalExpenses // ignore: cast_nullable_to_non_nullable
              as double,
      totalSavings: null == totalSavings
          ? _value.totalSavings
          : totalSavings // ignore: cast_nullable_to_non_nullable
              as double,
      categoryTotals: null == categoryTotals
          ? _value._categoryTotals
          : categoryTotals // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      transactionCount: null == transactionCount
          ? _value.transactionCount
          : transactionCount // ignore: cast_nullable_to_non_nullable
              as int,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$YearlySummaryImpl extends _YearlySummary {
  const _$YearlySummaryImpl(
      {required this.year,
      this.totalIncome = 0.0,
      this.totalExpenses = 0.0,
      this.totalSavings = 0.0,
      final Map<String, double> categoryTotals = const {},
      this.transactionCount = 0,
      this.lastUpdated})
      : _categoryTotals = categoryTotals,
        super._();

  factory _$YearlySummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$YearlySummaryImplFromJson(json);

  @override
  final int year;

  /// Total income for the year (positive values)
  @override
  @JsonKey()
  final double totalIncome;

  /// Total expenses for the year (positive values, although expenses are negative in transactions)
  @override
  @JsonKey()
  final double totalExpenses;

  /// Total savings for the year (income - expenses)
  @override
  @JsonKey()
  final double totalSavings;

  /// Total spending by category for the year
  final Map<String, double> _categoryTotals;

  /// Total spending by category for the year
  @override
  @JsonKey()
  Map<String, double> get categoryTotals {
    if (_categoryTotals is EqualUnmodifiableMapView) return _categoryTotals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryTotals);
  }

  /// Number of transactions in this year
  @override
  @JsonKey()
  final int transactionCount;

  /// The last updated timestamp
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'YearlySummary(year: $year, totalIncome: $totalIncome, totalExpenses: $totalExpenses, totalSavings: $totalSavings, categoryTotals: $categoryTotals, transactionCount: $transactionCount, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YearlySummaryImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.totalSavings, totalSavings) ||
                other.totalSavings == totalSavings) &&
            const DeepCollectionEquality()
                .equals(other._categoryTotals, _categoryTotals) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      year,
      totalIncome,
      totalExpenses,
      totalSavings,
      const DeepCollectionEquality().hash(_categoryTotals),
      transactionCount,
      lastUpdated);

  /// Create a copy of YearlySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$YearlySummaryImplCopyWith<_$YearlySummaryImpl> get copyWith =>
      __$$YearlySummaryImplCopyWithImpl<_$YearlySummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$YearlySummaryImplToJson(
      this,
    );
  }
}

abstract class _YearlySummary extends YearlySummary {
  const factory _YearlySummary(
      {required final int year,
      final double totalIncome,
      final double totalExpenses,
      final double totalSavings,
      final Map<String, double> categoryTotals,
      final int transactionCount,
      final DateTime? lastUpdated}) = _$YearlySummaryImpl;
  const _YearlySummary._() : super._();

  factory _YearlySummary.fromJson(Map<String, dynamic> json) =
      _$YearlySummaryImpl.fromJson;

  @override
  int get year;

  /// Total income for the year (positive values)
  @override
  double get totalIncome;

  /// Total expenses for the year (positive values, although expenses are negative in transactions)
  @override
  double get totalExpenses;

  /// Total savings for the year (income - expenses)
  @override
  double get totalSavings;

  /// Total spending by category for the year
  @override
  Map<String, double> get categoryTotals;

  /// Number of transactions in this year
  @override
  int get transactionCount;

  /// The last updated timestamp
  @override
  DateTime? get lastUpdated;

  /// Create a copy of YearlySummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$YearlySummaryImplCopyWith<_$YearlySummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
