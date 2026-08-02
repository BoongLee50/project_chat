// 유료 상점 DTO. (docs/01-protocol-api-spec.md §1.8, 기획서 화면 25~30)
//
// 가격·구성은 서버 카탈로그에서 내려온다. 화면에 숫자를 하드코딩하지 말 것 —
// BM 값이 바뀌면 서버 설정만 고치면 되도록 만들어 뒀다.

import '../../../../core/util/server_time.dart';
import '../../../../l10n/app_localizations.dart';

/// 루나로 사는 상품 하나. 부스트면 [quantity], 패스면 [durationDays]를 쓴다.
class LunaProduct {
  const LunaProduct({
    required this.id,
    required this.type,
    required this.kind,
    required this.price,
    required this.quantity,
    required this.durationDays,
  });

  final String id;

  /// BOOST | ENTITLEMENT
  final String type;

  /// POST_BOOST | SPOTLIGHT_BOOST | ALBUM_PASS | TRANSLATE_PASS
  final String kind;

  final int price;
  final int quantity;
  final int durationDays;

  bool get isBoost => type == 'BOOST';

  /// "1시간, 5매" / "30일" 같은 구성 문구.
  ///
  /// 문구가 언어마다 달라 L10n을 받는다 — 모델이 BuildContext를 알 수는 없으니
  /// 호출하는 화면이 넘겨준다.
  String optionLabel(L10n l10n) => isBoost
      ? l10n.storeOptionBoost(quantity)
      : l10n.storeOptionDays(durationDays);

  factory LunaProduct.fromJson(Map<String, dynamic> json) => LunaProduct(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    kind: json['kind'] as String? ?? '',
    price: json['price'] as int? ?? 0,
    quantity: json['quantity'] as int? ?? 0,
    durationDays: json['durationDays'] as int? ?? 0,
  );
}

/// 루나 충전 패키지(인앱결제).
class LunaPack {
  const LunaPack({
    required this.productId,
    required this.luna,
    required this.bonus,
    required this.total,
  });

  final String productId;
  final int luna;
  final int bonus;
  final int total;

  bool get hasBonus => bonus > 0;

  factory LunaPack.fromJson(Map<String, dynamic> json) => LunaPack(
    productId: json['productId'] as String,
    luna: json['luna'] as int? ?? 0,
    bonus: json['bonus'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
  );
}

/// 프라임 플랜(인앱결제).
class PrimePlan {
  const PrimePlan({
    required this.productId,
    required this.product,
    required this.durationDays,
    required this.luna,
    required this.entitlements,
    required this.boosts,
  });

  final String productId;
  final String product;
  final int durationDays;
  final int luna;
  final List<String> entitlements;
  final Map<String, int> boosts;

  int get months => (durationDays / 30).round();

  factory PrimePlan.fromJson(Map<String, dynamic> json) => PrimePlan(
    productId: json['productId'] as String,
    product: json['product'] as String? ?? '',
    durationDays: json['durationDays'] as int? ?? 0,
    luna: json['luna'] as int? ?? 0,
    entitlements:
        (json['entitlements'] as List? ?? const []).map((e) => e as String).toList(),
    boosts: (json['boosts'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, value as int),
    ),
  );
}

class ProductCatalog {
  const ProductCatalog({
    required this.lunaProducts,
    required this.lunaPacks,
    required this.primePlans,
  });

  final List<LunaProduct> lunaProducts;
  final List<LunaPack> lunaPacks;
  final List<PrimePlan> primePlans;

  /// 같은 kind의 옵션들(예: 포스트 부스트 5매/10매)을 가격 오름차순으로.
  List<LunaProduct> optionsOf(String kind) =>
      lunaProducts.where((p) => p.kind == kind).toList()
        ..sort((a, b) => a.price.compareTo(b.price));

