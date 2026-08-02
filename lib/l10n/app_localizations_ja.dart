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

  @override
  String get onboardingBack => '戻る';

  @override
  String get onboardingNext => '完了';

  @override
  String get onboardingPrivateNotice => '※ この情報は他のユーザーには公開されません。';

  @override
  String get birthYearTitle => '生年設定';

  @override
  String get birthYearSubtitle => '年齢確認のため生まれた年を選択してください。';

  @override
  String get genderCountryTitle => '性別・国の設定';

  @override
  String get genderCountrySubtitle => 'より合う相手と出会えるよう性別と国を選択してください。';

  @override
  String get genderSectionTitle => '性別を選択';

  @override
  String get genderMale => '男性';

  @override
  String get genderFemale => '女性';

  @override
  String get countrySectionTitle => '国を選択';

  @override
  String get countryKorea => '韓国';

  @override
  String get countryJapan => '日本';

  @override
  String get commonEdit => '編集';

  @override
  String get commonEmptyValue => '—';

  @override
  String get homeTitle => '今日のポスト';

  @override
  String get homeTodayMoon => '今日の月';

  @override
  String get homeMoonCrescent => '三日月';

  @override
  String get homeUploadRemaining => 'ポスト登録の残り時間';

  @override
  String get homeLoadFailed => 'ポストを読み込めませんでした。';

  @override
  String get homePullToRefresh => '下に引いて更新してください。';

  @override
  String homeEmptyGreeting(String nickname) {
    return '$nicknameさん';
  }

  @override
  String get homeEmptyHint => '月明かりの下の今をポストしてみましょう。\n新しい会話のきっかけになるかもしれません。';

  @override
  String get homeGateClosed => '今はポストを登録できる時間ではありません。';

  @override
  String get homeAlbumPass => 'ポストアルバムパス';

  @override
  String homeAlbumPassRemaining(int days) {
    return '残り$days日';
  }

  @override
  String homeAlbumPassMaxPhotos(int count) {
    return '最大$count枚まで登録可能';
  }

  @override
  String get homeBoost => 'ブースト';

  @override
  String get homeBoostActive => 'ブースト使用中';

  @override
  String homeBoostStock(int count) {
    return '保有$count枚';
  }

  @override
  String get homeOneLiner => '今日のひとこと';

  @override
  String get homeOneLinerHint => '今日の気分を一言で残してみましょう';

  @override
  String get homeOneLinerEmpty => '今日のひとことを入力してください。';

  @override
  String get homeOneLinerWrite => '作成';

  @override
  String get homeShare => 'ポストを共有する';

  @override
  String get homeShareAgain => '共有済み · もう一度共有';

  @override
  String get homeShared => 'ポストを共有しました 🌙';

  @override
  String get commonAll => 'すべて';

  @override
  String get commonSend => '送信';

  @override
  String get commonOnline => 'オンライン';

  @override
  String ageDecade(int decade) {
    return '$decade代';
  }

  @override
  String get gardenTitle => '月光ガーデン';

  @override
  String get gardenSubtitle => '月明かりの下、私たちの一日を分かち合う場所 ✨';

  @override
  String get gardenSpotlight => 'スポットライト';

  @override
  String get gardenLoadFailed => 'フィードを読み込めませんでした。';

  @override
  String get gardenEmptyTitle => '今は表示できるポストがありません。';

  @override
  String get gardenEmptyDetail => 'フィルターを変えるか、しばらくしてからご確認ください。';

  @override
  String get gardenGateTitle => '月光ガーデンはまだ開いていません。';

  @override
  String get gardenGateDescription => '月明かりが訪れる午後5時から\n翌朝6時までご利用いただけます。';

  @override
  String gardenChatRequestTitle(String nickname) {
    return '$nicknameさんに会話をリクエスト';
  }

  @override
  String get gardenChatRequestHint => '最初のあいさつを送ってみましょう（最大100文字）';

  @override
  String get gardenChatRequestSent => '会話をリクエストしました。相手の返事をお待ちください。';

  @override
  String commentsTitle(String nickname) {
    return '$nicknameさんのポスト';
  }

  @override
  String get commentsSection => 'コメント';

  @override
  String get commentsHint => 'コメントを残してみましょう（最大25文字）';

  @override
  String get commentsEmpty => '最初のコメントを残してみましょう。';

  @override
  String get commentsLoadFailed => 'コメントを読み込めませんでした。';

  @override
  String get gateOpensIn => '開くまで';

  @override
  String gateOpensAfter(String remaining) {
    return '$remaining後に開きます。';
  }

  @override
  String durationHourMinute(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String durationMinuteSecond(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String durationSecond(int seconds) {
    return '$seconds秒';
  }
}
