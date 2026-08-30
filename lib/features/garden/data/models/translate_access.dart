/// 어떤 자리(댓글창·대화방)에서 **지금 번역이 되는가**(기획 4-2 · 5장 · 8-3).
///
/// 화면은 이 답으로 둘을 정한다 — 번역을 켤지, 그리고 `[번역 | …]` 버튼에 뭐라고 쓸지.
/// 시안이 *"무료 적용 및 구매 전과 후에 따라 버튼 명칭 변경"* 이라고 했다.
///
/// 🚨 **숫자는 전부 서버가 준다.** 무료가 몇 회인지, 몇 개 남았는지, 패스가 언제 끝나는지 —
/// 화면이 알아서 정하는 값이 하나도 없다.
class TranslateAccess {
  const TranslateAccess({
    required this.granted,
    required this.unlimited,
    required this.remaining,
    required this.free,
    required this.provider,
    this.expiresInMinutes,
  });

  /// 이 창/방에서 번역이 적용되는가.
  final bool granted;

  /// 패스·프라임이라 세지 않는가.
  final bool unlimited;

  /// 남은 무료 자리(창 호출 횟수 또는 방 수). [unlimited]면 의미 없다.
  final int remaining;

  /// 무료 전체 자리 수 — "5회 중"을 말할 수 있게.
  final int free;

  /// 번역 공급자. `none`이면 **아직 실제로 번역되지 않는다**.
  final String provider;

  /// 패스 만료까지 남은 **분**. 시안이 "일, 시간, 분"으로 표시하라고 했다.
  final int? expiresInMinutes;

  /// 공급자가 붙어 있는가. 아니면 번역 자체가 준비되지 않은 것이다.
  bool get providerReady => provider != 'none';

  static const unavailable = TranslateAccess(
    granted: false,
    unlimited: false,
    remaining: 0,
    free: 0,
    provider: 'none',
  );

  factory TranslateAccess.fromJson(Map<String, dynamic> json) => TranslateAccess(
    granted: json['granted'] as bool? ?? false,
    unlimited: json['unlimited'] as bool? ?? false,
    remaining: json['remaining'] as int? ?? 0,
    free: json['free'] as int? ?? 0,
    provider: json['provider'] as String? ?? 'none',
    expiresInMinutes: (json['expiresAt'] as num?)?.toInt(),
  );
}
