import 'package:flutter/material.dart';

import 'shop_item_screen.dart';

/// [번역] 버튼 문(포스트 댓글 · 채팅창 · 달빛 한마디 상세 — 기획서 261111 10-4 "[자동 번역 구매] 화면 출력").
///
/// 갖고 있으면 [자동 번역 관리], 없으면 [자동 번역 구매] — 한 화면([ShopItemScreen])이 상태로 고른다.
/// (부르는 쪽 세 곳을 건드리지 않으려고 이름과 `route`를 남겼다)
abstract final class PassScreen {
  static Route<void> route(String kind) => ShopItemScreen.route(kind);
}
