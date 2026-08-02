/// 서버가 주는 시각 문자열을 기기 로컬 시간으로 바꾼다.
///
/// 서버는 **KST 기준 naive ISO-8601**을 준다(`"2026-08-02T14:44:32"` — 오프셋 없음).
/// 시간 판정의 권위가 서버(KST)에 있기 때문인데(01 문서 공통 규약), 오프셋이 없으면
/// `DateTime.parse`가 **기기 로컬 시간대**로 해석해 버린다.
/// 기기가 KST가 아니면(에뮬레이터 기본값은 GMT) 그대로 시차만큼 어긋난다 —
/// 부스트 "1시간 남음"이 "9시간 32분 남음"으로 보이는 식.
///
/// 그래서 오프셋이 없는 값은 KST로 못박아 해석한 뒤 로컬로 변환한다.
/// 서버가 나중에 오프셋을 붙여 주더라도 그대로 동작한다.
library;

const _kstOffset = '+09:00';
final _offsetPattern = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

DateTime? parseServerTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  final normalized = _offsetPattern.hasMatch(raw) ? raw : '$raw$_kstOffset';
  return DateTime.tryParse(normalized)?.toLocal();
}

/// 파싱에 실패하면 [fallback](기본: 지금)을 쓴다.
DateTime parseServerTimeOr(Object? raw, [DateTime? fallback]) =>
    parseServerTime(raw) ?? fallback ?? DateTime.now();
