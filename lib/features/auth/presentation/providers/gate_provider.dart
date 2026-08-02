import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/auth_models.dart';

/// 운영시간(17~06시) 상태. 서버 `/system/gate`가 권위다.
///
/// 클라가 시계를 직접 계산하지 않는 이유는 기기 시간이 틀릴 수 있어서다
/// (01 문서 공통 규약: 모든 시간 판정은 서버 권위 KST).
///
/// 열리는 시각이 지나면 스스로 다시 물어본다 — 사용자가 앱을 켜 둔 채
/// 17시를 맞아도 화면이 따라오게 하려는 것.
class GateController extends AsyncNotifier<GateState> {
  Timer? _reopenTimer;

  @override
  Future<GateState> build() async {
    ref.onDispose(() => _reopenTimer?.cancel());

    final gate = await ref.read(authApiProvider).gate();
    _scheduleReopen(gate);
    return gate;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final gate = await ref.read(authApiProvider).gate();
      _scheduleReopen(gate);
      return gate;
    });
  }

  /// 다음 개방 시각에 맞춰 한 번만 재조회를 예약한다.
  void _scheduleReopen(GateState gate) {
    _reopenTimer?.cancel();
    final nextOpen = gate.nextOpenAt;
    if (gate.open || nextOpen == null) return;

    // 서버 시계와 몇 초 어긋날 수 있어 여유를 둔다.
    final delay = nextOpen.difference(DateTime.now()) + const Duration(seconds: 2);
    if (delay.isNegative) {
      refresh();
      return;
    }
    _reopenTimer = Timer(delay, refresh);
  }
}

final gateProvider =
    AsyncNotifierProvider<GateController, GateState>(GateController.new);

/// 지금 열려 있는지. 아직 모르면(로딩·오류) **열린 것으로 본다** —
/// 게이트 조회에 실패했다고 화면을 잠가 버리면 서버가 허용하는 동작까지 막힌다.
/// 실제 차단은 어차피 서버가 하므로 클라는 안내 역할만 한다.
final gateOpenProvider = Provider<bool>(
  (ref) => ref.watch(gateProvider).valueOrNull?.open ?? true,
);
