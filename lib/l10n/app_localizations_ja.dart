// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class L10nJa extends L10n {
  L10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '月光トーク';

  @override
  String get commonSave => '保存する';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonDelete => '削除';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonClose => '閉じる';

  @override
  String get loginTagline => '夜だけ開くチャットの時間';

  @override
  String get loginHours => '午後5時 〜 午前6時';

  @override
  String get loginWithLine => 'LINEでログイン';

  @override
  String get loginWithKakao => 'カカオトークでログイン';

  @override
  String get loginWithGoogle => 'Googleでログイン';

  @override
  String get loginTermsNotice => 'ログインすると、利用規約およびプライバシーポリシーに同意したものとみなされます。';

  @override
  String get nicknameTitle => 'ニックネーム設定';

  @override
  String get nicknameSubtitle => '月光トークで使うニックネームを入力してください。';

  @override
  String get nicknameHint => 'ニックネームを入力してください';

  @override
  String get nicknameGuideTitle => 'ニックネームのガイド';

  @override
  String get nicknameGuideLength => '2文字以上10文字以下で入力してください。';

  @override
  String get nicknameGuideNoSpecialChars => '特殊文字と絵文字は使用できません。';

  @override
  String get nicknameGuideNoProfanity => '暴言・差別表現など不適切なニックネームは使用できません。';
}
