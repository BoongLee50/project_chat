// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class L10nKo extends L10n {
  L10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '달빛톡';

  @override
  String get commonSave => '저장하기';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonClose => '닫기';

  @override
  String get loginTagline => '밤에만 열리는 채팅의 시간';

  @override
  String get loginHours => '오후 5시 ~ 새벽 6시';

  @override
  String get loginWithLine => 'LINE으로 로그인';

  @override
  String get loginWithKakao => '카카오톡으로 로그인';

  @override
  String get loginWithGoogle => 'Google로 로그인';

  @override
  String get loginTermsNotice => '로그인하면 서비스 이용약관 및 개인정보처리방침에 동의하게 됩니다.';

  @override
  String get nicknameTitle => '닉네임 설정';

  @override
  String get nicknameSubtitle => '달빛톡에서 사용할 닉네임을 입력해주세요.';

  @override
  String get nicknameHint => '닉네임을 입력해주세요';

  @override
  String get nicknameGuideTitle => '닉네임 가이드';

  @override
  String get nicknameGuideLength => '2자 이상 10자 이하로 입력해주세요.';

  @override
  String get nicknameGuideNoSpecialChars => '특수문자 및 이모지는 사용할 수 없습니다.';

  @override
  String get nicknameGuideNoProfanity => '욕설, 혐오 표현 등 부적절한 닉네임은 사용할 수 없습니다.';
}
