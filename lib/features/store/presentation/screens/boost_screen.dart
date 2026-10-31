import 'package:flutter/material.dart';

import 'luna_store_screen.dart';

/// 포스트 화면 [부스트]·[포스트 앨범] 문(기획서 261011 10-2-1·10-2-2).
///
/// 2026-10-31 `Scene_Shop/LunaShop`부터 **따로 된 부스트 화면이 없다** — 구매는 루나 상점 카드에서,
/// 사용·사용 정보는 상품 관리 팝업에서 한다. 이 문은 루나 상점으로 가고, 이미 갖고 있으면
/// 그 상품 관리 팝업까지 연다([LunaStoreScreen.focus]).
/// (부르는 쪽 `home_screen.dart`를 건드리지 않으려고 이름과 `route`를 남겼다)
abstract final class BoostScreen {
  static Route<void> route(String kind) => LunaStoreScreen.route(focus: kind);
}
