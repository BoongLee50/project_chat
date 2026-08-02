import '../../../../l10n/app_localizations.dart';

/// 신고 사유. (기획서 화면 16)
///
/// 서버에는 **코드**를 보낸다(집계·운영 대응용). 화면 문구가 바뀌어도 저장된 값은 그대로다.
enum ReportReason {
  illegalAd('ILLEGAL_AD'),
  romanceScam('ROMANCE_SCAM'),
  sexualDeepfake('SEXUAL_DEEPFAKE'),
  abusive('ABUSIVE'),
  coercion('COERCION'),
  privacyLeak('PRIVACY_LEAK'),
  other('OTHER');

  const ReportReason(this.code);

  final String code;

  /// 화면 문구는 언어마다 달라 enum에 담아 둘 수 없다. 서버로 가는 건 [code]뿐.
  String label(L10n l10n) => switch (this) {
    illegalAd => l10n.reportReasonIllegalAd,
    romanceScam => l10n.reportReasonRomanceScam,
    sexualDeepfake => l10n.reportReasonSexualDeepfake,
    abusive => l10n.reportReasonAbusive,
    coercion => l10n.reportReasonCoercion,
    privacyLeak => l10n.reportReasonPrivacyLeak,
    other => l10n.reportReasonOther,
  };

  /// "기타"는 무엇이 문제였는지 알 수 없어 직접 적게 한다.
  bool get needsDetail => this == ReportReason.other;
}
