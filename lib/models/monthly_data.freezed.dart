// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monthly_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MonthlyData _$MonthlyDataFromJson(Map<String, dynamic> json) {
  return _MonthlyData.fromJson(json);
}

/// @nodoc
mixin _$MonthlyData {
  int get year => throw _privateConstructorUsedError;
  int get month => throw _privateConstructorUsedError;

  /// List of all transactions for this month
  List<Transaction> get transactions => throw _privateConstructorUsedError;

  /// Summary data for this month
  MonthlySummary get summary => throw _privateConstructorUsedError;

  /// Serializes this MonthlyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonthlyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonthlyDataCopyWith<MonthlyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonthlyDataCopyWith<$Res> {
  factory $MonthlyDataCopyWith(
          MonthlyData value, $Res Function(MonthlyData) then) =
      _$MonthlyDataCopyWithImpl<$Res, MonthlyData>;
  @useResult
  $Res call(
      {int year,
      int month,
      List<Transaction> transactions,
      MonthlySummary summary});

  $MonthlySummaryCopyWith<$Res> get summary;
}

/// @nodoc
class _$MonthlyDataCopyWithImpl<$Res, $Val extends MonthlyData>
    implements $MonthlyDataCopyWith<$Res> {
  _$MonthlyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonthlyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? transactions = null,
    Object? summary = null,
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
      transactions: null == transactions
          ? _value.transactions
          : transactions // ignore: cast_nullable_to_non_nullable
              as List<Transaction>,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as MonthlySummary,
    ) as $Val);
  }

  /// Create a copy of MonthlyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MonthlySummaryCopyWith<$Res> get summary {
    return $MonthlySummaryCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MonthlyDataImplCopyWith<$Res>
    implements $MonthlyDataCopyWith<$Res> {
  factory _$$MonthlyDataImplCopyWith(
          _$MonthlyDataImpl value, $Res Function(_$MonthlyDataImpl) then) =
      __$$MonthlyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int year,
      int month,
      List<Transaction> transactions,
      MonthlySummary summary});

  @override
  $MonthlySummaryCopyWith<$Res> get summary;
}

/// @nodoc
class __$$MonthlyDataImplCopyWithImpl<$Res>
    extends _$MonthlyDataCopyWithImpl<$Res, _$MonthlyDataImpl>
    implements _$$MonthlyDataImplCopyWith<$Res> {
  __$$MonthlyDataImplCopyWithImpl(
      _$MonthlyDataImpl _value, $Res Function(_$MonthlyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MonthlyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? transactions = null,
    Object? summary = null,
  }) {
    return _then(_$MonthlyDataImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      transactions: null == transactions
          ? _value._transactions
          : transactions // ignore: cast_nullable_to_non_nullable
              as List<Transaction>,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as MonthlySummary,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MonthlyDataImpl extends _MonthlyData {
  const _$MonthlyDataImpl(
      {required this.year,
      required this.month,
      final List<Transaction> transactions = const [],
      required this.summary})
      : _transactions = transactions,
        super._();

  factory _$MonthlyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonthlyDataImplFromJson(json);

  @override
  final int year;
  @override
  final int month;

  /// List of all transactions for this month
  final List<Transaction> _transactions;

  /// List of all transactions for this month
  @override
  @JsonKey()
  List<Transaction> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  /// Summary data for this month
  @override
  final MonthlySummary summary;

  @override
  String toString() {
    return 'MonthlyData(year: $year, month: $month, transactions: $transactions, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyDataImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            const DeepCollectionEquality()
                .equals(other._transactions, _transactions) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, year, month,
      const DeepCollectionEquality().hash(_transactions), summary);

  /// Create a copy of MonthlyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyDataImplCopyWith<_$MonthlyDataImpl> get copyWith =>
      __$$MonthlyDataImplCopyWithImpl<_$MonthlyDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonthlyDataImplToJson(
      this,
    );
  }
}

abstract class _MonthlyData extends MonthlyData {
  const factory _MonthlyData(
      {required final int year,
      required final int month,
      final List<Transaction> transactions,
      required final MonthlySummary summary}) = _$MonthlyDataImpl;
  const _MonthlyData._() : super._();

  factory _MonthlyData.fromJson(Map<String, dynamic> json) =
      _$MonthlyDataImpl.fromJson;

  @override
  int get year;
  @override
  int get month;

  /// List of all transactions for this month
  @override
  List<Transaction> get transactions;

  /// Summary data for this month
  @override
  MonthlySummary get summary;

  /// Create a copy of MonthlyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlyDataImplCopyWith<_$MonthlyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
