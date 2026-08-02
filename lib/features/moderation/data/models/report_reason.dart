/// 신고 사유. (기획서 화면 16)
///
/// 서버에는 **코드**를 보낸다(집계·운영 대응용). 화면 문구가 바뀌어도 저장된 값은 그대로다.
enum ReportReason {
  illegalAd('ILLEGAL_AD', '불법 광고 및 홍보'),
  romanceScam('ROMANCE_SCAM', '로맨스 스캠 (연애 사기)'),
  sexualDeepfake('SEXUAL_DEEPFAKE', '허위 합성/편집한 성인물'),
  abusive('ABUSIVE', '욕설 및 비매너'),
  coercion('COERCION', '강요 및 협박'),
  privacyLeak('PRIVACY_LEAK', '개인정보 유출'),
  other('OTHER', '기타');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;

  /// "기타"는 무엇이 문제였는지 알 수 없어 직접 적게 한다.
  bool get needsDetail => this == ReportReason.other;
}
