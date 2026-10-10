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
mixin _$ChatUsage implements DiagnosticableTreeMixin {

 int get promptTokens; int get completionTokens; int get totalTokens;
/// Create a copy of ChatUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUsageCopyWith<ChatUsage> get copyWith => _$ChatUsageCopyWithImpl<ChatUsage>(this as ChatUsage, _$identity);

  /// Serializes this ChatUsage to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatUsage'))
    ..add(DiagnosticsProperty('promptTokens', promptTokens))..add(DiagnosticsProperty('completionTokens', completionTokens))..add(DiagnosticsProperty('totalTokens', totalTokens));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUsage&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,promptTokens,completionTokens,totalTokens);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatUsage(promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens)';
}


}

/// @nodoc
abstract mixin class $ChatUsageCopyWith<$Res>  {
  factory $ChatUsageCopyWith(ChatUsage value, $Res Function(ChatUsage) _then) = _$ChatUsageCopyWithImpl;
@useResult
$Res call({
 int promptTokens, int completionTokens, int totalTokens
});




}
/// @nodoc
class _$ChatUsageCopyWithImpl<$Res>
    implements $ChatUsageCopyWith<$Res> {
  _$ChatUsageCopyWithImpl(this._self, this._then);

  final ChatUsage _self;
  final $Res Function(ChatUsage) _then;

/// Create a copy of ChatUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? promptTokens = null,Object? completionTokens = null,Object? totalTokens = null,}) {
  return _then(_self.copyWith(
promptTokens: null == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int,completionTokens: null == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int,totalTokens: null == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatUsage].
extension ChatUsagePatterns on ChatUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatUsage value)  $default,){
final _that = this;
switch (_that) {
case _ChatUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatUsage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int promptTokens,  int completionTokens,  int totalTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatUsage() when $default != null:
return $default(_that.promptTokens,_that.completionTokens,_that.totalTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int promptTokens,  int completionTokens,  int totalTokens)  $default,) {final _that = this;
switch (_that) {
case _ChatUsage():
return $default(_that.promptTokens,_that.completionTokens,_that.totalTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int promptTokens,  int completionTokens,  int totalTokens)?  $default,) {final _that = this;
switch (_that) {
case _ChatUsage() when $default != null:
return $default(_that.promptTokens,_that.completionTokens,_that.totalTokens);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ChatUsage with DiagnosticableTreeMixin implements ChatUsage {
  const _ChatUsage({required this.promptTokens, required this.completionTokens, required this.totalTokens});
  factory _ChatUsage.fromJson(Map<String, dynamic> json) => _$ChatUsageFromJson(json);

@override final  int promptTokens;
@override final  int completionTokens;
@override final  int totalTokens;

/// Create a copy of ChatUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatUsageCopyWith<_ChatUsage> get copyWith => __$ChatUsageCopyWithImpl<_ChatUsage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatUsageToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatUsage'))
    ..add(DiagnosticsProperty('promptTokens', promptTokens))..add(DiagnosticsProperty('completionTokens', completionTokens))..add(DiagnosticsProperty('totalTokens', totalTokens));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatUsage&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens)&&(identical(other.totalTokens, totalTokens) || other.totalTokens == totalTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,promptTokens,completionTokens,totalTokens);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatUsage(promptTokens: $promptTokens, completionTokens: $completionTokens, totalTokens: $totalTokens)';
}


}

/// @nodoc
abstract mixin class _$ChatUsageCopyWith<$Res> implements $ChatUsageCopyWith<$Res> {
  factory _$ChatUsageCopyWith(_ChatUsage value, $Res Function(_ChatUsage) _then) = __$ChatUsageCopyWithImpl;
@override @useResult
$Res call({
 int promptTokens, int completionTokens, int totalTokens
});




}
/// @nodoc
class __$ChatUsageCopyWithImpl<$Res>
    implements _$ChatUsageCopyWith<$Res> {
  __$ChatUsageCopyWithImpl(this._self, this._then);

  final _ChatUsage _self;
  final $Res Function(_ChatUsage) _then;

/// Create a copy of ChatUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? promptTokens = null,Object? completionTokens = null,Object? totalTokens = null,}) {
  return _then(_ChatUsage(
promptTokens: null == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int,completionTokens: null == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int,totalTokens: null == totalTokens ? _self.totalTokens : totalTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChatAssistantModelConfig implements DiagnosticableTreeMixin {

 ChatAssistantModelProvider? get provider; String? get baseUrl; String? get model; double? get temperature; bool? get thinkingEnabled; String? get reasoningEffort;
/// Create a copy of ChatAssistantModelConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAssistantModelConfigCopyWith<ChatAssistantModelConfig> get copyWith => _$ChatAssistantModelConfigCopyWithImpl<ChatAssistantModelConfig>(this as ChatAssistantModelConfig, _$identity);

  /// Serializes this ChatAssistantModelConfig to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatAssistantModelConfig'))
    ..add(DiagnosticsProperty('provider', provider))..add(DiagnosticsProperty('baseUrl', baseUrl))..add(DiagnosticsProperty('model', model))..add(DiagnosticsProperty('temperature', temperature))..add(DiagnosticsProperty('thinkingEnabled', thinkingEnabled))..add(DiagnosticsProperty('reasoningEffort', reasoningEffort));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAssistantModelConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.model, model) || other.model == model)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.thinkingEnabled, thinkingEnabled) || other.thinkingEnabled == thinkingEnabled)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,baseUrl,model,temperature,thinkingEnabled,reasoningEffort);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatAssistantModelConfig(provider: $provider, baseUrl: $baseUrl, model: $model, temperature: $temperature, thinkingEnabled: $thinkingEnabled, reasoningEffort: $reasoningEffort)';
}


}

