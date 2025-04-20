// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monthly_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) {
  return _MonthlySummary.fromJson(json);
}

/// @nodoc
mixin _$MonthlySummary {
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError;

  /// Total income for the month (positive values)
  double get totalIncome => throw _privateConstructorUsedError;

  /// Total expenses for the month (positive values, although expenses are negative in transactions)
  double get totalExpenses => throw _privateConstructorUsedError;

  /// Total savings for the month (income - expenses)
  double get totalSavings => throw _privateConstructorUsedError;

  /// Total spending by category
  Map<String, double> get categoryTotals => throw _privateConstructorUsedError;

  /// Number of transactions in this month
  int get transactionCount => throw _privateConstructorUsedError;

  /// Serializes this MonthlySummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonthlySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlySummaryCopyWith<MonthlySummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlySummaryCopyWith<$Res> {
  factory $MonthlySummaryCopyWith(
          MonthlySummary value, $Res Function(MonthlySummary) then) =
      _$MonthlySummaryCopyWithImpl<$Res, MonthlySummary>;
  @useResult
  $Res call(
      {int year,
      int month,
      double totalIncome,
      double totalExpenses,
      double totalSavings,
      Map<String, double> categoryTotals,
      int transactionCount});
}

/// @nodoc
class _$MonthlySummaryCopyWithImpl<$Res, $Val extends MonthlySummary>
    implements $MonthlySummaryCopyWith<$Res> {
  _$MonthlySummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? totalSavings = null,
    Object? categoryTotals = null,
    Object? transactionCount = null,
  }) {
    return _then(_value.copyWith(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MonthlySummaryImplCopyWith<$Res>
    implements $MonthlySummaryCopyWith<$Res> {
  factory _$$MonthlySummaryImplCopyWith(_$MonthlySummaryImpl value,
          $Res Function(_$MonthlySummaryImpl) then) =
      __$$MonthlySummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int year,
      int month,
      double totalIncome,
      double totalExpenses,
      double totalSavings,
      Map<String, double> categoryTotals,
      int transactionCount});
}

/// @nodoc
class __$$MonthlySummaryImplCopyWithImpl<$Res>
    extends _$MonthlySummaryCopyWithImpl<$Res, _$MonthlySummaryImpl>
    implements _$$MonthlySummaryImplCopyWith<$Res> {
  __$$MonthlySummaryImplCopyWithImpl(
      _$MonthlySummaryImpl _value, $Res Function(_$MonthlySummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of MonthlySummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? totalSavings = null,
    Object? categoryTotals = null,
    Object? transactionCount = null,
  }) {
    return _then(_$MonthlySummaryImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MonthlySummaryImpl extends _MonthlySummary {
  const _$MonthlySummaryImpl(
      {required this.year,
      required this.month,
      this.totalIncome = 0.0,
      this.totalExpenses = 0.0,
      this.totalSavings = 0.0,
      final Map<String, double> categoryTotals = const {},
      this.transactionCount = 0})
      : _categoryTotals = categoryTotals,
        super._();

  factory _$MonthlySummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlySummaryImplFromJson(json);

  @override
  final int year;
  @override
  final int month;

  /// Total income for the month (positive values)
  @override
  @JsonKey()
  final double totalIncome;

  /// Total expenses for the month (positive values, although expenses are negative in transactions)
  @override
  @JsonKey()
  final double totalExpenses;

  /// Total savings for the month (income - expenses)
  @override
  @JsonKey()
  final double totalSavings;

  /// Total spending by category
  final Map<String, double> _categoryTotals;

  /// Total spending by category
  @override
  @JsonKey()
  Map<String, double> get categoryTotals {
    if (_categoryTotals is EqualUnmodifiableMapView) return _categoryTotals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryTotals);
  }

  /// Number of transactions in this month
  @override
  @JsonKey()
  final int transactionCount;

  @override
  String toString() {
    return 'MonthlySummary(year: $year, month: $month, totalIncome: $totalIncome, totalExpenses: $totalExpenses, totalSavings: $totalSavings, categoryTotals: $categoryTotals, transactionCount: $transactionCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlySummaryImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.totalSavings, totalSavings) ||
                other.totalSavings == totalSavings) &&
            const DeepCollectionEquality()
                .equals(other._categoryTotals, _categoryTotals) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      year,
      month,
      totalIncome,
      totalExpenses,
      totalSavings,
      const DeepCollectionEquality().hash(_categoryTotals),
      transactionCount);

  /// Create a copy of MonthlySummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlySummaryImplCopyWith<_$MonthlySummaryImpl> get copyWith =>
      __$$MonthlySummaryImplCopyWithImpl<_$MonthlySummaryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlySummaryImplToJson(
      this,
    );
  }
}

abstract class _MonthlySummary extends MonthlySummary {
  const factory _MonthlySummary(
      {required final int year,
      required final int month,
      final double totalIncome,
      final double totalExpenses,
      final double totalSavings,
      final Map<String, double> categoryTotals,
      final int transactionCount}) = _$MonthlySummaryImpl;
  const _MonthlySummary._() : super._();

  factory _MonthlySummary.fromJson(Map<String, dynamic> json) =
      _$MonthlySummaryImpl.fromJson;

  @override
  int get year;
  @override
  int get month;

  /// Total income for the month (positive values)
  @override
  double get totalIncome;

  /// Total expenses for the month (positive values, although expenses are negative in transactions)
  @override
  double get totalExpenses;

  /// Total savings for the month (income - expenses)
  @override
  double get totalSavings;

  /// Total spending by category
  @override
  Map<String, double> get categoryTotals;

  /// Number of transactions in this month
  @override
  int get transactionCount;

  /// Create a copy of MonthlySummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlySummaryImplCopyWith<_$MonthlySummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
