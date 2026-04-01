// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coins_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletBalanceDto _$WalletBalanceDtoFromJson(Map<String, dynamic> json) {
  return _WalletBalanceDto.fromJson(json);
}

/// @nodoc
mixin _$WalletBalanceDto {
  int get available => throw _privateConstructorUsedError;
  int get reserved => throw _privateConstructorUsedError;
  int get lifetimeEarned => throw _privateConstructorUsedError;
  int get lifetimeSpent => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this WalletBalanceDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletBalanceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletBalanceDtoCopyWith<WalletBalanceDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletBalanceDtoCopyWith<$Res> {
  factory $WalletBalanceDtoCopyWith(
          WalletBalanceDto value, $Res Function(WalletBalanceDto) then) =
      _$WalletBalanceDtoCopyWithImpl<$Res, WalletBalanceDto>;
  @useResult
  $Res call(
      {int available,
      int reserved,
      int lifetimeEarned,
      int lifetimeSpent,
      DateTime updatedAt});
}

/// @nodoc
class _$WalletBalanceDtoCopyWithImpl<$Res, $Val extends WalletBalanceDto>
    implements $WalletBalanceDtoCopyWith<$Res> {
  _$WalletBalanceDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletBalanceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? available = null,
    Object? reserved = null,
    Object? lifetimeEarned = null,
    Object? lifetimeSpent = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      available: null == available
          ? _value.available
          : available // ignore: cast_nullable_to_non_nullable
              as int,
      reserved: null == reserved
          ? _value.reserved
          : reserved // ignore: cast_nullable_to_non_nullable
              as int,
      lifetimeEarned: null == lifetimeEarned
          ? _value.lifetimeEarned
          : lifetimeEarned // ignore: cast_nullable_to_non_nullable
              as int,
      lifetimeSpent: null == lifetimeSpent
          ? _value.lifetimeSpent
          : lifetimeSpent // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletBalanceDtoImplCopyWith<$Res>
    implements $WalletBalanceDtoCopyWith<$Res> {
  factory _$$WalletBalanceDtoImplCopyWith(_$WalletBalanceDtoImpl value,
          $Res Function(_$WalletBalanceDtoImpl) then) =
      __$$WalletBalanceDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int available,
      int reserved,
      int lifetimeEarned,
      int lifetimeSpent,
      DateTime updatedAt});
}