/// @nodoc
abstract mixin class $ChatAssistantModelConfigCopyWith<$Res>  {
  factory $ChatAssistantModelConfigCopyWith(ChatAssistantModelConfig value, $Res Function(ChatAssistantModelConfig) _then) = _$ChatAssistantModelConfigCopyWithImpl;
@useResult
$Res call({
 ChatAssistantModelProvider? provider, String? baseUrl, String? model, double? temperature, bool? thinkingEnabled, String? reasoningEffort
});




}
/// @nodoc
class _$ChatAssistantModelConfigCopyWithImpl<$Res>
    implements $ChatAssistantModelConfigCopyWith<$Res> {
  _$ChatAssistantModelConfigCopyWithImpl(this._self, this._then);

  final ChatAssistantModelConfig _self;
  final $Res Function(ChatAssistantModelConfig) _then;

/// Create a copy of ChatAssistantModelConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = freezed,Object? baseUrl = freezed,Object? model = freezed,Object? temperature = freezed,Object? thinkingEnabled = freezed,Object? reasoningEffort = freezed,}) {
  return _then(_self.copyWith(
provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as ChatAssistantModelProvider?,baseUrl: freezed == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,thinkingEnabled: freezed == thinkingEnabled ? _self.thinkingEnabled : thinkingEnabled // ignore: cast_nullable_to_non_nullable
as bool?,reasoningEffort: freezed == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatAssistantModelConfig].
extension ChatAssistantModelConfigPatterns on ChatAssistantModelConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatAssistantModelConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatAssistantModelConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatAssistantModelConfig value)  $default,){
final _that = this;
switch (_that) {
case _ChatAssistantModelConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatAssistantModelConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ChatAssistantModelConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatAssistantModelProvider? provider,  String? baseUrl,  String? model,  double? temperature,  bool? thinkingEnabled,  String? reasoningEffort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatAssistantModelConfig() when $default != null:
return $default(_that.provider,_that.baseUrl,_that.model,_that.temperature,_that.thinkingEnabled,_that.reasoningEffort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatAssistantModelProvider? provider,  String? baseUrl,  String? model,  double? temperature,  bool? thinkingEnabled,  String? reasoningEffort)  $default,) {final _that = this;
switch (_that) {
case _ChatAssistantModelConfig():
return $default(_that.provider,_that.baseUrl,_that.model,_that.temperature,_that.thinkingEnabled,_that.reasoningEffort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatAssistantModelProvider? provider,  String? baseUrl,  String? model,  double? temperature,  bool? thinkingEnabled,  String? reasoningEffort)?  $default,) {final _that = this;
switch (_that) {
case _ChatAssistantModelConfig() when $default != null:
return $default(_that.provider,_that.baseUrl,_that.model,_that.temperature,_that.thinkingEnabled,_that.reasoningEffort);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class _ChatAssistantModelConfig with DiagnosticableTreeMixin implements ChatAssistantModelConfig {
  const _ChatAssistantModelConfig({this.provider, this.baseUrl, this.model, this.temperature, this.thinkingEnabled, this.reasoningEffort});
  factory _ChatAssistantModelConfig.fromJson(Map<String, dynamic> json) => _$ChatAssistantModelConfigFromJson(json);

@override final  ChatAssistantModelProvider? provider;
@override final  String? baseUrl;
@override final  String? model;
@override final  double? temperature;
@override final  bool? thinkingEnabled;
@override final  String? reasoningEffort;

/// Create a copy of ChatAssistantModelConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatAssistantModelConfigCopyWith<_ChatAssistantModelConfig> get copyWith => __$ChatAssistantModelConfigCopyWithImpl<_ChatAssistantModelConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatAssistantModelConfigToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatAssistantModelConfig'))
    ..add(DiagnosticsProperty('provider', provider))..add(DiagnosticsProperty('baseUrl', baseUrl))..add(DiagnosticsProperty('model', model))..add(DiagnosticsProperty('temperature', temperature))..add(DiagnosticsProperty('thinkingEnabled', thinkingEnabled))..add(DiagnosticsProperty('reasoningEffort', reasoningEffort));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatAssistantModelConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl)&&(identical(other.model, model) || other.model == model)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.thinkingEnabled, thinkingEnabled) || other.thinkingEnabled == thinkingEnabled)&&(identical(other.reasoningEffort, reasoningEffort) || other.reasoningEffort == reasoningEffort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,baseUrl,model,temperature,thinkingEnabled,reasoningEffort);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatAssistantModelConfig(provider: $provider, baseUrl: $baseUrl, model: $model, temperature: $temperature, thinkingEnabled: $thinkingEnabled, reasoningEffort: $reasoningEffort)';
}


}

