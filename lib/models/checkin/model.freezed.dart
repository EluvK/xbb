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
mixin _$CheckinEvent implements DiagnosticableTreeMixin {

 String get name; String get description; int get colorValue;
/// Create a copy of CheckinEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckinEventCopyWith<CheckinEvent> get copyWith => _$CheckinEventCopyWithImpl<CheckinEvent>(this as CheckinEvent, _$identity);

  /// Serializes this CheckinEvent to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CheckinEvent'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('colorValue', colorValue));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckinEvent&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,colorValue);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CheckinEvent(name: $name, description: $description, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class $CheckinEventCopyWith<$Res>  {
  factory $CheckinEventCopyWith(CheckinEvent value, $Res Function(CheckinEvent) _then) = _$CheckinEventCopyWithImpl;
@useResult
$Res call({
 String name, String description, int colorValue
});




}
/// @nodoc
class _$CheckinEventCopyWithImpl<$Res>
    implements $CheckinEventCopyWith<$Res> {
  _$CheckinEventCopyWithImpl(this._self, this._then);

  final CheckinEvent _self;
  final $Res Function(CheckinEvent) _then;

/// Create a copy of CheckinEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? colorValue = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckinEvent].
extension CheckinEventPatterns on CheckinEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckinEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckinEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckinEvent value)  $default,){
final _that = this;
switch (_that) {
case _CheckinEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckinEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CheckinEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  int colorValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckinEvent() when $default != null:
return $default(_that.name,_that.description,_that.colorValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  int colorValue)  $default,) {final _that = this;
switch (_that) {
case _CheckinEvent():
return $default(_that.name,_that.description,_that.colorValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  int colorValue)?  $default,) {final _that = this;
switch (_that) {
case _CheckinEvent() when $default != null:
return $default(_that.name,_that.description,_that.colorValue);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _CheckinEvent with DiagnosticableTreeMixin implements CheckinEvent {
  const _CheckinEvent({required this.name, required this.description, required this.colorValue});
  factory _CheckinEvent.fromJson(Map<String, dynamic> json) => _$CheckinEventFromJson(json);

@override final  String name;
@override final  String description;
@override final  int colorValue;

/// Create a copy of CheckinEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckinEventCopyWith<_CheckinEvent> get copyWith => __$CheckinEventCopyWithImpl<_CheckinEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckinEventToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CheckinEvent'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('colorValue', colorValue));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckinEvent&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,colorValue);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CheckinEvent(name: $name, description: $description, colorValue: $colorValue)';
}


}

/// @nodoc
abstract mixin class _$CheckinEventCopyWith<$Res> implements $CheckinEventCopyWith<$Res> {
  factory _$CheckinEventCopyWith(_CheckinEvent value, $Res Function(_CheckinEvent) _then) = __$CheckinEventCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, int colorValue
});




}
/// @nodoc
class __$CheckinEventCopyWithImpl<$Res>
    implements _$CheckinEventCopyWith<$Res> {
  __$CheckinEventCopyWithImpl(this._self, this._then);

  final _CheckinEvent _self;
  final $Res Function(_CheckinEvent) _then;

/// Create a copy of CheckinEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? colorValue = null,}) {
  return _then(_CheckinEvent(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,colorValue: null == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CheckinRecord implements DiagnosticableTreeMixin {

 String get eventId; DateTime get createdAtUtc; String get localDayKey; int get timezoneOffsetMinutes; String? get note;
/// Create a copy of CheckinRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckinRecordCopyWith<CheckinRecord> get copyWith => _$CheckinRecordCopyWithImpl<CheckinRecord>(this as CheckinRecord, _$identity);

  /// Serializes this CheckinRecord to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CheckinRecord'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('createdAtUtc', createdAtUtc))..add(DiagnosticsProperty('localDayKey', localDayKey))..add(DiagnosticsProperty('timezoneOffsetMinutes', timezoneOffsetMinutes))..add(DiagnosticsProperty('note', note));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckinRecord&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.createdAtUtc, createdAtUtc) || other.createdAtUtc == createdAtUtc)&&(identical(other.localDayKey, localDayKey) || other.localDayKey == localDayKey)&&(identical(other.timezoneOffsetMinutes, timezoneOffsetMinutes) || other.timezoneOffsetMinutes == timezoneOffsetMinutes)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,createdAtUtc,localDayKey,timezoneOffsetMinutes,note);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CheckinRecord(eventId: $eventId, createdAtUtc: $createdAtUtc, localDayKey: $localDayKey, timezoneOffsetMinutes: $timezoneOffsetMinutes, note: $note)';
}


}

/// @nodoc
abstract mixin class $CheckinRecordCopyWith<$Res>  {
  factory $CheckinRecordCopyWith(CheckinRecord value, $Res Function(CheckinRecord) _then) = _$CheckinRecordCopyWithImpl;
@useResult
$Res call({
 String eventId, DateTime createdAtUtc, String localDayKey, int timezoneOffsetMinutes, String? note
});




}
/// @nodoc
class _$CheckinRecordCopyWithImpl<$Res>
    implements $CheckinRecordCopyWith<$Res> {
  _$CheckinRecordCopyWithImpl(this._self, this._then);

  final CheckinRecord _self;
  final $Res Function(CheckinRecord) _then;

/// Create a copy of CheckinRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? createdAtUtc = null,Object? localDayKey = null,Object? timezoneOffsetMinutes = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,createdAtUtc: null == createdAtUtc ? _self.createdAtUtc : createdAtUtc // ignore: cast_nullable_to_non_nullable
as DateTime,localDayKey: null == localDayKey ? _self.localDayKey : localDayKey // ignore: cast_nullable_to_non_nullable
as String,timezoneOffsetMinutes: null == timezoneOffsetMinutes ? _self.timezoneOffsetMinutes : timezoneOffsetMinutes // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckinRecord].
extension CheckinRecordPatterns on CheckinRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckinRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckinRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckinRecord value)  $default,){
final _that = this;
switch (_that) {
case _CheckinRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckinRecord value)?  $default,){
final _that = this;
switch (_that) {
case _CheckinRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  DateTime createdAtUtc,  String localDayKey,  int timezoneOffsetMinutes,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckinRecord() when $default != null:
return $default(_that.eventId,_that.createdAtUtc,_that.localDayKey,_that.timezoneOffsetMinutes,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  DateTime createdAtUtc,  String localDayKey,  int timezoneOffsetMinutes,  String? note)  $default,) {final _that = this;
switch (_that) {
case _CheckinRecord():
return $default(_that.eventId,_that.createdAtUtc,_that.localDayKey,_that.timezoneOffsetMinutes,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  DateTime createdAtUtc,  String localDayKey,  int timezoneOffsetMinutes,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _CheckinRecord() when $default != null:
return $default(_that.eventId,_that.createdAtUtc,_that.localDayKey,_that.timezoneOffsetMinutes,_that.note);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _CheckinRecord with DiagnosticableTreeMixin implements CheckinRecord {
  const _CheckinRecord({required this.eventId, required this.createdAtUtc, required this.localDayKey, this.timezoneOffsetMinutes = 0, this.note});
  factory _CheckinRecord.fromJson(Map<String, dynamic> json) => _$CheckinRecordFromJson(json);

@override final  String eventId;
@override final  DateTime createdAtUtc;
@override final  String localDayKey;
@override@JsonKey() final  int timezoneOffsetMinutes;
@override final  String? note;

/// Create a copy of CheckinRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckinRecordCopyWith<_CheckinRecord> get copyWith => __$CheckinRecordCopyWithImpl<_CheckinRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckinRecordToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CheckinRecord'))
    ..add(DiagnosticsProperty('eventId', eventId))..add(DiagnosticsProperty('createdAtUtc', createdAtUtc))..add(DiagnosticsProperty('localDayKey', localDayKey))..add(DiagnosticsProperty('timezoneOffsetMinutes', timezoneOffsetMinutes))..add(DiagnosticsProperty('note', note));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckinRecord&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.createdAtUtc, createdAtUtc) || other.createdAtUtc == createdAtUtc)&&(identical(other.localDayKey, localDayKey) || other.localDayKey == localDayKey)&&(identical(other.timezoneOffsetMinutes, timezoneOffsetMinutes) || other.timezoneOffsetMinutes == timezoneOffsetMinutes)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,createdAtUtc,localDayKey,timezoneOffsetMinutes,note);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CheckinRecord(eventId: $eventId, createdAtUtc: $createdAtUtc, localDayKey: $localDayKey, timezoneOffsetMinutes: $timezoneOffsetMinutes, note: $note)';
}


}

/// @nodoc
abstract mixin class _$CheckinRecordCopyWith<$Res> implements $CheckinRecordCopyWith<$Res> {
  factory _$CheckinRecordCopyWith(_CheckinRecord value, $Res Function(_CheckinRecord) _then) = __$CheckinRecordCopyWithImpl;
@override @useResult
$Res call({
 String eventId, DateTime createdAtUtc, String localDayKey, int timezoneOffsetMinutes, String? note
});




}
/// @nodoc
class __$CheckinRecordCopyWithImpl<$Res>
    implements _$CheckinRecordCopyWith<$Res> {
  __$CheckinRecordCopyWithImpl(this._self, this._then);

  final _CheckinRecord _self;
  final $Res Function(_CheckinRecord) _then;

/// Create a copy of CheckinRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? createdAtUtc = null,Object? localDayKey = null,Object? timezoneOffsetMinutes = null,Object? note = freezed,}) {
  return _then(_CheckinRecord(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,createdAtUtc: null == createdAtUtc ? _self.createdAtUtc : createdAtUtc // ignore: cast_nullable_to_non_nullable
as DateTime,localDayKey: null == localDayKey ? _self.localDayKey : localDayKey // ignore: cast_nullable_to_non_nullable
as String,timezoneOffsetMinutes: null == timezoneOffsetMinutes ? _self.timezoneOffsetMinutes : timezoneOffsetMinutes // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