/// @nodoc
class __$$WalletBalanceDtoImplCopyWithImpl<$Res>
    extends _$WalletBalanceDtoCopyWithImpl<$Res, _$WalletBalanceDtoImpl>
    implements _$$WalletBalanceDtoImplCopyWith<$Res> {
  __$$WalletBalanceDtoImplCopyWithImpl(_$WalletBalanceDtoImpl _value,
      $Res Function(_$WalletBalanceDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletBalanceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? available = null,
    Object? reserved = null,
    Object? lifetimeEarned = null,
    Object? lifetimeSpent = null,
    Object? updatedAt = null,
  }) {
    return _then(_$WalletBalanceDtoImpl(
      available: null == available
          ? _value.available
          : available // ignore: cast_nullable_to_non_nullable
              as int,
      reserved: null == reserved
          ? _value.reserved
          : reserved // ignore: cast_nullable_to_non_nullable
              as int,
      lifetimeEarned: null == lifetimeEarned
          ? _value.lifetimeEarned
          : lifetimeEarned // ignore: cast_nullable_to_non_nullable
              as int,
      lifetimeSpent: null == lifetimeSpent
          ? _value.lifetimeSpent
          : lifetimeSpent // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletBalanceDtoImpl extends _WalletBalanceDto {
  const _$WalletBalanceDtoImpl(
      {this.available = 0,
      this.reserved = 0,
      this.lifetimeEarned = 0,
      this.lifetimeSpent = 0,
      required this.updatedAt})
      : super._();

  factory _$WalletBalanceDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletBalanceDtoImplFromJson(json);

  @override
  @JsonKey()
  final int available;
  @override
  @JsonKey()
  final int reserved;
  @override
  @JsonKey()
  final int lifetimeEarned;
  @override
  @JsonKey()
  final int lifetimeSpent;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'WalletBalanceDto(available: $available, reserved: $reserved, lifetimeEarned: $lifetimeEarned, lifetimeSpent: $lifetimeSpent, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletBalanceDtoImpl &&
            (identical(other.available, available) ||
                other.available == available) &&
            (identical(other.reserved, reserved) ||
                other.reserved == reserved) &&
            (identical(other.lifetimeEarned, lifetimeEarned) ||
                other.lifetimeEarned == lifetimeEarned) &&
            (identical(other.lifetimeSpent, lifetimeSpent) ||
                other.lifetimeSpent == lifetimeSpent) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, available, reserved,
      lifetimeEarned, lifetimeSpent, updatedAt);

  /// Create a copy of WalletBalanceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletBalanceDtoImplCopyWith<_$WalletBalanceDtoImpl> get copyWith =>
      __$$WalletBalanceDtoImplCopyWithImpl<_$WalletBalanceDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletBalanceDtoImplToJson(
      this,
    );
  }
}

abstract class _WalletBalanceDto extends WalletBalanceDto {
  const factory _WalletBalanceDto(
      {final int available,
      final int reserved,
      final int lifetimeEarned,
      final int lifetimeSpent,
      required final DateTime updatedAt}) = _$WalletBalanceDtoImpl;
  const _WalletBalanceDto._() : super._();

  factory _WalletBalanceDto.fromJson(Map<String, dynamic> json) =
      _$WalletBalanceDtoImpl.fromJson;

  @override
  int get available;
  @override
  int get reserved;
  @override
  int get lifetimeEarned;
  @override
  int get lifetimeSpent;
  @override
  DateTime get updatedAt;

  /// Create a copy of WalletBalanceDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletBalanceDtoImplCopyWith<_$WalletBalanceDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoinPackageDto _$CoinPackageDtoFromJson(Map<String, dynamic> json) {
  return _CoinPackageDto.fromJson(json);
}

/// @nodoc
mixin _$CoinPackageDto {
  String get sku => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get subtitle => throw _privateConstructorUsedError;
  int get coins => throw _privateConstructorUsedError;
  int get bonusCoins => throw _privateConstructorUsedError;
  String get priceLabel => throw _privateConstructorUsedError;
  int get priceMicros => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  bool get isHighlighted => throw _privateConstructorUsedError;
  String? get badge => throw _privateConstructorUsedError;

  /// Serializes this CoinPackageDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoinPackageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoinPackageDtoCopyWith<CoinPackageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinPackageDtoCopyWith<$Res> {
  factory $CoinPackageDtoCopyWith(
          CoinPackageDto value, $Res Function(CoinPackageDto) then) =
      _$CoinPackageDtoCopyWithImpl<$Res, CoinPackageDto>;
  @useResult
  $Res call(
      {String sku,
      String title,
      String subtitle,
      int coins,
      int bonusCoins,
      String priceLabel,
      int priceMicros,
      String currencyCode,
      String productId,
      bool isHighlighted,
      String? badge});
}

/// @nodoc
class _$CoinPackageDtoCopyWithImpl<$Res, $Val extends CoinPackageDto>
    implements $CoinPackageDtoCopyWith<$Res> {
  _$CoinPackageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoinPackageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sku = null,
    Object? title = null,
    Object? subtitle = null,
    Object? coins = null,
    Object? bonusCoins = null,
    Object? priceLabel = null,
    Object? priceMicros = null,
    Object? currencyCode = null,
    Object? productId = null,
    Object? isHighlighted = null,
    Object? badge = freezed,
  }) {
    return _then(_value.copyWith(
      sku: null == sku
          ? _value.sku
          : sku // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: null == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String,
      coins: null == coins
          ? _value.coins
          : coins // ignore: cast_nullable_to_non_nullable
              as int,
      bonusCoins: null == bonusCoins
          ? _value.bonusCoins
          : bonusCoins // ignore: cast_nullable_to_non_nullable
              as int,
      priceLabel: null == priceLabel
          ? _value.priceLabel
          : priceLabel // ignore: cast_nullable_to_non_nullable
              as String,
      priceMicros: null == priceMicros
          ? _value.priceMicros
          : priceMicros // ignore: cast_nullable_to_non_nullable
              as int,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      isHighlighted: null == isHighlighted
          ? _value.isHighlighted
          : isHighlighted // ignore: cast_nullable_to_non_nullable
              as bool,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CoinPackageDtoImplCopyWith<$Res>
    implements $CoinPackageDtoCopyWith<$Res> {
  factory _$$CoinPackageDtoImplCopyWith(_$CoinPackageDtoImpl value,
          $Res Function(_$CoinPackageDtoImpl) then) =
      __$$CoinPackageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sku,
      String title,
      String subtitle,
      int coins,
      int bonusCoins,
      String priceLabel,
      int priceMicros,
      String currencyCode,
      String productId,
      bool isHighlighted,
      String? badge});
}

/// @nodoc
class __$$CoinPackageDtoImplCopyWithImpl<$Res>
    extends _$CoinPackageDtoCopyWithImpl<$Res, _$CoinPackageDtoImpl>
    implements _$$CoinPackageDtoImplCopyWith<$Res> {
  __$$CoinPackageDtoImplCopyWithImpl(
      _$CoinPackageDtoImpl _value, $Res Function(_$CoinPackageDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CoinPackageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sku = null,
    Object? title = null,
    Object? subtitle = null,
    Object? coins = null,
    Object? bonusCoins = null,
    Object? priceLabel = null,
    Object? priceMicros = null,
    Object? currencyCode = null,
    Object? productId = null,
    Object? isHighlighted = null,
    Object? badge = freezed,
  }) {
    return _then(_$CoinPackageDtoImpl(
      sku: null == sku
          ? _value.sku
          : sku // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: null == subtitle
          ? _value.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String,
      coins: null == coins
          ? _value.coins
          : coins // ignore: cast_nullable_to_non_nullable
              as int,
      bonusCoins: null == bonusCoins
          ? _value.bonusCoins
          : bonusCoins // ignore: cast_nullable_to_non_nullable
              as int,
      priceLabel: null == priceLabel
          ? _value.priceLabel
          : priceLabel // ignore: cast_nullable_to_non_nullable
              as String,
      priceMicros: null == priceMicros
          ? _value.priceMicros
          : priceMicros // ignore: cast_nullable_to_non_nullable
              as int,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      isHighlighted: null == isHighlighted
          ? _value.isHighlighted
          : isHighlighted // ignore: cast_nullable_to_non_nullable
              as bool,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CoinPackageDtoImpl extends _CoinPackageDto {
  const _$CoinPackageDtoImpl(
      {required this.sku,
      required this.title,
      required this.subtitle,
      required this.coins,
      this.bonusCoins = 0,
      required this.priceLabel,
      required this.priceMicros,
      required this.currencyCode,
      required this.productId,
      this.isHighlighted = false,
      this.badge})
      : super._();

  factory _$CoinPackageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoinPackageDtoImplFromJson(json);

  @override
  final String sku;
  @override
  final String title;
  @override
  final String subtitle;
  @override
  final int coins;
  @override
  @JsonKey()
  final int bonusCoins;
  @override
  final String priceLabel;
  @override
  final int priceMicros;
  @override
  final String currencyCode;
  @override
  final String productId;
  @override
  @JsonKey()
  final bool isHighlighted;
  @override
  final String? badge;

  @override
  String toString() {
    return 'CoinPackageDto(sku: $sku, title: $title, subtitle: $subtitle, coins: $coins, bonusCoins: $bonusCoins, priceLabel: $priceLabel, priceMicros: $priceMicros, currencyCode: $currencyCode, productId: $productId, isHighlighted: $isHighlighted, badge: $badge)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoinPackageDtoImpl &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.coins, coins) || other.coins == coins) &&
            (identical(other.bonusCoins, bonusCoins) ||
                other.bonusCoins == bonusCoins) &&
            (identical(other.priceLabel, priceLabel) ||
                other.priceLabel == priceLabel) &&
            (identical(other.priceMicros, priceMicros) ||
                other.priceMicros == priceMicros) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.isHighlighted, isHighlighted) ||
                other.isHighlighted == isHighlighted) &&
            (identical(other.badge, badge) || other.badge == badge));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sku,
      title,
      subtitle,
      coins,
      bonusCoins,
      priceLabel,
      priceMicros,
      currencyCode,
      productId,
      isHighlighted,
      badge);

  /// Create a copy of CoinPackageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoinPackageDtoImplCopyWith<_$CoinPackageDtoImpl> get copyWith =>
      __$$CoinPackageDtoImplCopyWithImpl<_$CoinPackageDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoinPackageDtoImplToJson(
      this,
    );
  }
}

abstract class _CoinPackageDto extends CoinPackageDto {
  const factory _CoinPackageDto(
      {required final String sku,
      required final String title,
      required final String subtitle,
      required final int coins,
      final int bonusCoins,
      required final String priceLabel,
      required final int priceMicros,
      required final String currencyCode,
      required final String productId,
      final bool isHighlighted,
      final String? badge}) = _$CoinPackageDtoImpl;
  const _CoinPackageDto._() : super._();

  factory _CoinPackageDto.fromJson(Map<String, dynamic> json) =
      _$CoinPackageDtoImpl.fromJson;

  @override
  String get sku;
  @override
  String get title;
  @override
  String get subtitle;
  @override
  int get coins;
  @override
  int get bonusCoins;
  @override
  String get priceLabel;
  @override
  int get priceMicros;
  @override
  String get currencyCode;
  @override
  String get productId;
  @override
  bool get isHighlighted;
  @override
  String? get badge;

  /// Create a copy of CoinPackageDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoinPackageDtoImplCopyWith<_$CoinPackageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PremiumFeatureDto _$PremiumFeatureDtoFromJson(Map<String, dynamic> json) {
  return _PremiumFeatureDto.fromJson(json);
}

/// @nodoc
mixin _$PremiumFeatureDto {
  String get featureId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get coinCost => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get isLimitedTime => throw _privateConstructorUsedError;

  /// Serializes this PremiumFeatureDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PremiumFeatureDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PremiumFeatureDtoCopyWith<PremiumFeatureDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PremiumFeatureDtoCopyWith<$Res> {
  factory $PremiumFeatureDtoCopyWith(
          PremiumFeatureDto value, $Res Function(PremiumFeatureDto) then) =
      _$PremiumFeatureDtoCopyWithImpl<$Res, PremiumFeatureDto>;
  @useResult
  $Res call(
      {String featureId,
      String title,
      String description,
      int coinCost,
      String category,
      bool isLimitedTime});
}

/// @nodoc
class _$PremiumFeatureDtoCopyWithImpl<$Res, $Val extends PremiumFeatureDto>
    implements $PremiumFeatureDtoCopyWith<$Res> {
  _$PremiumFeatureDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PremiumFeatureDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureId = null,
    Object? title = null,
    Object? description = null,
    Object? coinCost = null,
    Object? category = null,
    Object? isLimitedTime = null,
  }) {
    return _then(_value.copyWith(
      featureId: null == featureId
          ? _value.featureId
          : featureId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      coinCost: null == coinCost
          ? _value.coinCost
          : coinCost // ignore: cast_nullable_to_non_nullable
              as int,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      isLimitedTime: null == isLimitedTime
          ? _value.isLimitedTime
          : isLimitedTime // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PremiumFeatureDtoImplCopyWith<$Res>
    implements $PremiumFeatureDtoCopyWith<$Res> {
  factory _$$PremiumFeatureDtoImplCopyWith(_$PremiumFeatureDtoImpl value,
          $Res Function(_$PremiumFeatureDtoImpl) then) =
      __$$PremiumFeatureDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String featureId,
      String title,
      String description,
      int coinCost,
      String category,
      bool isLimitedTime});
}

/// @nodoc
class __$$PremiumFeatureDtoImplCopyWithImpl<$Res>
    extends _$PremiumFeatureDtoCopyWithImpl<$Res, _$PremiumFeatureDtoImpl>
    implements _$$PremiumFeatureDtoImplCopyWith<$Res> {
  __$$PremiumFeatureDtoImplCopyWithImpl(_$PremiumFeatureDtoImpl _value,
      $Res Function(_$PremiumFeatureDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of PremiumFeatureDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureId = null,
    Object? title = null,
    Object? description = null,
    Object? coinCost = null,
    Object? category = null,
    Object? isLimitedTime = null,
  }) {
    return _then(_$PremiumFeatureDtoImpl(
      featureId: null == featureId
          ? _value.featureId
          : featureId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      coinCost: null == coinCost
          ? _value.coinCost
          : coinCost // ignore: cast_nullable_to_non_nullable
              as int,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      isLimitedTime: null == isLimitedTime
          ? _value.isLimitedTime
          : isLimitedTime // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PremiumFeatureDtoImpl extends _PremiumFeatureDto {
  const _$PremiumFeatureDtoImpl(
      {required this.featureId,
      required this.title,
      required this.description,
      required this.coinCost,
      required this.category,
      this.isLimitedTime = false})
      : super._();

  factory _$PremiumFeatureDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$PremiumFeatureDtoImplFromJson(json);

  @override
  final String featureId;
  @override
  final String title;
  @override
  final String description;
  @override
  final int coinCost;
  @override
  final String category;
  @override
  @JsonKey()
  final bool isLimitedTime;

  @override
  String toString() {
    return 'PremiumFeatureDto(featureId: $featureId, title: $title, description: $description, coinCost: $coinCost, category: $category, isLimitedTime: $isLimitedTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PremiumFeatureDtoImpl &&
            (identical(other.featureId, featureId) ||
                other.featureId == featureId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coinCost, coinCost) ||
                other.coinCost == coinCost) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isLimitedTime, isLimitedTime) ||
                other.isLimitedTime == isLimitedTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, featureId, title, description,
      coinCost, category, isLimitedTime);

  /// Create a copy of PremiumFeatureDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PremiumFeatureDtoImplCopyWith<_$PremiumFeatureDtoImpl> get copyWith =>
      __$$PremiumFeatureDtoImplCopyWithImpl<_$PremiumFeatureDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PremiumFeatureDtoImplToJson(
      this,
    );
  }
}

abstract class _PremiumFeatureDto extends PremiumFeatureDto {
  const factory _PremiumFeatureDto(
      {required final String featureId,
      required final String title,
      required final String description,
      required final int coinCost,
      required final String category,
      final bool isLimitedTime}) = _$PremiumFeatureDtoImpl;
  const _PremiumFeatureDto._() : super._();

  factory _PremiumFeatureDto.fromJson(Map<String, dynamic> json) =
      _$PremiumFeatureDtoImpl.fromJson;

  @override
  String get featureId;
  @override
  String get title;
  @override
  String get description;
  @override
  int get coinCost;
  @override
  String get category;
  @override
  bool get isLimitedTime;

  /// Create a copy of PremiumFeatureDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PremiumFeatureDtoImplCopyWith<_$PremiumFeatureDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RiskFlagDto _$RiskFlagDtoFromJson(Map<String, dynamic> json) {
  return _RiskFlagDto.fromJson(json);
}

/// @nodoc
mixin _$RiskFlagDto {
  String get code => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  RiskSeverity get severity => throw _privateConstructorUsedError;
  bool get blocksPayout => throw _privateConstructorUsedError;

  /// Serializes this RiskFlagDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RiskFlagDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RiskFlagDtoCopyWith<RiskFlagDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RiskFlagDtoCopyWith<$Res> {
  factory $RiskFlagDtoCopyWith(
          RiskFlagDto value, $Res Function(RiskFlagDto) then) =
      _$RiskFlagDtoCopyWithImpl<$Res, RiskFlagDto>;
  @useResult
  $Res call(
      {String code,
      String title,
      String description,
      RiskSeverity severity,
      bool blocksPayout});
}

/// @nodoc
class _$RiskFlagDtoCopyWithImpl<$Res, $Val extends RiskFlagDto>
    implements $RiskFlagDtoCopyWith<$Res> {
  _$RiskFlagDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RiskFlagDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? title = null,
    Object? description = null,
    Object? severity = null,
    Object? blocksPayout = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as RiskSeverity,
      blocksPayout: null == blocksPayout
          ? _value.blocksPayout
          : blocksPayout // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RiskFlagDtoImplCopyWith<$Res>
    implements $RiskFlagDtoCopyWith<$Res> {
  factory _$$RiskFlagDtoImplCopyWith(
          _$RiskFlagDtoImpl value, $Res Function(_$RiskFlagDtoImpl) then) =
      __$$RiskFlagDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      String title,
      String description,
      RiskSeverity severity,
      bool blocksPayout});
}