/// @nodoc
abstract mixin class _$ChatAssistantModelConfigCopyWith<$Res> implements $ChatAssistantModelConfigCopyWith<$Res> {
  factory _$ChatAssistantModelConfigCopyWith(_ChatAssistantModelConfig value, $Res Function(_ChatAssistantModelConfig) _then) = __$ChatAssistantModelConfigCopyWithImpl;
@override @useResult
$Res call({
 ChatAssistantModelProvider? provider, String? baseUrl, String? model, double? temperature, bool? thinkingEnabled, String? reasoningEffort
});




}
/// @nodoc
class __$ChatAssistantModelConfigCopyWithImpl<$Res>
    implements _$ChatAssistantModelConfigCopyWith<$Res> {
  __$ChatAssistantModelConfigCopyWithImpl(this._self, this._then);

  final _ChatAssistantModelConfig _self;
  final $Res Function(_ChatAssistantModelConfig) _then;

/// Create a copy of ChatAssistantModelConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = freezed,Object? baseUrl = freezed,Object? model = freezed,Object? temperature = freezed,Object? thinkingEnabled = freezed,Object? reasoningEffort = freezed,}) {
  return _then(_ChatAssistantModelConfig(
provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as ChatAssistantModelProvider?,baseUrl: freezed == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,thinkingEnabled: freezed == thinkingEnabled ? _self.thinkingEnabled : thinkingEnabled // ignore: cast_nullable_to_non_nullable
as bool?,reasoningEffort: freezed == reasoningEffort ? _self.reasoningEffort : reasoningEffort // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatAssistant implements DiagnosticableTreeMixin {

 String get name; ChatAssistantType get type; String get description; String get prompt; String? get avatarUrl; ChatAssistantModelConfig? get modelConfig;
/// Create a copy of ChatAssistant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatAssistantCopyWith<ChatAssistant> get copyWith => _$ChatAssistantCopyWithImpl<ChatAssistant>(this as ChatAssistant, _$identity);

  /// Serializes this ChatAssistant to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatAssistant'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('prompt', prompt))..add(DiagnosticsProperty('avatarUrl', avatarUrl))..add(DiagnosticsProperty('modelConfig', modelConfig));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAssistant&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.modelConfig, modelConfig) || other.modelConfig == modelConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,description,prompt,avatarUrl,modelConfig);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatAssistant(name: $name, type: $type, description: $description, prompt: $prompt, avatarUrl: $avatarUrl, modelConfig: $modelConfig)';
}


}

/// @nodoc
abstract mixin class $ChatAssistantCopyWith<$Res>  {
  factory $ChatAssistantCopyWith(ChatAssistant value, $Res Function(ChatAssistant) _then) = _$ChatAssistantCopyWithImpl;
@useResult
$Res call({
 String name, ChatAssistantType type, String description, String prompt, String? avatarUrl, ChatAssistantModelConfig? modelConfig
});


$ChatAssistantModelConfigCopyWith<$Res>? get modelConfig;

}
/// @nodoc
class _$ChatAssistantCopyWithImpl<$Res>
    implements $ChatAssistantCopyWith<$Res> {
  _$ChatAssistantCopyWithImpl(this._self, this._then);

  final ChatAssistant _self;
  final $Res Function(ChatAssistant) _then;

/// Create a copy of ChatAssistant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? description = null,Object? prompt = null,Object? avatarUrl = freezed,Object? modelConfig = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatAssistantType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,modelConfig: freezed == modelConfig ? _self.modelConfig : modelConfig // ignore: cast_nullable_to_non_nullable
as ChatAssistantModelConfig?,
  ));
}
/// Create a copy of ChatAssistant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatAssistantModelConfigCopyWith<$Res>? get modelConfig {
    if (_self.modelConfig == null) {
    return null;
  }

  return $ChatAssistantModelConfigCopyWith<$Res>(_self.modelConfig!, (value) {
    return _then(_self.copyWith(modelConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatAssistant].
extension ChatAssistantPatterns on ChatAssistant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatAssistant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatAssistant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatAssistant value)  $default,){
final _that = this;
switch (_that) {
case _ChatAssistant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatAssistant value)?  $default,){
final _that = this;
switch (_that) {
case _ChatAssistant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  ChatAssistantType type,  String description,  String prompt,  String? avatarUrl,  ChatAssistantModelConfig? modelConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatAssistant() when $default != null:
return $default(_that.name,_that.type,_that.description,_that.prompt,_that.avatarUrl,_that.modelConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  ChatAssistantType type,  String description,  String prompt,  String? avatarUrl,  ChatAssistantModelConfig? modelConfig)  $default,) {final _that = this;
switch (_that) {
case _ChatAssistant():
return $default(_that.name,_that.type,_that.description,_that.prompt,_that.avatarUrl,_that.modelConfig);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  ChatAssistantType type,  String description,  String prompt,  String? avatarUrl,  ChatAssistantModelConfig? modelConfig)?  $default,) {final _that = this;
switch (_that) {
case _ChatAssistant() when $default != null:
return $default(_that.name,_that.type,_that.description,_that.prompt,_that.avatarUrl,_that.modelConfig);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ChatAssistant with DiagnosticableTreeMixin implements ChatAssistant {
  const _ChatAssistant({required this.name, required this.type, required this.description, required this.prompt, this.avatarUrl, this.modelConfig});
  factory _ChatAssistant.fromJson(Map<String, dynamic> json) => _$ChatAssistantFromJson(json);

@override final  String name;
@override final  ChatAssistantType type;
@override final  String description;
@override final  String prompt;
@override final  String? avatarUrl;
@override final  ChatAssistantModelConfig? modelConfig;

/// Create a copy of ChatAssistant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatAssistantCopyWith<_ChatAssistant> get copyWith => __$ChatAssistantCopyWithImpl<_ChatAssistant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatAssistantToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatAssistant'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('description', description))..add(DiagnosticsProperty('prompt', prompt))..add(DiagnosticsProperty('avatarUrl', avatarUrl))..add(DiagnosticsProperty('modelConfig', modelConfig));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatAssistant&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.modelConfig, modelConfig) || other.modelConfig == modelConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,type,description,prompt,avatarUrl,modelConfig);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatAssistant(name: $name, type: $type, description: $description, prompt: $prompt, avatarUrl: $avatarUrl, modelConfig: $modelConfig)';
}


}

/// @nodoc
abstract mixin class _$ChatAssistantCopyWith<$Res> implements $ChatAssistantCopyWith<$Res> {
  factory _$ChatAssistantCopyWith(_ChatAssistant value, $Res Function(_ChatAssistant) _then) = __$ChatAssistantCopyWithImpl;
@override @useResult
$Res call({
 String name, ChatAssistantType type, String description, String prompt, String? avatarUrl, ChatAssistantModelConfig? modelConfig
});


@override $ChatAssistantModelConfigCopyWith<$Res>? get modelConfig;

}
/// @nodoc
class __$ChatAssistantCopyWithImpl<$Res>
    implements _$ChatAssistantCopyWith<$Res> {
  __$ChatAssistantCopyWithImpl(this._self, this._then);

  final _ChatAssistant _self;
  final $Res Function(_ChatAssistant) _then;

/// Create a copy of ChatAssistant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? description = null,Object? prompt = null,Object? avatarUrl = freezed,Object? modelConfig = freezed,}) {
  return _then(_ChatAssistant(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatAssistantType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,modelConfig: freezed == modelConfig ? _self.modelConfig : modelConfig // ignore: cast_nullable_to_non_nullable
as ChatAssistantModelConfig?,
  ));
}

/// Create a copy of ChatAssistant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatAssistantModelConfigCopyWith<$Res>? get modelConfig {
    if (_self.modelConfig == null) {
    return null;
  }

  return $ChatAssistantModelConfigCopyWith<$Res>(_self.modelConfig!, (value) {
    return _then(_self.copyWith(modelConfig: value));
  });
}
}


/// @nodoc
mixin _$ChatConversation implements DiagnosticableTreeMixin {

 String get name; String get assistantId; String get assistantName; bool get like;
/// Create a copy of ChatConversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatConversationCopyWith<ChatConversation> get copyWith => _$ChatConversationCopyWithImpl<ChatConversation>(this as ChatConversation, _$identity);

  /// Serializes this ChatConversation to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatConversation'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('assistantId', assistantId))..add(DiagnosticsProperty('assistantName', assistantName))..add(DiagnosticsProperty('like', like));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatConversation&&(identical(other.name, name) || other.name == name)&&(identical(other.assistantId, assistantId) || other.assistantId == assistantId)&&(identical(other.assistantName, assistantName) || other.assistantName == assistantName)&&(identical(other.like, like) || other.like == like));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,assistantId,assistantName,like);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatConversation(name: $name, assistantId: $assistantId, assistantName: $assistantName, like: $like)';
}


}

