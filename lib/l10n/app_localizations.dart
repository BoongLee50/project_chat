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

  /// 달빛가든에 노출되는 대표 사진임을 알리는 배지
  ///
  /// In ko, this message translates to:
  /// **'메인'**
  String get homeMainPhoto;

  /// 보고 있는 사진을 대표 사진으로 지정하는 버튼
  ///
  /// In ko, this message translates to:
  /// **'메인으로'**
  String get homeSetMainPhoto;

  /// No description provided for @homeMainPhotoSet.
  ///
  /// In ko, this message translates to:
  /// **'메인 사진으로 지정했어요.'**
  String get homeMainPhotoSet;

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

  /// No description provided for @homeShare.
  ///
  /// In ko, this message translates to:
  /// **'포스트 공유하기'**
  String get homeShare;

  /// No description provided for @homeShareAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 공유'**
  String get homeShareAgain;

  /// No description provided for @homeShared.
  ///
  /// In ko, this message translates to:
  /// **'포스트를 공유했어요 🌙'**
  String get homeShared;

  /// No description provided for @homeBuy.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get homeBuy;

  /// No description provided for @homeBoostReady.
  ///
  /// In ko, this message translates to:
  /// **'가능'**
  String get homeBoostReady;

  /// No description provided for @homeBoostRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String homeBoostRemaining(int minutes);

  /// No description provided for @homePassRemainingDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String homePassRemainingDays(int days);

  /// No description provided for @homePick.
  ///
  /// In ko, this message translates to:
  /// **'PICK'**
  String get homePick;

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

  /// No description provided for @gardenPhotoLockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 {count}장이 더 있어요'**
  String gardenPhotoLockedTitle(int count);

  /// No description provided for @gardenPhotoLockedBody.
  ///
  /// In ko, this message translates to:
  /// **'오늘 내 포스트를 공유하면 상대의 사진을 모두 볼 수 있어요.'**
  String get gardenPhotoLockedBody;

  /// No description provided for @gardenPhotoLockedAction.
  ///
  /// In ko, this message translates to:
  /// **'내 포스트 등록하기'**
  String get gardenPhotoLockedAction;

  /// No description provided for @dailyTitle.
  ///
  /// In ko, this message translates to:
  /// **'달빛 한마디'**
  String get dailyTitle;

  /// No description provided for @dailyMissionNotice.
  ///
  /// In ko, this message translates to:
  /// **'매일 저녁 6시에 새로운 미션이 열려요 ✨'**
  String get dailyMissionNotice;

  /// No description provided for @dailyTodayQuestion.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 질문'**
  String get dailyTodayQuestion;

  /// No description provided for @dailyParticipants.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}명이 참여했어요'**
  String dailyParticipants(int count);

  /// No description provided for @dailyRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 시간'**
  String get dailyRemaining;

  /// No description provided for @dailyJoin.
  ///
  /// In ko, this message translates to:
  /// **'참여하기'**
  String get dailyJoin;

  /// No description provided for @dailySortLatest.
  ///
  /// In ko, this message translates to:
  /// **'최신순'**
  String get dailySortLatest;

  /// No description provided for @dailySortPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기순'**
  String get dailySortPopular;

  /// No description provided for @dailyMine.
  ///
  /// In ko, this message translates to:
  /// **'내 한마디'**
  String get dailyMine;

  /// No description provided for @dailyMineEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 작성한 내 한마디가 없어요. 오늘의 질문에 답해 보세요.'**
  String get dailyMineEmpty;

  /// No description provided for @dailyWriteTitle.
  ///
  /// In ko, this message translates to:
  /// **'달빛 한마디 작성'**
  String get dailyWriteTitle;

  /// No description provided for @dailyWriteHint.
  ///
  /// In ko, this message translates to:
  /// **'여기에 당신의 한마디를 입력해주세요...'**
  String get dailyWriteHint;

  /// No description provided for @dailyWriteImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지 추가 (선택)'**
  String get dailyWriteImage;

  /// No description provided for @dailyWriteSubmit.
  ///
  /// In ko, this message translates to:
  /// **'등록하기'**
  String get dailyWriteSubmit;

  /// No description provided for @dailyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 한마디가 없어요. 첫 번째로 답해 보세요.'**
  String get dailyEmpty;

  /// No description provided for @dailyLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'달빛 한마디를 불러오지 못했어요.'**
  String get dailyLoadFailed;

  /// No description provided for @dailyDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 달빛 한마디'**
  String get dailyDetailTitle;

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
  /// **'댓글을 남겨보세요 (최대 50자)'**
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

  /// No description provided for @commentsReply.
  ///
  /// In ko, this message translates to:
  /// **'답글'**
  String get commentsReply;

  /// No description provided for @commentsReplyingTo.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 답글 남기는 중'**
  String commentsReplyingTo(String name);

  /// No description provided for @commentsCancelReply.
  ///
  /// In ko, this message translates to:
  /// **'답글 취소'**
  String get commentsCancelReply;

  /// No description provided for @commentsAttachImage.
  ///
  /// In ko, this message translates to:
  /// **'사진 첨부'**
  String get commentsAttachImage;

  /// No description provided for @commentsImageAttached.
  ///
  /// In ko, this message translates to:
  /// **'사진 1장 첨부됨'**
  String get commentsImageAttached;

  /// No description provided for @commentsRemoveImage.
  ///
  /// In ko, this message translates to:
  /// **'첨부 사진 삭제'**
  String get commentsRemoveImage;

  /// No description provided for @commentsImageViewer.
  ///
  /// In ko, this message translates to:
  /// **'첨부 사진'**
  String get commentsImageViewer;

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

  /// No description provided for @chatRoomsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없어요.\n달빛가든에서 마음에 드는 사람에게 말을 걸어보세요.'**
  String get chatRoomsEmpty;

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

  /// No description provided for @photoSheetProfileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 변경'**
  String get photoSheetProfileTitle;

  /// No description provided for @photoSheetProfileSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'멋진 사진으로 프로필을 업데이트하고\n더 많은 매치를 만나보세요!'**
  String get photoSheetProfileSubtitle;

  /// No description provided for @photoSheetPostTitle.
  ///
  /// In ko, this message translates to:
  /// **'포스트 사진 등록'**
  String get photoSheetPostTitle;

  /// No description provided for @photoSheetPostSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘 밤의 순간을 남겨보세요.'**
  String get photoSheetPostSubtitle;

  /// No description provided for @photoSourceGallery.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 선택'**
  String get photoSourceGallery;

  /// No description provided for @photoSourceCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라 촬영'**
  String get photoSourceCamera;

  /// No description provided for @photoSourceRemove.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 제거'**
  String get photoSourceRemove;

  /// No description provided for @photoSourceGalleryPassOnly.
  ///
  /// In ko, this message translates to:
  /// **'앨범 패스가 있어야 이용할 수 있어요'**
  String get photoSourceGalleryPassOnly;

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
  /// **'포스트 9장·부스트·무제한 대화·자동 번역'**
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

  /// No description provided for @storeKindPostBoost.
  ///
  /// In ko, this message translates to:
  /// **'포스트 부스트'**
  String get storeKindPostBoost;

  /// No description provided for @storeKindAlbumPass.
  ///
  /// In ko, this message translates to:
  /// **'포스트 앨범 패스'**
  String get storeKindAlbumPass;

  /// No description provided for @storeKindTranslatePass.
  ///
  /// In ko, this message translates to:
  /// **'자동 번역 패스'**
  String get storeKindTranslatePass;

  /// No description provided for @storeDescPostBoost.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람보다 우선적으로 포스트 사진을 추천해드려요!'**
  String get storeDescPostBoost;

  /// No description provided for @storeDescAlbumPass.
  ///
  /// In ko, this message translates to:
  /// **'여러 장의 사진을 자유롭게 업로드! 시간 제한 없이, 카메라와 갤러리 사진 모두 사용할 수 있어요.'**
  String get storeDescAlbumPass;

  /// No description provided for @storeDescTranslatePass.
  ///
  /// In ko, this message translates to:
  /// **'모든 메시지를 자동으로 번역해 언어 장벽 없이 소통!'**
  String get storeDescTranslatePass;

  /// No description provided for @storeOptionBoost.
  ///
  /// In ko, this message translates to:
  /// **'1시간, {quantity}매'**
  String storeOptionBoost(int quantity);

  /// No description provided for @storeOptionDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String storeOptionDays(int days);

  /// No description provided for @lunaStoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'루나상점'**
  String get lunaStoreTitle;

  /// No description provided for @lunaStoreSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'루나로 더 특별한 경험을 만들어보세요.'**
  String get lunaStoreSubtitle;

  /// No description provided for @storeLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'상품을 불러오지 못했어요.'**
  String get storeLoadFailed;

  /// No description provided for @storeBuy.
  ///
  /// In ko, this message translates to:
  /// **'구매하기'**
  String get storeBuy;

  /// No description provided for @storeDetail.
  ///
  /// In ko, this message translates to:
  /// **'자세히'**
  String get storeDetail;

  /// No description provided for @storeDiscount.
  ///
  /// In ko, this message translates to:
  /// **'{percent}% 할인'**
  String storeDiscount(int percent);

  /// No description provided for @storePurchased.
  ///
  /// In ko, this message translates to:
  /// **'{item} {option} 구매 완료!'**
  String storePurchased(String item, String option);

  /// No description provided for @storeLunaBalance.
  ///
  /// In ko, this message translates to:
  /// **'보유 루나'**
  String get storeLunaBalance;

  /// No description provided for @storeCharge.
  ///
  /// In ko, this message translates to:
  /// **'충전하기'**
  String get storeCharge;

  /// No description provided for @boostOwnedTitle.
  ///
  /// In ko, this message translates to:
  /// **'보유 {item}'**
  String boostOwnedTitle(String item);

  /// No description provided for @boostItemHour.
  ///
  /// In ko, this message translates to:
  /// **'{item} (1시간)'**
  String boostItemHour(String item);

  /// No description provided for @boostStock.
  ///
  /// In ko, this message translates to:
  /// **'보유 {count}매'**
  String boostStock(int count);

  /// No description provided for @boostActiveRemaining.
  ///
  /// In ko, this message translates to:
  /// **'사용 중 — {remaining} 남음'**
  String boostActiveRemaining(String remaining);

  /// No description provided for @boostRemainHourMinute.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {minutes}분'**
  String boostRemainHourMinute(int hours, int minutes);

  /// No description provided for @boostRemainMinute.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분'**
  String boostRemainMinute(int minutes);

  /// No description provided for @boostRemainUnderMinute.
  ///
  /// In ko, this message translates to:
  /// **'1분 미만'**
  String get boostRemainUnderMinute;

  /// No description provided for @boostEffectTitle.
  ///
  /// In ko, this message translates to:
  /// **'예상 효과'**
  String get boostEffectTitle;

  /// No description provided for @boostEffectExposure.
  ///
  /// In ko, this message translates to:
  /// **'최대 노출 증가'**
  String get boostEffectExposure;

  /// No description provided for @boostEffectExposureValue.
  ///
  /// In ko, this message translates to:
  /// **'약 3배'**
  String get boostEffectExposureValue;

  /// No description provided for @boostEffectExposureDetail.
  ///
  /// In ko, this message translates to:
  /// **'더 많은 사용자에게 노출돼요'**
  String get boostEffectExposureDetail;

  /// No description provided for @boostEffectVisit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 방문 증가'**
  String get boostEffectVisit;

  /// No description provided for @boostEffectVisitValue.
  ///
  /// In ko, this message translates to:
  /// **'약 2.5배'**
  String get boostEffectVisitValue;

  /// No description provided for @boostEffectVisitDetail.
  ///
  /// In ko, this message translates to:
  /// **'프로필 방문 및 유입이 늘어나요'**
  String get boostEffectVisitDetail;

  /// No description provided for @boostEffectLike.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 증가'**
  String get boostEffectLike;

  /// No description provided for @boostEffectLikeValue.
  ///
  /// In ko, this message translates to:
  /// **'약 2배'**
  String get boostEffectLikeValue;

  /// No description provided for @boostEffectLikeDetail.
  ///
  /// In ko, this message translates to:
  /// **'좋아요와 관심을 더 많이 받아요'**
  String get boostEffectLikeDetail;

  /// No description provided for @boostHourHighlight.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get boostHourHighlight;

  /// No description provided for @boostHourSuffix.
  ///
  /// In ko, this message translates to:
  /// **' 동안 추천 우선순위가 올라가\n더 많은 사용자에게 노출돼요!'**
  String get boostHourSuffix;

  /// No description provided for @boostUse.
  ///
  /// In ko, this message translates to:
  /// **'부스트 사용하기 (1매)'**
  String get boostUse;

  /// No description provided for @boostInUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중이에요'**
  String get boostInUse;

  /// No description provided for @boostNoneShort.
  ///
  /// In ko, this message translates to:
  /// **'보유한 부스트가 없어요'**
  String get boostNoneShort;

  /// No description provided for @boostNone.
  ///
  /// In ko, this message translates to:
  /// **'보유한 부스트가 없어요.'**
  String get boostNone;

  /// No description provided for @boostBuyHint.
  ///
  /// In ko, this message translates to:
  /// **'루나상점에서 부스트를 구매할 수 있어요.'**
  String get boostBuyHint;

  /// No description provided for @boostGoStore.
  ///
  /// In ko, this message translates to:
  /// **'루나상점 가기'**
  String get boostGoStore;

  /// No description provided for @boostUsed.
  ///
  /// In ko, this message translates to:
  /// **'부스트를 사용했어요. 1시간 동안 우선 노출됩니다!'**
  String get boostUsed;

  /// No description provided for @passBuy.
  ///
  /// In ko, this message translates to:
  /// **'{item} 구매'**
  String passBuy(String item);

  /// No description provided for @passExtend.
  ///
  /// In ko, this message translates to:
  /// **'{item} 연장'**
  String passExtend(String item);

  /// No description provided for @passPurchased.
  ///
  /// In ko, this message translates to:
  /// **'{item} {days}일 구매 완료!'**
  String passPurchased(String item, int days);

  /// No description provided for @passPeriodSection.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get passPeriodSection;

  /// No description provided for @passDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String passDays(int days);

  /// No description provided for @passDaysPass.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 패스'**
  String passDaysPass(int days);

  /// No description provided for @passPriceLuna.
  ///
  /// In ko, this message translates to:
  /// **'{price} 루나'**
  String passPriceLuna(int price);

  /// No description provided for @passAmount.
  ///
  /// In ko, this message translates to:
  /// **'구매 금액'**
  String get passAmount;

  /// No description provided for @passUsageInfo.
  ///
  /// In ko, this message translates to:
  /// **'이용 정보'**
  String get passUsageInfo;

  /// No description provided for @passStatus.
  ///
  /// In ko, this message translates to:
  /// **'보유 상태'**
  String get passStatus;

  /// No description provided for @passStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'이용 중'**
  String get passStatusActive;

  /// No description provided for @passStatusNone.
  ///
  /// In ko, this message translates to:
  /// **'미보유'**
  String get passStatusNone;

  /// No description provided for @passStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'구매 대기'**
  String get passStatusPending;

  /// No description provided for @passRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 기간'**
  String get passRemaining;

  /// No description provided for @passValidUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지'**
  String passValidUntil(String date);

  /// No description provided for @passValidPeriod.
  ///
  /// In ko, this message translates to:
  /// **'유효 기간'**
  String get passValidPeriod;

  /// No description provided for @passExtendNotice.
  ///
  /// In ko, this message translates to:
  /// **'이미 이용 중이에요. 지금 구매하면 남은 기간에 이어서 연장됩니다.'**
  String get passExtendNotice;

  /// No description provided for @passAlbumHeadline.
  ///
  /// In ko, this message translates to:
  /// **'더 많은 포스트 사진을 등록하고 다양한 매력을 보여주세요!'**
  String get passAlbumHeadline;

  /// No description provided for @passAlbumBenefit1.
  ///
  /// In ko, this message translates to:
  /// **'포스트 사진 최대 9장까지 등록'**
  String get passAlbumBenefit1;

  /// No description provided for @passAlbumBenefit1Desc.
  ///
  /// In ko, this message translates to:
  /// **'기본 2장에서 최대 9장까지 여러 장의 사진을 등록할 수 있어요.'**
  String get passAlbumBenefit1Desc;

  /// No description provided for @passAlbumBenefit2.
  ///
  /// In ko, this message translates to:
  /// **'등록 시간 제한 없음 (24시간 자유롭게)'**
  String get passAlbumBenefit2;

  /// No description provided for @passAlbumBenefit2Desc.
  ///
  /// In ko, this message translates to:
  /// **'시간 제약 없이 언제든지 자유롭게 포스트를 등록할 수 있어요.'**
  String get passAlbumBenefit2Desc;

  /// No description provided for @passAlbumBenefit3.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 갤러리 사진까지 업로드 가능'**
  String get passAlbumBenefit3;

  /// No description provided for @passAlbumBenefit3Desc.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 찍은 사진뿐만 아니라 갤러리 사진도 올릴 수 있어요.'**
  String get passAlbumBenefit3Desc;

  /// No description provided for @passTranslateHeadline.
  ///
  /// In ko, this message translates to:
  /// **'언어의 장벽 없이 더 많은 사람과 대화해보세요!'**
  String get passTranslateHeadline;

  /// No description provided for @passTranslateBenefit1.
  ///
  /// In ko, this message translates to:
  /// **'채팅 자동 번역 무제한'**
  String get passTranslateBenefit1;

  /// No description provided for @passTranslateBenefit1Desc.
  ///
  /// In ko, this message translates to:
  /// **'상대방의 메시지를 자동으로 번역해 실시간으로 소통할 수 있어요.'**
  String get passTranslateBenefit1Desc;

  /// No description provided for @passTranslateBenefit2.
  ///
  /// In ko, this message translates to:
  /// **'댓글 자동 번역 무제한'**
  String get passTranslateBenefit2;

  /// No description provided for @passTranslateBenefit2Desc.
  ///
  /// In ko, this message translates to:
  /// **'달빛가든과 포스트의 댓글을 자동으로 번역해줘요.'**
  String get passTranslateBenefit2Desc;

  /// No description provided for @passTranslateBenefit3.
  ///
  /// In ko, this message translates to:
  /// **'프로필 자동 번역 무제한'**
  String get passTranslateBenefit3;

  /// No description provided for @passTranslateBenefit3Desc.
  ///
  /// In ko, this message translates to:
  /// **'상대방의 프로필 정보와 하루 한마디를 자동으로 번역해줘요.'**
  String get passTranslateBenefit3Desc;

  /// No description provided for @primeTitle.
  ///
  /// In ko, this message translates to:
  /// **'PRIME 멤버십'**
  String get primeTitle;

  /// No description provided for @primeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'PRIME으로 더 특별한 경험을 즐겨보세요.'**
  String get primeSubtitle;

  /// No description provided for @primeHeadline.
  ///
  /// In ko, this message translates to:
  /// **'달빛톡을 완벽하게 즐기는 방법'**
  String get primeHeadline;

  /// No description provided for @primeHeadlineDetail.
  ///
  /// In ko, this message translates to:
  /// **'모든 기능을 제한 없이!'**
  String get primeHeadlineDetail;

  /// No description provided for @primePlanSection.
  ///
  /// In ko, this message translates to:
  /// **'요금제 선택하기'**
  String get primePlanSection;

  /// No description provided for @primeMonths.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월'**
  String primeMonths(int months);

  /// No description provided for @primeBestValue.
  ///
  /// In ko, this message translates to:
  /// **'가성비 끝판왕'**
  String get primeBestValue;

  /// No description provided for @primeStorePrice.
  ///
  /// In ko, this message translates to:
  /// **'스토어 가격'**
  String get primeStorePrice;

  /// No description provided for @primePay.
  ///
  /// In ko, this message translates to:
  /// **'결제하기'**
  String get primePay;

  /// No description provided for @primeStarted.
  ///
  /// In ko, this message translates to:
  /// **'PRIME 멤버십이 시작됐어요!'**
  String get primeStarted;

  /// No description provided for @primeActive.
  ///
  /// In ko, this message translates to:
  /// **'PRIME 이용 중'**
  String get primeActive;

  /// No description provided for @primeActiveMonths.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월 이용 중'**
  String primeActiveMonths(int months);

  /// No description provided for @primeRemainingDays.
  ///
  /// In ko, this message translates to:
  /// **'남은 기간 {days}일'**
  String primeRemainingDays(int days);

  /// No description provided for @primeNextBilling.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제 예정일  {date}'**
  String primeNextBilling(String date);

  /// No description provided for @primeEndDate.
  ///
  /// In ko, this message translates to:
  /// **'이용 종료일  {date}'**
  String primeEndDate(String date);

  /// No description provided for @primeAutoRenew.
  ///
  /// In ko, this message translates to:
  /// **'자동 갱신'**
  String get primeAutoRenew;

  /// No description provided for @primeAutoRenewOff.
  ///
  /// In ko, this message translates to:
  /// **'갱신 안 함'**
  String get primeAutoRenewOff;

  /// No description provided for @primeCancelRenew.
  ///
  /// In ko, this message translates to:
  /// **'자동 갱신 해지'**
  String get primeCancelRenew;

  /// No description provided for @primeCancelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'자동 갱신을 해지할까요?'**
  String get primeCancelConfirm;

  /// No description provided for @primeCancelDetail.
  ///
  /// In ko, this message translates to:
  /// **'남은 기간 동안은 혜택이 그대로 유지되고, 만료일에 갱신되지 않아요.'**
  String get primeCancelDetail;

  /// No description provided for @primeCancelDone.
  ///
  /// In ko, this message translates to:
  /// **'자동 갱신을 해지했어요.'**
  String get primeCancelDone;

  /// No description provided for @commonUnsubscribe.
  ///
  /// In ko, this message translates to:
  /// **'해지'**
  String get commonUnsubscribe;

  /// No description provided for @primeBenefitsSection.
  ///
  /// In ko, this message translates to:
  /// **'프라임 혜택'**
  String get primeBenefitsSection;

  /// No description provided for @primeCurrentPlan.
  ///
  /// In ko, this message translates to:
  /// **'현재 적용 중'**
  String get primeCurrentPlan;

  /// No description provided for @primeAlbumBenefit.
  ///
  /// In ko, this message translates to:
  /// **'포스트 사진 앨범 패스 {days}일'**
  String primeAlbumBenefit(int days);

  /// No description provided for @primeAlbumBenefitDesc.
  ///
  /// In ko, this message translates to:
  /// **'하루에 여러 장의 사진을 자유롭게 업로드!'**
  String get primeAlbumBenefitDesc;

  /// No description provided for @primeBoostBenefit.
  ///
  /// In ko, this message translates to:
  /// **'{item} 1시간, {count}매'**
  String primeBoostBenefit(String item, int count);

  /// No description provided for @primeBoostSummary.
  ///
  /// In ko, this message translates to:
  /// **'{item} {count}매'**
  String primeBoostSummary(String item, int count);

  /// No description provided for @primePostBoostDesc.
  ///
  /// In ko, this message translates to:
  /// **'내 포스트를 더 많은 사람에게 노출! (일일제한 없음)'**
  String get primePostBoostDesc;

  /// No description provided for @primeUnlimitedChat.
  ///
  /// In ko, this message translates to:
  /// **'대화 신청 무제한'**
  String get primeUnlimitedChat;

  /// No description provided for @primeUnlimitedChatDesc.
  ///
  /// In ko, this message translates to:
  /// **'하루 무료 횟수에 관계없이 대화를 신청할 수 있어요.'**
  String get primeUnlimitedChatDesc;

  /// No description provided for @primeAutoRenewNotice.
  ///
  /// In ko, this message translates to:
  /// **'* PRIME은 선택하신 기간 동안 혜택이 자동 갱신됩니다.'**
  String get primeAutoRenewNotice;

  /// No description provided for @primeSubscriptionNotice.
  ///
  /// In ko, this message translates to:
  /// **'구독 서비스는 동일한 기간, 동일한 가격으로 자동 갱신되며,\n언제든 구독을 해지할 수 있습니다.'**
  String get primeSubscriptionNotice;

  /// No description provided for @chargeTitle.
  ///
  /// In ko, this message translates to:
  /// **'루나 충전'**
  String get chargeTitle;

  /// No description provided for @chargeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'루나로 더 특별한 경험을 즐겨보세요.'**
  String get chargeSubtitle;

  /// No description provided for @chargeLunaPrefix.
  ///
  /// In ko, this message translates to:
  /// **'루나 '**
  String get chargeLunaPrefix;

  /// No description provided for @chargeLunaSuffix.
  ///
  /// In ko, this message translates to:
  /// **' 개'**
  String get chargeLunaSuffix;

  /// No description provided for @chargeBaseBonus.
  ///
  /// In ko, this message translates to:
  /// **'기본 {luna}개 + 보너스 {bonus}개'**
  String chargeBaseBonus(int luna, int bonus);

  /// No description provided for @chargeBonusBadge.
  ///
  /// In ko, this message translates to:
  /// **'보너스 {bonus}'**
  String chargeBonusBadge(int bonus);

  /// No description provided for @chargeBuy.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get chargeBuy;

  /// No description provided for @chargeSecure.
  ///
  /// In ko, this message translates to:
  /// **'안전한 결제'**
  String get chargeSecure;

  /// No description provided for @chargeNotice.
  ///
  /// In ko, this message translates to:
  /// **'결제는 스토어를 통해 처리되며, 구매한 루나는 즉시 지급됩니다.\n가격은 스토어 연동 후 표시됩니다.'**
  String get chargeNotice;

  /// No description provided for @chargeDone.
  ///
  /// In ko, this message translates to:
  /// **'루나 {total}개가 충전됐어요.'**
  String chargeDone(int total);

  /// No description provided for @navPost.
  ///
  /// In ko, this message translates to:
  /// **'포스트'**
  String get navPost;

  /// No description provided for @navGarden.
  ///
  /// In ko, this message translates to:
  /// **'달빛가든'**
  String get navGarden;

  /// No description provided for @navChat.
  ///
  /// In ko, this message translates to:
  /// **'대화방'**
  String get navChat;

  /// No description provided for @navFriend.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get navFriend;

  /// No description provided for @navProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get navProfile;

  /// No description provided for @blockConfirmSuffix.
  ///
  /// In ko, this message translates to:
  /// **'님을 차단하시겠습니까?'**
  String get blockConfirmSuffix;

  /// No description provided for @blockDescription.
  ///
  /// In ko, this message translates to:
  /// **'차단하면 상대방과의 채팅이 중단되고,\n상대방은 더 이상 나에게 메시지를 보낼 수 없습니다.'**
  String get blockDescription;

  /// No description provided for @blockEffectChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅 차단'**
  String get blockEffectChat;

  /// No description provided for @blockEffectChatDesc.
  ///
  /// In ko, this message translates to:
  /// **'상대방과의 채팅이 중단되며,\n더 이상 메시지를 주고받을 수 없습니다.'**
  String get blockEffectChatDesc;

  /// No description provided for @blockEffectProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 비공개'**
  String get blockEffectProfile;

  /// No description provided for @blockEffectProfileDesc.
  ///
  /// In ko, this message translates to:
  /// **'상대방이 내 프로필과 소식을\n볼 수 없게 됩니다.'**
  String get blockEffectProfileDesc;

  /// No description provided for @blockAction.
  ///
  /// In ko, this message translates to:
  /// **'차단하기'**
  String get blockAction;

  /// No description provided for @reportSelectReason.
  ///
  /// In ko, this message translates to:
  /// **'신고 이유를 선택해주세요.'**
  String get reportSelectReason;

  /// No description provided for @reportPrivacyNotice.
  ///
  /// In ko, this message translates to:
  /// **'공유해 주신 내용은 안전을 위해\n철저히 비밀로 유지됩니다.'**
  String get reportPrivacyNotice;

  /// No description provided for @reportDetailHint.
  ///
  /// In ko, this message translates to:
  /// **'어떤 점이 문제였는지 알려주세요.'**
  String get reportDetailHint;

  /// No description provided for @reportWarning.
  ///
  /// In ko, this message translates to:
  /// **'신고하면 {nickname}님과의 대화가 종료되고 친구 관계도 해제돼요.'**
  String reportWarning(String nickname);

  /// No description provided for @reportAction.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportAction;

  /// No description provided for @reportReasonIllegalAd.
  ///
  /// In ko, this message translates to:
  /// **'불법 광고 및 홍보'**
  String get reportReasonIllegalAd;

  /// No description provided for @reportReasonRomanceScam.
  ///
  /// In ko, this message translates to:
  /// **'로맨스 스캠 (연애 사기)'**
  String get reportReasonRomanceScam;

  /// No description provided for @reportReasonSexualDeepfake.
  ///
  /// In ko, this message translates to:
  /// **'허위 합성/편집한 성인물'**
  String get reportReasonSexualDeepfake;

  /// No description provided for @reportReasonAbusive.
  ///
  /// In ko, this message translates to:
  /// **'욕설 및 비매너'**
  String get reportReasonAbusive;

  /// No description provided for @reportReasonCoercion.
  ///
  /// In ko, this message translates to:
  /// **'강요 및 협박'**
  String get reportReasonCoercion;

  /// No description provided for @reportReasonPrivacyLeak.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 유출'**
  String get reportReasonPrivacyLeak;

  /// No description provided for @reportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportReasonOther;

  /// No description provided for @interestGroupHobby.
  ///
  /// In ko, this message translates to:
  /// **'취미'**
  String get interestGroupHobby;

  /// No description provided for @interestGroupLifestyle.
  ///
  /// In ko, this message translates to:
  /// **'라이프스타일'**
  String get interestGroupLifestyle;

  /// No description provided for @interestGroupCulture.
  ///
  /// In ko, this message translates to:
  /// **'문화/엔터테인먼트'**
  String get interestGroupCulture;

  /// No description provided for @interestGroupSports.
  ///
  /// In ko, this message translates to:
  /// **'스포츠'**
  String get interestGroupSports;

  /// No description provided for @interestTravel.
  ///
  /// In ko, this message translates to:
  /// **'여행'**
  String get interestTravel;

  /// No description provided for @interestPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get interestPhoto;

  /// No description provided for @interestArt.
  ///
  /// In ko, this message translates to:
  /// **'그림/미술'**
  String get interestArt;

  /// No description provided for @interestReading.
  ///
  /// In ko, this message translates to:
  /// **'독서'**
  String get interestReading;

  /// No description provided for @interestMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get interestMusic;

  /// No description provided for @interestMovie.
  ///
  /// In ko, this message translates to:
  /// **'영화'**
  String get interestMovie;

  /// No description provided for @interestDrama.
  ///
  /// In ko, this message translates to:
  /// **'드라마'**
  String get interestDrama;

  /// No description provided for @interestGame.
  ///
  /// In ko, this message translates to:
  /// **'게임'**
  String get interestGame;

  /// No description provided for @interestWorkout.
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get interestWorkout;

  /// No description provided for @interestCooking.
  ///
  /// In ko, this message translates to:
  /// **'요리'**
  String get interestCooking;

  /// No description provided for @interestCafe.
  ///
  /// In ko, this message translates to:
  /// **'카페 탐방'**
  String get interestCafe;

  /// No description provided for @interestPet.
  ///
  /// In ko, this message translates to:
  /// **'반려동물'**
  String get interestPet;

  /// No description provided for @interestCamping.
  ///
  /// In ko, this message translates to:
  /// **'자연/캠핑'**
  String get interestCamping;

  /// No description provided for @interestExhibition.
  ///
  /// In ko, this message translates to:
  /// **'공연/전시'**
  String get interestExhibition;

  /// No description provided for @interestSinging.
  ///
  /// In ko, this message translates to:
  /// **'노래/악기'**
  String get interestSinging;

  /// No description provided for @interestSelfDev.
  ///
  /// In ko, this message translates to:
  /// **'자기계발'**
  String get interestSelfDev;

  /// No description provided for @interestFinance.
  ///
  /// In ko, this message translates to:
  /// **'재테크'**
  String get interestFinance;

  /// No description provided for @interestIt.
  ///
  /// In ko, this message translates to:
  /// **'IT/기술'**
  String get interestIt;

  /// No description provided for @interestFashion.
  ///
  /// In ko, this message translates to:
  /// **'패션'**
  String get interestFashion;

  /// No description provided for @interestBeauty.
  ///
  /// In ko, this message translates to:
  /// **'뷰티'**
  String get interestBeauty;

  /// No description provided for @interestWellbeing.
  ///
  /// In ko, this message translates to:
  /// **'건강/웰빙'**
  String get interestWellbeing;

  /// No description provided for @interestMinimal.
  ///
  /// In ko, this message translates to:
  /// **'정리/미니멀'**
  String get interestMinimal;

  /// No description provided for @interestSustainable.
  ///
  /// In ko, this message translates to:
  /// **'지속가능성'**
  String get interestSustainable;

  /// No description provided for @interestKpop.
  ///
  /// In ko, this message translates to:
  /// **'K-POP'**
  String get interestKpop;

  /// No description provided for @interestJpop.
  ///
  /// In ko, this message translates to:
  /// **'J-POP'**
  String get interestJpop;

  /// No description provided for @interestAnime.
  ///
  /// In ko, this message translates to:
  /// **'애니메이션'**
  String get interestAnime;

  /// No description provided for @interestWebtoon.
  ///
  /// In ko, this message translates to:
  /// **'웹툰/만화'**
  String get interestWebtoon;

  /// No description provided for @interestMusical.
  ///
  /// In ko, this message translates to:
  /// **'뮤지컬/연극'**
  String get interestMusical;

  /// No description provided for @interestFestival.
  ///
  /// In ko, this message translates to:
  /// **'페스티벌'**
  String get interestFestival;

  /// No description provided for @interestSoccer.
  ///
  /// In ko, this message translates to:
  /// **'축구'**
  String get interestSoccer;

  /// No description provided for @interestBaseball.
  ///
  /// In ko, this message translates to:
  /// **'야구'**
  String get interestBaseball;

  /// No description provided for @interestBasketball.
  ///
  /// In ko, this message translates to:
  /// **'농구'**
  String get interestBasketball;

  /// No description provided for @interestGolf.
  ///
  /// In ko, this message translates to:
  /// **'골프'**
  String get interestGolf;

  /// No description provided for @interestTennis.
  ///
  /// In ko, this message translates to:
  /// **'테니스'**
  String get interestTennis;

  /// No description provided for @interestSwimming.
  ///
  /// In ko, this message translates to:
  /// **'수영'**
  String get interestSwimming;

  /// No description provided for @interestClimbing.
  ///
  /// In ko, this message translates to:
  /// **'등산/클라이밍'**
  String get interestClimbing;

  /// No description provided for @interestCycling.
  ///
  /// In ko, this message translates to:
  /// **'자전거'**
  String get interestCycling;

  /// No description provided for @cityKrSeoul.
  ///
  /// In ko, this message translates to:
  /// **'서울'**
  String get cityKrSeoul;

  /// No description provided for @cityKrBusan.
  ///
  /// In ko, this message translates to:
  /// **'부산'**
  String get cityKrBusan;

  /// No description provided for @cityKrDaegu.
  ///
  /// In ko, this message translates to:
  /// **'대구'**
  String get cityKrDaegu;

  /// No description provided for @cityKrIncheon.
  ///
  /// In ko, this message translates to:
  /// **'인천'**
  String get cityKrIncheon;

  /// No description provided for @cityKrGwangju.
  ///
  /// In ko, this message translates to:
  /// **'광주'**
  String get cityKrGwangju;

  /// No description provided for @cityKrDaejeon.
  ///
  /// In ko, this message translates to:
  /// **'대전'**
  String get cityKrDaejeon;

  /// No description provided for @cityKrUlsan.
  ///
  /// In ko, this message translates to:
  /// **'울산'**
  String get cityKrUlsan;

  /// No description provided for @cityKrSejong.
  ///
  /// In ko, this message translates to:
  /// **'세종'**
  String get cityKrSejong;

  /// No description provided for @cityKrSuwon.
  ///
  /// In ko, this message translates to:
  /// **'수원'**
  String get cityKrSuwon;

  /// No description provided for @cityKrGoyang.
  ///
  /// In ko, this message translates to:
  /// **'고양'**
  String get cityKrGoyang;

  /// No description provided for @cityKrSeongnam.
  ///
  /// In ko, this message translates to:
  /// **'성남'**
  String get cityKrSeongnam;

  /// No description provided for @cityJpTokyo.
  ///
  /// In ko, this message translates to:
  /// **'도쿄'**
  String get cityJpTokyo;

  /// No description provided for @cityJpOsaka.
  ///
  /// In ko, this message translates to:
  /// **'오사카'**
  String get cityJpOsaka;

  /// No description provided for @cityJpKyoto.
  ///
  /// In ko, this message translates to:
  /// **'교토'**
  String get cityJpKyoto;

  /// No description provided for @cityJpNagoya.
  ///
  /// In ko, this message translates to:
  /// **'나고야'**
  String get cityJpNagoya;

  /// No description provided for @cityJpYokohama.
  ///
  /// In ko, this message translates to:
  /// **'요코하마'**
  String get cityJpYokohama;

  /// No description provided for @cityJpFukuoka.
  ///
  /// In ko, this message translates to:
  /// **'후쿠오카'**
  String get cityJpFukuoka;

  /// No description provided for @cityJpSapporo.
  ///
  /// In ko, this message translates to:
  /// **'삿포로'**
  String get cityJpSapporo;

  /// No description provided for @cityJpKobe.
  ///
  /// In ko, this message translates to:
  /// **'고베'**
  String get cityJpKobe;

  /// No description provided for @cityJpSendai.
  ///
  /// In ko, this message translates to:
  /// **'센다이'**
  String get cityJpSendai;

  /// No description provided for @errorUserNotFound.
  ///
  /// In ko, this message translates to:
  /// **'사용자를 찾을 수 없어요.'**
  String get errorUserNotFound;

  /// No description provided for @errorProviderDisabled.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 방법으로 로그인할 수 없어요.'**
  String get errorProviderDisabled;

  /// No description provided for @errorNicknameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'사용할 수 없는 닉네임이에요.'**
  String get errorNicknameInvalid;

  /// No description provided for @errorNicknameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임이에요.'**
  String get errorNicknameDuplicate;

  /// No description provided for @errorNicknameFormat.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 특수문자·이모지 없이 10자 이내여야 해요.'**
  String get errorNicknameFormat;

  /// No description provided for @errorAgeRestricted.
  ///
  /// In ko, this message translates to:
  /// **'만 18세 이상만 가입할 수 있어요.'**
  String get errorAgeRestricted;

  /// No description provided for @errorPostPhotoRequired.
  ///
  /// In ko, this message translates to:
  /// **'새로운 포스트 사진을 등록해 주세요.'**
  String get errorPostPhotoRequired;

  /// No description provided for @errorPostPhotoNotFound.
  ///
  /// In ko, this message translates to:
  /// **'사진을 찾을 수 없어요.'**
  String get errorPostPhotoNotFound;

  /// No description provided for @errorPostPhotoNotMine.
  ///
  /// In ko, this message translates to:
  /// **'내 사진만 삭제할 수 있어요.'**
  String get errorPostPhotoNotMine;

  /// No description provided for @errorPostPhotoLimit.
  ///
  /// In ko, this message translates to:
  /// **'사진은 최대 {count}장까지 등록할 수 있어요. 기존 사진을 먼저 삭제해 주세요.'**
  String errorPostPhotoLimit(int count);

  /// No description provided for @errorPostReplaceLimit.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 사진 교체 횟수({count}회)를 모두 썼어요. 내일 다시 이용해 주세요.'**
  String errorPostReplaceLimit(int count);

  /// No description provided for @errorPostReplaceFreeLimit.
  ///
  /// In ko, this message translates to:
  /// **'사진은 하루 {count}번까지 교체할 수 있어요. 내일 다시 이용해 주세요.'**
  String errorPostReplaceFreeLimit(int count);

  /// No description provided for @errorPostNotPublishedToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 등록된 포스트가 없어요.'**
  String get errorPostNotPublishedToday;

  /// No description provided for @errorGardenTargetBlocked.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 사용자에게 댓글을 남길 수 없어요.'**
  String get errorGardenTargetBlocked;

  /// No description provided for @errorCommentTooLong.
  ///
  /// In ko, this message translates to:
  /// **'댓글은 {count}자까지 입력할 수 있어요.'**
  String errorCommentTooLong(int count);

  /// No description provided for @errorCommentDepthExceeded.
  ///
  /// In ko, this message translates to:
  /// **'답글은 {count}단계까지만 달 수 있어요.'**
  String errorCommentDepthExceeded(int count);

  /// No description provided for @errorCommentParentNotFound.
  ///
  /// In ko, this message translates to:
  /// **'답글을 달 댓글을 찾을 수 없어요.'**
  String get errorCommentParentNotFound;

  /// No description provided for @errorCommentImageKeyInvalid.
  ///
  /// In ko, this message translates to:
  /// **'첨부한 사진이 올바르지 않아요. 다시 선택해 주세요.'**
  String get errorCommentImageKeyInvalid;

  /// No description provided for @errorCommentReplyNotAllowed.
  ///
  /// In ko, this message translates to:
  /// **'답글은 글쓴이와 댓글을 단 사람이 번갈아 주고받을 수 있어요.'**
  String get errorCommentReplyNotAllowed;

  /// No description provided for @errorDailyQuestionNotReady.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 질문이 아직 준비되지 않았어요.'**
  String get errorDailyQuestionNotReady;

  /// No description provided for @errorDailyAnswerNotFound.
  ///
  /// In ko, this message translates to:
  /// **'한마디를 찾을 수 없어요.'**
  String get errorDailyAnswerNotFound;

  /// No description provided for @errorDailyAnswerAlready.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 이미 한마디를 남겼어요.'**
  String get errorDailyAnswerAlready;

  /// No description provided for @errorDailyAnswerTooLong.
  ///
  /// In ko, this message translates to:
  /// **'{count}자까지 입력할 수 있어요.'**
  String errorDailyAnswerTooLong(int count);

  /// No description provided for @errorDailyAnswerImageKeyInvalid.
  ///
  /// In ko, this message translates to:
  /// **'첨부한 사진이 올바르지 않아요. 다시 선택해 주세요.'**
  String get errorDailyAnswerImageKeyInvalid;

  /// No description provided for @errorTranslateQuotaExceeded.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 무료 번역을 모두 사용했어요. 자동 번역 패스를 이용해 보세요.'**
  String get errorTranslateQuotaExceeded;

  /// No description provided for @errorTranslateTargetRequired.
  ///
  /// In ko, this message translates to:
  /// **'번역할 상대를 지정해 주세요.'**
  String get errorTranslateTargetRequired;

  /// No description provided for @errorChatSelf.
  ///
  /// In ko, this message translates to:
  /// **'자신에게는 대화를 신청할 수 없어요.'**
  String get errorChatSelf;

  /// No description provided for @errorChatTargetBlocked.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 사용자에게 대화를 신청할 수 없어요.'**
  String get errorChatTargetBlocked;

  /// No description provided for @errorChatRequestPending.
  ///
  /// In ko, this message translates to:
  /// **'이미 대화를 신청했어요. 상대의 응답을 기다려 주세요.'**
  String get errorChatRequestPending;

  /// No description provided for @errorChatRequestNotFound.
  ///
  /// In ko, this message translates to:
  /// **'신청을 찾을 수 없어요.'**
  String get errorChatRequestNotFound;

  /// No description provided for @errorChatRequestAlreadyHandled.
  ///
  /// In ko, this message translates to:
  /// **'이미 처리된 신청이에요.'**
  String get errorChatRequestAlreadyHandled;

  /// No description provided for @errorChatAcceptNotReceiver.
  ///
  /// In ko, this message translates to:
  /// **'내가 받은 신청만 수락할 수 있어요.'**
  String get errorChatAcceptNotReceiver;

  /// No description provided for @errorChatRejectNotReceiver.
  ///
  /// In ko, this message translates to:
  /// **'내가 받은 신청만 거절할 수 있어요.'**
  String get errorChatRejectNotReceiver;

  /// No description provided for @errorRoomAlreadyActive.
  ///
  /// In ko, this message translates to:
  /// **'이미 진행 중인 대화가 있어요.'**
  String get errorRoomAlreadyActive;

  /// No description provided for @errorChatRoomNotFound.
  ///
  /// In ko, this message translates to:
  /// **'대화방을 찾을 수 없어요.'**
  String get errorChatRoomNotFound;

  /// No description provided for @errorChatRoomClosed.
  ///
  /// In ko, this message translates to:
  /// **'종료된 대화방이에요.'**
  String get errorChatRoomClosed;

  /// No description provided for @errorChatNotMember.
  ///
  /// In ko, this message translates to:
  /// **'참여 중인 대화방이 아니에요.'**
  String get errorChatNotMember;

  /// No description provided for @errorFriendSelf.
  ///
  /// In ko, this message translates to:
  /// **'자신에게는 친구 요청을 보낼 수 없어요.'**
  String get errorFriendSelf;

  /// No description provided for @errorFriendTargetBlocked.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 사용자에게 친구 요청을 보낼 수 없어요.'**
  String get errorFriendTargetBlocked;

  /// No description provided for @errorFriendAlready.
  ///
  /// In ko, this message translates to:
  /// **'이미 친구예요.'**
  String get errorFriendAlready;

  /// No description provided for @errorFriendNotYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 친구가 아니에요.'**
  String get errorFriendNotYet;

  /// No description provided for @errorFriendNotMine.
  ///
  /// In ko, this message translates to:
  /// **'내 친구 관계가 아니에요.'**
  String get errorFriendNotMine;

  /// No description provided for @errorFriendRequestPending.
  ///
  /// In ko, this message translates to:
  /// **'이미 친구 요청이 오갔어요. 응답을 기다려 주세요.'**
  String get errorFriendRequestPending;

  /// No description provided for @errorFriendRequestAlreadyAccepted.
  ///
  /// In ko, this message translates to:
  /// **'이미 친구가 된 요청이에요.'**
  String get errorFriendRequestAlreadyAccepted;

  /// No description provided for @errorFriendRequestNotFound.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청을 찾을 수 없어요.'**
  String get errorFriendRequestNotFound;

  /// No description provided for @errorFriendAcceptNotReceiver.
  ///
  /// In ko, this message translates to:
  /// **'내가 받은 요청만 수락할 수 있어요.'**
  String get errorFriendAcceptNotReceiver;

  /// No description provided for @errorFriendRejectNotReceiver.
  ///
  /// In ko, this message translates to:
  /// **'내가 받은 요청만 거절할 수 있어요.'**
  String get errorFriendRejectNotReceiver;

  /// No description provided for @errorFriendCancelNotSender.
  ///
  /// In ko, this message translates to:
  /// **'내가 보낸 요청만 취소할 수 있어요.'**
  String get errorFriendCancelNotSender;

  /// No description provided for @errorFriendLimitExceeded.
  ///
  /// In ko, this message translates to:
  /// **'친구는 최대 {limit}명까지예요.'**
  String errorFriendLimitExceeded(int limit);

  /// No description provided for @errorFriendNoTodayPost.
  ///
  /// In ko, this message translates to:
  /// **'친구가 아직 오늘의 포스트를 공유하지 않았어요.'**
  String get errorFriendNoTodayPost;

  /// No description provided for @errorLunaInsufficient.
  ///
  /// In ko, this message translates to:
  /// **'루나가 부족해요.'**
  String get errorLunaInsufficient;

  /// No description provided for @errorStoreProductNotFound.
  ///
  /// In ko, this message translates to:
  /// **'존재하지 않는 상품이에요.'**
  String get errorStoreProductNotFound;

  /// No description provided for @errorStoreProductInvalid.
  ///
  /// In ko, this message translates to:
  /// **'상품 구성이 잘못됐어요.'**
  String get errorStoreProductInvalid;

  /// No description provided for @errorStoreBoostNone.
  ///
  /// In ko, this message translates to:
  /// **'보유한 부스트가 없어요.'**
  String get errorStoreBoostNone;

  /// No description provided for @errorStoreBoostAlreadyActive.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 부스트예요.'**
  String get errorStoreBoostAlreadyActive;

  /// No description provided for @errorStoreAlreadySubscribed.
  ///
  /// In ko, this message translates to:
  /// **'이미 프라임을 구독 중이에요.'**
  String get errorStoreAlreadySubscribed;

  /// No description provided for @errorStoreNotSubscribed.
  ///
  /// In ko, this message translates to:
  /// **'구독 중이 아니에요.'**
  String get errorStoreNotSubscribed;

  /// No description provided for @errorStoreAlreadyCanceled.
  ///
  /// In ko, this message translates to:
  /// **'이미 자동 갱신을 해지했어요.'**
  String get errorStoreAlreadyCanceled;

  /// No description provided for @errorStoreReceiptInvalid.
  ///
  /// In ko, this message translates to:
  /// **'결제 정보를 확인할 수 없어요.'**
  String get errorStoreReceiptInvalid;

  /// No description provided for @errorStorePurchaseFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 결제를 처리할 수 없어요.'**
  String get errorStorePurchaseFailed;

  /// No description provided for @errorModerationSelf.
  ///
  /// In ko, this message translates to:
  /// **'자기 자신은 대상이 될 수 없어요.'**
  String get errorModerationSelf;

  /// No description provided for @errorTargetBlockedOrReported.
  ///
  /// In ko, this message translates to:
  /// **'지금은 이 사용자에게 요청할 수 없어요.'**
  String get errorTargetBlockedOrReported;

  /// No description provided for @errorNetworkTimeout.
  ///
  /// In ko, this message translates to:
  /// **'서버 응답이 늦어요. 잠시 후 다시 시도해 주세요.'**
  String get errorNetworkTimeout;

  /// No description provided for @errorNetworkUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없어요. 네트워크를 확인해 주세요.'**
  String get errorNetworkUnreachable;

  /// No description provided for @errorNetworkUnknown.
  ///
  /// In ko, this message translates to:
  /// **'통신 중 문제가 발생했어요.'**
  String get errorNetworkUnknown;

  /// No description provided for @errorSocketDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊겼어요. 잠시 후 다시 보내주세요.'**
  String get errorSocketDisconnected;

  /// No description provided for @errorSocketSendTimeout.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 보내지 못했어요. 다시 시도해 주세요.'**
  String get errorSocketSendTimeout;

  /// No description provided for @errorUnknown.
  ///
  /// In ko, this message translates to:
  /// **'요청을 처리하지 못했어요.'**
  String get errorUnknown;

  /// No description provided for @regionLabelFormat.
  ///
  /// In ko, this message translates to:
  /// **'{country}, {city}'**
  String regionLabelFormat(String country, String city);

  /// No description provided for @voiceStop.
  ///
  /// In ko, this message translates to:
  /// **'녹음 정지'**
  String get voiceStop;

  /// No description provided for @voicePlay.
  ///
  /// In ko, this message translates to:
  /// **'미리 듣기'**
  String get voicePlay;

  /// No description provided for @voiceDelete.
  ///
  /// In ko, this message translates to:
  /// **'녹음 삭제'**
  String get voiceDelete;

  /// No description provided for @voiceSend.
  ///
  /// In ko, this message translates to:
  /// **'메시지 올리기'**
  String get voiceSend;

  /// No description provided for @voiceRecord.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지'**
  String get voiceRecord;

  /// No description provided for @voicePermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'마이크 권한이 필요해요. 설정에서 허용해 주세요.'**
  String get voicePermissionDenied;

  /// No description provided for @errorChatVoiceKeyRequired.
  ///
  /// In ko, this message translates to:
  /// **'음성 파일이 업로드되지 않았어요.'**
  String get errorChatVoiceKeyRequired;

  /// No description provided for @errorChatVoiceKeyInvalid.
  ///
  /// In ko, this message translates to:
  /// **'잘못된 음성 파일이에요.'**
  String get errorChatVoiceKeyInvalid;

  /// No description provided for @errorChatVoiceTooLong.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지는 최대 {seconds}초까지예요.'**
  String errorChatVoiceTooLong(String seconds);

  /// No description provided for @chatRoomsVoicePreview.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지'**
  String get chatRoomsVoicePreview;
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
