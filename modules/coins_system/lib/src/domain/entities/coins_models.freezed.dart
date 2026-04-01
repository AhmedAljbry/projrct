// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coins_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletBalance _$WalletBalanceFromJson(Map<String, dynamic> json) {
  return _WalletBalance.fromJson(json);
}

/// @nodoc
mixin _$WalletBalance {
  int get available => throw _privateConstructorUsedError;
  int get reserved => throw _privateConstructorUsedError;
  int get lifetimeEarned => throw _privateConstructorUsedError;
  int get lifetimeSpent => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this WalletBalance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletBalanceCopyWith<WalletBalance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletBalanceCopyWith<$Res> {
  factory $WalletBalanceCopyWith(
          WalletBalance value, $Res Function(WalletBalance) then) =
      _$WalletBalanceCopyWithImpl<$Res, WalletBalance>;
  @useResult
  $Res call(
      {int available,
      int reserved,
      int lifetimeEarned,
      int lifetimeSpent,
      DateTime updatedAt});
}

/// @nodoc
class _$WalletBalanceCopyWithImpl<$Res, $Val extends WalletBalance>
    implements $WalletBalanceCopyWith<$Res> {
  _$WalletBalanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletBalance
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
abstract class _$$WalletBalanceImplCopyWith<$Res>
    implements $WalletBalanceCopyWith<$Res> {
  factory _$$WalletBalanceImplCopyWith(
          _$WalletBalanceImpl value, $Res Function(_$WalletBalanceImpl) then) =
      __$$WalletBalanceImplCopyWithImpl<$Res>;
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
class __$$WalletBalanceImplCopyWithImpl<$Res>
    extends _$WalletBalanceCopyWithImpl<$Res, _$WalletBalanceImpl>
    implements _$$WalletBalanceImplCopyWith<$Res> {
  __$$WalletBalanceImplCopyWithImpl(
      _$WalletBalanceImpl _value, $Res Function(_$WalletBalanceImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletBalance
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
    return _then(_$WalletBalanceImpl(
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
class _$WalletBalanceImpl implements _WalletBalance {
  const _$WalletBalanceImpl(
      {this.available = 0,
      this.reserved = 0,
      this.lifetimeEarned = 0,
      this.lifetimeSpent = 0,
      required this.updatedAt});

  factory _$WalletBalanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletBalanceImplFromJson(json);

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
    return 'WalletBalance(available: $available, reserved: $reserved, lifetimeEarned: $lifetimeEarned, lifetimeSpent: $lifetimeSpent, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletBalanceImpl &&
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

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletBalanceImplCopyWith<_$WalletBalanceImpl> get copyWith =>
      __$$WalletBalanceImplCopyWithImpl<_$WalletBalanceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletBalanceImplToJson(
      this,
    );
  }
}

abstract class _WalletBalance implements WalletBalance {
  const factory _WalletBalance(
      {final int available,
      final int reserved,
      final int lifetimeEarned,
      final int lifetimeSpent,
      required final DateTime updatedAt}) = _$WalletBalanceImpl;

  factory _WalletBalance.fromJson(Map<String, dynamic> json) =
      _$WalletBalanceImpl.fromJson;

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

  /// Create a copy of WalletBalance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletBalanceImplCopyWith<_$WalletBalanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoinPackage _$CoinPackageFromJson(Map<String, dynamic> json) {
  return _CoinPackage.fromJson(json);
}

/// @nodoc
mixin _$CoinPackage {
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

  /// Serializes this CoinPackage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoinPackage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoinPackageCopyWith<CoinPackage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinPackageCopyWith<$Res> {
  factory $CoinPackageCopyWith(
          CoinPackage value, $Res Function(CoinPackage) then) =
      _$CoinPackageCopyWithImpl<$Res, CoinPackage>;
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
class _$CoinPackageCopyWithImpl<$Res, $Val extends CoinPackage>
    implements $CoinPackageCopyWith<$Res> {
  _$CoinPackageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoinPackage
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
abstract class _$$CoinPackageImplCopyWith<$Res>
    implements $CoinPackageCopyWith<$Res> {
  factory _$$CoinPackageImplCopyWith(
          _$CoinPackageImpl value, $Res Function(_$CoinPackageImpl) then) =
      __$$CoinPackageImplCopyWithImpl<$Res>;
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
class __$$CoinPackageImplCopyWithImpl<$Res>
    extends _$CoinPackageCopyWithImpl<$Res, _$CoinPackageImpl>
    implements _$$CoinPackageImplCopyWith<$Res> {
  __$$CoinPackageImplCopyWithImpl(
      _$CoinPackageImpl _value, $Res Function(_$CoinPackageImpl) _then)
      : super(_value, _then);

  /// Create a copy of CoinPackage
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
    return _then(_$CoinPackageImpl(
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
class _$CoinPackageImpl implements _CoinPackage {
  const _$CoinPackageImpl(
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
      this.badge});

  factory _$CoinPackageImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoinPackageImplFromJson(json);

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
    return 'CoinPackage(sku: $sku, title: $title, subtitle: $subtitle, coins: $coins, bonusCoins: $bonusCoins, priceLabel: $priceLabel, priceMicros: $priceMicros, currencyCode: $currencyCode, productId: $productId, isHighlighted: $isHighlighted, badge: $badge)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoinPackageImpl &&
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

  /// Create a copy of CoinPackage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoinPackageImplCopyWith<_$CoinPackageImpl> get copyWith =>
      __$$CoinPackageImplCopyWithImpl<_$CoinPackageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoinPackageImplToJson(
      this,
    );
  }
}

abstract class _CoinPackage implements CoinPackage {
  const factory _CoinPackage(
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
      final String? badge}) = _$CoinPackageImpl;

  factory _CoinPackage.fromJson(Map<String, dynamic> json) =
      _$CoinPackageImpl.fromJson;

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

  /// Create a copy of CoinPackage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoinPackageImplCopyWith<_$CoinPackageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PremiumFeature _$PremiumFeatureFromJson(Map<String, dynamic> json) {
  return _PremiumFeature.fromJson(json);
}

/// @nodoc
mixin _$PremiumFeature {
  String get featureId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get coinCost => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  bool get isLimitedTime => throw _privateConstructorUsedError;

  /// Serializes this PremiumFeature to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PremiumFeature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PremiumFeatureCopyWith<PremiumFeature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PremiumFeatureCopyWith<$Res> {
  factory $PremiumFeatureCopyWith(
          PremiumFeature value, $Res Function(PremiumFeature) then) =
      _$PremiumFeatureCopyWithImpl<$Res, PremiumFeature>;
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
class _$PremiumFeatureCopyWithImpl<$Res, $Val extends PremiumFeature>
    implements $PremiumFeatureCopyWith<$Res> {
  _$PremiumFeatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PremiumFeature
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
abstract class _$$PremiumFeatureImplCopyWith<$Res>
    implements $PremiumFeatureCopyWith<$Res> {
  factory _$$PremiumFeatureImplCopyWith(_$PremiumFeatureImpl value,
          $Res Function(_$PremiumFeatureImpl) then) =
      __$$PremiumFeatureImplCopyWithImpl<$Res>;
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
class __$$PremiumFeatureImplCopyWithImpl<$Res>
    extends _$PremiumFeatureCopyWithImpl<$Res, _$PremiumFeatureImpl>
    implements _$$PremiumFeatureImplCopyWith<$Res> {
  __$$PremiumFeatureImplCopyWithImpl(
      _$PremiumFeatureImpl _value, $Res Function(_$PremiumFeatureImpl) _then)
      : super(_value, _then);

  /// Create a copy of PremiumFeature
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
    return _then(_$PremiumFeatureImpl(
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
class _$PremiumFeatureImpl implements _PremiumFeature {
  const _$PremiumFeatureImpl(
      {required this.featureId,
      required this.title,
      required this.description,
      required this.coinCost,
      required this.category,
      this.isLimitedTime = false});

  factory _$PremiumFeatureImpl.fromJson(Map<String, dynamic> json) =>
      _$$PremiumFeatureImplFromJson(json);

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
    return 'PremiumFeature(featureId: $featureId, title: $title, description: $description, coinCost: $coinCost, category: $category, isLimitedTime: $isLimitedTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PremiumFeatureImpl &&
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

  /// Create a copy of PremiumFeature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PremiumFeatureImplCopyWith<_$PremiumFeatureImpl> get copyWith =>
      __$$PremiumFeatureImplCopyWithImpl<_$PremiumFeatureImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PremiumFeatureImplToJson(
      this,
    );
  }
}

abstract class _PremiumFeature implements PremiumFeature {
  const factory _PremiumFeature(
      {required final String featureId,
      required final String title,
      required final String description,
      required final int coinCost,
      required final String category,
      final bool isLimitedTime}) = _$PremiumFeatureImpl;

  factory _PremiumFeature.fromJson(Map<String, dynamic> json) =
      _$PremiumFeatureImpl.fromJson;

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

  /// Create a copy of PremiumFeature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PremiumFeatureImplCopyWith<_$PremiumFeatureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RiskFlag _$RiskFlagFromJson(Map<String, dynamic> json) {
  return _RiskFlag.fromJson(json);
}

/// @nodoc
mixin _$RiskFlag {
  String get code => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  RiskSeverity get severity => throw _privateConstructorUsedError;
  bool get blocksPayout => throw _privateConstructorUsedError;

  /// Serializes this RiskFlag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RiskFlag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RiskFlagCopyWith<RiskFlag> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RiskFlagCopyWith<$Res> {
  factory $RiskFlagCopyWith(RiskFlag value, $Res Function(RiskFlag) then) =
      _$RiskFlagCopyWithImpl<$Res, RiskFlag>;
  @useResult
  $Res call(
      {String code,
      String title,
      String description,
      RiskSeverity severity,
      bool blocksPayout});
}

/// @nodoc
class _$RiskFlagCopyWithImpl<$Res, $Val extends RiskFlag>
    implements $RiskFlagCopyWith<$Res> {
  _$RiskFlagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RiskFlag
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
abstract class _$$RiskFlagImplCopyWith<$Res>
    implements $RiskFlagCopyWith<$Res> {
  factory _$$RiskFlagImplCopyWith(
          _$RiskFlagImpl value, $Res Function(_$RiskFlagImpl) then) =
      __$$RiskFlagImplCopyWithImpl<$Res>;
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
class __$$RiskFlagImplCopyWithImpl<$Res>
    extends _$RiskFlagCopyWithImpl<$Res, _$RiskFlagImpl>
    implements _$$RiskFlagImplCopyWith<$Res> {
  __$$RiskFlagImplCopyWithImpl(
      _$RiskFlagImpl _value, $Res Function(_$RiskFlagImpl) _then)
      : super(_value, _then);

  /// Create a copy of RiskFlag
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
    return _then(_$RiskFlagImpl(
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
class _$RiskFlagImpl implements _RiskFlag {
  const _$RiskFlagImpl(
      {required this.code,
      required this.title,
      required this.description,
      required this.severity,
      this.blocksPayout = false});

  factory _$RiskFlagImpl.fromJson(Map<String, dynamic> json) =>
      _$$RiskFlagImplFromJson(json);

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
    return 'RiskFlag(code: $code, title: $title, description: $description, severity: $severity, blocksPayout: $blocksPayout)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RiskFlagImpl &&
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

  /// Create a copy of RiskFlag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RiskFlagImplCopyWith<_$RiskFlagImpl> get copyWith =>
      __$$RiskFlagImplCopyWithImpl<_$RiskFlagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RiskFlagImplToJson(
      this,
    );
  }
}

abstract class _RiskFlag implements RiskFlag {
  const factory _RiskFlag(
      {required final String code,
      required final String title,
      required final String description,
      required final RiskSeverity severity,
      final bool blocksPayout}) = _$RiskFlagImpl;

  factory _RiskFlag.fromJson(Map<String, dynamic> json) =
      _$RiskFlagImpl.fromJson;

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

  /// Create a copy of RiskFlag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RiskFlagImplCopyWith<_$RiskFlagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoinTransaction _$CoinTransactionFromJson(Map<String, dynamic> json) {
  return _CoinTransaction.fromJson(json);
}

/// @nodoc
mixin _$CoinTransaction {
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

  /// Serializes this CoinTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoinTransactionCopyWith<CoinTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoinTransactionCopyWith<$Res> {
  factory $CoinTransactionCopyWith(
          CoinTransaction value, $Res Function(CoinTransaction) then) =
      _$CoinTransactionCopyWithImpl<$Res, CoinTransaction>;
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
class _$CoinTransactionCopyWithImpl<$Res, $Val extends CoinTransaction>
    implements $CoinTransactionCopyWith<$Res> {
  _$CoinTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoinTransaction
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
abstract class _$$CoinTransactionImplCopyWith<$Res>
    implements $CoinTransactionCopyWith<$Res> {
  factory _$$CoinTransactionImplCopyWith(_$CoinTransactionImpl value,
          $Res Function(_$CoinTransactionImpl) then) =
      __$$CoinTransactionImplCopyWithImpl<$Res>;
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
class __$$CoinTransactionImplCopyWithImpl<$Res>
    extends _$CoinTransactionCopyWithImpl<$Res, _$CoinTransactionImpl>
    implements _$$CoinTransactionImplCopyWith<$Res> {
  __$$CoinTransactionImplCopyWithImpl(
      _$CoinTransactionImpl _value, $Res Function(_$CoinTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CoinTransaction
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
    return _then(_$CoinTransactionImpl(
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
class _$CoinTransactionImpl implements _CoinTransaction {
  const _$CoinTransactionImpl(
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
      : _metadata = metadata;

  factory _$CoinTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoinTransactionImplFromJson(json);

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
    return 'CoinTransaction(id: $id, userId: $userId, direction: $direction, type: $type, status: $status, amount: $amount, balanceAfter: $balanceAfter, title: $title, referenceId: $referenceId, occurredAt: $occurredAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoinTransactionImpl &&
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

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoinTransactionImplCopyWith<_$CoinTransactionImpl> get copyWith =>
      __$$CoinTransactionImplCopyWithImpl<_$CoinTransactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoinTransactionImplToJson(
      this,
    );
  }
}

abstract class _CoinTransaction implements CoinTransaction {
  const factory _CoinTransaction(
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
      final Map<String, dynamic> metadata}) = _$CoinTransactionImpl;

  factory _CoinTransaction.fromJson(Map<String, dynamic> json) =
      _$CoinTransactionImpl.fromJson;

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

  /// Create a copy of CoinTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoinTransactionImplCopyWith<_$CoinTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransactionPage _$TransactionPageFromJson(Map<String, dynamic> json) {
  return _TransactionPage.fromJson(json);
}

/// @nodoc
mixin _$TransactionPage {
  List<CoinTransaction> get items => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;

  /// Serializes this TransactionPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionPageCopyWith<TransactionPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionPageCopyWith<$Res> {
  factory $TransactionPageCopyWith(
          TransactionPage value, $Res Function(TransactionPage) then) =
      _$TransactionPageCopyWithImpl<$Res, TransactionPage>;
  @useResult
  $Res call({List<CoinTransaction> items, String? nextCursor, bool hasMore});
}

/// @nodoc
class _$TransactionPageCopyWithImpl<$Res, $Val extends TransactionPage>
    implements $TransactionPageCopyWith<$Res> {
  _$TransactionPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionPage
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
              as List<CoinTransaction>,
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
abstract class _$$TransactionPageImplCopyWith<$Res>
    implements $TransactionPageCopyWith<$Res> {
  factory _$$TransactionPageImplCopyWith(_$TransactionPageImpl value,
          $Res Function(_$TransactionPageImpl) then) =
      __$$TransactionPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CoinTransaction> items, String? nextCursor, bool hasMore});
}

/// @nodoc
class __$$TransactionPageImplCopyWithImpl<$Res>
    extends _$TransactionPageCopyWithImpl<$Res, _$TransactionPageImpl>
    implements _$$TransactionPageImplCopyWith<$Res> {
  __$$TransactionPageImplCopyWithImpl(
      _$TransactionPageImpl _value, $Res Function(_$TransactionPageImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransactionPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? nextCursor = freezed,
    Object? hasMore = null,
  }) {
    return _then(_$TransactionPageImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CoinTransaction>,
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
class _$TransactionPageImpl implements _TransactionPage {
  const _$TransactionPageImpl(
      {final List<CoinTransaction> items = const <CoinTransaction>[],
      this.nextCursor,
      this.hasMore = false})
      : _items = items;

  factory _$TransactionPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionPageImplFromJson(json);

  final List<CoinTransaction> _items;
  @override
  @JsonKey()
  List<CoinTransaction> get items {
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
    return 'TransactionPage(items: $items, nextCursor: $nextCursor, hasMore: $hasMore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionPageImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), nextCursor, hasMore);

  /// Create a copy of TransactionPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionPageImplCopyWith<_$TransactionPageImpl> get copyWith =>
      __$$TransactionPageImplCopyWithImpl<_$TransactionPageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionPageImplToJson(
      this,
    );
  }
}

abstract class _TransactionPage implements TransactionPage {
  const factory _TransactionPage(
      {final List<CoinTransaction> items,
      final String? nextCursor,
      final bool hasMore}) = _$TransactionPageImpl;

  factory _TransactionPage.fromJson(Map<String, dynamic> json) =
      _$TransactionPageImpl.fromJson;

  @override
  List<CoinTransaction> get items;
  @override
  String? get nextCursor;
  @override
  bool get hasMore;

  /// Create a copy of TransactionPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionPageImplCopyWith<_$TransactionPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WalletOverview _$WalletOverviewFromJson(Map<String, dynamic> json) {
  return _WalletOverview.fromJson(json);
}

/// @nodoc
mixin _$WalletOverview {
  String get userId => throw _privateConstructorUsedError;
  WalletBalance get balance => throw _privateConstructorUsedError;
  List<CoinPackage> get packages => throw _privateConstructorUsedError;
  List<PremiumFeature> get premiumFeatures =>
      throw _privateConstructorUsedError;
  List<CoinTransaction> get recentTransactions =>
      throw _privateConstructorUsedError;
  List<RiskFlag> get riskFlags => throw _privateConstructorUsedError;

  /// Serializes this WalletOverview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletOverviewCopyWith<WalletOverview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletOverviewCopyWith<$Res> {
  factory $WalletOverviewCopyWith(
          WalletOverview value, $Res Function(WalletOverview) then) =
      _$WalletOverviewCopyWithImpl<$Res, WalletOverview>;
  @useResult
  $Res call(
      {String userId,
      WalletBalance balance,
      List<CoinPackage> packages,
      List<PremiumFeature> premiumFeatures,
      List<CoinTransaction> recentTransactions,
      List<RiskFlag> riskFlags});

  $WalletBalanceCopyWith<$Res> get balance;
}

/// @nodoc
class _$WalletOverviewCopyWithImpl<$Res, $Val extends WalletOverview>
    implements $WalletOverviewCopyWith<$Res> {
  _$WalletOverviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletOverview
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
              as WalletBalance,
      packages: null == packages
          ? _value.packages
          : packages // ignore: cast_nullable_to_non_nullable
              as List<CoinPackage>,
      premiumFeatures: null == premiumFeatures
          ? _value.premiumFeatures
          : premiumFeatures // ignore: cast_nullable_to_non_nullable
              as List<PremiumFeature>,
      recentTransactions: null == recentTransactions
          ? _value.recentTransactions
          : recentTransactions // ignore: cast_nullable_to_non_nullable
              as List<CoinTransaction>,
      riskFlags: null == riskFlags
          ? _value.riskFlags
          : riskFlags // ignore: cast_nullable_to_non_nullable
              as List<RiskFlag>,
    ) as $Val);
  }

  /// Create a copy of WalletOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletBalanceCopyWith<$Res> get balance {
    return $WalletBalanceCopyWith<$Res>(_value.balance, (value) {
      return _then(_value.copyWith(balance: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WalletOverviewImplCopyWith<$Res>
    implements $WalletOverviewCopyWith<$Res> {
  factory _$$WalletOverviewImplCopyWith(_$WalletOverviewImpl value,
          $Res Function(_$WalletOverviewImpl) then) =
      __$$WalletOverviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      WalletBalance balance,
      List<CoinPackage> packages,
      List<PremiumFeature> premiumFeatures,
      List<CoinTransaction> recentTransactions,
      List<RiskFlag> riskFlags});

  @override
  $WalletBalanceCopyWith<$Res> get balance;
}

/// @nodoc
class __$$WalletOverviewImplCopyWithImpl<$Res>
    extends _$WalletOverviewCopyWithImpl<$Res, _$WalletOverviewImpl>
    implements _$$WalletOverviewImplCopyWith<$Res> {
  __$$WalletOverviewImplCopyWithImpl(
      _$WalletOverviewImpl _value, $Res Function(_$WalletOverviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletOverview
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
    return _then(_$WalletOverviewImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      balance: null == balance
          ? _value.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as WalletBalance,
      packages: null == packages
          ? _value._packages
          : packages // ignore: cast_nullable_to_non_nullable
              as List<CoinPackage>,
      premiumFeatures: null == premiumFeatures
          ? _value._premiumFeatures
          : premiumFeatures // ignore: cast_nullable_to_non_nullable
              as List<PremiumFeature>,
      recentTransactions: null == recentTransactions
          ? _value._recentTransactions
          : recentTransactions // ignore: cast_nullable_to_non_nullable
              as List<CoinTransaction>,
      riskFlags: null == riskFlags
          ? _value._riskFlags
          : riskFlags // ignore: cast_nullable_to_non_nullable
              as List<RiskFlag>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletOverviewImpl implements _WalletOverview {
  const _$WalletOverviewImpl(
      {required this.userId,
      required this.balance,
      final List<CoinPackage> packages = const <CoinPackage>[],
      final List<PremiumFeature> premiumFeatures = const <PremiumFeature>[],
      final List<CoinTransaction> recentTransactions =
          const <CoinTransaction>[],
      final List<RiskFlag> riskFlags = const <RiskFlag>[]})
      : _packages = packages,
        _premiumFeatures = premiumFeatures,
        _recentTransactions = recentTransactions,
        _riskFlags = riskFlags;

  factory _$WalletOverviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletOverviewImplFromJson(json);

  @override
  final String userId;
  @override
  final WalletBalance balance;
  final List<CoinPackage> _packages;
  @override
  @JsonKey()
  List<CoinPackage> get packages {
    if (_packages is EqualUnmodifiableListView) return _packages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_packages);
  }

  final List<PremiumFeature> _premiumFeatures;
  @override
  @JsonKey()
  List<PremiumFeature> get premiumFeatures {
    if (_premiumFeatures is EqualUnmodifiableListView) return _premiumFeatures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_premiumFeatures);
  }

  final List<CoinTransaction> _recentTransactions;
  @override
  @JsonKey()
  List<CoinTransaction> get recentTransactions {
    if (_recentTransactions is EqualUnmodifiableListView)
      return _recentTransactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentTransactions);
  }

  final List<RiskFlag> _riskFlags;
  @override
  @JsonKey()
  List<RiskFlag> get riskFlags {
    if (_riskFlags is EqualUnmodifiableListView) return _riskFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_riskFlags);
  }

  @override
  String toString() {
    return 'WalletOverview(userId: $userId, balance: $balance, packages: $packages, premiumFeatures: $premiumFeatures, recentTransactions: $recentTransactions, riskFlags: $riskFlags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletOverviewImpl &&
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

  /// Create a copy of WalletOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletOverviewImplCopyWith<_$WalletOverviewImpl> get copyWith =>
      __$$WalletOverviewImplCopyWithImpl<_$WalletOverviewImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletOverviewImplToJson(
      this,
    );
  }
}

abstract class _WalletOverview implements WalletOverview {
  const factory _WalletOverview(
      {required final String userId,
      required final WalletBalance balance,
      final List<CoinPackage> packages,
      final List<PremiumFeature> premiumFeatures,
      final List<CoinTransaction> recentTransactions,
      final List<RiskFlag> riskFlags}) = _$WalletOverviewImpl;

  factory _WalletOverview.fromJson(Map<String, dynamic> json) =
      _$WalletOverviewImpl.fromJson;

  @override
  String get userId;
  @override
  WalletBalance get balance;
  @override
  List<CoinPackage> get packages;
  @override
  List<PremiumFeature> get premiumFeatures;
  @override
  List<CoinTransaction> get recentTransactions;
  @override
  List<RiskFlag> get riskFlags;

  /// Create a copy of WalletOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletOverviewImplCopyWith<_$WalletOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransactionHistoryQuery _$TransactionHistoryQueryFromJson(
    Map<String, dynamic> json) {
  return _TransactionHistoryQuery.fromJson(json);
}

/// @nodoc
mixin _$TransactionHistoryQuery {
  String get userId => throw _privateConstructorUsedError;
  String? get cursor => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;

  /// Serializes this TransactionHistoryQuery to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionHistoryQuery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionHistoryQueryCopyWith<TransactionHistoryQuery> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionHistoryQueryCopyWith<$Res> {
  factory $TransactionHistoryQueryCopyWith(TransactionHistoryQuery value,
          $Res Function(TransactionHistoryQuery) then) =
      _$TransactionHistoryQueryCopyWithImpl<$Res, TransactionHistoryQuery>;
  @useResult
  $Res call({String userId, String? cursor, int limit});
}

/// @nodoc
class _$TransactionHistoryQueryCopyWithImpl<$Res,
        $Val extends TransactionHistoryQuery>
    implements $TransactionHistoryQueryCopyWith<$Res> {
  _$TransactionHistoryQueryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionHistoryQuery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? cursor = freezed,
    Object? limit = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      cursor: freezed == cursor
          ? _value.cursor
          : cursor // ignore: cast_nullable_to_non_nullable
              as String?,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionHistoryQueryImplCopyWith<$Res>
    implements $TransactionHistoryQueryCopyWith<$Res> {
  factory _$$TransactionHistoryQueryImplCopyWith(
          _$TransactionHistoryQueryImpl value,
          $Res Function(_$TransactionHistoryQueryImpl) then) =
      __$$TransactionHistoryQueryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String? cursor, int limit});
}

/// @nodoc
class __$$TransactionHistoryQueryImplCopyWithImpl<$Res>
    extends _$TransactionHistoryQueryCopyWithImpl<$Res,
        _$TransactionHistoryQueryImpl>
    implements _$$TransactionHistoryQueryImplCopyWith<$Res> {
  __$$TransactionHistoryQueryImplCopyWithImpl(
      _$TransactionHistoryQueryImpl _value,
      $Res Function(_$TransactionHistoryQueryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TransactionHistoryQuery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? cursor = freezed,
    Object? limit = null,
  }) {
    return _then(_$TransactionHistoryQueryImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      cursor: freezed == cursor
          ? _value.cursor
          : cursor // ignore: cast_nullable_to_non_nullable
              as String?,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionHistoryQueryImpl implements _TransactionHistoryQuery {
  const _$TransactionHistoryQueryImpl(
      {required this.userId, this.cursor, this.limit = 20});

  factory _$TransactionHistoryQueryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionHistoryQueryImplFromJson(json);

  @override
  final String userId;
  @override
  final String? cursor;
  @override
  @JsonKey()
  final int limit;

  @override
  String toString() {
    return 'TransactionHistoryQuery(userId: $userId, cursor: $cursor, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionHistoryQueryImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.cursor, cursor) || other.cursor == cursor) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, cursor, limit);

  /// Create a copy of TransactionHistoryQuery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionHistoryQueryImplCopyWith<_$TransactionHistoryQueryImpl>
      get copyWith => __$$TransactionHistoryQueryImplCopyWithImpl<
          _$TransactionHistoryQueryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionHistoryQueryImplToJson(
      this,
    );
  }
}

abstract class _TransactionHistoryQuery implements TransactionHistoryQuery {
  const factory _TransactionHistoryQuery(
      {required final String userId,
      final String? cursor,
      final int limit}) = _$TransactionHistoryQueryImpl;

  factory _TransactionHistoryQuery.fromJson(Map<String, dynamic> json) =
      _$TransactionHistoryQueryImpl.fromJson;

  @override
  String get userId;
  @override
  String? get cursor;
  @override
  int get limit;

  /// Create a copy of TransactionHistoryQuery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionHistoryQueryImplCopyWith<_$TransactionHistoryQueryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

TaskRewardClaim _$TaskRewardClaimFromJson(Map<String, dynamic> json) {
  return _TaskRewardClaim.fromJson(json);
}

/// @nodoc
mixin _$TaskRewardClaim {
  String get userId => throw _privateConstructorUsedError;
  String get taskId => throw _privateConstructorUsedError;
  String get completionId => throw _privateConstructorUsedError;
  int get rewardAmount => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;
  String get serverProof => throw _privateConstructorUsedError;
  String get deviceAttestationToken => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this TaskRewardClaim to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskRewardClaim
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskRewardClaimCopyWith<TaskRewardClaim> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskRewardClaimCopyWith<$Res> {
  factory $TaskRewardClaimCopyWith(
          TaskRewardClaim value, $Res Function(TaskRewardClaim) then) =
      _$TaskRewardClaimCopyWithImpl<$Res, TaskRewardClaim>;
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
class _$TaskRewardClaimCopyWithImpl<$Res, $Val extends TaskRewardClaim>
    implements $TaskRewardClaimCopyWith<$Res> {
  _$TaskRewardClaimCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskRewardClaim
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
abstract class _$$TaskRewardClaimImplCopyWith<$Res>
    implements $TaskRewardClaimCopyWith<$Res> {
  factory _$$TaskRewardClaimImplCopyWith(_$TaskRewardClaimImpl value,
          $Res Function(_$TaskRewardClaimImpl) then) =
      __$$TaskRewardClaimImplCopyWithImpl<$Res>;
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
class __$$TaskRewardClaimImplCopyWithImpl<$Res>
    extends _$TaskRewardClaimCopyWithImpl<$Res, _$TaskRewardClaimImpl>
    implements _$$TaskRewardClaimImplCopyWith<$Res> {
  __$$TaskRewardClaimImplCopyWithImpl(
      _$TaskRewardClaimImpl _value, $Res Function(_$TaskRewardClaimImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskRewardClaim
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
    return _then(_$TaskRewardClaimImpl(
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
class _$TaskRewardClaimImpl extends _TaskRewardClaim {
  const _$TaskRewardClaimImpl(
      {required this.userId,
      required this.taskId,
      required this.completionId,
      required this.rewardAmount,
      required this.completedAt,
      required this.serverProof,
      required this.deviceAttestationToken,
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata,
        super._();

  factory _$TaskRewardClaimImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskRewardClaimImplFromJson(json);

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
    return 'TaskRewardClaim(userId: $userId, taskId: $taskId, completionId: $completionId, rewardAmount: $rewardAmount, completedAt: $completedAt, serverProof: $serverProof, deviceAttestationToken: $deviceAttestationToken, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskRewardClaimImpl &&
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

  /// Create a copy of TaskRewardClaim
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskRewardClaimImplCopyWith<_$TaskRewardClaimImpl> get copyWith =>
      __$$TaskRewardClaimImplCopyWithImpl<_$TaskRewardClaimImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskRewardClaimImplToJson(
      this,
    );
  }
}

abstract class _TaskRewardClaim extends TaskRewardClaim {
  const factory _TaskRewardClaim(
      {required final String userId,
      required final String taskId,
      required final String completionId,
      required final int rewardAmount,
      required final DateTime completedAt,
      required final String serverProof,
      required final String deviceAttestationToken,
      final Map<String, dynamic> metadata}) = _$TaskRewardClaimImpl;
  const _TaskRewardClaim._() : super._();

  factory _TaskRewardClaim.fromJson(Map<String, dynamic> json) =
      _$TaskRewardClaimImpl.fromJson;

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

  /// Create a copy of TaskRewardClaim
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskRewardClaimImplCopyWith<_$TaskRewardClaimImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RewardedAdClaim _$RewardedAdClaimFromJson(Map<String, dynamic> json) {
  return _RewardedAdClaim.fromJson(json);
}

/// @nodoc
mixin _$RewardedAdClaim {
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

  /// Serializes this RewardedAdClaim to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RewardedAdClaim
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RewardedAdClaimCopyWith<RewardedAdClaim> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RewardedAdClaimCopyWith<$Res> {
  factory $RewardedAdClaimCopyWith(
          RewardedAdClaim value, $Res Function(RewardedAdClaim) then) =
      _$RewardedAdClaimCopyWithImpl<$Res, RewardedAdClaim>;
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
class _$RewardedAdClaimCopyWithImpl<$Res, $Val extends RewardedAdClaim>
    implements $RewardedAdClaimCopyWith<$Res> {
  _$RewardedAdClaimCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RewardedAdClaim
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
abstract class _$$RewardedAdClaimImplCopyWith<$Res>
    implements $RewardedAdClaimCopyWith<$Res> {
  factory _$$RewardedAdClaimImplCopyWith(_$RewardedAdClaimImpl value,
          $Res Function(_$RewardedAdClaimImpl) then) =
      __$$RewardedAdClaimImplCopyWithImpl<$Res>;
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
class __$$RewardedAdClaimImplCopyWithImpl<$Res>
    extends _$RewardedAdClaimCopyWithImpl<$Res, _$RewardedAdClaimImpl>
    implements _$$RewardedAdClaimImplCopyWith<$Res> {
  __$$RewardedAdClaimImplCopyWithImpl(
      _$RewardedAdClaimImpl _value, $Res Function(_$RewardedAdClaimImpl) _then)
      : super(_value, _then);

  /// Create a copy of RewardedAdClaim
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
    return _then(_$RewardedAdClaimImpl(
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
class _$RewardedAdClaimImpl extends _RewardedAdClaim {
  const _$RewardedAdClaimImpl(
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
      : _metadata = metadata,
        super._();

  factory _$RewardedAdClaimImpl.fromJson(Map<String, dynamic> json) =>
      _$$RewardedAdClaimImplFromJson(json);

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
    return 'RewardedAdClaim(userId: $userId, adUnitId: $adUnitId, adNetwork: $adNetwork, sessionId: $sessionId, networkTransactionId: $networkTransactionId, rewardNonce: $rewardNonce, rewardAmount: $rewardAmount, watchedMillis: $watchedMillis, completedAt: $completedAt, serverSideVerificationToken: $serverSideVerificationToken, deviceAttestationToken: $deviceAttestationToken, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RewardedAdClaimImpl &&
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

  /// Create a copy of RewardedAdClaim
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RewardedAdClaimImplCopyWith<_$RewardedAdClaimImpl> get copyWith =>
      __$$RewardedAdClaimImplCopyWithImpl<_$RewardedAdClaimImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RewardedAdClaimImplToJson(
      this,
    );
  }
}

abstract class _RewardedAdClaim extends RewardedAdClaim {
  const factory _RewardedAdClaim(
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
      final Map<String, dynamic> metadata}) = _$RewardedAdClaimImpl;
  const _RewardedAdClaim._() : super._();

  factory _RewardedAdClaim.fromJson(Map<String, dynamic> json) =
      _$RewardedAdClaimImpl.fromJson;

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

  /// Create a copy of RewardedAdClaim
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RewardedAdClaimImplCopyWith<_$RewardedAdClaimImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PurchaseVerificationRequest _$PurchaseVerificationRequestFromJson(
    Map<String, dynamic> json) {
  return _PurchaseVerificationRequest.fromJson(json);
}

/// @nodoc
mixin _$PurchaseVerificationRequest {
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

  /// Serializes this PurchaseVerificationRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PurchaseVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PurchaseVerificationRequestCopyWith<PurchaseVerificationRequest>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseVerificationRequestCopyWith<$Res> {
  factory $PurchaseVerificationRequestCopyWith(
          PurchaseVerificationRequest value,
          $Res Function(PurchaseVerificationRequest) then) =
      _$PurchaseVerificationRequestCopyWithImpl<$Res,
          PurchaseVerificationRequest>;
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
class _$PurchaseVerificationRequestCopyWithImpl<$Res,
        $Val extends PurchaseVerificationRequest>
    implements $PurchaseVerificationRequestCopyWith<$Res> {
  _$PurchaseVerificationRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseVerificationRequest
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
abstract class _$$PurchaseVerificationRequestImplCopyWith<$Res>
    implements $PurchaseVerificationRequestCopyWith<$Res> {
  factory _$$PurchaseVerificationRequestImplCopyWith(
          _$PurchaseVerificationRequestImpl value,
          $Res Function(_$PurchaseVerificationRequestImpl) then) =
      __$$PurchaseVerificationRequestImplCopyWithImpl<$Res>;
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
class __$$PurchaseVerificationRequestImplCopyWithImpl<$Res>
    extends _$PurchaseVerificationRequestCopyWithImpl<$Res,
        _$PurchaseVerificationRequestImpl>
    implements _$$PurchaseVerificationRequestImplCopyWith<$Res> {
  __$$PurchaseVerificationRequestImplCopyWithImpl(
      _$PurchaseVerificationRequestImpl _value,
      $Res Function(_$PurchaseVerificationRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseVerificationRequest
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
    return _then(_$PurchaseVerificationRequestImpl(
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
class _$PurchaseVerificationRequestImpl extends _PurchaseVerificationRequest {
  const _$PurchaseVerificationRequestImpl(
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
      : _metadata = metadata,
        super._();

  factory _$PurchaseVerificationRequestImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PurchaseVerificationRequestImplFromJson(json);

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
    return 'PurchaseVerificationRequest(userId: $userId, packageSku: $packageSku, productId: $productId, store: $store, transactionId: $transactionId, purchaseToken: $purchaseToken, signedPayload: $signedPayload, priceMicros: $priceMicros, currencyCode: $currencyCode, completedAt: $completedAt, deviceAttestationToken: $deviceAttestationToken, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseVerificationRequestImpl &&
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

  /// Create a copy of PurchaseVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseVerificationRequestImplCopyWith<_$PurchaseVerificationRequestImpl>
      get copyWith => __$$PurchaseVerificationRequestImplCopyWithImpl<
          _$PurchaseVerificationRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseVerificationRequestImplToJson(
      this,
    );
  }
}

abstract class _PurchaseVerificationRequest
    extends PurchaseVerificationRequest {
  const factory _PurchaseVerificationRequest(
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
      final Map<String, dynamic> metadata}) = _$PurchaseVerificationRequestImpl;
  const _PurchaseVerificationRequest._() : super._();

  factory _PurchaseVerificationRequest.fromJson(Map<String, dynamic> json) =
      _$PurchaseVerificationRequestImpl.fromJson;

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

  /// Create a copy of PurchaseVerificationRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseVerificationRequestImplCopyWith<_$PurchaseVerificationRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

SpendCoinsCommand _$SpendCoinsCommandFromJson(Map<String, dynamic> json) {
  return _SpendCoinsCommand.fromJson(json);
}

/// @nodoc
mixin _$SpendCoinsCommand {
  String get userId => throw _privateConstructorUsedError;
  String get featureId => throw _privateConstructorUsedError;
  String get referenceId => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  int get currentAvailableBalance => throw _privateConstructorUsedError;
  String get idempotencyKey => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this SpendCoinsCommand to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpendCoinsCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpendCoinsCommandCopyWith<SpendCoinsCommand> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpendCoinsCommandCopyWith<$Res> {
  factory $SpendCoinsCommandCopyWith(
          SpendCoinsCommand value, $Res Function(SpendCoinsCommand) then) =
      _$SpendCoinsCommandCopyWithImpl<$Res, SpendCoinsCommand>;
  @useResult
  $Res call(
      {String userId,
      String featureId,
      String referenceId,
      int amount,
      int currentAvailableBalance,
      String idempotencyKey,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$SpendCoinsCommandCopyWithImpl<$Res, $Val extends SpendCoinsCommand>
    implements $SpendCoinsCommandCopyWith<$Res> {
  _$SpendCoinsCommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpendCoinsCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? featureId = null,
    Object? referenceId = null,
    Object? amount = null,
    Object? currentAvailableBalance = null,
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
      currentAvailableBalance: null == currentAvailableBalance
          ? _value.currentAvailableBalance
          : currentAvailableBalance // ignore: cast_nullable_to_non_nullable
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
abstract class _$$SpendCoinsCommandImplCopyWith<$Res>
    implements $SpendCoinsCommandCopyWith<$Res> {
  factory _$$SpendCoinsCommandImplCopyWith(_$SpendCoinsCommandImpl value,
          $Res Function(_$SpendCoinsCommandImpl) then) =
      __$$SpendCoinsCommandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String featureId,
      String referenceId,
      int amount,
      int currentAvailableBalance,
      String idempotencyKey,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$$SpendCoinsCommandImplCopyWithImpl<$Res>
    extends _$SpendCoinsCommandCopyWithImpl<$Res, _$SpendCoinsCommandImpl>
    implements _$$SpendCoinsCommandImplCopyWith<$Res> {
  __$$SpendCoinsCommandImplCopyWithImpl(_$SpendCoinsCommandImpl _value,
      $Res Function(_$SpendCoinsCommandImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpendCoinsCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? featureId = null,
    Object? referenceId = null,
    Object? amount = null,
    Object? currentAvailableBalance = null,
    Object? idempotencyKey = null,
    Object? metadata = null,
  }) {
    return _then(_$SpendCoinsCommandImpl(
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
      currentAvailableBalance: null == currentAvailableBalance
          ? _value.currentAvailableBalance
          : currentAvailableBalance // ignore: cast_nullable_to_non_nullable
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
class _$SpendCoinsCommandImpl extends _SpendCoinsCommand {
  const _$SpendCoinsCommandImpl(
      {required this.userId,
      required this.featureId,
      required this.referenceId,
      required this.amount,
      required this.currentAvailableBalance,
      this.idempotencyKey = '',
      final Map<String, dynamic> metadata = const <String, dynamic>{}})
      : _metadata = metadata,
        super._();

  factory _$SpendCoinsCommandImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpendCoinsCommandImplFromJson(json);

  @override
  final String userId;
  @override
  final String featureId;
  @override
  final String referenceId;
  @override
  final int amount;
  @override
  final int currentAvailableBalance;
  @override
  @JsonKey()
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
    return 'SpendCoinsCommand(userId: $userId, featureId: $featureId, referenceId: $referenceId, amount: $amount, currentAvailableBalance: $currentAvailableBalance, idempotencyKey: $idempotencyKey, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpendCoinsCommandImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.featureId, featureId) ||
                other.featureId == featureId) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(
                    other.currentAvailableBalance, currentAvailableBalance) ||
                other.currentAvailableBalance == currentAvailableBalance) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      featureId,
      referenceId,
      amount,
      currentAvailableBalance,
      idempotencyKey,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of SpendCoinsCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpendCoinsCommandImplCopyWith<_$SpendCoinsCommandImpl> get copyWith =>
      __$$SpendCoinsCommandImplCopyWithImpl<_$SpendCoinsCommandImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpendCoinsCommandImplToJson(
      this,
    );
  }
}

abstract class _SpendCoinsCommand extends SpendCoinsCommand {
  const factory _SpendCoinsCommand(
      {required final String userId,
      required final String featureId,
      required final String referenceId,
      required final int amount,
      required final int currentAvailableBalance,
      final String idempotencyKey,
      final Map<String, dynamic> metadata}) = _$SpendCoinsCommandImpl;
  const _SpendCoinsCommand._() : super._();

  factory _SpendCoinsCommand.fromJson(Map<String, dynamic> json) =
      _$SpendCoinsCommandImpl.fromJson;

  @override
  String get userId;
  @override
  String get featureId;
  @override
  String get referenceId;
  @override
  int get amount;
  @override
  int get currentAvailableBalance;
  @override
  String get idempotencyKey;
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of SpendCoinsCommand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpendCoinsCommandImplCopyWith<_$SpendCoinsCommandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LedgerMutationResult _$LedgerMutationResultFromJson(Map<String, dynamic> json) {
  return _LedgerMutationResult.fromJson(json);
}

/// @nodoc
mixin _$LedgerMutationResult {
  WalletBalance get walletBalance => throw _privateConstructorUsedError;
  CoinTransaction get transaction => throw _privateConstructorUsedError;
  RewardReviewStatus get reviewStatus => throw _privateConstructorUsedError;
  String get idempotencyKey => throw _privateConstructorUsedError;
  bool get shouldRefreshHistory => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this LedgerMutationResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LedgerMutationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LedgerMutationResultCopyWith<LedgerMutationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LedgerMutationResultCopyWith<$Res> {
  factory $LedgerMutationResultCopyWith(LedgerMutationResult value,
          $Res Function(LedgerMutationResult) then) =
      _$LedgerMutationResultCopyWithImpl<$Res, LedgerMutationResult>;
  @useResult
  $Res call(
      {WalletBalance walletBalance,
      CoinTransaction transaction,
      RewardReviewStatus reviewStatus,
      String idempotencyKey,
      bool shouldRefreshHistory,
      String? message});

  $WalletBalanceCopyWith<$Res> get walletBalance;
  $CoinTransactionCopyWith<$Res> get transaction;
}

/// @nodoc
class _$LedgerMutationResultCopyWithImpl<$Res,
        $Val extends LedgerMutationResult>
    implements $LedgerMutationResultCopyWith<$Res> {
  _$LedgerMutationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LedgerMutationResult
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
              as WalletBalance,
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as CoinTransaction,
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

  /// Create a copy of LedgerMutationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletBalanceCopyWith<$Res> get walletBalance {
    return $WalletBalanceCopyWith<$Res>(_value.walletBalance, (value) {
      return _then(_value.copyWith(walletBalance: value) as $Val);
    });
  }

  /// Create a copy of LedgerMutationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CoinTransactionCopyWith<$Res> get transaction {
    return $CoinTransactionCopyWith<$Res>(_value.transaction, (value) {
      return _then(_value.copyWith(transaction: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LedgerMutationResultImplCopyWith<$Res>
    implements $LedgerMutationResultCopyWith<$Res> {
  factory _$$LedgerMutationResultImplCopyWith(_$LedgerMutationResultImpl value,
          $Res Function(_$LedgerMutationResultImpl) then) =
      __$$LedgerMutationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {WalletBalance walletBalance,
      CoinTransaction transaction,
      RewardReviewStatus reviewStatus,
      String idempotencyKey,
      bool shouldRefreshHistory,
      String? message});

  @override
  $WalletBalanceCopyWith<$Res> get walletBalance;
  @override
  $CoinTransactionCopyWith<$Res> get transaction;
}

/// @nodoc
class __$$LedgerMutationResultImplCopyWithImpl<$Res>
    extends _$LedgerMutationResultCopyWithImpl<$Res, _$LedgerMutationResultImpl>
    implements _$$LedgerMutationResultImplCopyWith<$Res> {
  __$$LedgerMutationResultImplCopyWithImpl(_$LedgerMutationResultImpl _value,
      $Res Function(_$LedgerMutationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of LedgerMutationResult
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
    return _then(_$LedgerMutationResultImpl(
      walletBalance: null == walletBalance
          ? _value.walletBalance
          : walletBalance // ignore: cast_nullable_to_non_nullable
              as WalletBalance,
      transaction: null == transaction
          ? _value.transaction
          : transaction // ignore: cast_nullable_to_non_nullable
              as CoinTransaction,
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
class _$LedgerMutationResultImpl implements _LedgerMutationResult {
  const _$LedgerMutationResultImpl(
      {required this.walletBalance,
      required this.transaction,
      required this.reviewStatus,
      required this.idempotencyKey,
      this.shouldRefreshHistory = true,
      this.message});

  factory _$LedgerMutationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$LedgerMutationResultImplFromJson(json);

  @override
  final WalletBalance walletBalance;
  @override
  final CoinTransaction transaction;
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
    return 'LedgerMutationResult(walletBalance: $walletBalance, transaction: $transaction, reviewStatus: $reviewStatus, idempotencyKey: $idempotencyKey, shouldRefreshHistory: $shouldRefreshHistory, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LedgerMutationResultImpl &&
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

  /// Create a copy of LedgerMutationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LedgerMutationResultImplCopyWith<_$LedgerMutationResultImpl>
      get copyWith =>
          __$$LedgerMutationResultImplCopyWithImpl<_$LedgerMutationResultImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LedgerMutationResultImplToJson(
      this,
    );
  }
}

abstract class _LedgerMutationResult implements LedgerMutationResult {
  const factory _LedgerMutationResult(
      {required final WalletBalance walletBalance,
      required final CoinTransaction transaction,
      required final RewardReviewStatus reviewStatus,
      required final String idempotencyKey,
      final bool shouldRefreshHistory,
      final String? message}) = _$LedgerMutationResultImpl;

  factory _LedgerMutationResult.fromJson(Map<String, dynamic> json) =
      _$LedgerMutationResultImpl.fromJson;

  @override
  WalletBalance get walletBalance;
  @override
  CoinTransaction get transaction;
  @override
  RewardReviewStatus get reviewStatus;
  @override
  String get idempotencyKey;
  @override
  bool get shouldRefreshHistory;
  @override
  String? get message;

  /// Create a copy of LedgerMutationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LedgerMutationResultImplCopyWith<_$LedgerMutationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}
