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
mixin _$Tracker implements DiagnosticableTreeMixin {

 String get name; String get description; String get category; String get type; TrackerConfig get config;
/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerCopyWith<Tracker> get copyWith => _$TrackerCopyWithImpl<Tracker>(this as Tracker, _$identity);

  /// Serializes this Tracker to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Tracker'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('config', config));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tracker&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.config, config) || other.config == config));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,category,type,config);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Tracker(name: $name, description: $description, category: $category, type: $type, config: $config)';
}


}

/// @nodoc
abstract mixin class $TrackerCopyWith<$Res>  {
  factory $TrackerCopyWith(Tracker value, $Res Function(Tracker) _then) = _$TrackerCopyWithImpl;
@useResult
$Res call({
 String name, String description, String category, String type, TrackerConfig config
});


$TrackerConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$TrackerCopyWithImpl<$Res>
    implements $TrackerCopyWith<$Res> {
  _$TrackerCopyWithImpl(this._self, this._then);

  final Tracker _self;
  final $Res Function(Tracker) _then;

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? category = null,Object? type = null,Object? config = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as TrackerConfig,
  ));
}
/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerConfigCopyWith<$Res> get config {
  
  return $TrackerConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tracker].
extension TrackerPatterns on Tracker {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tracker value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tracker() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tracker value)  $default,){
final _that = this;
switch (_that) {
case _Tracker():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tracker value)?  $default,){
final _that = this;
switch (_that) {
case _Tracker() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  String category,  String type,  TrackerConfig config)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tracker() when $default != null:
return $default(_that.name,_that.description,_that.category,_that.type,_that.config);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  String category,  String type,  TrackerConfig config)  $default,) {final _that = this;
switch (_that) {
case _Tracker():
return $default(_that.name,_that.description,_that.category,_that.type,_that.config);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  String category,  String type,  TrackerConfig config)?  $default,) {final _that = this;
switch (_that) {
case _Tracker() when $default != null:
return $default(_that.name,_that.description,_that.category,_that.type,_that.config);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Tracker with DiagnosticableTreeMixin implements Tracker {
  const _Tracker({required this.name, required this.description, required this.category, required this.type, required this.config});
  factory _Tracker.fromJson(Map<String, dynamic> json) => _$TrackerFromJson(json);

@override final  String name;
@override final  String description;
@override final  String category;
@override final  String type;
@override final  TrackerConfig config;

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackerCopyWith<_Tracker> get copyWith => __$TrackerCopyWithImpl<_Tracker>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackerToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Tracker'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('category', category))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('config', config));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tracker&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.config, config) || other.config == config));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,category,type,config);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Tracker(name: $name, description: $description, category: $category, type: $type, config: $config)';
}


}

/// @nodoc
abstract mixin class _$TrackerCopyWith<$Res> implements $TrackerCopyWith<$Res> {
  factory _$TrackerCopyWith(_Tracker value, $Res Function(_Tracker) _then) = __$TrackerCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, String category, String type, TrackerConfig config
});


@override $TrackerConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$TrackerCopyWithImpl<$Res>
    implements _$TrackerCopyWith<$Res> {
  __$TrackerCopyWithImpl(this._self, this._then);

  final _Tracker _self;
  final $Res Function(_Tracker) _then;

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? category = null,Object? type = null,Object? config = null,}) {
  return _then(_Tracker(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as TrackerConfig,
  ));
}

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerConfigCopyWith<$Res> get config {
  
  return $TrackerConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

TrackerConfig _$TrackerConfigFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'event':
          return EventTrackerConfig.fromJson(
            json
          );
                case 'milestone':
          return MilestoneTrackerConfig.fromJson(
            json
          );
                case 'anniversary':
          return AnniversaryTrackerConfig.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'TrackerConfig',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$TrackerConfig implements DiagnosticableTreeMixin {



  /// Serializes this TrackerConfig to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TrackerConfig'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TrackerConfig()';
}


}

/// @nodoc
class $TrackerConfigCopyWith<$Res>  {
$TrackerConfigCopyWith(TrackerConfig _, $Res Function(TrackerConfig) __);
}


