import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 **세로 고정**(2026-10-05 결정). 화면 전부가 1080×2640 세로 캔버스 위에 좌표로 그려져
  // 가로로 돌면 깨진다. 폰을 눕혀도 앱은 세로를 유지한다.
  // 안드로이드는 `AndroidManifest.xml`의 `screenOrientation="portrait"`가 엔진이 뜨기 전부터 막고,
  // 이 줄은 iOS와 그 밖의 경우를 맡는다 — 둘 중 하나만 고치면 다른 쪽에서 돈다.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 시스템 바(상태바·내비게이션 바)를 앱이 직접 그린다.
  //
  // 안드로이드 15부터는 edge-to-edge가 강제되고 `systemNavigationBarColor` 지정이
  // **무시된다**. 그래서 색을 넣는 대신 바를 투명하게 두고 그 자리에 앱 배경이
  // 비치게 한다 — 다크 앱인데 내비 영역만 밝은 회색으로 뜨던 문제가 이걸로 사라진다.
  //
  // 색을 못 정하는 대신 **아이콘 밝기**는 지정할 수 있다. 배경이 어두우니 밝은 아이콘.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // 안드로이드
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: DalbittokApp()));
}