/// @nodoc
class __$$RiskFlagDtoImplCopyWithImpl<$Res>
    extends _$RiskFlagDtoCopyWithImpl<$Res, _$RiskFlagDtoImpl>
    implements _$$RiskFlagDtoImplCopyWith<$Res> {
  __$$RiskFlagDtoImplCopyWithImpl(
      _$RiskFlagDtoImpl _value, $Res Function(_$RiskFlagDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of RiskFlagDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? title = null,
    Object? description = null,
    Object? severity = null,
    Object? blocksPayout = null,
  }) {
    return _then(_$RiskFlagDtoImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as RiskSeverity,
      blocksPayout: null == blocksPayout
          ? _value.blocksPayout
          : blocksPayout // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RiskFlagDtoImpl extends _RiskFlagDto {
  const _$RiskFlagDtoImpl(
      {required this.code,
      required this.title,
      required this.description,
      required this.severity,
      this.blocksPayout = false})
      : super._();

  factory _$RiskFlagDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RiskFlagDtoImplFromJson(json);

  @override
  final String code;
  @override
  final String title;
  @override
  final String description;
  @override
  final RiskSeverity severity;
  @override
  @JsonKey()
  final bool blocksPayout;

  @override
  String toString() {
    return 'RiskFlagDto(code: $code, title: $title, description: $description, severity: $severity, blocksPayout: $blocksPayout)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RiskFlagDtoImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.blocksPayout, blocksPayout) ||
                other.blocksPayout == blocksPayout));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, code, title, description, severity, blocksPayout);

  /// Create a copy of RiskFlagDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RiskFlagDtoImplCopyWith<_$RiskFlagDtoImpl> get copyWith =>
      __$$RiskFlagDtoImplCopyWithImpl<_$RiskFlagDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RiskFlagDtoImplToJson(
      this,
    );
  }
}

abstract class _RiskFlagDto extends RiskFlagDto {
  const factory _RiskFlagDto(
      {required final String code,
      required final String title,
      required final String description,
      required final RiskSeverity severity,
      final bool blocksPayout}) = _$RiskFlagDtoImpl;
  const _RiskFlagDto._() : super._();

  factory _RiskFlagDto.fromJson(Map<String, dynamic> json) =
      _$RiskFlagDtoImpl.fromJson;

  @override
  String get code;
  @override
  String get title;
  @override
  String get description;
  @override
  RiskSeverity get severity;
  @override
  bool get blocksPayout;

  /// Create a copy of RiskFlagDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RiskFlagDtoImplCopyWith<_$RiskFlagDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoinTransactionDto _$CoinTransactionDtoFromJson(Map<String, dynamic> json) {
  return _CoinTransactionDto.fromJson(json);
}

