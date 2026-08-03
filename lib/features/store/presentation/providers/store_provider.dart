import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/providers.dart';
import '../../data/models/store_models.dart';

/// 상품 카탈로그 — 가격·구성이 서버 설정에서 오므로 화면은 이것만 보고 그린다.
/// 자주 바뀌지 않아 한 번 읽고 캐시한다.
final catalogProvider = FutureProvider<ProductCatalog>(
  (ref) => ref.read(storeApiProvider).catalog(),
);

/// 내 재화·구독·권리. 구매/사용 후에는 서버가 돌려준 최신 값으로 갱신한다.
class WalletController extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() => ref.read(storeApiProvider).wallet();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(storeApiProvider).wallet());
  }

  /// 구매·사용 API는 갱신된 지갑을 그대로 돌려주므로 재조회하지 않는다.
  void apply(Wallet wallet) => state = AsyncValue.data(wallet);
}

final walletProvider = AsyncNotifierProvider<WalletController, Wallet>(
  WalletController.new,
);

/// 구매·사용 동작 — 성공하면 null, 실패하면 사용자에게 보여줄 메시지.
class StoreActions {
  const StoreActions(this._ref);

  final Ref _ref;

  Future<ApiException?> purchaseWithLuna(String productId) =>
      _run(() => _ref.read(storeApiProvider).purchaseWithLuna(productId));

  Future<ApiException?> useBoost(String kind) =>
      _run(() => _ref.read(storeApiProvider).useBoost(kind));

  Future<ApiException?> cancelSubscription() =>
      _run(() => _ref.read(storeApiProvider).cancelSubscription());

  /// 인앱결제. 실제 스토어 결제창은 계정 발급 후 붙는다(01 §1.8 ①).
  Future<ApiException?> verifyPurchase({
    required String productId,
    required String purchaseToken,
    String platform = 'GOOGLE',
  }) => _run(
    () => _ref.read(storeApiProvider).verifyPurchase(
      platform: platform,
      productId: productId,
      purchaseToken: purchaseToken,
    ),
  );

  Future<ApiException?> _run(Future<Wallet> Function() action) async {
    try {
      _ref.read(walletProvider.notifier).apply(await action());
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final storeActionsProvider = Provider<StoreActions>(StoreActions.new);
