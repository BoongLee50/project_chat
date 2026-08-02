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
