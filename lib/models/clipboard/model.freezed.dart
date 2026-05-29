// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClipboardHistoryEntry implements DiagnosticableTreeMixin {

 String get data; bool get localOnly;
/// Create a copy of ClipboardHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClipboardHistoryEntryCopyWith<ClipboardHistoryEntry> get copyWith => _$ClipboardHistoryEntryCopyWithImpl<ClipboardHistoryEntry>(this as ClipboardHistoryEntry, _$identity);

  /// Serializes this ClipboardHistoryEntry to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ClipboardHistoryEntry'))
    ..add(DiagnosticsProperty('data', data))..add(DiagnosticsProperty('localOnly', localOnly));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClipboardHistoryEntry&&(identical(other.data, data) || other.data == data)&&(identical(other.localOnly, localOnly) || other.localOnly == localOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data,localOnly);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ClipboardHistoryEntry(data: $data, localOnly: $localOnly)';
}


}

/// @nodoc
abstract mixin class $ClipboardHistoryEntryCopyWith<$Res>  {
  factory $ClipboardHistoryEntryCopyWith(ClipboardHistoryEntry value, $Res Function(ClipboardHistoryEntry) _then) = _$ClipboardHistoryEntryCopyWithImpl;
@useResult
$Res call({
 String data, bool localOnly
});




}
/// @nodoc
class _$ClipboardHistoryEntryCopyWithImpl<$Res>
    implements $ClipboardHistoryEntryCopyWith<$Res> {
  _$ClipboardHistoryEntryCopyWithImpl(this._self, this._then);

  final ClipboardHistoryEntry _self;
  final $Res Function(ClipboardHistoryEntry) _then;

/// Create a copy of ClipboardHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? localOnly = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,localOnly: null == localOnly ? _self.localOnly : localOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ClipboardHistoryEntry].
extension ClipboardHistoryEntryPatterns on ClipboardHistoryEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClipboardHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClipboardHistoryEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClipboardHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _ClipboardHistoryEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClipboardHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ClipboardHistoryEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String data,  bool localOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClipboardHistoryEntry() when $default != null:
return $default(_that.data,_that.localOnly);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String data,  bool localOnly)  $default,) {final _that = this;
switch (_that) {
case _ClipboardHistoryEntry():
return $default(_that.data,_that.localOnly);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String data,  bool localOnly)?  $default,) {final _that = this;
switch (_that) {
case _ClipboardHistoryEntry() when $default != null:
return $default(_that.data,_that.localOnly);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ClipboardHistoryEntry with DiagnosticableTreeMixin implements ClipboardHistoryEntry {
  const _ClipboardHistoryEntry({required this.data, this.localOnly = true});
  factory _ClipboardHistoryEntry.fromJson(Map<String, dynamic> json) => _$ClipboardHistoryEntryFromJson(json);

@override final  String data;
@override@JsonKey() final  bool localOnly;

/// Create a copy of ClipboardHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClipboardHistoryEntryCopyWith<_ClipboardHistoryEntry> get copyWith => __$ClipboardHistoryEntryCopyWithImpl<_ClipboardHistoryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClipboardHistoryEntryToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ClipboardHistoryEntry'))
    ..add(DiagnosticsProperty('data', data))..add(DiagnosticsProperty('localOnly', localOnly));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClipboardHistoryEntry&&(identical(other.data, data) || other.data == data)&&(identical(other.localOnly, localOnly) || other.localOnly == localOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,data,localOnly);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ClipboardHistoryEntry(data: $data, localOnly: $localOnly)';
}


}

/// @nodoc
abstract mixin class _$ClipboardHistoryEntryCopyWith<$Res> implements $ClipboardHistoryEntryCopyWith<$Res> {
  factory _$ClipboardHistoryEntryCopyWith(_ClipboardHistoryEntry value, $Res Function(_ClipboardHistoryEntry) _then) = __$ClipboardHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 String data, bool localOnly
});




}
/// @nodoc
class __$ClipboardHistoryEntryCopyWithImpl<$Res>
    implements _$ClipboardHistoryEntryCopyWith<$Res> {
  __$ClipboardHistoryEntryCopyWithImpl(this._self, this._then);

  final _ClipboardHistoryEntry _self;
  final $Res Function(_ClipboardHistoryEntry) _then;

/// Create a copy of ClipboardHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? localOnly = null,}) {
  return _then(_ClipboardHistoryEntry(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,localOnly: null == localOnly ? _self.localOnly : localOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