/// Adds pattern-matching-related methods to [TrackerConfig].
extension TrackerConfigPatterns on TrackerConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EventTrackerConfig value)?  event,TResult Function( MilestoneTrackerConfig value)?  milestone,TResult Function( AnniversaryTrackerConfig value)?  anniversary,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EventTrackerConfig() when event != null:
return event(_that);case MilestoneTrackerConfig() when milestone != null:
return milestone(_that);case AnniversaryTrackerConfig() when anniversary != null:
return anniversary(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EventTrackerConfig value)  event,required TResult Function( MilestoneTrackerConfig value)  milestone,required TResult Function( AnniversaryTrackerConfig value)  anniversary,}){
final _that = this;
switch (_that) {
case EventTrackerConfig():
return event(_that);case MilestoneTrackerConfig():
return milestone(_that);case AnniversaryTrackerConfig():
return anniversary(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EventTrackerConfig value)?  event,TResult? Function( MilestoneTrackerConfig value)?  milestone,TResult? Function( AnniversaryTrackerConfig value)?  anniversary,}){
final _that = this;
switch (_that) {
case EventTrackerConfig() when event != null:
return event(_that);case MilestoneTrackerConfig() when milestone != null:
return milestone(_that);case AnniversaryTrackerConfig() when anniversary != null:
return anniversary(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int? periodDays)?  event,TResult Function( String goalType,  String targetValue)?  milestone,TResult Function( DateTime baseDate,  bool isLunar,  String remindType)?  anniversary,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EventTrackerConfig() when event != null:
return event(_that.periodDays);case MilestoneTrackerConfig() when milestone != null:
return milestone(_that.goalType,_that.targetValue);case AnniversaryTrackerConfig() when anniversary != null:
return anniversary(_that.baseDate,_that.isLunar,_that.remindType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int? periodDays)  event,required TResult Function( String goalType,  String targetValue)  milestone,required TResult Function( DateTime baseDate,  bool isLunar,  String remindType)  anniversary,}) {final _that = this;
switch (_that) {
case EventTrackerConfig():
return event(_that.periodDays);case MilestoneTrackerConfig():
return milestone(_that.goalType,_that.targetValue);case AnniversaryTrackerConfig():
return anniversary(_that.baseDate,_that.isLunar,_that.remindType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int? periodDays)?  event,TResult? Function( String goalType,  String targetValue)?  milestone,TResult? Function( DateTime baseDate,  bool isLunar,  String remindType)?  anniversary,}) {final _that = this;
switch (_that) {
case EventTrackerConfig() when event != null:
return event(_that.periodDays);case MilestoneTrackerConfig() when milestone != null:
return milestone(_that.goalType,_that.targetValue);case AnniversaryTrackerConfig() when anniversary != null:
return anniversary(_that.baseDate,_that.isLunar,_that.remindType);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class EventTrackerConfig with DiagnosticableTreeMixin implements TrackerConfig {
  const EventTrackerConfig({this.periodDays, final  String? $type}): $type = $type ?? 'event';
  factory EventTrackerConfig.fromJson(Map<String, dynamic> json) => _$EventTrackerConfigFromJson(json);

 final  int? periodDays;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TrackerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTrackerConfigCopyWith<EventTrackerConfig> get copyWith => _$EventTrackerConfigCopyWithImpl<EventTrackerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTrackerConfigToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TrackerConfig.event'))
    ..add(DiagnosticsProperty('periodDays', periodDays));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTrackerConfig&&(identical(other.periodDays, periodDays) || other.periodDays == periodDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,periodDays);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TrackerConfig.event(periodDays: $periodDays)';
}


}

/// @nodoc
abstract mixin class $EventTrackerConfigCopyWith<$Res> implements $TrackerConfigCopyWith<$Res> {
  factory $EventTrackerConfigCopyWith(EventTrackerConfig value, $Res Function(EventTrackerConfig) _then) = _$EventTrackerConfigCopyWithImpl;
@useResult
$Res call({
 int? periodDays
});




}
/// @nodoc
class _$EventTrackerConfigCopyWithImpl<$Res>
    implements $EventTrackerConfigCopyWith<$Res> {
  _$EventTrackerConfigCopyWithImpl(this._self, this._then);

  final EventTrackerConfig _self;
  final $Res Function(EventTrackerConfig) _then;

/// Create a copy of TrackerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? periodDays = freezed,}) {
  return _then(EventTrackerConfig(
periodDays: freezed == periodDays ? _self.periodDays : periodDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class MilestoneTrackerConfig with DiagnosticableTreeMixin implements TrackerConfig {
  const MilestoneTrackerConfig({required this.goalType, required this.targetValue, final  String? $type}): $type = $type ?? 'milestone';
  factory MilestoneTrackerConfig.fromJson(Map<String, dynamic> json) => _$MilestoneTrackerConfigFromJson(json);

 final  String goalType;
// 'time' / 'number' / 'boolean'
 final  String targetValue;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TrackerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MilestoneTrackerConfigCopyWith<MilestoneTrackerConfig> get copyWith => _$MilestoneTrackerConfigCopyWithImpl<MilestoneTrackerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MilestoneTrackerConfigToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TrackerConfig.milestone'))
    ..add(DiagnosticsProperty('goalType', goalType))..add(DiagnosticsProperty('targetValue', targetValue));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MilestoneTrackerConfig&&(identical(other.goalType, goalType) || other.goalType == goalType)&&(identical(other.targetValue, targetValue) || other.targetValue == targetValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,goalType,targetValue);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TrackerConfig.milestone(goalType: $goalType, targetValue: $targetValue)';
}


}

/// @nodoc
abstract mixin class $MilestoneTrackerConfigCopyWith<$Res> implements $TrackerConfigCopyWith<$Res> {
  factory $MilestoneTrackerConfigCopyWith(MilestoneTrackerConfig value, $Res Function(MilestoneTrackerConfig) _then) = _$MilestoneTrackerConfigCopyWithImpl;
@useResult
$Res call({
 String goalType, String targetValue
});




}
/// @nodoc
class _$MilestoneTrackerConfigCopyWithImpl<$Res>
    implements $MilestoneTrackerConfigCopyWith<$Res> {
  _$MilestoneTrackerConfigCopyWithImpl(this._self, this._then);

  final MilestoneTrackerConfig _self;
  final $Res Function(MilestoneTrackerConfig) _then;

/// Create a copy of TrackerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? goalType = null,Object? targetValue = null,}) {
  return _then(MilestoneTrackerConfig(
goalType: null == goalType ? _self.goalType : goalType // ignore: cast_nullable_to_non_nullable
as String,targetValue: null == targetValue ? _self.targetValue : targetValue // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class AnniversaryTrackerConfig with DiagnosticableTreeMixin implements TrackerConfig {
  const AnniversaryTrackerConfig({required this.baseDate, required this.isLunar, required this.remindType, final  String? $type}): $type = $type ?? 'anniversary';
  factory AnniversaryTrackerConfig.fromJson(Map<String, dynamic> json) => _$AnniversaryTrackerConfigFromJson(json);

 final  DateTime baseDate;
 final  bool isLunar;
 final  String remindType;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of TrackerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnniversaryTrackerConfigCopyWith<AnniversaryTrackerConfig> get copyWith => _$AnniversaryTrackerConfigCopyWithImpl<AnniversaryTrackerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnniversaryTrackerConfigToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TrackerConfig.anniversary'))
    ..add(DiagnosticsProperty('baseDate', baseDate))..add(DiagnosticsProperty('isLunar', isLunar))..add(DiagnosticsProperty('remindType', remindType));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnniversaryTrackerConfig&&(identical(other.baseDate, baseDate) || other.baseDate == baseDate)&&(identical(other.isLunar, isLunar) || other.isLunar == isLunar)&&(identical(other.remindType, remindType) || other.remindType == remindType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,baseDate,isLunar,remindType);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TrackerConfig.anniversary(baseDate: $baseDate, isLunar: $isLunar, remindType: $remindType)';
}


}

/// @nodoc
abstract mixin class $AnniversaryTrackerConfigCopyWith<$Res> implements $TrackerConfigCopyWith<$Res> {
  factory $AnniversaryTrackerConfigCopyWith(AnniversaryTrackerConfig value, $Res Function(AnniversaryTrackerConfig) _then) = _$AnniversaryTrackerConfigCopyWithImpl;
@useResult
$Res call({
 DateTime baseDate, bool isLunar, String remindType
});




}
/// @nodoc
class _$AnniversaryTrackerConfigCopyWithImpl<$Res>
    implements $AnniversaryTrackerConfigCopyWith<$Res> {
  _$AnniversaryTrackerConfigCopyWithImpl(this._self, this._then);

  final AnniversaryTrackerConfig _self;
  final $Res Function(AnniversaryTrackerConfig) _then;

/// Create a copy of TrackerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? baseDate = null,Object? isLunar = null,Object? remindType = null,}) {
  return _then(AnniversaryTrackerConfig(
baseDate: null == baseDate ? _self.baseDate : baseDate // ignore: cast_nullable_to_non_nullable
as DateTime,isLunar: null == isLunar ? _self.isLunar : isLunar // ignore: cast_nullable_to_non_nullable
as bool,remindType: null == remindType ? _self.remindType : remindType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TrackerRecord implements DiagnosticableTreeMixin {

 String get trackerId; DateTime get timestamp; String? get value;// 统一存为 String，例如 "3600", "50.0", "true"
 String? get content;
/// Create a copy of TrackerRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerRecordCopyWith<TrackerRecord> get copyWith => _$TrackerRecordCopyWithImpl<TrackerRecord>(this as TrackerRecord, _$identity);

  /// Serializes this TrackerRecord to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TrackerRecord'))
    ..add(DiagnosticsProperty('trackerId', trackerId))..add(DiagnosticsProperty('timestamp', timestamp))..add(DiagnosticsProperty('value', value))..add(DiagnosticsProperty('content', content));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerRecord&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.value, value) || other.value == value)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trackerId,timestamp,value,content);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TrackerRecord(trackerId: $trackerId, timestamp: $timestamp, value: $value, content: $content)';
}


}

/// @nodoc
abstract mixin class $TrackerRecordCopyWith<$Res>  {
  factory $TrackerRecordCopyWith(TrackerRecord value, $Res Function(TrackerRecord) _then) = _$TrackerRecordCopyWithImpl;
@useResult
$Res call({
 String trackerId, DateTime timestamp, String? value, String? content
});




}
/// @nodoc
class _$TrackerRecordCopyWithImpl<$Res>
    implements $TrackerRecordCopyWith<$Res> {
  _$TrackerRecordCopyWithImpl(this._self, this._then);

  final TrackerRecord _self;
  final $Res Function(TrackerRecord) _then;

/// Create a copy of TrackerRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trackerId = null,Object? timestamp = null,Object? value = freezed,Object? content = freezed,}) {
  return _then(_self.copyWith(
trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackerRecord].
extension TrackerRecordPatterns on TrackerRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackerRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackerRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackerRecord value)  $default,){
final _that = this;
switch (_that) {
case _TrackerRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackerRecord value)?  $default,){
final _that = this;
switch (_that) {
case _TrackerRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trackerId,  DateTime timestamp,  String? value,  String? content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackerRecord() when $default != null:
return $default(_that.trackerId,_that.timestamp,_that.value,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trackerId,  DateTime timestamp,  String? value,  String? content)  $default,) {final _that = this;
switch (_that) {
case _TrackerRecord():
return $default(_that.trackerId,_that.timestamp,_that.value,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trackerId,  DateTime timestamp,  String? value,  String? content)?  $default,) {final _that = this;
switch (_that) {
case _TrackerRecord() when $default != null:
return $default(_that.trackerId,_that.timestamp,_that.value,_that.content);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TrackerRecord with DiagnosticableTreeMixin implements TrackerRecord {
  const _TrackerRecord({required this.trackerId, required this.timestamp, this.value, this.content});
  factory _TrackerRecord.fromJson(Map<String, dynamic> json) => _$TrackerRecordFromJson(json);

@override final  String trackerId;
@override final  DateTime timestamp;
@override final  String? value;
// 统一存为 String，例如 "3600", "50.0", "true"
@override final  String? content;

/// Create a copy of TrackerRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackerRecordCopyWith<_TrackerRecord> get copyWith => __$TrackerRecordCopyWithImpl<_TrackerRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackerRecordToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'TrackerRecord'))
    ..add(DiagnosticsProperty('trackerId', trackerId))..add(DiagnosticsProperty('timestamp', timestamp))..add(DiagnosticsProperty('value', value))..add(DiagnosticsProperty('content', content));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackerRecord&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.value, value) || other.value == value)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trackerId,timestamp,value,content);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'TrackerRecord(trackerId: $trackerId, timestamp: $timestamp, value: $value, content: $content)';
}


}

/// @nodoc
abstract mixin class _$TrackerRecordCopyWith<$Res> implements $TrackerRecordCopyWith<$Res> {
  factory _$TrackerRecordCopyWith(_TrackerRecord value, $Res Function(_TrackerRecord) _then) = __$TrackerRecordCopyWithImpl;
@override @useResult
$Res call({
 String trackerId, DateTime timestamp, String? value, String? content
});




}
/// @nodoc
class __$TrackerRecordCopyWithImpl<$Res>
    implements _$TrackerRecordCopyWith<$Res> {
  __$TrackerRecordCopyWithImpl(this._self, this._then);

  final _TrackerRecord _self;
  final $Res Function(_TrackerRecord) _then;

/// Create a copy of TrackerRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackerId = null,Object? timestamp = null,Object? value = freezed,Object? content = freezed,}) {
  return _then(_TrackerRecord(
trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
