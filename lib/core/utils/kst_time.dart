/// KST(한국 표준시) 기준 시간 헬퍼 골격.
///
/// 주의: 게이트(18~05시) 개폐의 최종 판정은 서버 시각을 신뢰한다.
/// 아래는 UI 표시/폴백용 참고값이며 디바이스 시계에 의존한다.
/// (docs/03-flutter-structure.md 게이트 섹션 참고)
class KstTime {
  const KstTime._();

  /// UTC 대비 KST 오프셋 (+09:00)
  static const Duration kstOffset = Duration(hours: 9);

  /// 현재 시각을 KST로 환산 (참고용).
  static DateTime nowKst() => DateTime.now().toUtc().add(kstOffset);
}
