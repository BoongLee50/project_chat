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

  @override
  String get chatRoomsTitle => 'チャットルーム';

  @override
  String get chatRoomsSubtitle => '心が通じ合う人と話してみましょう。';

  @override
  String get chatTabMatch => 'マッチトーク';

  @override
  String get chatTabFriend => '友だち';

  @override
  String get chatTabReceived => '受け取ったリクエスト';

  @override
  String get chatTabSent => '送ったリクエスト';

  @override
  String get chatRoomsEmpty => 'まだ会話がありません。\n月光ガーデンで気になる人に話しかけてみましょう。';

  @override
  String get chatRoomsEmptySent => '送った会話リクエストはありません。';

  @override
  String get chatRoomsStart => '会話を始めてみましょう。';

  @override
  String get chatRoomsOngoing => '会話中';

  @override
  String get chatGateClosed => '今はマッチトークができる時間ではありません。\n友だちとの会話はいつでも可能です。';

  @override
  String get commonAccept => '承認';

  @override
  String get commonReject => '拒否';

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String ageYears(int age) {
    return '$age歳';
  }

  @override
  String get chatLoadFailed => '会話を読み込めませんでした。';

  @override
  String get chatInputHint => 'メッセージを入力してください...';

  @override
  String get chatMatchedNotice => 'マッチしました。礼儀正しく素敵な会話を楽しみましょう。';

  @override
  String get chatMenuProfile => 'プロフィールを見る';

  @override
  String get chatMenuFriendRequest => '友だちリクエスト';

  @override
  String get chatMenuReport => '通報する';

  @override
  String get chatMenuBlock => 'ブロックする';

  @override
  String get chatMenuLeave => 'チャットルームを出る';

  @override
  String get chatFriendRequestSent => '友だちリクエストを送りました。相手が承認すると友だちになります。';

  @override
  String get chatReportDone => '通報を受け付けました。会話は終了します。';

  @override
  String chatBlockDone(String nickname) {
    return '$nicknameさんをブロックしました。';
  }

  @override
  String get friendsTitle => '友だち';

  @override
  String get friendsOnlineNowLabel => '現在オンライン ';

  @override
  String friendsOnlineCount(int count) {
    return '$count人';
  }

  @override
  String friendsRequestsReceived(int count) {
    return '受け取った友だちリクエスト $count';
  }

  @override
  String get friendsLoadFailed => '友だちリストを読み込めませんでした。';

  @override
  String get friendsEmpty => 'まだ友だちがいません。';

  @override
  String get friendsEmptyHint => '会話した相手に、チャット画面のメニューから友だちリクエストを送ってみましょう。';

  @override
  String get friendsAccepted => '友だちになりました。これからはいつでも会話できます。';

  @override
  String get friendsRejected => 'リクエストを拒否しました。';

  @override
  String get friendsRequestSent => '友だちリクエストを送りました。';

  @override
  String get friendsRoomNotFound => 'チャットルームが見つかりません。更新してください。';

  @override
  String friendsDeleteConfirm(String nickname) {
    return '$nicknameさんを友だちから削除しますか？';
  }

  @override
  String get friendsDeleteDetail => '常時チャットルームも一緒に終了します。';

  @override
  String get filterAge => '年齢';

  @override
  String get filterCountry => '国';

  @override
  String get statusOnline => 'オンライン';

  @override
  String get statusOffline => 'オフライン';

  @override
  String get friendPostTitle => '今日のポスト';

  @override
  String get friendPostLoadFailed => 'ポストを読み込めませんでした。';

  @override
  String get friendPostMessage => 'メッセージ';

  @override
  String get friendPostSendMessage => 'メッセージを送る';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profilePhotoPrompt => 'プロフィール写真を登録してください';

  @override
  String get profileLunaBalance => '保有ルナ';

  @override
  String get profileLunaStore => 'ルナストア';

  @override
  String get profilePrimeTitle => 'プライムでもっと特別に ✨';

  @override
  String get profilePrimeBenefits => 'ポスト8枚・ブースト・無制限チャット・自動翻訳';

  @override
  String get profileSeeDetail => '詳しく見る';

  @override
  String get profileBoostPost => 'ポストブースト';

  @override
  String get profileBoostMatch => 'マッチブースト';

  @override
  String profileBoostCount(int count) {
    return '$count枚';
  }

  @override
  String get profileSpotlight => 'スポットライト';

  @override
  String get profileFreeUpload => '無料アップロード';

  @override
  String get profileNoAds => '広告非表示';

  @override
  String get profileVisitors => '訪問者を見る';

  @override
  String get profileIntro => 'ひとこと紹介';

  @override
  String get profileIntroEmpty => '自分を紹介するひとことを書いてみましょう。（最大50文字）';

  @override
  String get profileInterests => '興味・関心';

  @override
  String get profileInterestsEmpty => '興味・関心を登録すると、より合う人に出会えます。';

  @override
  String get profileRegions => '活動地域';

  @override
  String get profileRegionsEmpty => '活動地域は最大2か所まで選択できます。';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get introEditTitle => 'ひとこと紹介';

  @override
  String get introEditHint => '趣味や性格、伝えたいことを\n自由に書いてみましょう。';

  @override
  String get introEditCounter => '最大50文字まで入力できます。';

  @override
  String get interestsEditTitle => '興味・関心の登録';

  @override
  String get interestsEditSubtitle => '最近ハマっているものはありますか？好みをシェアしましょう！';

  @override
  String interestsEditSelected(int count, int max) {
    return '選択中の興味・関心 ($count/$max)';
  }

  @override
  String get interestsEditEmpty => '興味・関心を選択してください。';

  @override
  String get interestsEditReset => 'すべてリセット';

  @override
  String interestsEditSave(int count, int max) {
    return '保存する ($count/$max)';
  }

  @override
  String interestsEditLimit(int max) {
    return '興味・関心は最大$max個まで選択できます。';
  }

  @override
  String get regionsEditTitle => '地域の選択';

  @override
  String regionsEditSubtitle(int max) {
    return '国と地域を選択してください。（最大$maxか所）';
  }

  @override
  String get regionsEditOfCountry => 'の主要地域';

  @override
  String get regionsEditSelected => '選択した地域';

  @override
  String get regionsEditApply => '適用する';

  @override
  String regionsEditLimit(int max) {
    return '活動地域は最大$maxか所まで選択できます。';
  }

  @override
  String get commonNone => 'なし';
}
