// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$PronuncModel {
  String get playUrl => throw _privateConstructorUsedError;
  PronuncState get state => throw _privateConstructorUsedError;
  String? get recUrl => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PronuncModelCopyWith<PronuncModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PronuncModelCopyWith<$Res> {
  factory $PronuncModelCopyWith(
          PronuncModel value, $Res Function(PronuncModel) then) =
      _$PronuncModelCopyWithImpl<$Res>;
  $Res call({String playUrl, PronuncState state, String? recUrl});
}

/// @nodoc
class _$PronuncModelCopyWithImpl<$Res> implements $PronuncModelCopyWith<$Res> {
  _$PronuncModelCopyWithImpl(this._value, this._then);

  final PronuncModel _value;
  // ignore: unused_field
  final $Res Function(PronuncModel) _then;

  @override
  $Res call({
    Object? playUrl = freezed,
    Object? state = freezed,
    Object? recUrl = freezed,
  }) {
    return _then(_value.copyWith(
      playUrl: playUrl == freezed
          ? _value.playUrl
          : playUrl // ignore: cast_nullable_to_non_nullable
              as String,
      state: state == freezed
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as PronuncState,
      recUrl: recUrl == freezed
          ? _value.recUrl
          : recUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
abstract class _$PersonCopyWith<$Res> implements $PronuncModelCopyWith<$Res> {
  factory _$PersonCopyWith(_Person value, $Res Function(_Person) then) =
      __$PersonCopyWithImpl<$Res>;
  @override
  $Res call({String playUrl, PronuncState state, String? recUrl});
}

/// @nodoc
class __$PersonCopyWithImpl<$Res> extends _$PronuncModelCopyWithImpl<$Res>
    implements _$PersonCopyWith<$Res> {
  __$PersonCopyWithImpl(_Person _value, $Res Function(_Person) _then)
      : super(_value, (v) => _then(v as _Person));

  @override
  _Person get _value => super._value as _Person;

  @override
  $Res call({
    Object? playUrl = freezed,
    Object? state = freezed,
    Object? recUrl = freezed,
  }) {
    return _then(_Person(
      playUrl: playUrl == freezed
          ? _value.playUrl
          : playUrl // ignore: cast_nullable_to_non_nullable
              as String,
      state: state == freezed
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as PronuncState,
      recUrl: recUrl == freezed
          ? _value.recUrl
          : recUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$_Person implements _Person {
  const _$_Person({required this.playUrl, required this.state, this.recUrl});

  @override
  final String playUrl;
  @override
  final PronuncState state;
  @override
  final String? recUrl;

  @override
  String toString() {
    return 'PronuncModel(playUrl: $playUrl, state: $state, recUrl: $recUrl)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Person &&
            const DeepCollectionEquality().equals(other.playUrl, playUrl) &&
            const DeepCollectionEquality().equals(other.state, state) &&
            const DeepCollectionEquality().equals(other.recUrl, recUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(playUrl),
      const DeepCollectionEquality().hash(state),
      const DeepCollectionEquality().hash(recUrl));

  @JsonKey(ignore: true)
  @override
  _$PersonCopyWith<_Person> get copyWith =>
      __$PersonCopyWithImpl<_Person>(this, _$identity);
}

abstract class _Person implements PronuncModel {
  const factory _Person(
      {required final String playUrl,
      required final PronuncState state,
      final String? recUrl}) = _$_Person;

  @override
  String get playUrl => throw _privateConstructorUsedError;
  @override
  PronuncState get state => throw _privateConstructorUsedError;
  @override
  String? get recUrl => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$PersonCopyWith<_Person> get copyWith => throw _privateConstructorUsedError;
}