/// @nodoc
abstract mixin class $ChatConversationCopyWith<$Res>  {
  factory $ChatConversationCopyWith(ChatConversation value, $Res Function(ChatConversation) _then) = _$ChatConversationCopyWithImpl;
@useResult
$Res call({
 String name, String assistantId, String assistantName, bool like
});




}
/// @nodoc
class _$ChatConversationCopyWithImpl<$Res>
    implements $ChatConversationCopyWith<$Res> {
  _$ChatConversationCopyWithImpl(this._self, this._then);

  final ChatConversation _self;
  final $Res Function(ChatConversation) _then;

/// Create a copy of ChatConversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? assistantId = null,Object? assistantName = null,Object? like = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,assistantId: null == assistantId ? _self.assistantId : assistantId // ignore: cast_nullable_to_non_nullable
as String,assistantName: null == assistantName ? _self.assistantName : assistantName // ignore: cast_nullable_to_non_nullable
as String,like: null == like ? _self.like : like // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatConversation].
extension ChatConversationPatterns on ChatConversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatConversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatConversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatConversation value)  $default,){
final _that = this;
switch (_that) {
case _ChatConversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatConversation value)?  $default,){
final _that = this;
switch (_that) {
case _ChatConversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String assistantId,  String assistantName,  bool like)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatConversation() when $default != null:
return $default(_that.name,_that.assistantId,_that.assistantName,_that.like);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String assistantId,  String assistantName,  bool like)  $default,) {final _that = this;
switch (_that) {
case _ChatConversation():
return $default(_that.name,_that.assistantId,_that.assistantName,_that.like);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String assistantId,  String assistantName,  bool like)?  $default,) {final _that = this;
switch (_that) {
case _ChatConversation() when $default != null:
return $default(_that.name,_that.assistantId,_that.assistantName,_that.like);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ChatConversation with DiagnosticableTreeMixin implements ChatConversation {
  const _ChatConversation({required this.name, required this.assistantId, required this.assistantName, this.like = false});
  factory _ChatConversation.fromJson(Map<String, dynamic> json) => _$ChatConversationFromJson(json);

@override final  String name;
@override final  String assistantId;
@override final  String assistantName;
@override@JsonKey() final  bool like;

/// Create a copy of ChatConversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatConversationCopyWith<_ChatConversation> get copyWith => __$ChatConversationCopyWithImpl<_ChatConversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatConversationToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatConversation'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('assistantId', assistantId))..add(DiagnosticsProperty('assistantName', assistantName))..add(DiagnosticsProperty('like', like));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatConversation&&(identical(other.name, name) || other.name == name)&&(identical(other.assistantId, assistantId) || other.assistantId == assistantId)&&(identical(other.assistantName, assistantName) || other.assistantName == assistantName)&&(identical(other.like, like) || other.like == like));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,assistantId,assistantName,like);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatConversation(name: $name, assistantId: $assistantId, assistantName: $assistantName, like: $like)';
}


}

/// @nodoc
abstract mixin class _$ChatConversationCopyWith<$Res> implements $ChatConversationCopyWith<$Res> {
  factory _$ChatConversationCopyWith(_ChatConversation value, $Res Function(_ChatConversation) _then) = __$ChatConversationCopyWithImpl;
@override @useResult
$Res call({
 String name, String assistantId, String assistantName, bool like
});




}
/// @nodoc
class __$ChatConversationCopyWithImpl<$Res>
    implements _$ChatConversationCopyWith<$Res> {
  __$ChatConversationCopyWithImpl(this._self, this._then);

  final _ChatConversation _self;
  final $Res Function(_ChatConversation) _then;

/// Create a copy of ChatConversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? assistantId = null,Object? assistantName = null,Object? like = null,}) {
  return _then(_ChatConversation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,assistantId: null == assistantId ? _self.assistantId : assistantId // ignore: cast_nullable_to_non_nullable
as String,assistantName: null == assistantName ? _self.assistantName : assistantName // ignore: cast_nullable_to_non_nullable
as String,like: null == like ? _self.like : like // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ChatMessage implements DiagnosticableTreeMixin {

 String get conversationId; ChatMessageRole get role; String get text; String? get reasoningText; ChatUsage? get usage;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();

@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatMessage'))
    ..add(DiagnosticsProperty('conversationId', conversationId))..add(DiagnosticsProperty('role', role))..add(DiagnosticsProperty('text', text))..add(DiagnosticsProperty('reasoningText', reasoningText))..add(DiagnosticsProperty('usage', usage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&(identical(other.reasoningText, reasoningText) || other.reasoningText == reasoningText)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,role,text,reasoningText,usage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatMessage(conversationId: $conversationId, role: $role, text: $text, reasoningText: $reasoningText, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String conversationId, ChatMessageRole role, String text, String? reasoningText, ChatUsage? usage
});


$ChatUsageCopyWith<$Res>? get usage;

}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? role = null,Object? text = null,Object? reasoningText = freezed,Object? usage = freezed,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatMessageRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,reasoningText: freezed == reasoningText ? _self.reasoningText : reasoningText // ignore: cast_nullable_to_non_nullable
as String?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as ChatUsage?,
  ));
}
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatUsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $ChatUsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  ChatMessageRole role,  String text,  String? reasoningText,  ChatUsage? usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.conversationId,_that.role,_that.text,_that.reasoningText,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  ChatMessageRole role,  String text,  String? reasoningText,  ChatUsage? usage)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.conversationId,_that.role,_that.text,_that.reasoningText,_that.usage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  ChatMessageRole role,  String text,  String? reasoningText,  ChatUsage? usage)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.conversationId,_that.role,_that.text,_that.reasoningText,_that.usage);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ChatMessage with DiagnosticableTreeMixin implements ChatMessage {
  const _ChatMessage({required this.conversationId, required this.role, required this.text, this.reasoningText, this.usage});
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String conversationId;
@override final  ChatMessageRole role;
@override final  String text;
@override final  String? reasoningText;
@override final  ChatUsage? usage;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}
@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ChatMessage'))
    ..add(DiagnosticsProperty('conversationId', conversationId))..add(DiagnosticsProperty('role', role))..add(DiagnosticsProperty('text', text))..add(DiagnosticsProperty('reasoningText', reasoningText))..add(DiagnosticsProperty('usage', usage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&(identical(other.reasoningText, reasoningText) || other.reasoningText == reasoningText)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,role,text,reasoningText,usage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ChatMessage(conversationId: $conversationId, role: $role, text: $text, reasoningText: $reasoningText, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, ChatMessageRole role, String text, String? reasoningText, ChatUsage? usage
});


@override $ChatUsageCopyWith<$Res>? get usage;

}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? role = null,Object? text = null,Object? reasoningText = freezed,Object? usage = freezed,}) {
  return _then(_ChatMessage(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatMessageRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,reasoningText: freezed == reasoningText ? _self.reasoningText : reasoningText // ignore: cast_nullable_to_non_nullable
as String?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as ChatUsage?,
  ));
}

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatUsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $ChatUsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

// dart format on
