import 'package:flutter/material.dart';

import 'shop_item_screen.dart';

/// 포스트 화면 [포스트 부스트]·[포스트 앨범] 문(기획서 261111 3-1 · 10-2 · 10-3).
///
/// 기획서 261111부터 상품마다 **구매 화면 / 관리 화면**이 따로 있다 — 갖고 있으면 관리, 없으면 구매.
/// 둘을 한 화면([ShopItemScreen])이 상태로 고른다.
/// (부르는 쪽 `home_screen.dart`를 건드리지 않으려고 이름과 `route`를 남겼다)
abstract final class BoostScreen {
  static Route<void> route(String kind) => ShopItemScreen.route(kind);
}
