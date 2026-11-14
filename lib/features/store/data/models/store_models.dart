// 유료 상점 DTO. (docs/01-protocol-api-spec.md §1.8, 기획서 화면 25~30)
//
// 가격·구성은 서버 카탈로그에서 내려온다. 화면에 숫자를 하드코딩하지 말 것 —
// BM 값이 바뀌면 서버 설정만 고치면 되도록 만들어 뒀다.

import '../../../../core/util/server_time.dart';
import '../../../../l10n/app_localizations.dart';

/// 상점 상품 하나(인앱결제 — 기획서 261111 10-2~10-4). 부스트면 [quantity], 패스면 [durationDays]를 쓴다.
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.type,
    required this.kind,
    required this.price,
    required this.quantity,
    required this.durationDays,
    this.discount = 0,
  });

  final String id;

  /// BOOST | ENTITLEMENT
  final String type;

  /// POST_BOOST | ALBUM_PASS | TRANSLATE_PASS
  final String kind;

  /// 표시용 기준가(원). 실제 청구액은 스토어가 정한다 — 결제창이 붙으면 스토어 SDK 현지 가격으로 바꾼다.
  final int price;
  final int quantity;
  final int durationDays;

  /// 상점 카드의 `○% 할인` 표시(0이면 없음). 서버 설정의 표시값이다 — 단가에서 계산하지 않는다.
  final int discount;

  bool get isBoost => type == 'BOOST';

  /// "1시간, 5매" / "30일" 같은 구성 문구.
  ///
  /// 문구가 언어마다 달라 L10n을 받는다 — 모델이 BuildContext를 알 수는 없으니
  /// 호출하는 화면이 넘겨준다.
  String optionLabel(L10n l10n) => isBoost
      ? l10n.storeOptionBoost(quantity)
      : l10n.storeOptionDays(durationDays);

  factory ShopProduct.fromJson(Map<String, dynamic> json) => ShopProduct(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    kind: json['kind'] as String? ?? '',
    price: json['price'] as int? ?? 0,
    quantity: json['quantity'] as int? ?? 0,
    durationDays: json['durationDays'] as int? ?? 0,
    discount: json['discount'] as int? ?? 0,
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
    this.price = 0,
  });

  final String productId;
  final String product;
  final int durationDays;
  final int luna;
  final List<String> entitlements;
  final Map<String, int> boosts;

  /// 표시용 기준가(원). 실제 청구액은 스토어가 정한다 — 결제창이 붙으면 스토어 SDK 현지 가격으로 바꾼다.
  final int price;

  int get months => (durationDays / 30).round();

  factory PrimePlan.fromJson(Map<String, dynamic> json) => PrimePlan(
    productId: json['productId'] as String,
    product: json['product'] as String? ?? '',
    durationDays: json['durationDays'] as int? ?? 0,
    luna: json['luna'] as int? ?? 0,
    entitlements: (json['entitlements'] as List? ?? const [])
        .map((e) => e as String)
        .toList(),
    boosts: (json['boosts'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, value as int),
    ),
    price: json['price'] as int? ?? 0,
  );
}

class ProductCatalog {
  const ProductCatalog({
    required this.shopProducts,
    required this.primePlans,
    this.maxPhotosFree = 0,
    this.maxPhotosPass = 0,
  });

  final List<ShopProduct> shopProducts;
  final List<PrimePlan> primePlans;

  /// BM 화면의 혜택 문구가 말하는 사진 장수(기획 화면 26·29).
  ///
  /// 🚨 서버가 주는 이유: *"포스트 사진 최대 9장 등록"*, *"기본 2장에서 최대 9장까지"* 는
  /// 설정값(`app.post.max-photos-*`)이다. 여기서 받지 않으면 그 숫자가
  /// 앱 코드나 번역 파일에 굳어, 설정이 바뀌는 순간 화면이 거짓말을 한다.
  final int maxPhotosFree;
  final int maxPhotosPass;

  /// 같은 kind의 옵션들(예: 포스트 부스트 5매/10매)을 가격 오름차순으로.
  List<ShopProduct> optionsOf(String kind) =>
      shopProducts.where((p) => p.kind == kind).toList()
        ..sort((a, b) => a.price.compareTo(b.price));

