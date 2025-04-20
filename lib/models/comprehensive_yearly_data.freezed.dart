// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comprehensive_yearly_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ComprehensiveYearlyData _$ComprehensiveYearlyDataFromJson(
    Map<String, dynamic> json) {
  return _ComprehensiveYearlyData.fromJson(json);
}

/// @nodoc
mixin _$ComprehensiveYearlyData {
  int get year => throw _privateConstructorUsedError;
  YearlyData get yearlyData => throw _privateConstructorUsedError;
  DateTime get generatedAt => throw _privateConstructorUsedError;

  /// Serializes this ComprehensiveYearlyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ComprehensiveYearlyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ComprehensiveYearlyDataCopyWith<ComprehensiveYearlyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComprehensiveYearlyDataCopyWith<$Res> {
  factory $ComprehensiveYearlyDataCopyWith(ComprehensiveYearlyData value,
          $Res Function(ComprehensiveYearlyData) then) =
      _$ComprehensiveYearlyDataCopyWithImpl<$Res, ComprehensiveYearlyData>;
  @useResult
  $Res call({int year, YearlyData yearlyData, DateTime generatedAt});

  $YearlyDataCopyWith<$Res> get yearlyData;
}

/// @nodoc
class _$ComprehensiveYearlyDataCopyWithImpl<$Res,
        $Val extends ComprehensiveYearlyData>
    implements $ComprehensiveYearlyDataCopyWith<$Res> {
  _$ComprehensiveYearlyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ComprehensiveYearlyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? yearlyData = null,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      yearlyData: null == yearlyData
          ? _value.yearlyData
          : yearlyData // ignore: cast_nullable_to_non_nullable
              as YearlyData,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of ComprehensiveYearlyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YearlyDataCopyWith<$Res> get yearlyData {
    return $YearlyDataCopyWith<$Res>(_value.yearlyData, (value) {
      return _then(_value.copyWith(yearlyData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ComprehensiveYearlyDataImplCopyWith<$Res>
    implements $ComprehensiveYearlyDataCopyWith<$Res> {
  factory _$$ComprehensiveYearlyDataImplCopyWith(
          _$ComprehensiveYearlyDataImpl value,
          $Res Function(_$ComprehensiveYearlyDataImpl) then) =
      __$$ComprehensiveYearlyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int year, YearlyData yearlyData, DateTime generatedAt});

  @override
  $YearlyDataCopyWith<$Res> get yearlyData;
}

/// @nodoc
class __$$ComprehensiveYearlyDataImplCopyWithImpl<$Res>
    extends _$ComprehensiveYearlyDataCopyWithImpl<$Res,
        _$ComprehensiveYearlyDataImpl>
    implements _$$ComprehensiveYearlyDataImplCopyWith<$Res> {
  __$$ComprehensiveYearlyDataImplCopyWithImpl(
      _$ComprehensiveYearlyDataImpl _value,
      $Res Function(_$ComprehensiveYearlyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ComprehensiveYearlyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? yearlyData = null,
    Object? generatedAt = null,
  }) {
    return _then(_$ComprehensiveYearlyDataImpl(
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      yearlyData: null == yearlyData
          ? _value.yearlyData
          : yearlyData // ignore: cast_nullable_to_non_nullable
              as YearlyData,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ComprehensiveYearlyDataImpl extends _ComprehensiveYearlyData
    with DiagnosticableTreeMixin {
  const _$ComprehensiveYearlyDataImpl(
      {required this.year, required this.yearlyData, required this.generatedAt})
      : super._();

  factory _$ComprehensiveYearlyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComprehensiveYearlyDataImplFromJson(json);

  @override
  final int year;
  @override
  final YearlyData yearlyData;
  @override
  final DateTime generatedAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ComprehensiveYearlyData(year: $year, yearlyData: $yearlyData, generatedAt: $generatedAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ComprehensiveYearlyData'))
      ..add(DiagnosticsProperty('year', year))
      ..add(DiagnosticsProperty('yearlyData', yearlyData))
      ..add(DiagnosticsProperty('generatedAt', generatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComprehensiveYearlyDataImpl &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.yearlyData, yearlyData) ||
                other.yearlyData == yearlyData) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, year, yearlyData, generatedAt);

  /// Create a copy of ComprehensiveYearlyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ComprehensiveYearlyDataImplCopyWith<_$ComprehensiveYearlyDataImpl>
      get copyWith => __$$ComprehensiveYearlyDataImplCopyWithImpl<
          _$ComprehensiveYearlyDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ComprehensiveYearlyDataImplToJson(
      this,
    );
  }
}

abstract class _ComprehensiveYearlyData extends ComprehensiveYearlyData {
  const factory _ComprehensiveYearlyData(
      {required final int year,
      required final YearlyData yearlyData,
      required final DateTime generatedAt}) = _$ComprehensiveYearlyDataImpl;
  const _ComprehensiveYearlyData._() : super._();

  factory _ComprehensiveYearlyData.fromJson(Map<String, dynamic> json) =
      _$ComprehensiveYearlyDataImpl.fromJson;

  @override
  int get year;
  @override
  YearlyData get yearlyData;
  @override
  DateTime get generatedAt;

  /// Create a copy of ComprehensiveYearlyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ComprehensiveYearlyDataImplCopyWith<_$ComprehensiveYearlyDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
