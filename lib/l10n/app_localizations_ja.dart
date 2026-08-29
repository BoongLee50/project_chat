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
  String get gardenLoadFailed => 'フィードを読み込めませんでした。';

  @override
  String get gardenEmptyTitle => '今は表示できるポストがありません。';

  @override
  String get gardenEmptyDetail => 'フィルターを変えるか、しばらくしてからご確認ください。';

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
  String get chatRoomsTitle => 'チャットルーム';

  @override
  String get chatRoomsSubtitle => '心が通じ合う人と話してみましょう。';

  @override
  String get chatTabFriend => '友だち';

  @override
  String get chatTabReceived => '受け取ったリクエスト';

  @override
  String get chatRoomsEmpty => 'まだ会話がありません。\n月光ガーデンで気になる人に話しかけてみましょう。';

  @override
  String get chatRoomsStart => '会話を始めてみましょう。';

  @override
  String get chatRoomsOngoing => '会話中';

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
  String get photoSheetProfileTitle => 'プロフィール写真の変更';

  @override
  String get photoSheetProfileSubtitle =>
      'すてきな写真でプロフィールを更新して\nもっと多くの出会いを見つけましょう!';

  @override
  String get photoSheetPostTitle => 'ポスト写真の登録';

  @override
  String get photoSheetPostSubtitle => '今夜の瞬間を残してみましょう。';

  @override
  String get photoSourceGallery => 'アルバムから選択';

  @override
  String get photoSourceCamera => 'カメラで撮影';

  @override
  String get photoSourceRemove => 'プロフィール写真を削除';

  @override
  String get photoSourceGalleryPassOnly => 'アルバムパスが必要です';

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

  @override
  String get storeKindPostBoost => 'ポストブースト';

  @override
  String get storeKindAlbumPass => 'ポストアルバムパス';

  @override
  String get storeKindTranslatePass => '自動翻訳パス';

  @override
  String get storeDescPostBoost => '他の人より優先してポスト写真をおすすめします！';

  @override
  String get storeDescAlbumPass =>
      '複数の写真を自由にアップロード！時間制限なしで、カメラとギャラリーの写真どちらも使えます。';

  @override
  String get storeDescTranslatePass => 'すべてのメッセージを自動翻訳して、言葉の壁なくやりとり！';

  @override
  String storeOptionBoost(int quantity) {
    return '1時間、$quantity枚';
  }

  @override
  String storeOptionDays(int days) {
    return '$days日';
  }

  @override
  String get lunaStoreTitle => 'ルナストア';

  @override
  String get lunaStoreSubtitle => 'ルナでもっと特別な体験を作りましょう。';

  @override
  String get storeLoadFailed => '商品を読み込めませんでした。';

  @override
  String get storeBuy => '購入する';

  @override
  String get storeDetail => '詳細';

  @override
  String storeDiscount(int percent) {
    return '$percent%オフ';
  }

  @override
  String storePurchased(String item, String option) {
    return '$item $option を購入しました！';
  }

  @override
  String get storeLunaBalance => '保有ルナ';

  @override
  String get storeCharge => 'チャージする';

  @override
  String boostOwnedTitle(String item) {
    return '保有中の$item';
  }

  @override
  String boostItemHour(String item) {
    return '$item（1時間）';
  }

  @override
  String boostStock(int count) {
    return '保有$count枚';
  }

  @override
  String boostActiveRemaining(String remaining) {
    return '使用中 — 残り$remaining';
  }

  @override
  String boostRemainHourMinute(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String boostRemainMinute(int minutes) {
    return '$minutes分';
  }

  @override
  String get boostRemainUnderMinute => '1分未満';

  @override
  String get boostEffectTitle => '期待できる効果';

  @override
  String get boostEffectExposure => '最大表示回数アップ';

  @override
  String get boostEffectExposureValue => '約3倍';

  @override
  String get boostEffectExposureDetail => 'より多くのユーザーに表示されます';

  @override
  String get boostEffectVisit => 'プロフィール訪問アップ';

  @override
  String get boostEffectVisitValue => '約2.5倍';

  @override
  String get boostEffectVisitDetail => 'プロフィールへの訪問と流入が増えます';

  @override
  String get boostEffectLike => 'いいねアップ';

  @override
  String get boostEffectLikeValue => '約2倍';

  @override
  String get boostEffectLikeDetail => 'いいねと関心をより多く集められます';

  @override
  String get boostHourHighlight => '1時間';

  @override
  String get boostHourSuffix => 'のあいだおすすめの優先度が上がり\nより多くのユーザーに表示されます！';

  @override
  String get boostUse => 'ブーストを使う（1枚）';

  @override
  String get boostInUse => '使用中です';

  @override
  String get boostNoneShort => '保有中のブーストがありません';

  @override
  String get boostNone => '保有中のブーストがありません。';

  @override
  String get boostBuyHint => 'ルナストアでブーストを購入できます。';

  @override
  String get boostGoStore => 'ルナストアへ';

  @override
  String get boostUsed => 'ブーストを使いました。1時間のあいだ優先表示されます！';

  @override
  String passBuy(String item) {
    return '$itemを購入';
  }

  @override
  String passExtend(String item) {
    return '$itemを延長';
  }

  @override
  String passPurchased(String item, int days) {
    return '$item $days日分を購入しました！';
  }

  @override
  String get passPeriodSection => '期間を選択';

  @override
  String passDays(int days) {
    return '$days日';
  }

  @override
  String passDaysPass(int days) {
    return '$days日パス';
  }

  @override
  String passPriceLuna(int price) {
    return '$price ルナ';
  }

  @override
  String get passAmount => '購入金額';

  @override
  String get passUsageInfo => '利用情報';

  @override
  String get passStatus => '保有状況';

  @override
  String get passStatusActive => '利用中';

  @override
  String get passStatusNone => '未保有';

  @override
  String get passStatusPending => '購入待ち';

  @override
  String get passRemaining => '残り期間';

  @override
  String passValidUntil(String date) {
    return '$dateまで';
  }

  @override
  String get passValidPeriod => '有効期間';

  @override
  String get passExtendNotice => 'すでに利用中です。今購入すると、残り期間に続けて延長されます。';

  @override
  String get passAlbumHeadline => 'もっと多くのポスト写真を登録して、いろいろな魅力を見せましょう！';

  @override
  String get passAlbumBenefit1 => 'ポスト写真を最大8枚まで登録';

  @override
  String get passAlbumBenefit1Desc => '基本1枚から最大8枚まで、複数の写真を登録できます。';

  @override
  String get passAlbumBenefit2 => '登録時間の制限なし（24時間いつでも）';

  @override
  String get passAlbumBenefit2Desc => '時間の制約なく、いつでも自由にポストを登録できます。';

  @override
  String get passAlbumBenefit3 => 'スマホのギャラリー写真もアップロード可能';

  @override
  String get passAlbumBenefit3Desc => 'カメラで撮った写真だけでなく、ギャラリーの写真も投稿できます。';

  @override
  String get passTranslateHeadline => '言葉の壁なく、もっと多くの人と話してみましょう！';

  @override
  String get passTranslateBenefit1 => 'チャット自動翻訳が無制限';

  @override
  String get passTranslateBenefit1Desc => '相手のメッセージを自動翻訳して、リアルタイムでやりとりできます。';

  @override
  String get passTranslateBenefit2 => 'コメント自動翻訳が無制限';

  @override
  String get passTranslateBenefit2Desc => '月光ガーデンとポストのコメントを自動で翻訳します。';

  @override
  String get passTranslateBenefit3 => 'プロフィール自動翻訳が無制限';

  @override
  String get passTranslateBenefit3Desc => '相手のプロフィール情報と今日のひとことを自動で翻訳します。';

  @override
  String get primeTitle => 'PRIMEメンバーシップ';

  @override
  String get primeSubtitle => 'PRIMEでもっと特別な体験を楽しみましょう。';

  @override
  String get primeHeadline => '月光トークを完璧に楽しむ方法';

  @override
  String get primeHeadlineDetail => 'すべての機能を制限なく！';

  @override
  String get primePlanSection => 'プランを選ぶ';

  @override
  String primeMonths(int months) {
    return '$monthsか月';
  }

  @override
  String get primeBestValue => 'コスパ最強';

  @override
  String get primeStorePrice => 'ストア価格';

  @override
  String get primePay => '支払う';

  @override
  String get primeStarted => 'PRIMEメンバーシップが始まりました！';

  @override
  String get primeActive => 'PRIME利用中';

  @override
  String primeActiveMonths(int months) {
    return '$monthsか月プラン利用中';
  }

  @override
  String primeRemainingDays(int days) {
    return '残り$days日';
  }

  @override
  String primeNextBilling(String date) {
    return '次回のお支払い予定日  $date';
  }

  @override
  String primeEndDate(String date) {
    return '利用終了日  $date';
  }

  @override
  String get primeAutoRenew => '自動更新';

  @override
  String get primeAutoRenewOff => '更新しない';

  @override
  String get primeCancelRenew => '自動更新を解約';

  @override
  String get primeCancelConfirm => '自動更新を解約しますか？';

  @override
  String get primeCancelDetail => '残りの期間は特典がそのまま維持され、満了日に更新されません。';

  @override
  String get primeCancelDone => '自動更新を解約しました。';

  @override
  String get commonUnsubscribe => '解約';

  @override
  String get primeBenefitsSection => 'プライム特典';

  @override
  String get primeCurrentPlan => '適用中';

  @override
  String primeAlbumBenefit(int days) {
    return 'ポスト写真アルバムパス $days日';
  }

  @override
  String get primeAlbumBenefitDesc => '1日に複数の写真を自由にアップロード！';

  @override
  String primeBoostBenefit(String item, int count) {
    return '$item 1時間、$count枚';
  }

  @override
  String primeBoostSummary(String item, int count) {
    return '$item $count枚';
  }

  @override
  String get primePostBoostDesc => '自分のポストをより多くの人に表示！（1日の制限なし）';

  @override
  String get primeUnlimitedChat => '会話リクエスト無制限';

  @override
  String get primeUnlimitedChatDesc => '1日の無料回数に関係なく、会話をリクエストできます。';

  @override
  String get primeAutoRenewNotice => '※ PRIMEは選択した期間のあいだ、特典が自動更新されます。';

  @override
  String get primeSubscriptionNotice => '定期購読は同じ期間・同じ価格で自動更新され、\nいつでも解約できます。';

  @override
  String get chargeTitle => 'ルナチャージ';

  @override
  String get chargeSubtitle => 'ルナでもっと特別な体験を楽しみましょう。';

  @override
  String get chargeLunaPrefix => 'ルナ ';

  @override
  String get chargeLunaSuffix => ' 個';

  @override
  String chargeBaseBonus(int luna, int bonus) {
    return '基本$luna個 + ボーナス$bonus個';
  }

  @override
  String chargeBonusBadge(int bonus) {
    return 'ボーナス $bonus';
  }

  @override
  String get chargeBuy => '購入';

  @override
  String get chargeSecure => '安全なお支払い';

  @override
  String get chargeNotice =>
      'お支払いはストアを通じて処理され、購入したルナはすぐに付与されます。\n価格はストア連携後に表示されます。';

  @override
  String chargeDone(int total) {
    return 'ルナ$total個をチャージしました。';
  }

  @override
  String get navPost => 'ポスト';

  @override
  String get navGarden => '月光ガーデン';

  @override
  String get navChat => 'チャット';

  @override
  String get navFriend => '友だち';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get blockConfirmSuffix => 'さんをブロックしますか？';

  @override
  String get blockDescription =>
      'ブロックすると相手とのチャットが停止し、\n相手はこれ以上あなたにメッセージを送れなくなります。';

  @override
  String get blockEffectChat => 'チャットのブロック';

  @override
  String get blockEffectChatDesc => '相手とのチャットが停止し、\nこれ以上メッセージのやりとりができなくなります。';

  @override
  String get blockEffectProfile => 'プロフィールの非公開';

  @override
  String get blockEffectProfileDesc => '相手はあなたのプロフィールと投稿を\n見られなくなります。';

  @override
  String get blockAction => 'ブロックする';

  @override
  String get reportSelectReason => '通報の理由を選んでください。';

  @override
  String get reportPrivacyNotice => 'お知らせいただいた内容は、安全のため\n厳重に秘密として扱われます。';

  @override
  String get reportDetailHint => 'どのような点が問題だったか教えてください。';

  @override
  String reportWarning(String nickname) {
    return '通報すると$nicknameさんとの会話が終了し、友だち関係も解除されます。';
  }

  @override
  String get reportAction => '通報する';

  @override
  String get reportReasonIllegalAd => '違法な広告・宣伝';

  @override
  String get reportReasonRomanceScam => 'ロマンス詐欺';

  @override
  String get reportReasonSexualDeepfake => '偽造・加工された性的コンテンツ';

  @override
  String get reportReasonAbusive => '暴言・マナー違反';

  @override
  String get reportReasonCoercion => '強要・脅迫';

  @override
  String get reportReasonPrivacyLeak => '個人情報の流出';

  @override
  String get reportReasonOther => 'その他';

  @override
  String get interestGroupHobby => '趣味';

  @override
  String get interestGroupLifestyle => 'ライフスタイル';

  @override
  String get interestGroupCulture => 'カルチャー・エンタメ';

  @override
  String get interestGroupSports => 'スポーツ';

  @override
  String get interestTravel => '旅行';

  @override
  String get interestPhoto => '写真';

  @override
  String get interestArt => '絵・アート';

  @override
  String get interestReading => '読書';

  @override
  String get interestMusic => '音楽';

  @override
  String get interestMovie => '映画';

  @override
  String get interestDrama => 'ドラマ';

  @override
  String get interestGame => 'ゲーム';

  @override
  String get interestWorkout => '運動';

  @override
  String get interestCooking => '料理';

  @override
  String get interestCafe => 'カフェめぐり';

  @override
  String get interestPet => 'ペット';

  @override
  String get interestCamping => '自然・キャンプ';

  @override
  String get interestExhibition => 'ライブ・展示';

  @override
  String get interestSinging => '歌・楽器';

  @override
  String get interestSelfDev => '自己啓発';

  @override
  String get interestFinance => '資産運用';

  @override
  String get interestIt => 'IT・テクノロジー';

  @override
  String get interestFashion => 'ファッション';

  @override
  String get interestBeauty => 'ビューティー';

  @override
  String get interestWellbeing => '健康・ウェルビーイング';

  @override
  String get interestMinimal => '整理・ミニマル';

  @override
  String get interestSustainable => 'サステナビリティ';

  @override
  String get interestKpop => 'K-POP';

  @override
  String get interestJpop => 'J-POP';

  @override
  String get interestAnime => 'アニメ';

  @override
  String get interestWebtoon => 'ウェブトゥーン・漫画';

  @override
  String get interestMusical => 'ミュージカル・演劇';

  @override
  String get interestFestival => 'フェス';

  @override
  String get interestSoccer => 'サッカー';

  @override
  String get interestBaseball => '野球';

  @override
  String get interestBasketball => 'バスケットボール';

  @override
  String get interestGolf => 'ゴルフ';

  @override
  String get interestTennis => 'テニス';

  @override
  String get interestSwimming => '水泳';

  @override
  String get interestClimbing => '登山・クライミング';

  @override
  String get interestCycling => '自転車';

  @override
  String get cityKrSeoul => 'ソウル';

  @override
  String get cityKrBusan => '釜山';

  @override
  String get cityKrDaegu => '大邱';

  @override
  String get cityKrIncheon => '仁川';

  @override
  String get cityKrGwangju => '光州';

  @override
  String get cityKrDaejeon => '大田';

  @override
  String get cityKrUlsan => '蔚山';

  @override
  String get cityKrSejong => '世宗';

  @override
  String get cityKrSuwon => '水原';

  @override
  String get cityKrGoyang => '高陽';

  @override
  String get cityKrSeongnam => '城南';

  @override
  String get cityJpTokyo => '東京';

  @override
  String get cityJpOsaka => '大阪';

  @override
  String get cityJpKyoto => '京都';

  @override
  String get cityJpNagoya => '名古屋';

  @override
  String get cityJpYokohama => '横浜';

  @override
  String get cityJpFukuoka => '福岡';

  @override
  String get cityJpSapporo => '札幌';

  @override
  String get cityJpKobe => '神戸';

  @override
  String get cityJpSendai => '仙台';

  @override
  String get errorUserNotFound => 'ユーザーが見つかりません。';

  @override
  String get errorProviderDisabled => '現在この方法ではログインできません。';

  @override
  String get errorNicknameInvalid => '使用できないニックネームです。';

  @override
  String get errorNicknameDuplicate => 'すでに使われているニックネームです。';

  @override
  String get errorNicknameFormat => 'ニックネームは記号・絵文字なしの10文字以内で入力してください。';

  @override
  String get errorAgeRestricted => '18歳以上のみ登録できます。';

  @override
  String get errorPostPhotoRequired => '新しいポスト写真を登録してください。';

  @override
  String get errorPostPhotoNotFound => '写真が見つかりません。';

  @override
  String get errorPostPhotoNotMine => '自分の写真のみ削除できます。';

  @override
  String get errorPostPhotoLimit => '登録できる写真の枚数を超えました。先に既存の写真を削除してください。';

  @override
  String get errorPostReplaceLimit => '今日の写真の入れ替え回数をすべて使いました。明日またご利用ください。';

  @override
  String get errorPostReplaceFreeLimit =>
      '無料では1日2枚まで入れ替えできます。アルバムパスがあれば時間制限なしで1日20枚まで変更できます。';

  @override
  String get errorPostNotPublishedToday => '今日登録されたポストがありません。';

  @override
  String get errorGardenTargetBlocked => '今はこのユーザーにコメントを残せません。';

  @override
  String get errorTranslateQuotaExceeded => '本日の無料翻訳をすべて使いました。自動翻訳パスをご利用ください。';

  @override
  String get errorTranslateTargetRequired => '翻訳する相手を指定してください。';

  @override
  String get errorChatSelf => '自分自身には会話を申し込めません。';

  @override
  String get errorChatTargetBlocked => '今はこのユーザーに会話を申し込めません。';

  @override
  String get errorChatRequestPending => 'すでに会話を申し込んでいます。相手の返事をお待ちください。';

  @override
  String get errorChatRequestNotFound => '申し込みが見つかりません。';

  @override
  String get errorChatRequestAlreadyHandled => 'すでに処理された申し込みです。';

  @override
  String get errorChatAcceptNotReceiver => '自分が受け取った申し込みのみ承認できます。';

  @override
  String get errorChatRejectNotReceiver => '自分が受け取った申し込みのみ辞退できます。';

  @override
  String get errorRoomAlreadyActive => 'すでに進行中の会話があります。';

  @override
  String get errorChatRoomNotFound => 'チャットルームが見つかりません。';

  @override
  String get errorChatRoomClosed => '終了したチャットルームです。';

  @override
  String get errorChatNotMember => '参加中のチャットルームではありません。';

  @override
  String get errorFriendSelf => '自分自身には友だち申請を送れません。';

  @override
  String get errorFriendTargetBlocked => '今はこのユーザーに友だち申請を送れません。';

  @override
  String get errorFriendAlready => 'すでに友だちです。';

  @override
  String get errorFriendNotYet => 'まだ友だちではありません。';

  @override
  String get errorFriendNotMine => '自分の友だち関係ではありません。';

  @override
  String get errorFriendRequestPending => 'すでに友だち申請をやりとりしています。返事をお待ちください。';

  @override
  String get errorFriendRequestAlreadyAccepted => 'すでに友だちになった申請です。';

  @override
  String get errorFriendRequestNotFound => '友だち申請が見つかりません。';

  @override
  String get errorFriendAcceptNotReceiver => '自分が受け取った申請のみ承認できます。';

  @override
  String get errorFriendRejectNotReceiver => '自分が受け取った申請のみ辞退できます。';

  @override
  String get errorFriendCancelNotSender => '自分が送った申請のみ取り消せます。';

  @override
  String errorFriendLimitExceeded(int limit) {
    return '友だちは最大$limit人までです。';
  }

  @override
  String get errorFriendNoTodayPost => '友だちはまだ今日のポストを共有していません。';

  @override
  String get errorLunaInsufficient => 'ルナが足りません。';

  @override
  String get errorStoreProductNotFound => '存在しない商品です。';

  @override
  String get errorStoreProductInvalid => '商品の構成が正しくありません。';

  @override
  String get errorStoreBoostNone => '保有しているブーストがありません。';

  @override
  String get errorStoreBoostAlreadyActive => 'すでに使用中のブーストです。';

  @override
  String get errorStoreAlreadySubscribed => 'すでにPrimeを購読中です。';

  @override
  String get errorStoreNotSubscribed => '購読中ではありません。';

  @override
  String get errorStoreAlreadyCanceled => 'すでに自動更新を解約しています。';

  @override
  String get errorStoreReceiptInvalid => '決済情報を確認できません。';

  @override
  String get errorStorePurchaseFailed => '現在、決済を処理できません。';

  @override
  String get errorModerationSelf => '自分自身は対象にできません。';

  @override
  String get errorTargetBlockedOrReported => '今はこのユーザーにリクエストできません。';

  @override
  String get errorNetworkTimeout => 'サーバーの応答が遅れています。しばらくしてからもう一度お試しください。';

  @override
  String get errorNetworkUnreachable => 'サーバーに接続できません。ネットワークをご確認ください。';

  @override
  String get errorNetworkUnknown => '通信中に問題が発生しました。';

  @override
  String get errorSocketDisconnected => '接続が切れました。しばらくしてからもう一度送信してください。';

  @override
  String get errorSocketSendTimeout => 'メッセージを送信できませんでした。もう一度お試しください。';

  @override
  String get errorUnknown => 'リクエストを処理できませんでした。';

  @override
  String regionLabelFormat(String country, String city) {
    return '$country、$city';
  }

  @override
  String get voiceStop => '録音停止';

  @override
  String get voicePlay => '試聴';

  @override
  String get voiceDelete => '録音を削除';

  @override
  String get voiceSend => 'メッセージを送る';

  @override
  String get voiceRecord => '音声メッセージ';

  @override
  String get voicePermissionDenied => 'マイクの許可が必要です。設定から許可してください。';

  @override
  String get errorChatVoiceKeyRequired => '音声ファイルがアップロードされていません。';

  @override
  String get errorChatVoiceKeyInvalid => '無効な音声ファイルです。';

  @override
  String errorChatVoiceTooLong(String seconds) {
    return '音声メッセージは最大$seconds秒までです。';
  }

  @override
  String get chatRoomsVoicePreview => '音声メッセージ';
}