  factory ProductCatalog.fromJson(Map<String, dynamic> json) => ProductCatalog(
    maxPhotosFree: json['maxPhotosFree'] as int? ?? 0,
    maxPhotosPass: json['maxPhotosPass'] as int? ?? 0,
    shopProducts: (json['shopProducts'] as List? ?? const [])
        .map((e) => ShopProduct.fromJson(Map<String, dynamic>.from(e as Map)))
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
    this.entitlementStartedAt = const {},
    required this.boostInventory,
    this.boosts = const {},
    this.passes = const {},
    required this.activeBoosts,
    this.subscriptionProduct,
    this.subscriptionStartedAt,
    this.subscriptionExpiresAt,
  });

  final int luna;
  final bool prime;
  final bool autoRenew;
  final String? subscriptionProduct;
  final DateTime? subscriptionStartedAt;
  final DateTime? subscriptionExpiresAt;

  /// kind → 만료 시각.
  final Map<String, DateTime> entitlements;

  /// kind → 시작 시각(상품 관리 팝업의 `사용 시작`).
  final Map<String, DateTime> entitlementStartedAt;

  /// kind → 보유 매수.
  final Map<String, int> boostInventory;

  /// kind → 프라임 구독분 / 상점 구매분 매수(기획서 261111 10-2 관리 화면).
  final Map<String, BoostHolding> boosts;

  /// kind → 프라임 구독분 / 상점 구매분 기간(기획서 261111 10-3·10-4 관리 화면).
  final Map<String, PassHolding> passes;

  /// 지금 켜져 있는 부스트.
  final List<ActiveBoost> activeBoosts;

  bool has(String kind) => entitlements.containsKey(kind);

  BoostHolding boostOf(String kind) => boosts[kind] ?? BoostHolding.none;

  PassHolding passOf(String kind) => passes[kind] ?? PassHolding.none;

  /// 그 상품의 관리 화면으로 갈지(아니면 구매 화면) — 기획서 261111 10-2~10-4 "미 사용 보유량이 존재할 경우".
  bool owns(String kind) =>
      kind == StoreKind.postBoost ? boostOf(kind).owned : passOf(kind).owned;

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
    return diff.isNegative
        ? 0
        : diff.inHours ~/ 24 + (diff.inHours % 24 > 0 ? 1 : 0);
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
    subscriptionStartedAt: json['subscriptionStartedAt'] == null
        ? null
        : parseServerTime(json['subscriptionStartedAt']),
    subscriptionExpiresAt: json['subscriptionExpiresAt'] == null
        ? null
        : parseServerTime(json['subscriptionExpiresAt']),
    entitlements: (json['entitlements'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, parseServerTimeOr(value)),
    ),
    entitlementStartedAt: (json['entitlementStartedAt'] as Map? ?? const {})
        .map((key, value) => MapEntry(key as String, parseServerTimeOr(value))),
    boostInventory: (json['boostInventory'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key as String, value as int),
    ),
    boosts: (json['boosts'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        BoostHolding.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    ),
    passes: (json['passes'] as Map? ?? const {}).map(
      (key, value) => MapEntry(
        key as String,
        PassHolding.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    ),
    activeBoosts: (json['activeBoosts'] as List? ?? const [])
        .map((e) => ActiveBoost.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

DateTime? _time(Object? v) => v == null ? null : parseServerTime(v);

/// 부스트 보유 — 프라임 구독분과 상점 구매분(기획서 261111 10-2).
class BoostHolding {
  const BoostHolding({
    this.prime = 0,
    this.store = 0,
    this.activeSource,
    this.activeStartedAt,
    this.activeExpiresAt,
  });

  final int prime;
  final int store;

  /// 지금 켜진 부스트가 나간 쪽(`PRIME`·`STORE`, 없으면 null) — 그 칸에 `이용 중`.
  final String? activeSource;
  final DateTime? activeStartedAt;
  final DateTime? activeExpiresAt;

  int get total => prime + store;
  bool get active => activeExpiresAt != null && activeExpiresAt!.isAfter(DateTime.now());

  /// 관리 화면에 갈 만큼 갖고 있나 — 남은 매수가 있거나 쓰는 중.
  bool get owned => total > 0 || active;

  static const none = BoostHolding();

  factory BoostHolding.fromJson(Map<String, dynamic> json) => BoostHolding(
    prime: json['prime'] as int? ?? 0,
    store: json['store'] as int? ?? 0,
    activeSource: json['activeSource'] as String?,
    activeStartedAt: _time(json['activeStartedAt']),
    activeExpiresAt: _time(json['activeExpiresAt']),
  );
}

/// 패스 보유 — 프라임 구독분과 상점 구매분 기간(기획서 261111 10-3·10-4).
///
/// 상점 구매분은 **프라임이 끝난 뒤부터** 흐른다(사용자 2026-11-14) — [storeStartedAt]이 미래일 수 있다.
class PassHolding {
  const PassHolding({
    this.primeStartedAt,
    this.primeExpiresAt,
    this.storeStartedAt,
    this.storeExpiresAt,
  });

  final DateTime? primeStartedAt;
  final DateTime? primeExpiresAt;
  final DateTime? storeStartedAt;
  final DateTime? storeExpiresAt;

  /// 남은 일수(올림) — 프라임 구독분.
  int get primeDays => _daysLeft(DateTime.now(), primeExpiresAt);

  /// 남은 일수(올림) — 상점 구매분. 아직 시작 전이면 산 기간 전부.
  int get storeDays {
    final now = DateTime.now();
    final start = storeStartedAt;
    return _daysLeft(start != null && start.isAfter(now) ? start : now, storeExpiresAt);
  }

  int get totalDays => primeDays + storeDays;
  bool get owned => primeDays > 0 || storeDays > 0;

  /// 지금 흐르는 쪽 — 프라임이 먼저(`PRIME`·`STORE`·null).
  String? get runningSource {
    final now = DateTime.now();
    bool on(DateTime? s, DateTime? e) =>
        s != null && e != null && !s.isAfter(now) && e.isAfter(now);
    if (on(primeStartedAt, primeExpiresAt)) return 'PRIME';
    if (on(storeStartedAt, storeExpiresAt)) return 'STORE';
    return null;
  }

  DateTime? get runningStartedAt =>
      runningSource == 'PRIME' ? primeStartedAt : runningSource == 'STORE' ? storeStartedAt : null;
  DateTime? get runningExpiresAt =>
      runningSource == 'PRIME' ? primeExpiresAt : runningSource == 'STORE' ? storeExpiresAt : null;

  static int _daysLeft(DateTime from, DateTime? to) {
    if (to == null || !to.isAfter(from)) return 0;
    final hours = to.difference(from).inHours;
    return hours ~/ 24 + (hours % 24 > 0 ? 1 : 0);
  }

  static const none = PassHolding();

  factory PassHolding.fromJson(Map<String, dynamic> json) => PassHolding(
    primeStartedAt: _time(json['primeStartedAt']),
    primeExpiresAt: _time(json['primeExpiresAt']),
    storeStartedAt: _time(json['storeStartedAt']),
    storeExpiresAt: _time(json['storeExpiresAt']),
  );
}

class ActiveBoost {
  const ActiveBoost({required this.kind, required this.expiresAt, this.source});

  final String kind;
  final DateTime expiresAt;

  /// 나간 쪽(`PRIME`·`STORE`).
  final String? source;

  Duration get remaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ActiveBoost.fromJson(Map<String, dynamic> json) => ActiveBoost(
    kind: json['kind'] as String? ?? '',
    expiresAt: parseServerTimeOr(json['expiresAt']),
    source: json['source'] as String?,
  );
}

/// 상품 종류별 화면 문구 — 여러 화면에서 같은 표현을 쓰려고 한곳에 모았다.
abstract final class StoreKind {
  static const postBoost = 'POST_BOOST';
  static const albumPass = 'ALBUM_PASS';
  static const translatePass = 'TRANSLATE_PASS';
  static const unlimitedChatReq = 'UNLIMITED_CHAT_REQ';
  static const noAds = 'NO_ADS';

  static String label(L10n l10n, String kind) => switch (kind) {
    postBoost => l10n.storeKindPostBoost,
    albumPass => l10n.storeKindAlbumPass,
    translatePass => l10n.storeKindTranslatePass,
    _ => kind,
  };

  static String description(L10n l10n, String kind) => switch (kind) {
    postBoost => l10n.storeDescPostBoost,
    albumPass => l10n.storeDescAlbumPass,
    translatePass => l10n.storeDescTranslatePass,
    _ => '',
  };
}