/// @nodoc
mixin _$CoinTransactionDto {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  CoinTransactionDirection get direction => throw _privateConstructorUsedError;
  CoinTransactionType get type => throw _privateConstructorUsedError;
  LedgerEntryStatus get status => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int get balanceAfter => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get referenceId => throw _privateConstructorUsedError;
  DateTime get occurredAt => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this CoinTransactionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoinTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoinTransactionDtoCopyWith<CoinTransactionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinTransactionDtoCopyWith<$Res> {
  factory $CoinTransactionDtoCopyWith(
          CoinTransactionDto value, $Res Function(CoinTransactionDto) then) =
      _$CoinTransactionDtoCopyWithImpl<$Res, CoinTransactionDto>;
  @useResult
  $Res call(
      {String id,
      String userId,
      CoinTransactionDirection direction,
      CoinTransactionType type,
      LedgerEntryStatus status,
      int amount,
      int balanceAfter,
      String title,
      String referenceId,
      DateTime occurredAt,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$CoinTransactionDtoCopyWithImpl<$Res, $Val extends CoinTransactionDto>
    implements $CoinTransactionDtoCopyWith<$Res> {
  _$CoinTransactionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoinTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? direction = null,
    Object? type = null,
    Object? status = null,
    Object? amount = null,
    Object? balanceAfter = null,
    Object? title = null,
    Object? referenceId = null,
    Object? occurredAt = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as CoinTransactionDirection,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CoinTransactionType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as LedgerEntryStatus,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      balanceAfter: null == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      referenceId: null == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String,
      occurredAt: null == occurredAt
          ? _value.occurredAt
          : occurredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CoinTransactionDtoImplCopyWith<$Res>
    implements $CoinTransactionDtoCopyWith<$Res> {
  factory _$$CoinTransactionDtoImplCopyWith(_$CoinTransactionDtoImpl value,
          $Res Function(_$CoinTransactionDtoImpl) then) =
      __$$CoinTransactionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      CoinTransactionDirection direction,
      CoinTransactionType type,
      LedgerEntryStatus status,
      int amount,
      int balanceAfter,
      String title,
      String referenceId,
      DateTime occurredAt,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$CoinTransactionDtoImplCopyWithImpl<$Res>
    extends _$CoinTransactionDtoCopyWithImpl<$Res, _$CoinTransactionDtoImpl>
    implements _$$CoinTransactionDtoImplCopyWith<$Res> {
  __$$CoinTransactionDtoImplCopyWithImpl(_$CoinTransactionDtoImpl _value,
      $Res Function(_$CoinTransactionDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CoinTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? direction = null,
    Object? type = null,
    Object? status = null,
    Object? amount = null,
    Object? balanceAfter = null,
    Object? title = null,
    Object? referenceId = null,
    Object? occurredAt = null,
    Object? metadata = null,
  }) {
    return _then(_$CoinTransactionDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as CoinTransactionDirection,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CoinTransactionType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as LedgerEntryStatus,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      balanceAfter: null == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      referenceId: null == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String,
      occurredAt: null == occurredAt
          ? _value.occurredAt
          : occurredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CoinTransactionDtoImpl extends _CoinTransactionDto {
  const _$CoinTransactionDtoImpl(
      {required this.id,
      required this.userId,
      required this.direction,
      required this.type,
      required this.status,
      required this.amount,
      required this.balanceAfter,
      required this.title,
      required this.referenceId,
      required this.occurredAt,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata,
        super._();

  factory _$CoinTransactionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoinTransactionDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final CoinTransactionDirection direction;
  @override
  final CoinTransactionType type;
  @override
  final LedgerEntryStatus status;
  @override
  final int amount;
  @override
  final int balanceAfter;
  @override
  final String title;
  @override
  final String referenceId;
  @override
  final DateTime occurredAt;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'CoinTransactionDto(id: $id, userId: $userId, direction: $direction, type: $type, status: $status, amount: $amount, balanceAfter: $balanceAfter, title: $title, referenceId: $referenceId, occurredAt: $occurredAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoinTransactionDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.balanceAfter, balanceAfter) ||
                other.balanceAfter == balanceAfter) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.occurredAt, occurredAt) ||
                other.occurredAt == occurredAt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      direction,
      type,
      status,
      amount,
      balanceAfter,
      title,
      referenceId,
      occurredAt,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of CoinTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoinTransactionDtoImplCopyWith<_$CoinTransactionDtoImpl> get copyWith =>
      __$$CoinTransactionDtoImplCopyWithImpl<_$CoinTransactionDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoinTransactionDtoImplToJson(
      this,
    );
  }
}

abstract class _CoinTransactionDto extends CoinTransactionDto {
  const factory _CoinTransactionDto(
      {required final String id,
      required final String userId,
      required final CoinTransactionDirection direction,
      required final CoinTransactionType type,
      required final LedgerEntryStatus status,
      required final int amount,
      required final int balanceAfter,
      required final String title,
      required final String referenceId,
      required final DateTime occurredAt,
      final Map<String, dynamic> metadata}) = _$CoinTransactionDtoImpl;
  const _CoinTransactionDto._() : super._();

  factory _CoinTransactionDto.fromJson(Map<String, dynamic> json) =
      _$CoinTransactionDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  CoinTransactionDirection get direction;
  @override
  CoinTransactionType get type;
  @override
  LedgerEntryStatus get status;
  @override
  int get amount;
  @override
  int get balanceAfter;
  @override
  String get title;
  @override
  String get referenceId;
  @override
  DateTime get occurredAt;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of CoinTransactionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoinTransactionDtoImplCopyWith<_$CoinTransactionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransactionPageDto _$TransactionPageDtoFromJson(Map<String, dynamic> json) {
  return _TransactionPageDto.fromJson(json);
}

/// @nodoc
mixin _$TransactionPageDto {
  List<CoinTransactionDto> get items => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;

  /// Serializes this TransactionPageDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionPageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionPageDtoCopyWith<TransactionPageDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionPageDtoCopyWith<$Res> {
  factory $TransactionPageDtoCopyWith(
          TransactionPageDto value, $Res Function(TransactionPageDto) then) =
      _$TransactionPageDtoCopyWithImpl<$Res, TransactionPageDto>;
  @useResult
  $Res call({List<CoinTransactionDto> items, String? nextCursor, bool hasMore});
}

/// @nodoc
class _$TransactionPageDtoCopyWithImpl<$Res, $Val extends TransactionPageDto>
    implements $TransactionPageDtoCopyWith<$Res> {
  _$TransactionPageDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionPageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CoinTransactionDto>,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionPageDtoImplCopyWith<$Res>
    implements $TransactionPageDtoCopyWith<$Res> {
  factory _$$TransactionPageDtoImplCopyWith(_$TransactionPageDtoImpl value,
          $Res Function(_$TransactionPageDtoImpl) then) =
      __$$TransactionPageDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CoinTransactionDto> items, String? nextCursor, bool hasMore});
}

/// @nodoc
class __$$TransactionPageDtoImplCopyWithImpl<$Res>
    extends _$TransactionPageDtoCopyWithImpl<$Res, _$TransactionPageDtoImpl>
    implements _$$TransactionPageDtoImplCopyWith<$Res> {
  __$$TransactionPageDtoImplCopyWithImpl(_$TransactionPageDtoImpl _value,
      $Res Function(_$TransactionPageDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransactionPageDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(_$TransactionPageDtoImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CoinTransactionDto>,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionPageDtoImpl extends _TransactionPageDto {
  const _$TransactionPageDtoImpl(
      {final List<CoinTransactionDto> items = const <CoinTransactionDto>[],
      this.nextCursor,
      this.hasMore = false})
      : _items = items,
        super._();

  factory _$TransactionPageDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionPageDtoImplFromJson(json);

  final List<CoinTransactionDto> _items;
  @override
  @JsonKey()
  List<CoinTransactionDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? nextCursor;
  @override
  @JsonKey()
  final bool hasMore;

  @override
  String toString() {
    return 'TransactionPageDto(items: $items, nextCursor: $nextCursor, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionPageDtoImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), nextCursor, hasMore);

  /// Create a copy of TransactionPageDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionPageDtoImplCopyWith<_$TransactionPageDtoImpl> get copyWith =>
      __$$TransactionPageDtoImplCopyWithImpl<_$TransactionPageDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionPageDtoImplToJson(
      this,
    );
  }
}

abstract class _TransactionPageDto extends TransactionPageDto {
  const factory _TransactionPageDto(
      {final List<CoinTransactionDto> items,
      final String? nextCursor,
      final bool hasMore}) = _$TransactionPageDtoImpl;
  const _TransactionPageDto._() : super._();

  factory _TransactionPageDto.fromJson(Map<String, dynamic> json) =
      _$TransactionPageDtoImpl.fromJson;

  @override
  List<CoinTransactionDto> get items;
  @override
  String? get nextCursor;
  @override
  bool get hasMore;

  /// Create a copy of TransactionPageDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionPageDtoImplCopyWith<_$TransactionPageDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WalletOverviewDto _$WalletOverviewDtoFromJson(Map<String, dynamic> json) {
  return _WalletOverviewDto.fromJson(json);
}

/// @nodoc
mixin _$WalletOverviewDto {
  String get userId => throw _privateConstructorUsedError;
  WalletBalanceDto get balance => throw _privateConstructorUsedError;
  List<CoinPackageDto> get packages => throw _privateConstructorUsedError;
  List<PremiumFeatureDto> get premiumFeatures =>
      throw _privateConstructorUsedError;
  List<CoinTransactionDto> get recentTransactions =>
      throw _privateConstructorUsedError;
  List<RiskFlagDto> get riskFlags => throw _privateConstructorUsedError;

  /// Serializes this WalletOverviewDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletOverviewDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletOverviewDtoCopyWith<WalletOverviewDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletOverviewDtoCopyWith<$Res> {
  factory $WalletOverviewDtoCopyWith(
          WalletOverviewDto value, $Res Function(WalletOverviewDto) then) =
      _$WalletOverviewDtoCopyWithImpl<$Res, WalletOverviewDto>;
  @useResult
  $Res call(
      {String userId,
      WalletBalanceDto balance,
      List<CoinPackageDto> packages,
      List<PremiumFeatureDto> premiumFeatures,
      List<CoinTransactionDto> recentTransactions,
      List<RiskFlagDto> riskFlags});

  $WalletBalanceDtoCopyWith<$Res> get balance;
}

/// @nodoc
class _$WalletOverviewDtoCopyWithImpl<$Res, $Val extends WalletOverviewDto>
    implements $WalletOverviewDtoCopyWith<$Res> {
  _$WalletOverviewDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletOverviewDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? balance = null,
    Object? packages = null,
    Object? premiumFeatures = null,
    Object? recentTransactions = null,
    Object? riskFlags = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as WalletBalanceDto,
      packages: null == packages
          ? _value.packages
          : packages // ignore: cast_nullable_to_non_nullable
              as List<CoinPackageDto>,
      premiumFeatures: null == premiumFeatures
          ? _value.premiumFeatures
          : premiumFeatures // ignore: cast_nullable_to_non_nullable
              as List<PremiumFeatureDto>,
      recentTransactions: null == recentTransactions
          ? _value.recentTransactions
          : recentTransactions // ignore: cast_nullable_to_non_nullable
              as List<CoinTransactionDto>,
      riskFlags: null == riskFlags
          ? _value.riskFlags
          : riskFlags // ignore: cast_nullable_to_non_nullable
              as List<RiskFlagDto>,
    ) as $Val);
  }

  /// Create a copy of WalletOverviewDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletBalanceDtoCopyWith<$Res> get balance {
    return $WalletBalanceDtoCopyWith<$Res>(_value.balance, (value) {
      return _then(_value.copyWith(balance: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WalletOverviewDtoImplCopyWith<$Res>
    implements $WalletOverviewDtoCopyWith<$Res> {
  factory _$$WalletOverviewDtoImplCopyWith(_$WalletOverviewDtoImpl value,
          $Res Function(_$WalletOverviewDtoImpl) then) =
      __$$WalletOverviewDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      WalletBalanceDto balance,
      List<CoinPackageDto> packages,
      List<PremiumFeatureDto> premiumFeatures,
      List<CoinTransactionDto> recentTransactions,
      List<RiskFlagDto> riskFlags});

  @override
  $WalletBalanceDtoCopyWith<$Res> get balance;
}

/// @nodoc
class __$$WalletOverviewDtoImplCopyWithImpl<$Res>
    extends _$WalletOverviewDtoCopyWithImpl<$Res, _$WalletOverviewDtoImpl>
    implements _$$WalletOverviewDtoImplCopyWith<$Res> {
  __$$WalletOverviewDtoImplCopyWithImpl(_$WalletOverviewDtoImpl _value,
      $Res Function(_$WalletOverviewDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletOverviewDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? balance = null,
    Object? packages = null,
    Object? premiumFeatures = null,
    Object? recentTransactions = null,
    Object? riskFlags = null,
  }) {
    return _then(_$WalletOverviewDtoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as WalletBalanceDto,
      packages: null == packages
          ? _value._packages
          : packages // ignore: cast_nullable_to_non_nullable
              as List<CoinPackageDto>,
      premiumFeatures: null == premiumFeatures
          ? _value._premiumFeatures
          : premiumFeatures // ignore: cast_nullable_to_non_nullable
              as List<PremiumFeatureDto>,
      recentTransactions: null == recentTransactions
          ? _value._recentTransactions
          : recentTransactions // ignore: cast_nullable_to_non_nullable
              as List<CoinTransactionDto>,
      riskFlags: null == riskFlags
          ? _value._riskFlags
          : riskFlags // ignore: cast_nullable_to_non_nullable
              as List<RiskFlagDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletOverviewDtoImpl extends _WalletOverviewDto {
  const _$WalletOverviewDtoImpl(
      {required this.userId,
      required this.balance,
      final List<CoinPackageDto> packages = const <CoinPackageDto>[],
      final List<PremiumFeatureDto> premiumFeatures =
          const <PremiumFeatureDto>[],
      final List<CoinTransactionDto> recentTransactions =
          const <CoinTransactionDto>[],
      final List<RiskFlagDto> riskFlags = const <RiskFlagDto>[]})
      : _packages = packages,
        _premiumFeatures = premiumFeatures,
        _recentTransactions = recentTransactions,
        _riskFlags = riskFlags,
        super._();

  factory _$WalletOverviewDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletOverviewDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final WalletBalanceDto balance;
  final List<CoinPackageDto> _packages;
  @override
  @JsonKey()
  List<CoinPackageDto> get packages {
    if (_packages is EqualUnmodifiableListView) return _packages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_packages);
  }

  final List<PremiumFeatureDto> _premiumFeatures;
  @override
  @JsonKey()
  List<PremiumFeatureDto> get premiumFeatures {
    if (_premiumFeatures is EqualUnmodifiableListView) return _premiumFeatures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_premiumFeatures);
  }

  final List<CoinTransactionDto> _recentTransactions;
  @override
  @JsonKey()
  List<CoinTransactionDto> get recentTransactions {
    if (_recentTransactions is EqualUnmodifiableListView)
      return _recentTransactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentTransactions);
  }

  final List<RiskFlagDto> _riskFlags;
  @override
  @JsonKey()
  List<RiskFlagDto> get riskFlags {
    if (_riskFlags is EqualUnmodifiableListView) return _riskFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_riskFlags);
  }

  @override
  String toString() {
    return 'WalletOverviewDto(userId: $userId, balance: $balance, packages: $packages, premiumFeatures: $premiumFeatures, recentTransactions: $recentTransactions, riskFlags: $riskFlags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletOverviewDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            const DeepCollectionEquality().equals(other._packages, _packages) &&
            const DeepCollectionEquality()
                .equals(other._premiumFeatures, _premiumFeatures) &&
            const DeepCollectionEquality()
                .equals(other._recentTransactions, _recentTransactions) &&
            const DeepCollectionEquality()
                .equals(other._riskFlags, _riskFlags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      balance,
      const DeepCollectionEquality().hash(_packages),
      const DeepCollectionEquality().hash(_premiumFeatures),
      const DeepCollectionEquality().hash(_recentTransactions),
      const DeepCollectionEquality().hash(_riskFlags));

  /// Create a copy of WalletOverviewDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletOverviewDtoImplCopyWith<_$WalletOverviewDtoImpl> get copyWith =>
      __$$WalletOverviewDtoImplCopyWithImpl<_$WalletOverviewDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletOverviewDtoImplToJson(
      this,
    );
  }
}

abstract class _WalletOverviewDto extends WalletOverviewDto {
  const factory _WalletOverviewDto(
      {required final String userId,
      required final WalletBalanceDto balance,
      final List<CoinPackageDto> packages,
      final List<PremiumFeatureDto> premiumFeatures,
      final List<CoinTransactionDto> recentTransactions,
      final List<RiskFlagDto> riskFlags}) = _$WalletOverviewDtoImpl;
  const _WalletOverviewDto._() : super._();

  factory _WalletOverviewDto.fromJson(Map<String, dynamic> json) =
      _$WalletOverviewDtoImpl.fromJson;

  @override
  String get userId;
  @override
  WalletBalanceDto get balance;
  @override
  List<CoinPackageDto> get packages;
  @override
  List<PremiumFeatureDto> get premiumFeatures;
  @override
  List<CoinTransactionDto> get recentTransactions;
  @override
  List<RiskFlagDto> get riskFlags;

  /// Create a copy of WalletOverviewDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletOverviewDtoImplCopyWith<_$WalletOverviewDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LedgerMutationResultDto _$LedgerMutationResultDtoFromJson(
    Map<String, dynamic> json) {
  return _LedgerMutationResultDto.fromJson(json);
}

/// @nodoc
mixin _$LedgerMutationResultDto {
  WalletBalanceDto get walletBalance => throw _privateConstructorUsedError;
  CoinTransactionDto get transaction => throw _privateConstructorUsedError;
  RewardReviewStatus get reviewStatus => throw _privateConstructorUsedError;
  String get idempotencyKey => throw _privateConstructorUsedError;
  bool get shouldRefreshHistory => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this LedgerMutationResultDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LedgerMutationResultDtoCopyWith<LedgerMutationResultDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LedgerMutationResultDtoCopyWith<$Res> {
  factory $LedgerMutationResultDtoCopyWith(LedgerMutationResultDto value,
          $Res Function(LedgerMutationResultDto) then) =
      _$LedgerMutationResultDtoCopyWithImpl<$Res, LedgerMutationResultDto>;
  @useResult
  $Res call(
      {WalletBalanceDto walletBalance,
      CoinTransactionDto transaction,
      RewardReviewStatus reviewStatus,
      String idempotencyKey,
      bool shouldRefreshHistory,
      String? message});

  $WalletBalanceDtoCopyWith<$Res> get walletBalance;
  $CoinTransactionDtoCopyWith<$Res> get transaction;
}

/// @nodoc
class _$LedgerMutationResultDtoCopyWithImpl<$Res,
        $Val extends LedgerMutationResultDto>
    implements $LedgerMutationResultDtoCopyWith<$Res> {
  _$LedgerMutationResultDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletBalance = null,
    Object? transaction = null,
    Object? reviewStatus = null,
    Object? idempotencyKey = null,
    Object? shouldRefreshHistory = null,
    Object? message = freezed,
  }) {
    return _then(_value.copyWith(
      walletBalance: null == walletBalance
          ? _value.walletBalance
          : walletBalance // ignore: cast_nullable_to_non_nullable
              as WalletBalanceDto,
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as CoinTransactionDto,
      reviewStatus: null == reviewStatus
          ? _value.reviewStatus
          : reviewStatus // ignore: cast_nullable_to_non_nullable
              as RewardReviewStatus,
      idempotencyKey: null == idempotencyKey
          ? _value.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String,
      shouldRefreshHistory: null == shouldRefreshHistory
          ? _value.shouldRefreshHistory
          : shouldRefreshHistory // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletBalanceDtoCopyWith<$Res> get walletBalance {
    return $WalletBalanceDtoCopyWith<$Res>(_value.walletBalance, (value) {
      return _then(_value.copyWith(walletBalance: value) as $Val);
    });
  }

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CoinTransactionDtoCopyWith<$Res> get transaction {
    return $CoinTransactionDtoCopyWith<$Res>(_value.transaction, (value) {
      return _then(_value.copyWith(transaction: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LedgerMutationResultDtoImplCopyWith<$Res>
    implements $LedgerMutationResultDtoCopyWith<$Res> {
  factory _$$LedgerMutationResultDtoImplCopyWith(
          _$LedgerMutationResultDtoImpl value,
          $Res Function(_$LedgerMutationResultDtoImpl) then) =
      __$$LedgerMutationResultDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {WalletBalanceDto walletBalance,
      CoinTransactionDto transaction,
      RewardReviewStatus reviewStatus,
      String idempotencyKey,
      bool shouldRefreshHistory,
      String? message});

  @override
  $WalletBalanceDtoCopyWith<$Res> get walletBalance;
  @override
  $CoinTransactionDtoCopyWith<$Res> get transaction;
}

/// @nodoc
class __$$LedgerMutationResultDtoImplCopyWithImpl<$Res>
    extends _$LedgerMutationResultDtoCopyWithImpl<$Res,
        _$LedgerMutationResultDtoImpl>
    implements _$$LedgerMutationResultDtoImplCopyWith<$Res> {
  __$$LedgerMutationResultDtoImplCopyWithImpl(
      _$LedgerMutationResultDtoImpl _value,
      $Res Function(_$LedgerMutationResultDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletBalance = null,
    Object? transaction = null,
    Object? reviewStatus = null,
    Object? idempotencyKey = null,
    Object? shouldRefreshHistory = null,
    Object? message = freezed,
  }) {
    return _then(_$LedgerMutationResultDtoImpl(
      walletBalance: null == walletBalance
          ? _value.walletBalance
          : walletBalance // ignore: cast_nullable_to_non_nullable
              as WalletBalanceDto,
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as CoinTransactionDto,
      reviewStatus: null == reviewStatus
          ? _value.reviewStatus
          : reviewStatus // ignore: cast_nullable_to_non_nullable
              as RewardReviewStatus,
      idempotencyKey: null == idempotencyKey
          ? _value.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String,
      shouldRefreshHistory: null == shouldRefreshHistory
          ? _value.shouldRefreshHistory
          : shouldRefreshHistory // ignore: cast_nullable_to_non_nullable
              as bool,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LedgerMutationResultDtoImpl extends _LedgerMutationResultDto {
  const _$LedgerMutationResultDtoImpl(
      {required this.walletBalance,
      required this.transaction,
      required this.reviewStatus,
      required this.idempotencyKey,
      this.shouldRefreshHistory = true,
      this.message})
      : super._();

  factory _$LedgerMutationResultDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LedgerMutationResultDtoImplFromJson(json);

  @override
  final WalletBalanceDto walletBalance;
  @override
  final CoinTransactionDto transaction;
  @override
  final RewardReviewStatus reviewStatus;
  @override
  final String idempotencyKey;
  @override
  @JsonKey()
  final bool shouldRefreshHistory;
  @override
  final String? message;

  @override
  String toString() {
    return 'LedgerMutationResultDto(walletBalance: $walletBalance, transaction: $transaction, reviewStatus: $reviewStatus, idempotencyKey: $idempotencyKey, shouldRefreshHistory: $shouldRefreshHistory, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LedgerMutationResultDtoImpl &&
            (identical(other.walletBalance, walletBalance) ||
                other.walletBalance == walletBalance) &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.reviewStatus, reviewStatus) ||
                other.reviewStatus == reviewStatus) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            (identical(other.shouldRefreshHistory, shouldRefreshHistory) ||
                other.shouldRefreshHistory == shouldRefreshHistory) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, walletBalance, transaction,
      reviewStatus, idempotencyKey, shouldRefreshHistory, message);

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LedgerMutationResultDtoImplCopyWith<_$LedgerMutationResultDtoImpl>
      get copyWith => __$$LedgerMutationResultDtoImplCopyWithImpl<
          _$LedgerMutationResultDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LedgerMutationResultDtoImplToJson(
      this,
    );
  }
}

abstract class _LedgerMutationResultDto extends LedgerMutationResultDto {
  const factory _LedgerMutationResultDto(
      {required final WalletBalanceDto walletBalance,
      required final CoinTransactionDto transaction,
      required final RewardReviewStatus reviewStatus,
      required final String idempotencyKey,
      final bool shouldRefreshHistory,
      final String? message}) = _$LedgerMutationResultDtoImpl;
  const _LedgerMutationResultDto._() : super._();

  factory _LedgerMutationResultDto.fromJson(Map<String, dynamic> json) =
      _$LedgerMutationResultDtoImpl.fromJson;

  @override
  WalletBalanceDto get walletBalance;
  @override
  CoinTransactionDto get transaction;
  @override
  RewardReviewStatus get reviewStatus;
  @override
  String get idempotencyKey;
  @override
  bool get shouldRefreshHistory;
  @override
  String? get message;

  /// Create a copy of LedgerMutationResultDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LedgerMutationResultDtoImplCopyWith<_$LedgerMutationResultDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

TaskRewardClaimRequestDto _$TaskRewardClaimRequestDtoFromJson(
    Map<String, dynamic> json) {
  return _TaskRewardClaimRequestDto.fromJson(json);
}

/// @nodoc
mixin _$TaskRewardClaimRequestDto {
  String get userId => throw _privateConstructorUsedError;
  String get taskId => throw _privateConstructorUsedError;
  String get completionId => throw _privateConstructorUsedError;
  int get rewardAmount => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;
  String get serverProof => throw _privateConstructorUsedError;
  String get deviceAttestationToken => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this TaskRewardClaimRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskRewardClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskRewardClaimRequestDtoCopyWith<TaskRewardClaimRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskRewardClaimRequestDtoCopyWith<$Res> {
  factory $TaskRewardClaimRequestDtoCopyWith(TaskRewardClaimRequestDto value,
          $Res Function(TaskRewardClaimRequestDto) then) =
      _$TaskRewardClaimRequestDtoCopyWithImpl<$Res, TaskRewardClaimRequestDto>;
  @useResult
  $Res call(
      {String userId,
      String taskId,
      String completionId,
      int rewardAmount,
      DateTime completedAt,
      String serverProof,
      String deviceAttestationToken,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$TaskRewardClaimRequestDtoCopyWithImpl<$Res,
        $Val extends TaskRewardClaimRequestDto>
    implements $TaskRewardClaimRequestDtoCopyWith<$Res> {
  _$TaskRewardClaimRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskRewardClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? taskId = null,
    Object? completionId = null,
    Object? rewardAmount = null,
    Object? completedAt = null,
    Object? serverProof = null,
    Object? deviceAttestationToken = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      completionId: null == completionId
          ? _value.completionId
          : completionId // ignore: cast_nullable_to_non_nullable
              as String,
      rewardAmount: null == rewardAmount
          ? _value.rewardAmount
          : rewardAmount // ignore: cast_nullable_to_non_nullable
              as int,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      serverProof: null == serverProof
          ? _value.serverProof
          : serverProof // ignore: cast_nullable_to_non_nullable
              as String,
      deviceAttestationToken: null == deviceAttestationToken
          ? _value.deviceAttestationToken
          : deviceAttestationToken // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskRewardClaimRequestDtoImplCopyWith<$Res>
    implements $TaskRewardClaimRequestDtoCopyWith<$Res> {
  factory _$$TaskRewardClaimRequestDtoImplCopyWith(
          _$TaskRewardClaimRequestDtoImpl value,
          $Res Function(_$TaskRewardClaimRequestDtoImpl) then) =
      __$$TaskRewardClaimRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String taskId,
      String completionId,
      int rewardAmount,
      DateTime completedAt,
      String serverProof,
      String deviceAttestationToken,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$TaskRewardClaimRequestDtoImplCopyWithImpl<$Res>
    extends _$TaskRewardClaimRequestDtoCopyWithImpl<$Res,
        _$TaskRewardClaimRequestDtoImpl>
    implements _$$TaskRewardClaimRequestDtoImplCopyWith<$Res> {
  __$$TaskRewardClaimRequestDtoImplCopyWithImpl(
      _$TaskRewardClaimRequestDtoImpl _value,
      $Res Function(_$TaskRewardClaimRequestDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskRewardClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? taskId = null,
    Object? completionId = null,
    Object? rewardAmount = null,
    Object? completedAt = null,
    Object? serverProof = null,
    Object? deviceAttestationToken = null,
    Object? metadata = null,
  }) {
    return _then(_$TaskRewardClaimRequestDtoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      completionId: null == completionId
          ? _value.completionId
          : completionId // ignore: cast_nullable_to_non_nullable
              as String,
      rewardAmount: null == rewardAmount
          ? _value.rewardAmount
          : rewardAmount // ignore: cast_nullable_to_non_nullable
              as int,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      serverProof: null == serverProof
          ? _value.serverProof
          : serverProof // ignore: cast_nullable_to_non_nullable
              as String,
      deviceAttestationToken: null == deviceAttestationToken
          ? _value.deviceAttestationToken
          : deviceAttestationToken // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskRewardClaimRequestDtoImpl implements _TaskRewardClaimRequestDto {
  const _$TaskRewardClaimRequestDtoImpl(
      {required this.userId,
      required this.taskId,
      required this.completionId,
      required this.rewardAmount,
      required this.completedAt,
      required this.serverProof,
      required this.deviceAttestationToken,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata;

  factory _$TaskRewardClaimRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskRewardClaimRequestDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String taskId;
  @override
  final String completionId;
  @override
  final int rewardAmount;
  @override
  final DateTime completedAt;
  @override
  final String serverProof;
  @override
  final String deviceAttestationToken;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'TaskRewardClaimRequestDto(userId: $userId, taskId: $taskId, completionId: $completionId, rewardAmount: $rewardAmount, completedAt: $completedAt, serverProof: $serverProof, deviceAttestationToken: $deviceAttestationToken, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskRewardClaimRequestDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.completionId, completionId) ||
                other.completionId == completionId) &&
            (identical(other.rewardAmount, rewardAmount) ||
                other.rewardAmount == rewardAmount) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.serverProof, serverProof) ||
                other.serverProof == serverProof) &&
            (identical(other.deviceAttestationToken, deviceAttestationToken) ||
                other.deviceAttestationToken == deviceAttestationToken) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      taskId,
      completionId,
      rewardAmount,
      completedAt,
      serverProof,
      deviceAttestationToken,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of TaskRewardClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskRewardClaimRequestDtoImplCopyWith<_$TaskRewardClaimRequestDtoImpl>
      get copyWith => __$$TaskRewardClaimRequestDtoImplCopyWithImpl<
          _$TaskRewardClaimRequestDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskRewardClaimRequestDtoImplToJson(
      this,
    );
  }
}

abstract class _TaskRewardClaimRequestDto implements TaskRewardClaimRequestDto {
  const factory _TaskRewardClaimRequestDto(
      {required final String userId,
      required final String taskId,
      required final String completionId,
      required final int rewardAmount,
      required final DateTime completedAt,
      required final String serverProof,
      required final String deviceAttestationToken,
      final Map<String, dynamic> metadata}) = _$TaskRewardClaimRequestDtoImpl;

  factory _TaskRewardClaimRequestDto.fromJson(Map<String, dynamic> json) =
      _$TaskRewardClaimRequestDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get taskId;
  @override
  String get completionId;
  @override
  int get rewardAmount;
  @override
  DateTime get completedAt;
  @override
  String get serverProof;
  @override
  String get deviceAttestationToken;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of TaskRewardClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskRewardClaimRequestDtoImplCopyWith<_$TaskRewardClaimRequestDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

RewardedAdClaimRequestDto _$RewardedAdClaimRequestDtoFromJson(
    Map<String, dynamic> json) {
  return _RewardedAdClaimRequestDto.fromJson(json);
}

/// @nodoc
mixin _$RewardedAdClaimRequestDto {
  String get userId => throw _privateConstructorUsedError;
  String get adUnitId => throw _privateConstructorUsedError;
  AdNetworkType get adNetwork => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  String get networkTransactionId => throw _privateConstructorUsedError;
  String get rewardNonce => throw _privateConstructorUsedError;
  int get rewardAmount => throw _privateConstructorUsedError;
  int get watchedMillis => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;
  String get serverSideVerificationToken => throw _privateConstructorUsedError;
  String get deviceAttestationToken => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this RewardedAdClaimRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RewardedAdClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RewardedAdClaimRequestDtoCopyWith<RewardedAdClaimRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RewardedAdClaimRequestDtoCopyWith<$Res> {
  factory $RewardedAdClaimRequestDtoCopyWith(RewardedAdClaimRequestDto value,
          $Res Function(RewardedAdClaimRequestDto) then) =
      _$RewardedAdClaimRequestDtoCopyWithImpl<$Res, RewardedAdClaimRequestDto>;
  @useResult
  $Res call(
      {String userId,
      String adUnitId,
      AdNetworkType adNetwork,
      String sessionId,
      String networkTransactionId,
      String rewardNonce,
      int rewardAmount,
      int watchedMillis,
      DateTime completedAt,
      String serverSideVerificationToken,
      String deviceAttestationToken,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$RewardedAdClaimRequestDtoCopyWithImpl<$Res,
        $Val extends RewardedAdClaimRequestDto>
    implements $RewardedAdClaimRequestDtoCopyWith<$Res> {
  _$RewardedAdClaimRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RewardedAdClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? adUnitId = null,
    Object? adNetwork = null,
    Object? sessionId = null,
    Object? networkTransactionId = null,
    Object? rewardNonce = null,
    Object? rewardAmount = null,
    Object? watchedMillis = null,
    Object? completedAt = null,
    Object? serverSideVerificationToken = null,
    Object? deviceAttestationToken = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      adUnitId: null == adUnitId
          ? _value.adUnitId
          : adUnitId // ignore: cast_nullable_to_non_nullable
              as String,
      adNetwork: null == adNetwork
          ? _value.adNetwork
          : adNetwork // ignore: cast_nullable_to_non_nullable
              as AdNetworkType,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      networkTransactionId: null == networkTransactionId
          ? _value.networkTransactionId
          : networkTransactionId // ignore: cast_nullable_to_non_nullable
              as String,
      rewardNonce: null == rewardNonce
          ? _value.rewardNonce
          : rewardNonce // ignore: cast_nullable_to_non_nullable
              as String,
      rewardAmount: null == rewardAmount
          ? _value.rewardAmount
          : rewardAmount // ignore: cast_nullable_to_non_nullable
              as int,
      watchedMillis: null == watchedMillis
          ? _value.watchedMillis
          : watchedMillis // ignore: cast_nullable_to_non_nullable
              as int,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      serverSideVerificationToken: null == serverSideVerificationToken
          ? _value.serverSideVerificationToken
          : serverSideVerificationToken // ignore: cast_nullable_to_non_nullable
              as String,
      deviceAttestationToken: null == deviceAttestationToken
          ? _value.deviceAttestationToken
          : deviceAttestationToken // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RewardedAdClaimRequestDtoImplCopyWith<$Res>
    implements $RewardedAdClaimRequestDtoCopyWith<$Res> {
  factory _$$RewardedAdClaimRequestDtoImplCopyWith(
          _$RewardedAdClaimRequestDtoImpl value,
          $Res Function(_$RewardedAdClaimRequestDtoImpl) then) =
      __$$RewardedAdClaimRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String adUnitId,
      AdNetworkType adNetwork,
      String sessionId,
      String networkTransactionId,
      String rewardNonce,
      int rewardAmount,
      int watchedMillis,
      DateTime completedAt,
      String serverSideVerificationToken,
      String deviceAttestationToken,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$RewardedAdClaimRequestDtoImplCopyWithImpl<$Res>
    extends _$RewardedAdClaimRequestDtoCopyWithImpl<$Res,
        _$RewardedAdClaimRequestDtoImpl>
    implements _$$RewardedAdClaimRequestDtoImplCopyWith<$Res> {
  __$$RewardedAdClaimRequestDtoImplCopyWithImpl(
      _$RewardedAdClaimRequestDtoImpl _value,
      $Res Function(_$RewardedAdClaimRequestDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of RewardedAdClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? adUnitId = null,
    Object? adNetwork = null,
    Object? sessionId = null,
    Object? networkTransactionId = null,
    Object? rewardNonce = null,
    Object? rewardAmount = null,
    Object? watchedMillis = null,
    Object? completedAt = null,
    Object? serverSideVerificationToken = null,
    Object? deviceAttestationToken = null,
    Object? metadata = null,
  }) {
    return _then(_$RewardedAdClaimRequestDtoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      adUnitId: null == adUnitId
          ? _value.adUnitId
          : adUnitId // ignore: cast_nullable_to_non_nullable
              as String,
      adNetwork: null == adNetwork
          ? _value.adNetwork
          : adNetwork // ignore: cast_nullable_to_non_nullable
              as AdNetworkType,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      networkTransactionId: null == networkTransactionId
          ? _value.networkTransactionId
          : networkTransactionId // ignore: cast_nullable_to_non_nullable
              as String,
      rewardNonce: null == rewardNonce
          ? _value.rewardNonce
          : rewardNonce // ignore: cast_nullable_to_non_nullable
              as String,
      rewardAmount: null == rewardAmount
          ? _value.rewardAmount
          : rewardAmount // ignore: cast_nullable_to_non_nullable
              as int,
      watchedMillis: null == watchedMillis
          ? _value.watchedMillis
          : watchedMillis // ignore: cast_nullable_to_non_nullable
              as int,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      serverSideVerificationToken: null == serverSideVerificationToken
          ? _value.serverSideVerificationToken
          : serverSideVerificationToken // ignore: cast_nullable_to_non_nullable
              as String,
      deviceAttestationToken: null == deviceAttestationToken
          ? _value.deviceAttestationToken
          : deviceAttestationToken // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RewardedAdClaimRequestDtoImpl implements _RewardedAdClaimRequestDto {
  const _$RewardedAdClaimRequestDtoImpl(
      {required this.userId,
      required this.adUnitId,
      required this.adNetwork,
      required this.sessionId,
      required this.networkTransactionId,
      required this.rewardNonce,
      required this.rewardAmount,
      required this.watchedMillis,
      required this.completedAt,
      required this.serverSideVerificationToken,
      required this.deviceAttestationToken,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata;

  factory _$RewardedAdClaimRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RewardedAdClaimRequestDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String adUnitId;
  @override
  final AdNetworkType adNetwork;
  @override
  final String sessionId;
  @override
  final String networkTransactionId;
  @override
  final String rewardNonce;
  @override
  final int rewardAmount;
  @override
  final int watchedMillis;
  @override
  final DateTime completedAt;
  @override
  final String serverSideVerificationToken;
  @override
  final String deviceAttestationToken;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'RewardedAdClaimRequestDto(userId: $userId, adUnitId: $adUnitId, adNetwork: $adNetwork, sessionId: $sessionId, networkTransactionId: $networkTransactionId, rewardNonce: $rewardNonce, rewardAmount: $rewardAmount, watchedMillis: $watchedMillis, completedAt: $completedAt, serverSideVerificationToken: $serverSideVerificationToken, deviceAttestationToken: $deviceAttestationToken, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RewardedAdClaimRequestDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.adUnitId, adUnitId) ||
                other.adUnitId == adUnitId) &&
            (identical(other.adNetwork, adNetwork) ||
                other.adNetwork == adNetwork) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.networkTransactionId, networkTransactionId) ||
                other.networkTransactionId == networkTransactionId) &&
            (identical(other.rewardNonce, rewardNonce) ||
                other.rewardNonce == rewardNonce) &&
            (identical(other.rewardAmount, rewardAmount) ||
                other.rewardAmount == rewardAmount) &&
            (identical(other.watchedMillis, watchedMillis) ||
                other.watchedMillis == watchedMillis) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.serverSideVerificationToken,
                    serverSideVerificationToken) ||
                other.serverSideVerificationToken ==
                    serverSideVerificationToken) &&
            (identical(other.deviceAttestationToken, deviceAttestationToken) ||
                other.deviceAttestationToken == deviceAttestationToken) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      adUnitId,
      adNetwork,
      sessionId,
      networkTransactionId,
      rewardNonce,
      rewardAmount,
      watchedMillis,
      completedAt,
      serverSideVerificationToken,
      deviceAttestationToken,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of RewardedAdClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RewardedAdClaimRequestDtoImplCopyWith<_$RewardedAdClaimRequestDtoImpl>
      get copyWith => __$$RewardedAdClaimRequestDtoImplCopyWithImpl<
          _$RewardedAdClaimRequestDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RewardedAdClaimRequestDtoImplToJson(
      this,
    );
  }
}

abstract class _RewardedAdClaimRequestDto implements RewardedAdClaimRequestDto {
  const factory _RewardedAdClaimRequestDto(
      {required final String userId,
      required final String adUnitId,
      required final AdNetworkType adNetwork,
      required final String sessionId,
      required final String networkTransactionId,
      required final String rewardNonce,
      required final int rewardAmount,
      required final int watchedMillis,
      required final DateTime completedAt,
      required final String serverSideVerificationToken,
      required final String deviceAttestationToken,
      final Map<String, dynamic> metadata}) = _$RewardedAdClaimRequestDtoImpl;

  factory _RewardedAdClaimRequestDto.fromJson(Map<String, dynamic> json) =
      _$RewardedAdClaimRequestDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get adUnitId;
  @override
  AdNetworkType get adNetwork;
  @override
  String get sessionId;
  @override
  String get networkTransactionId;
  @override
  String get rewardNonce;
  @override
  int get rewardAmount;
  @override
  int get watchedMillis;
  @override
  DateTime get completedAt;
  @override
  String get serverSideVerificationToken;
  @override
  String get deviceAttestationToken;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of RewardedAdClaimRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RewardedAdClaimRequestDtoImplCopyWith<_$RewardedAdClaimRequestDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PurchaseVerificationRequestDto _$PurchaseVerificationRequestDtoFromJson(
    Map<String, dynamic> json) {
  return _PurchaseVerificationRequestDto.fromJson(json);
}

/// @nodoc
mixin _$PurchaseVerificationRequestDto {
  String get userId => throw _privateConstructorUsedError;
  String get packageSku => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  StoreProvider get store => throw _privateConstructorUsedError;
  String get transactionId => throw _privateConstructorUsedError;
  String get purchaseToken => throw _privateConstructorUsedError;
  String get signedPayload => throw _privateConstructorUsedError;
  int get priceMicros => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;
  String get deviceAttestationToken => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this PurchaseVerificationRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PurchaseVerificationRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PurchaseVerificationRequestDtoCopyWith<PurchaseVerificationRequestDto>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseVerificationRequestDtoCopyWith<$Res> {
  factory $PurchaseVerificationRequestDtoCopyWith(
          PurchaseVerificationRequestDto value,
          $Res Function(PurchaseVerificationRequestDto) then) =
      _$PurchaseVerificationRequestDtoCopyWithImpl<$Res,
          PurchaseVerificationRequestDto>;
  @useResult
  $Res call(
      {String userId,
      String packageSku,
      String productId,
      StoreProvider store,
      String transactionId,
      String purchaseToken,
      String signedPayload,
      int priceMicros,
      String currencyCode,
      DateTime completedAt,
      String deviceAttestationToken,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$PurchaseVerificationRequestDtoCopyWithImpl<$Res,
        $Val extends PurchaseVerificationRequestDto>
    implements $PurchaseVerificationRequestDtoCopyWith<$Res> {
  _$PurchaseVerificationRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseVerificationRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? packageSku = null,
    Object? productId = null,
    Object? store = null,
    Object? transactionId = null,
    Object? purchaseToken = null,
    Object? signedPayload = null,
    Object? priceMicros = null,
    Object? currencyCode = null,
    Object? completedAt = null,
    Object? deviceAttestationToken = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      packageSku: null == packageSku
          ? _value.packageSku
          : packageSku // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      store: null == store
          ? _value.store
          : store // ignore: cast_nullable_to_non_nullable
              as StoreProvider,
      transactionId: null == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String,
      purchaseToken: null == purchaseToken
          ? _value.purchaseToken
          : purchaseToken // ignore: cast_nullable_to_non_nullable
              as String,
      signedPayload: null == signedPayload
          ? _value.signedPayload
          : signedPayload // ignore: cast_nullable_to_non_nullable
              as String,
      priceMicros: null == priceMicros
          ? _value.priceMicros
          : priceMicros // ignore: cast_nullable_to_non_nullable
              as int,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deviceAttestationToken: null == deviceAttestationToken
          ? _value.deviceAttestationToken
          : deviceAttestationToken // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PurchaseVerificationRequestDtoImplCopyWith<$Res>
    implements $PurchaseVerificationRequestDtoCopyWith<$Res> {
  factory _$$PurchaseVerificationRequestDtoImplCopyWith(
          _$PurchaseVerificationRequestDtoImpl value,
          $Res Function(_$PurchaseVerificationRequestDtoImpl) then) =
      __$$PurchaseVerificationRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String packageSku,
      String productId,
      StoreProvider store,
      String transactionId,
      String purchaseToken,
      String signedPayload,
      int priceMicros,
      String currencyCode,
      DateTime completedAt,
      String deviceAttestationToken,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$PurchaseVerificationRequestDtoImplCopyWithImpl<$Res>
    extends _$PurchaseVerificationRequestDtoCopyWithImpl<$Res,
        _$PurchaseVerificationRequestDtoImpl>
    implements _$$PurchaseVerificationRequestDtoImplCopyWith<$Res> {
  __$$PurchaseVerificationRequestDtoImplCopyWithImpl(
      _$PurchaseVerificationRequestDtoImpl _value,
      $Res Function(_$PurchaseVerificationRequestDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseVerificationRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? packageSku = null,
    Object? productId = null,
    Object? store = null,
    Object? transactionId = null,
    Object? purchaseToken = null,
    Object? signedPayload = null,
    Object? priceMicros = null,
    Object? currencyCode = null,
    Object? completedAt = null,
    Object? deviceAttestationToken = null,
    Object? metadata = null,
  }) {
    return _then(_$PurchaseVerificationRequestDtoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      packageSku: null == packageSku
          ? _value.packageSku
          : packageSku // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      store: null == store
          ? _value.store
          : store // ignore: cast_nullable_to_non_nullable
              as StoreProvider,
      transactionId: null == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String,
      purchaseToken: null == purchaseToken
          ? _value.purchaseToken
          : purchaseToken // ignore: cast_nullable_to_non_nullable
              as String,
      signedPayload: null == signedPayload
          ? _value.signedPayload
          : signedPayload // ignore: cast_nullable_to_non_nullable
              as String,
      priceMicros: null == priceMicros
          ? _value.priceMicros
          : priceMicros // ignore: cast_nullable_to_non_nullable
              as int,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deviceAttestationToken: null == deviceAttestationToken
          ? _value.deviceAttestationToken
          : deviceAttestationToken // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseVerificationRequestDtoImpl
    implements _PurchaseVerificationRequestDto {
  const _$PurchaseVerificationRequestDtoImpl(
      {required this.userId,
      required this.packageSku,
      required this.productId,
      required this.store,
      required this.transactionId,
      required this.purchaseToken,
      required this.signedPayload,
      required this.priceMicros,
      required this.currencyCode,
      required this.completedAt,
      required this.deviceAttestationToken,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata;

  factory _$PurchaseVerificationRequestDtoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PurchaseVerificationRequestDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String packageSku;
  @override
  final String productId;
  @override
  final StoreProvider store;
  @override
  final String transactionId;
  @override
  final String purchaseToken;
  @override
  final String signedPayload;
  @override
  final int priceMicros;
  @override
  final String currencyCode;
  @override
  final DateTime completedAt;
  @override
  final String deviceAttestationToken;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'PurchaseVerificationRequestDto(userId: $userId, packageSku: $packageSku, productId: $productId, store: $store, transactionId: $transactionId, purchaseToken: $purchaseToken, signedPayload: $signedPayload, priceMicros: $priceMicros, currencyCode: $currencyCode, completedAt: $completedAt, deviceAttestationToken: $deviceAttestationToken, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseVerificationRequestDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.packageSku, packageSku) ||
                other.packageSku == packageSku) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.store, store) || other.store == store) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.purchaseToken, purchaseToken) ||
                other.purchaseToken == purchaseToken) &&
            (identical(other.signedPayload, signedPayload) ||
                other.signedPayload == signedPayload) &&
            (identical(other.priceMicros, priceMicros) ||
                other.priceMicros == priceMicros) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.deviceAttestationToken, deviceAttestationToken) ||
                other.deviceAttestationToken == deviceAttestationToken) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      packageSku,
      productId,
      store,
      transactionId,
      purchaseToken,
      signedPayload,
      priceMicros,
      currencyCode,
      completedAt,
      deviceAttestationToken,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of PurchaseVerificationRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseVerificationRequestDtoImplCopyWith<
          _$PurchaseVerificationRequestDtoImpl>
      get copyWith => __$$PurchaseVerificationRequestDtoImplCopyWithImpl<
          _$PurchaseVerificationRequestDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseVerificationRequestDtoImplToJson(
      this,
    );
  }
}

abstract class _PurchaseVerificationRequestDto
    implements PurchaseVerificationRequestDto {
  const factory _PurchaseVerificationRequestDto(
          {required final String userId,
          required final String packageSku,
          required final String productId,
          required final StoreProvider store,
          required final String transactionId,
          required final String purchaseToken,
          required final String signedPayload,
          required final int priceMicros,
          required final String currencyCode,
          required final DateTime completedAt,
          required final String deviceAttestationToken,
          final Map<String, dynamic> metadata}) =
      _$PurchaseVerificationRequestDtoImpl;

  factory _PurchaseVerificationRequestDto.fromJson(Map<String, dynamic> json) =
      _$PurchaseVerificationRequestDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get packageSku;
  @override
  String get productId;
  @override
  StoreProvider get store;
  @override
  String get transactionId;
  @override
  String get purchaseToken;
  @override
  String get signedPayload;
  @override
  int get priceMicros;
  @override
  String get currencyCode;
  @override
  DateTime get completedAt;
  @override
  String get deviceAttestationToken;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of PurchaseVerificationRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseVerificationRequestDtoImplCopyWith<
          _$PurchaseVerificationRequestDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SpendCoinsRequestDto _$SpendCoinsRequestDtoFromJson(Map<String, dynamic> json) {
  return _SpendCoinsRequestDto.fromJson(json);
}

/// @nodoc
mixin _$SpendCoinsRequestDto {
  String get userId => throw _privateConstructorUsedError;
  String get featureId => throw _privateConstructorUsedError;
  String get referenceId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  String get idempotencyKey => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this SpendCoinsRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpendCoinsRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpendCoinsRequestDtoCopyWith<SpendCoinsRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpendCoinsRequestDtoCopyWith<$Res> {
  factory $SpendCoinsRequestDtoCopyWith(SpendCoinsRequestDto value,
          $Res Function(SpendCoinsRequestDto) then) =
      _$SpendCoinsRequestDtoCopyWithImpl<$Res, SpendCoinsRequestDto>;
  @useResult
  $Res call(
      {String userId,
      String featureId,
      String referenceId,
      int amount,
      String idempotencyKey,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$SpendCoinsRequestDtoCopyWithImpl<$Res,
        $Val extends SpendCoinsRequestDto>
    implements $SpendCoinsRequestDtoCopyWith<$Res> {
  _$SpendCoinsRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpendCoinsRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? featureId = null,
    Object? referenceId = null,
    Object? amount = null,
    Object? idempotencyKey = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      featureId: null == featureId
          ? _value.featureId
          : featureId // ignore: cast_nullable_to_non_nullable
              as String,
      referenceId: null == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      idempotencyKey: null == idempotencyKey
          ? _value.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpendCoinsRequestDtoImplCopyWith<$Res>
    implements $SpendCoinsRequestDtoCopyWith<$Res> {
  factory _$$SpendCoinsRequestDtoImplCopyWith(_$SpendCoinsRequestDtoImpl value,
          $Res Function(_$SpendCoinsRequestDtoImpl) then) =
      __$$SpendCoinsRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String featureId,
      String referenceId,
      int amount,
      String idempotencyKey,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$SpendCoinsRequestDtoImplCopyWithImpl<$Res>
    extends _$SpendCoinsRequestDtoCopyWithImpl<$Res, _$SpendCoinsRequestDtoImpl>
    implements _$$SpendCoinsRequestDtoImplCopyWith<$Res> {
  __$$SpendCoinsRequestDtoImplCopyWithImpl(_$SpendCoinsRequestDtoImpl _value,
      $Res Function(_$SpendCoinsRequestDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpendCoinsRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? featureId = null,
    Object? referenceId = null,
    Object? amount = null,
    Object? idempotencyKey = null,
    Object? metadata = null,
  }) {
    return _then(_$SpendCoinsRequestDtoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      featureId: null == featureId
          ? _value.featureId
          : featureId // ignore: cast_nullable_to_non_nullable
              as String,
      referenceId: null == referenceId
          ? _value.referenceId
          : referenceId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      idempotencyKey: null == idempotencyKey
          ? _value.idempotencyKey
          : idempotencyKey // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SpendCoinsRequestDtoImpl implements _SpendCoinsRequestDto {
  const _$SpendCoinsRequestDtoImpl(
      {required this.userId,
      required this.featureId,
      required this.referenceId,
      required this.amount,
      required this.idempotencyKey,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata;

  factory _$SpendCoinsRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpendCoinsRequestDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String featureId;
  @override
  final String referenceId;
  @override
  final int amount;
  @override
  final String idempotencyKey;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'SpendCoinsRequestDto(userId: $userId, featureId: $featureId, referenceId: $referenceId, amount: $amount, idempotencyKey: $idempotencyKey, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpendCoinsRequestDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.featureId, featureId) ||
                other.featureId == featureId) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, featureId, referenceId,
      amount, idempotencyKey, const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of SpendCoinsRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpendCoinsRequestDtoImplCopyWith<_$SpendCoinsRequestDtoImpl>
      get copyWith =>
          __$$SpendCoinsRequestDtoImplCopyWithImpl<_$SpendCoinsRequestDtoImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpendCoinsRequestDtoImplToJson(
      this,
    );
  }
}

abstract class _SpendCoinsRequestDto implements SpendCoinsRequestDto {
  const factory _SpendCoinsRequestDto(
      {required final String userId,
      required final String featureId,
      required final String referenceId,
      required final int amount,
      required final String idempotencyKey,
      final Map<String, dynamic> metadata}) = _$SpendCoinsRequestDtoImpl;

  factory _SpendCoinsRequestDto.fromJson(Map<String, dynamic> json) =
      _$SpendCoinsRequestDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get featureId;
  @override
  String get referenceId;
  @override
  int get amount;
  @override
  String get idempotencyKey;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of SpendCoinsRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpendCoinsRequestDtoImplCopyWith<_$SpendCoinsRequestDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
