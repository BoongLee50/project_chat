import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  // 상태관리(ProviderScope), 라우팅(go_router), 소켓/REST 초기화는
  // 패키지 도입 단계에서 여기에 연결한다. (docs/03-flutter-structure.md)
  runApp(const DalbittokApp());
}
