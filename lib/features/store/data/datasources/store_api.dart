import '../../../../core/network/dio_client.dart';
import '../models/store_models.dart';

/// 유료 상점 REST 호출. (docs/01 §1.8)
class StoreApi {
  const StoreApi(this._client);

  final DioClient _client;

  Future<ProductCatalog> catalog() async {
    final data = await _client.get('/store/products');
    return ProductCatalog.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Wallet> wallet() async {
    final data = await _client.get('/me/wallet');
    return Wallet.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 루나로 개별 상품 구매(부스트 매수·패스). 인앱결제가 아니다.
  Future<Wallet> purchaseWithLuna(String productId) async {
    final data = await _client.post(
      '/store/luna:purchase',
      body: {'productId': productId},
    );
    return Wallet.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 보유 부스트 1매 사용 → 1시간 활성.
  Future<Wallet> useBoost(String kind) async {
    final data = await _client.post('/boosts:use', body: {'kind': kind});
    return Wallet.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 인앱결제 영수증 검증 → 루나 지급 또는 구독 활성화.
  ///
  /// 실제 결제창(in_app_purchase)은 스토어 계정이 생긴 뒤에 붙는다. 그 전까지는
  /// 개발용 검증기가 `dev-`로 시작하는 토큰만 통과시킨다(서버 `MockReceiptVerifier`).
  Future<Wallet> verifyPurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
  }) async {
    final data = await _client.post(
      '/store/purchases:verify',
      body: {
        'platform': platform,
        'productId': productId,
        'purchaseToken': purchaseToken,
      },
    );
    return Wallet.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// 자동갱신 해지(만료까지는 혜택 유지).
  Future<Wallet> cancelSubscription() async {
    final data = await _client.post('/me/subscription:cancel');
    return Wallet.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