  factory ProductCatalog.fromJson(Map<String, dynamic> json) => ProductCatalog(
    lunaProducts: (json['lunaProducts'] as List? ?? const [])
        .map((e) => LunaProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    lunaPacks: (json['lunaPacks'] as List? ?? const [])
        .map((e) => LunaPack.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    primePlans: (json['primePlans'] as List? ?? const [])
        .map((e) => PrimePlan.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

/// 내 재화·구독·권리 요약. 화면 상태(PASS 표시·버튼)를 이걸로 정한다.
class Wallet {
  const Wallet({
    required this.luna,
    required this.prime,
    required this.autoRenew,
    required this.entitlements,
    required this.boostInventory,
    required this.activeBoosts,
    this.subscriptionProduct,
    this.subscriptionExpiresAt,
  });

  final int luna;
  final bool prime;
  final bool autoRenew;
  final String? subscriptionProduct;
  final DateTime? subscriptionExpiresAt;

  /// kind → 만료 시각.
  final Map<String, DateTime> entitlements;

  /// kind → 보유 매수.
  final Map<String, int> boostInventory;

  /// 지금 켜져 있는 부스트.
  final List<ActiveBoost> activeBoosts;

  bool has(String kind) => entitlements.containsKey(kind);

  DateTime? expiresAt(String kind) => entitlements[kind];

  int stockOf(String kind) => boostInventory[kind] ?? 0;

  bool isBoostOn(String kind) => activeBoosts.any((b) => b.kind == kind);

  ActiveBoost? activeBoost(String kind) {
    for (final b in activeBoosts) {
      if (b.kind == kind) return b;
    }
    return null;
  }

  /// 남은 일수(올림). 만료 정보가 없으면 null.
  int? remainingDays(String kind) {
    final expires = entitlements[kind];
    if (expires == null) return null;
    final diff = expires.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inHours ~/ 24 + (diff.inHours % 24 > 0 ? 1 : 0);
  }

  static const empty = Wallet(
    luna: 0,
    prime: false,
    autoRenew: false,
    entitlements: {},
    boostInventory: {},
    activeBoosts: [],
  );

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    luna: json['luna'] as int? ?? 0,
    prime: json['prime'] as bool? ?? false,
    autoRenew: json['autoRenew'] as bool? ?? false,
    subscriptionProduct: json['subscriptionProduct'] as String?,
    subscriptionExpiresAt: json['subscriptionExpiresAt'] == null
        ? null
        : parseServerTime(json['subscriptionExpiresAt']),
    entitlements: (json['entitlements'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        parseServerTimeOr(value),
      ),
    ),
    boostInventory: (json['boostInventory'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, value as int),
    ),
    activeBoosts: (json['activeBoosts'] as List? ?? const [])
        .map((e) => ActiveBoost.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class ActiveBoost {
  const ActiveBoost({required this.kind, required this.expiresAt});

  final String kind;
  final DateTime expiresAt;

  Duration get remaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ActiveBoost.fromJson(Map<String, dynamic> json) => ActiveBoost(
    kind: json['kind'] as String? ?? '',
    expiresAt: parseServerTimeOr(json['expiresAt']),
  );
}

/// 상품 종류별 화면 문구 — 여러 화면에서 같은 표현을 쓰려고 한곳에 모았다.
abstract final class StoreKind {
  static const postBoost = 'POST_BOOST';
  static const spotlightBoost = 'SPOTLIGHT_BOOST';
  static const albumPass = 'ALBUM_PASS';
  static const translatePass = 'TRANSLATE_PASS';
  static const unlimitedChatReq = 'UNLIMITED_CHAT_REQ';
  static const noAds = 'NO_ADS';

  static String label(L10n l10n, String kind) => switch (kind) {
    postBoost => l10n.storeKindPostBoost,
    spotlightBoost => l10n.storeKindSpotlightBoost,
    albumPass => l10n.storeKindAlbumPass,
    translatePass => l10n.storeKindTranslatePass,
    _ => kind,
  };

  static String description(L10n l10n, String kind) => switch (kind) {
    postBoost => l10n.storeDescPostBoost,
    spotlightBoost => l10n.storeDescSpotlightBoost,
    albumPass => l10n.storeDescAlbumPass,
    translatePass => l10n.storeDescTranslatePass,
    _ => '',
  };
}
