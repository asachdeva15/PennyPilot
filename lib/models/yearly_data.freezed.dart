// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'yearly_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

YearlyData _$YearlyDataFromJson(Map<String, dynamic> json) {
  return _YearlyData.fromJson(json);
}

/// @nodoc
mixin _$YearlyData {
  int get year => throw _privateConstructorUsedError;

  /// Monthly data indexed by month number (1-12)
  Map<int, MonthlyData> get months => throw _privateConstructorUsedError;

  /// Yearly summary data containing aggregated financial metrics
  YearlySummary get summary => throw _privateConstructorUsedError;

  /// Serializes this YearlyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of YearlyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $YearlyDataCopyWith<YearlyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $YearlyDataCopyWith<$Res> {
  factory $YearlyDataCopyWith(
          YearlyData value, $Res Function(YearlyData) then) =
      _$YearlyDataCopyWithImpl<$Res, YearlyData>;
  @useResult
  $Res call({int year, Map<int, MonthlyData> months, YearlySummary summary});

  $YearlySummaryCopyWith<$Res> get summary;
}

/// @nodoc
class _$YearlyDataCopyWithImpl<$Res, $Val extends YearlyData>
    implements $YearlyDataCopyWith<$Res> {
  _$YearlyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of YearlyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? months = null,
    Object? summary = null,
  }) {
    return _then(_value.copyWith(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      months: null == months
          ? _value.months
          : months // ignore: cast_nullable_to_non_nullable
              as Map<int, MonthlyData>,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as YearlySummary,
    ) as $Val);
  }

  /// Create a copy of YearlyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YearlySummaryCopyWith<$Res> get summary {
    return $YearlySummaryCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$YearlyDataImplCopyWith<$Res>
    implements $YearlyDataCopyWith<$Res> {
  factory _$$YearlyDataImplCopyWith(
          _$YearlyDataImpl value, $Res Function(_$YearlyDataImpl) then) =
      __$$YearlyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int year, Map<int, MonthlyData> months, YearlySummary summary});

  @override
  $YearlySummaryCopyWith<$Res> get summary;
}

/// @nodoc
class __$$YearlyDataImplCopyWithImpl<$Res>
    extends _$YearlyDataCopyWithImpl<$Res, _$YearlyDataImpl>
    implements _$$YearlyDataImplCopyWith<$Res> {
  __$$YearlyDataImplCopyWithImpl(
      _$YearlyDataImpl _value, $Res Function(_$YearlyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of YearlyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? months = null,
    Object? summary = null,
  }) {
    return _then(_$YearlyDataImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      months: null == months
          ? _value._months
          : months // ignore: cast_nullable_to_non_nullable
              as Map<int, MonthlyData>,
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as YearlySummary,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$YearlyDataImpl extends _YearlyData {
  const _$YearlyDataImpl(
      {required this.year,
      final Map<int, MonthlyData> months = const {},
      required this.summary})
      : _months = months,
        super._();

  factory _$YearlyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$YearlyDataImplFromJson(json);

  @override
  final int year;

  /// Monthly data indexed by month number (1-12)
  final Map<int, MonthlyData> _months;

  /// Monthly data indexed by month number (1-12)
  @override
  @JsonKey()
  Map<int, MonthlyData> get months {
    if (_months is EqualUnmodifiableMapView) return _months;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_months);
  }

  /// Yearly summary data containing aggregated financial metrics
  @override
  final YearlySummary summary;

  @override
  String toString() {
    return 'YearlyData(year: $year, months: $months, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YearlyDataImpl &&
            (identical(other.year, year) || other.year == year) &&
            const DeepCollectionEquality().equals(other._months, _months) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, year, const DeepCollectionEquality().hash(_months), summary);

  /// Create a copy of YearlyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$YearlyDataImplCopyWith<_$YearlyDataImpl> get copyWith =>
      __$$YearlyDataImplCopyWithImpl<_$YearlyDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$YearlyDataImplToJson(
      this,
    );
  }
}

abstract class _YearlyData extends YearlyData {
  const factory _YearlyData(
      {required final int year,
      final Map<int, MonthlyData> months,
      required final YearlySummary summary}) = _$YearlyDataImpl;
  const _YearlyData._() : super._();

  factory _YearlyData.fromJson(Map<String, dynamic> json) =
      _$YearlyDataImpl.fromJson;

  @override
  int get year;

  /// Monthly data indexed by month number (1-12)
  @override
  Map<int, MonthlyData> get months;

  /// Yearly summary data containing aggregated financial metrics
  @override
  YearlySummary get summary;

  /// Create a copy of YearlyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$YearlyDataImplCopyWith<_$YearlyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
