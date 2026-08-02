import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('ko'),
  ];

  /// 앱 이름. 태스크 스위처와 MaterialApp title
  ///
  /// In ko, this message translates to:
  /// **'달빛톡'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// 로그인 화면 상단 문구
  ///
  /// In ko, this message translates to:
  /// **'밤에만 열리는 채팅의 시간'**
  String get loginTagline;

  /// 운영시간 안내. 시각이 바뀌면 이 문구도 함께 고칠 것
  ///
  /// In ko, this message translates to:
  /// **'오후 5시 ~ 새벽 6시'**
  String get loginHours;

  /// No description provided for @loginWithLine.
  ///
  /// In ko, this message translates to:
  /// **'LINE으로 로그인'**
  String get loginWithLine;

  /// No description provided for @loginWithKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡으로 로그인'**
  String get loginWithKakao;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 로그인'**
  String get loginWithGoogle;

  /// No description provided for @loginTermsNotice.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 서비스 이용약관 및 개인정보처리방침에 동의하게 됩니다.'**
  String get loginTermsNotice;

  /// No description provided for @nicknameTitle.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 설정'**
  String get nicknameTitle;

  /// No description provided for @nicknameSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'달빛톡에서 사용할 닉네임을 입력해주세요.'**
  String get nicknameSubtitle;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get nicknameHint;

  /// No description provided for @nicknameGuideTitle.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 가이드'**
  String get nicknameGuideTitle;

  /// No description provided for @nicknameGuideLength.
  ///
  /// In ko, this message translates to:
  /// **'2자 이상 10자 이하로 입력해주세요.'**
  String get nicknameGuideLength;

  /// No description provided for @nicknameGuideNoSpecialChars.
  ///
  /// In ko, this message translates to:
  /// **'특수문자 및 이모지는 사용할 수 없습니다.'**
  String get nicknameGuideNoSpecialChars;

  /// No description provided for @nicknameGuideNoProfanity.
  ///
  /// In ko, this message translates to:
  /// **'욕설, 혐오 표현 등 부적절한 닉네임은 사용할 수 없습니다.'**
  String get nicknameGuideNoProfanity;

  /// No description provided for @onboardingBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get onboardingNext;

  /// No description provided for @onboardingPrivateNotice.
  ///
  /// In ko, this message translates to:
  /// **'* 이 정보는 다른 사용자에게 공개되지 않습니다.'**
  String get onboardingPrivateNotice;

  /// No description provided for @birthYearTitle.
  ///
  /// In ko, this message translates to:
  /// **'출생년도 설정'**
  String get birthYearTitle;

  /// No description provided for @birthYearSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'정확한 나이 확인을 위해 출생년도를 선택해주세요.'**
  String get birthYearSubtitle;

  /// No description provided for @genderCountryTitle.
  ///
  /// In ko, this message translates to:
  /// **'성별 및 나라 설정'**
  String get genderCountryTitle;

  /// No description provided for @genderCountrySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'정확한 매칭을 위해 성별과 나라를 선택해주세요.'**
  String get genderCountrySubtitle;

  /// No description provided for @genderSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'성별 선택'**
  String get genderSectionTitle;

  /// No description provided for @genderMale.
  ///
  /// In ko, this message translates to:
  /// **'남자'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ko, this message translates to:
  /// **'여자'**
  String get genderFemale;

  /// No description provided for @countrySectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'나라 선택'**
  String get countrySectionTitle;

  /// No description provided for @countryKorea.
  ///
  /// In ko, this message translates to:
  /// **'한국'**
  String get countryKorea;

  /// No description provided for @countryJapan.
  ///
  /// In ko, this message translates to:
  /// **'일본'**
  String get countryJapan;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonEdit;

  /// No description provided for @commonEmptyValue.
  ///
  /// In ko, this message translates to:
  /// **'—'**
  String get commonEmptyValue;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 포스트'**
  String get homeTitle;

  /// No description provided for @homeTodayMoon.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 달'**
  String get homeTodayMoon;

  /// No description provided for @homeMoonCrescent.
  ///
  /// In ko, this message translates to:
  /// **'초승달'**
  String get homeMoonCrescent;

  /// No description provided for @homeUploadRemaining.
  ///
  /// In ko, this message translates to:
  /// **'포스트 등록 남은 시간'**
  String get homeUploadRemaining;

  /// No description provided for @homeLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'포스트를 불러오지 못했어요.'**
  String get homeLoadFailed;

  /// No description provided for @homePullToRefresh.
  ///
  /// In ko, this message translates to:
  /// **'아래로 당겨 새로고침해 주세요.'**
  String get homePullToRefresh;

  /// No description provided for @homeEmptyGreeting.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님'**
  String homeEmptyGreeting(String nickname);

  /// No description provided for @homeEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'달빛 아래의 지금을 포스트해 보세요.\n새로운 대화의 시작이 될 수 있어요.'**
  String get homeEmptyHint;

  /// No description provided for @homeGateClosed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 포스트를 등록할 수 있는 시간이 아니에요.'**
  String get homeGateClosed;

  /// No description provided for @homeAlbumPass.
  ///
  /// In ko, this message translates to:
  /// **'포스트 앨범 패스'**
  String get homeAlbumPass;

  /// No description provided for @homeAlbumPassRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String homeAlbumPassRemaining(int days);

  /// No description provided for @homeAlbumPassMaxPhotos.
  ///
  /// In ko, this message translates to:
  /// **'최대 {count}장 등록 가능'**
  String homeAlbumPassMaxPhotos(int count);

  /// No description provided for @homeBoost.
  ///
  /// In ko, this message translates to:
  /// **'부스트'**
  String get homeBoost;

  /// No description provided for @homeBoostActive.
  ///
  /// In ko, this message translates to:
  /// **'부스트 사용 중'**
  String get homeBoostActive;

  /// No description provided for @homeBoostStock.
  ///
  /// In ko, this message translates to:
  /// **'보유 {count}매'**
  String homeBoostStock(int count);

  /// No description provided for @homeOneLiner.
  ///
  /// In ko, this message translates to:
  /// **'하루 한 마디'**
  String get homeOneLiner;

  /// No description provided for @homeOneLinerHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 기분을 한 줄로 남겨보세요'**
  String get homeOneLinerHint;

  /// No description provided for @homeOneLinerEmpty.
  ///
  /// In ko, this message translates to:
  /// **'하루 한 마디를 입력해 주세요.'**
  String get homeOneLinerEmpty;

  /// No description provided for @homeOneLinerWrite.
  ///
  /// In ko, this message translates to:
  /// **'작성'**
  String get homeOneLinerWrite;

  /// No description provided for @homeShare.
  ///
  /// In ko, this message translates to:
  /// **'포스트 공유하기'**
  String get homeShare;

  /// No description provided for @homeShareAgain.
  ///
  /// In ko, this message translates to:
  /// **'공유됨 · 다시 공유하기'**
  String get homeShareAgain;

  /// No description provided for @homeShared.
  ///
  /// In ko, this message translates to:
  /// **'포스트를 공유했어요 🌙'**
  String get homeShared;

  /// No description provided for @commonAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get commonAll;

  /// No description provided for @commonSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get commonSend;

  /// No description provided for @commonOnline.
  ///
  /// In ko, this message translates to:
  /// **'접속 중'**
  String get commonOnline;

  /// No description provided for @ageDecade.
  ///
  /// In ko, this message translates to:
  /// **'{decade}대'**
  String ageDecade(int decade);

  /// No description provided for @gardenTitle.
  ///
  /// In ko, this message translates to:
  /// **'달빛가든'**
  String get gardenTitle;

  /// No description provided for @gardenSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'달빛 아래, 우리의 하루를 나누는 공간 ✨'**
  String get gardenSubtitle;

  /// No description provided for @gardenSpotlight.
  ///
  /// In ko, this message translates to:
  /// **'스포트라이트'**
  String get gardenSpotlight;

  /// No description provided for @gardenLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'피드를 불러오지 못했어요.'**
  String get gardenLoadFailed;

  /// No description provided for @gardenEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금은 보여줄 포스트가 없어요.'**
  String get gardenEmptyTitle;

  /// No description provided for @gardenEmptyDetail.
  ///
  /// In ko, this message translates to:
  /// **'필터를 바꾸거나 잠시 후 다시 확인해 주세요.'**
  String get gardenEmptyDetail;

  /// No description provided for @gardenGateTitle.
  ///
  /// In ko, this message translates to:
  /// **'달빛가든은 아직 문을 열지 않았어요.'**
  String get gardenGateTitle;

  /// No description provided for @gardenGateDescription.
  ///
  /// In ko, this message translates to:
  /// **'달빛이 찾아오는 오후 5시부터\n다음날 오전 6시까지 이용할 수 있어요.'**
  String get gardenGateDescription;

  /// No description provided for @gardenChatRequestTitle.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님에게 대화 신청'**
  String gardenChatRequestTitle(String nickname);

  /// No description provided for @gardenChatRequestHint.
  ///
  /// In ko, this message translates to:
  /// **'첫 인사를 남겨보세요 (최대 100자)'**
  String get gardenChatRequestHint;

  /// No description provided for @gardenChatRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'대화 신청을 보냈어요. 상대의 응답을 기다려 주세요.'**
  String get gardenChatRequestSent;

  /// No description provided for @commentsTitle.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님의 포스트'**
  String commentsTitle(String nickname);

  /// No description provided for @commentsSection.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get commentsSection;

  /// No description provided for @commentsHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 남겨보세요 (최대 25자)'**
  String get commentsHint;

  /// No description provided for @commentsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첫 댓글을 남겨보세요.'**
  String get commentsEmpty;

  /// No description provided for @commentsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 불러오지 못했어요.'**
  String get commentsLoadFailed;

  /// No description provided for @gateOpensIn.
  ///
  /// In ko, this message translates to:
  /// **'문 열리기까지'**
  String get gateOpensIn;

  /// No description provided for @gateOpensAfter.
  ///
  /// In ko, this message translates to:
  /// **'{remaining} 뒤에 열려요.'**
  String gateOpensAfter(String remaining);

  /// No description provided for @durationHourMinute.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String durationHourMinute(int hours, int minutes);

  /// No description provided for @durationMinuteSecond.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 {seconds}초'**
  String durationMinuteSecond(int minutes, int seconds);

  /// No description provided for @durationSecond.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String durationSecond(int seconds);

  /// No description provided for @chatRoomsTitle.
  ///
  /// In ko, this message translates to:
  /// **'대화방'**
  String get chatRoomsTitle;

  /// No description provided for @chatRoomsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'마음이 통하는 사람들과 이야기를 나눠보세요.'**
  String get chatRoomsSubtitle;

  /// No description provided for @chatTabMatch.
  ///
  /// In ko, this message translates to:
  /// **'매칭 대화'**
  String get chatTabMatch;

  /// No description provided for @chatTabFriend.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get chatTabFriend;

  /// No description provided for @chatTabReceived.
  ///
  /// In ko, this message translates to:
  /// **'받은 신청'**
  String get chatTabReceived;

  /// No description provided for @chatTabSent.
  ///
  /// In ko, this message translates to:
  /// **'보낸 신청'**
  String get chatTabSent;

  /// No description provided for @chatRoomsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없어요.\n달빛가든에서 마음에 드는 사람에게 말을 걸어보세요.'**
  String get chatRoomsEmpty;

  /// No description provided for @chatRoomsEmptySent.
  ///
  /// In ko, this message translates to:
  /// **'보낸 대화 신청이 없어요.'**
  String get chatRoomsEmptySent;

  /// No description provided for @chatRoomsStart.
  ///
  /// In ko, this message translates to:
  /// **'대화를 시작해보세요.'**
  String get chatRoomsStart;

  /// No description provided for @chatRoomsOngoing.
  ///
  /// In ko, this message translates to:
  /// **'대화 중'**
  String get chatRoomsOngoing;

  /// No description provided for @chatGateClosed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 매칭 대화를 나눌 수 있는 시간이 아니에요.\n친구와의 대화는 언제든 가능해요.'**
  String get chatGateClosed;

  /// No description provided for @commonAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get commonAccept;

  /// No description provided for @commonReject.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get commonReject;

  /// No description provided for @timeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 전'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 전'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String timeDaysAgo(int days);

  /// No description provided for @ageYears.
  ///
  /// In ko, this message translates to:
  /// **'{age}세'**
  String ageYears(int age);

  /// No description provided for @chatLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'대화를 불러오지 못했어요.'**
  String get chatLoadFailed;

  /// No description provided for @chatInputHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요...'**
  String get chatInputHint;

  /// No description provided for @chatMatchedNotice.
  ///
  /// In ko, this message translates to:
  /// **'매칭되었습니다. 예의 있는 멋진 대화를 나눠보세요.'**
  String get chatMatchedNotice;

  /// No description provided for @chatMenuProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 보기'**
  String get chatMenuProfile;

  /// No description provided for @chatMenuFriendRequest.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청'**
  String get chatMenuFriendRequest;

  /// No description provided for @chatMenuReport.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get chatMenuReport;

  /// No description provided for @chatMenuBlock.
  ///
  /// In ko, this message translates to:
  /// **'차단하기'**
  String get chatMenuBlock;

  /// No description provided for @chatMenuLeave.
  ///
  /// In ko, this message translates to:
  /// **'대화방 나가기'**
  String get chatMenuLeave;

  /// No description provided for @chatFriendRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청을 보냈어요. 상대가 수락하면 친구가 돼요.'**
  String get chatFriendRequestSent;

  /// No description provided for @chatReportDone.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수됐어요. 대화가 종료됩니다.'**
  String get chatReportDone;

  /// No description provided for @chatBlockDone.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님을 차단했어요.'**
  String chatBlockDone(String nickname);

  /// No description provided for @friendsTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get friendsTitle;

  /// No description provided for @friendsOnlineNowLabel.
  ///
  /// In ko, this message translates to:
  /// **'지금 접속 중 '**
  String get friendsOnlineNowLabel;

  /// No description provided for @friendsOnlineCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String friendsOnlineCount(int count);

  /// No description provided for @friendsRequestsReceived.
  ///
  /// In ko, this message translates to:
  /// **'받은 친구 요청 {count}'**
  String friendsRequestsReceived(int count);

  /// No description provided for @friendsLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'친구 목록을 불러오지 못했어요.'**
  String get friendsLoadFailed;

  /// No description provided for @friendsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 친구가 없어요.'**
  String get friendsEmpty;

  /// No description provided for @friendsEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'대화를 나눈 상대에게 채팅창 메뉴에서 친구 요청을 보내보세요.'**
  String get friendsEmptyHint;

  /// No description provided for @friendsAccepted.
  ///
  /// In ko, this message translates to:
  /// **'친구가 되었어요. 이제 언제든 대화할 수 있어요.'**
  String get friendsAccepted;

  /// No description provided for @friendsRejected.
  ///
  /// In ko, this message translates to:
  /// **'요청을 거절했어요.'**
  String get friendsRejected;

  /// No description provided for @friendsRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청을 보냈어요.'**
  String get friendsRequestSent;

  /// No description provided for @friendsRoomNotFound.
  ///
  /// In ko, this message translates to:
  /// **'대화방을 찾을 수 없어요. 새로고침해 주세요.'**
  String get friendsRoomNotFound;

  /// No description provided for @friendsDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님을 친구에서 삭제할까요?'**
  String friendsDeleteConfirm(String nickname);

  /// No description provided for @friendsDeleteDetail.
  ///
  /// In ko, this message translates to:
  /// **'상시 대화방도 함께 종료돼요.'**
  String get friendsDeleteDetail;

  /// No description provided for @filterAge.
  ///
  /// In ko, this message translates to:
  /// **'나이'**
  String get filterAge;

  /// No description provided for @filterCountry.
  ///
  /// In ko, this message translates to:
  /// **'국가'**
  String get filterCountry;

  /// No description provided for @statusOnline.
  ///
  /// In ko, this message translates to:
  /// **'온라인'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In ko, this message translates to:
  /// **'오프라인'**
  String get statusOffline;

  /// No description provided for @friendPostTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 포스트'**
  String get friendPostTitle;

  /// No description provided for @friendPostLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'포스트를 불러오지 못했어요.'**
  String get friendPostLoadFailed;

  /// No description provided for @friendPostMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get friendPostMessage;

  /// No description provided for @friendPostSendMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 보내기'**
  String get friendPostSendMessage;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profileTitle;

  /// No description provided for @profilePhotoPrompt.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 등록해 주세요'**
  String get profilePhotoPrompt;

  /// No description provided for @profileLunaBalance.
  ///
  /// In ko, this message translates to:
  /// **'보유 루나'**
  String get profileLunaBalance;

  /// No description provided for @profileLunaStore.
  ///
  /// In ko, this message translates to:
  /// **'루나상점'**
  String get profileLunaStore;

  /// No description provided for @profilePrimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'프라임으로 더 특별하게 ✨'**
  String get profilePrimeTitle;

  /// No description provided for @profilePrimeBenefits.
  ///
  /// In ko, this message translates to:
  /// **'포스트 8장·부스트·무제한 대화·자동 번역'**
  String get profilePrimeBenefits;

  /// No description provided for @profileSeeDetail.
  ///
  /// In ko, this message translates to:
  /// **'자세히 보기'**
  String get profileSeeDetail;

  /// No description provided for @profileBoostPost.
  ///
  /// In ko, this message translates to:
  /// **'포스트 부스트'**
  String get profileBoostPost;

  /// No description provided for @profileBoostMatch.
  ///
  /// In ko, this message translates to:
  /// **'매칭 부스트'**
  String get profileBoostMatch;

  /// No description provided for @profileBoostCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}매'**
  String profileBoostCount(int count);

  /// No description provided for @profileSpotlight.
  ///
  /// In ko, this message translates to:
  /// **'스포트라이트'**
  String get profileSpotlight;

  /// No description provided for @profileFreeUpload.
  ///
  /// In ko, this message translates to:
  /// **'무료 업로드'**
  String get profileFreeUpload;

  /// No description provided for @profileNoAds.
  ///
  /// In ko, this message translates to:
  /// **'광고 제거'**
  String get profileNoAds;

  /// No description provided for @profileVisitors.
  ///
  /// In ko, this message translates to:
  /// **'방문자 확인'**
  String get profileVisitors;

  /// No description provided for @profileIntro.
  ///
  /// In ko, this message translates to:
  /// **'소개 한마디'**
  String get profileIntro;

  /// No description provided for @profileIntroEmpty.
  ///
  /// In ko, this message translates to:
  /// **'나를 소개하는 한마디를 남겨보세요. (최대 50자)'**
  String get profileIntroEmpty;

  /// No description provided for @profileInterests.
  ///
  /// In ko, this message translates to:
  /// **'관심사'**
  String get profileInterests;

  /// No description provided for @profileInterestsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'관심사를 등록하면 더 잘 맞는 사람을 만날 수 있어요.'**
  String get profileInterestsEmpty;

  /// No description provided for @profileRegions.
  ///
  /// In ko, this message translates to:
  /// **'활동 지역'**
  String get profileRegions;

  /// No description provided for @profileRegionsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'활동 지역은 최대 2곳까지 선택할 수 있어요.'**
  String get profileRegionsEmpty;

  /// No description provided for @profileLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get profileLogout;

  /// No description provided for @introEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'소개 한마디'**
  String get introEditTitle;

  /// No description provided for @introEditHint.
  ///
  /// In ko, this message translates to:
  /// **'자신의 취미, 성격, 또는\n하고 싶은 말을 자유롭게 적어보세요.'**
  String get introEditHint;

  /// No description provided for @introEditCounter.
  ///
  /// In ko, this message translates to:
  /// **'최대 50자까지 가능합니다.'**
  String get introEditCounter;

  /// No description provided for @interestsEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'관심사 등록'**
  String get interestsEditTitle;

  /// No description provided for @interestsEditSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'요즘 어떤 것에 꽂혀 계시나요? 취향을 공유해 보세요!'**
  String get interestsEditSubtitle;

  /// No description provided for @interestsEditSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택된 관심사 ({count}/{max})'**
  String interestsEditSelected(int count, int max);

  /// No description provided for @interestsEditEmpty.
  ///
  /// In ko, this message translates to:
  /// **'관심사를 선택해 주세요.'**
  String get interestsEditEmpty;

  /// No description provided for @interestsEditReset.
  ///
  /// In ko, this message translates to:
  /// **'전체 초기화'**
  String get interestsEditReset;

  /// No description provided for @interestsEditSave.
  ///
  /// In ko, this message translates to:
  /// **'저장하기 ({count}/{max})'**
  String interestsEditSave(int count, int max);

  /// No description provided for @interestsEditLimit.
  ///
  /// In ko, this message translates to:
  /// **'관심사는 최대 {max}개까지 선택할 수 있어요.'**
  String interestsEditLimit(int max);

  /// No description provided for @regionsEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'지역 선택'**
  String get regionsEditTitle;

  /// No description provided for @regionsEditSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'국가와 지역을 선택해주세요. (최대 {max}곳)'**
  String regionsEditSubtitle(int max);

  /// No description provided for @regionsEditOfCountry.
  ///
  /// In ko, this message translates to:
  /// **'의 주요 지역'**
  String get regionsEditOfCountry;

  /// No description provided for @regionsEditSelected.
  ///
  /// In ko, this message translates to:
  /// **'선택한 지역'**
  String get regionsEditSelected;

  /// No description provided for @regionsEditApply.
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get regionsEditApply;

  /// No description provided for @regionsEditLimit.
  ///
  /// In ko, this message translates to:
  /// **'활동 지역은 최대 {max}곳까지 선택할 수 있어요.'**
  String regionsEditLimit(int max);

  /// No description provided for @commonNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get commonNone;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return L10nJa();
    case 'ko':
      return L10nKo();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
