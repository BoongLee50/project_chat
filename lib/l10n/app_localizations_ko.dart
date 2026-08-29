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

  @override
  String get onboardingBack => '뒤로';

  @override
  String get onboardingNext => '완료';

  @override
  String get onboardingPrivateNotice => '* 이 정보는 다른 사용자에게 공개되지 않습니다.';

  @override
  String get birthYearTitle => '출생년도 설정';

  @override
  String get birthYearSubtitle => '정확한 나이 확인을 위해 출생년도를 선택해주세요.';

  @override
  String get genderCountryTitle => '성별 및 나라 설정';

  @override
  String get genderCountrySubtitle => '정확한 매칭을 위해 성별과 나라를 선택해주세요.';

  @override
  String get genderSectionTitle => '성별 선택';

  @override
  String get genderMale => '남자';

  @override
  String get genderFemale => '여자';

  @override
  String get countrySectionTitle => '나라 선택';

  @override
  String get countryKorea => '한국';

  @override
  String get countryJapan => '일본';

  @override
  String get commonEdit => '수정';

  @override
  String get commonEmptyValue => '—';

  @override
  String get homeTitle => '오늘의 포스트';

  @override
  String get homeTodayMoon => '오늘의 달';

  @override
  String get homeMoonCrescent => '초승달';

  @override
  String get homeLoadFailed => '포스트를 불러오지 못했어요.';

  @override
  String get homePullToRefresh => '아래로 당겨 새로고침해 주세요.';

  @override
  String homeEmptyGreeting(String nickname) {
    return '$nickname님';
  }

  @override
  String get homeEmptyHint => '달빛 아래의 지금을 포스트해 보세요.\n새로운 대화의 시작이 될 수 있어요.';

  @override
  String get homeAlbumPass => '포스트 앨범 패스';

  @override
  String homeAlbumPassRemaining(int days) {
    return '$days일 남음';
  }

  @override
  String homeAlbumPassMaxPhotos(int count) {
    return '최대 $count장 등록 가능';
  }

  @override
  String get homeMainPhoto => '메인';

  @override
  String get homeSetMainPhoto => '메인으로';

  @override
  String get homeMainPhotoSet => '메인 사진으로 지정했어요.';

  @override
  String get homeBoost => '부스트';

  @override
  String get homeBoostActive => '부스트 사용 중';

  @override
  String homeBoostStock(int count) {
    return '보유 $count매';
  }

  @override
  String get homeShare => '포스트 공유하기';

  @override
  String get homeShareAgain => '공유됨 · 다시 공유하기';

  @override
  String get homeShared => '포스트를 공유했어요 🌙';

  @override
  String get commonAll => '전체';

  @override
  String get commonSend => '보내기';

  @override
  String get commonOnline => '접속 중';

  @override
  String ageDecade(int decade) {
    return '$decade대';
  }

  @override
  String get gardenTitle => '달빛가든';

  @override
  String get gardenSubtitle => '달빛 아래, 우리의 하루를 나누는 공간 ✨';

  @override
  String get gardenLoadFailed => '피드를 불러오지 못했어요.';

  @override
  String get gardenEmptyTitle => '지금은 보여줄 포스트가 없어요.';

  @override
  String get gardenEmptyDetail => '필터를 바꾸거나 잠시 후 다시 확인해 주세요.';

  @override
  String gardenChatRequestTitle(String nickname) {
    return '$nickname님에게 대화 신청';
  }

  @override
  String get gardenChatRequestHint => '첫 인사를 남겨보세요 (최대 100자)';

  @override
  String get gardenChatRequestSent => '대화 신청을 보냈어요. 상대의 응답을 기다려 주세요.';

  @override
  String gardenPhotoLockedTitle(int count) {
    return '사진 $count장이 더 있어요';
  }

  @override
  String get gardenPhotoLockedBody => '오늘 내 포스트를 공유하면 상대의 사진을 모두 볼 수 있어요.';

  @override
  String get gardenPhotoLockedAction => '내 포스트 등록하기';

  @override
  String commentsTitle(String nickname) {
    return '$nickname님의 포스트';
  }

  @override
  String get commentsSection => '댓글';

  @override
  String get commentsHint => '댓글을 남겨보세요 (최대 25자)';

  @override
  String get commentsEmpty => '첫 댓글을 남겨보세요.';

  @override
  String get commentsLoadFailed => '댓글을 불러오지 못했어요.';

  @override
  String get chatRoomsTitle => '대화방';

  @override
  String get chatRoomsSubtitle => '마음이 통하는 사람들과 이야기를 나눠보세요.';

  @override
  String get chatTabFriend => '친구';

  @override
  String get chatTabReceived => '받은 신청';

  @override
  String get chatRoomsEmpty => '아직 대화가 없어요.\n달빛가든에서 마음에 드는 사람에게 말을 걸어보세요.';

  @override
  String get chatRoomsStart => '대화를 시작해보세요.';

  @override
  String get chatRoomsOngoing => '대화 중';

  @override
  String get commonAccept => '수락';

  @override
  String get commonReject => '거절';

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours시간 전';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String ageYears(int age) {
    return '$age세';
  }

  @override
  String get chatLoadFailed => '대화를 불러오지 못했어요.';

  @override
  String get chatInputHint => '메시지를 입력하세요...';

  @override
  String get chatMatchedNotice => '매칭되었습니다. 예의 있는 멋진 대화를 나눠보세요.';

  @override
  String get chatMenuProfile => '프로필 보기';

  @override
  String get chatMenuFriendRequest => '친구 요청';

  @override
  String get chatMenuReport => '신고하기';

  @override
  String get chatMenuBlock => '차단하기';

  @override
  String get chatMenuLeave => '대화방 나가기';

  @override
  String get chatFriendRequestSent => '친구 요청을 보냈어요. 상대가 수락하면 친구가 돼요.';

  @override
  String get chatReportDone => '신고가 접수됐어요. 대화가 종료됩니다.';

  @override
  String chatBlockDone(String nickname) {
    return '$nickname님을 차단했어요.';
  }

  @override
  String get friendsTitle => '친구';

  @override
  String get friendsOnlineNowLabel => '지금 접속 중 ';

  @override
  String friendsOnlineCount(int count) {
    return '$count명';
  }

  @override
  String friendsRequestsReceived(int count) {
    return '받은 친구 요청 $count';
  }

  @override
  String get friendsLoadFailed => '친구 목록을 불러오지 못했어요.';

  @override
  String get friendsEmpty => '아직 친구가 없어요.';

  @override
  String get friendsEmptyHint => '대화를 나눈 상대에게 채팅창 메뉴에서 친구 요청을 보내보세요.';

  @override
  String get friendsAccepted => '친구가 되었어요. 이제 언제든 대화할 수 있어요.';

  @override
  String get friendsRejected => '요청을 거절했어요.';

  @override
  String get friendsRequestSent => '친구 요청을 보냈어요.';

  @override
  String get friendsRoomNotFound => '대화방을 찾을 수 없어요. 새로고침해 주세요.';

  @override
  String friendsDeleteConfirm(String nickname) {
    return '$nickname님을 친구에서 삭제할까요?';
  }

  @override
  String get friendsDeleteDetail => '상시 대화방도 함께 종료돼요.';

  @override
  String get filterAge => '나이';

  @override
  String get filterCountry => '국가';

  @override
  String get statusOnline => '온라인';

  @override
  String get statusOffline => '오프라인';

  @override
  String get friendPostTitle => '오늘의 포스트';

  @override
  String get friendPostLoadFailed => '포스트를 불러오지 못했어요.';

  @override
  String get friendPostMessage => '메시지';

  @override
  String get friendPostSendMessage => '메시지 보내기';

  @override
  String get profileTitle => '프로필';

  @override
  String get profilePhotoPrompt => '프로필 사진을 등록해 주세요';

  @override
  String get photoSheetProfileTitle => '프로필 사진 변경';

  @override
  String get photoSheetProfileSubtitle =>
      '멋진 사진으로 프로필을 업데이트하고\n더 많은 매치를 만나보세요!';

  @override
  String get photoSheetPostTitle => '포스트 사진 등록';

  @override
  String get photoSheetPostSubtitle => '오늘 밤의 순간을 남겨보세요.';

  @override
  String get photoSourceGallery => '앨범에서 선택';

  @override
  String get photoSourceCamera => '카메라 촬영';

  @override
  String get photoSourceRemove => '프로필 사진 제거';

  @override
  String get photoSourceGalleryPassOnly => '앨범 패스가 있어야 이용할 수 있어요';

  @override
  String get profileLunaBalance => '보유 루나';

  @override
  String get profileLunaStore => '루나상점';

  @override
  String get profilePrimeTitle => '프라임으로 더 특별하게 ✨';

  @override
  String get profilePrimeBenefits => '포스트 9장·부스트·무제한 대화·자동 번역';

  @override
  String get profileSeeDetail => '자세히 보기';

  @override
  String get profileBoostPost => '포스트 부스트';

  @override
  String get profileBoostMatch => '매칭 부스트';

  @override
  String profileBoostCount(int count) {
    return '$count매';
  }

  @override
  String get profileFreeUpload => '무료 업로드';

  @override
  String get profileNoAds => '광고 제거';

  @override
  String get profileVisitors => '방문자 확인';

  @override
  String get profileIntro => '소개 한마디';

  @override
  String get profileIntroEmpty => '나를 소개하는 한마디를 남겨보세요. (최대 50자)';

  @override
  String get profileInterests => '관심사';

  @override
  String get profileInterestsEmpty => '관심사를 등록하면 더 잘 맞는 사람을 만날 수 있어요.';

  @override
  String get profileRegions => '활동 지역';

  @override
  String get profileRegionsEmpty => '활동 지역은 최대 2곳까지 선택할 수 있어요.';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get introEditTitle => '소개 한마디';

  @override
  String get introEditHint => '자신의 취미, 성격, 또는\n하고 싶은 말을 자유롭게 적어보세요.';

  @override
  String get introEditCounter => '최대 50자까지 가능합니다.';

  @override
  String get interestsEditTitle => '관심사 등록';

  @override
  String get interestsEditSubtitle => '요즘 어떤 것에 꽂혀 계시나요? 취향을 공유해 보세요!';

  @override
  String interestsEditSelected(int count, int max) {
    return '선택된 관심사 ($count/$max)';
  }

  @override
  String get interestsEditEmpty => '관심사를 선택해 주세요.';

  @override
  String get interestsEditReset => '전체 초기화';

  @override
  String interestsEditSave(int count, int max) {
    return '저장하기 ($count/$max)';
  }

  @override
  String interestsEditLimit(int max) {
    return '관심사는 최대 $max개까지 선택할 수 있어요.';
  }

  @override
  String get regionsEditTitle => '지역 선택';

  @override
  String regionsEditSubtitle(int max) {
    return '국가와 지역을 선택해주세요. (최대 $max곳)';
  }

  @override
  String get regionsEditOfCountry => '의 주요 지역';

  @override
  String get regionsEditSelected => '선택한 지역';

  @override
  String get regionsEditApply => '적용하기';

  @override
  String regionsEditLimit(int max) {
    return '활동 지역은 최대 $max곳까지 선택할 수 있어요.';
  }

  @override
  String get commonNone => '없음';

  @override
  String get storeKindPostBoost => '포스트 부스트';

  @override
  String get storeKindAlbumPass => '포스트 앨범 패스';

  @override
  String get storeKindTranslatePass => '자동 번역 패스';

  @override
  String get storeDescPostBoost => '다른 사람보다 우선적으로 포스트 사진을 추천해드려요!';

  @override
  String get storeDescAlbumPass =>
      '여러 장의 사진을 자유롭게 업로드! 시간 제한 없이, 카메라와 갤러리 사진 모두 사용할 수 있어요.';

  @override
  String get storeDescTranslatePass => '모든 메시지를 자동으로 번역해 언어 장벽 없이 소통!';

  @override
  String storeOptionBoost(int quantity) {
    return '1시간, $quantity매';
  }

  @override
  String storeOptionDays(int days) {
    return '$days일';
  }

  @override
  String get lunaStoreTitle => '루나상점';

  @override
  String get lunaStoreSubtitle => '루나로 더 특별한 경험을 만들어보세요.';

  @override
  String get storeLoadFailed => '상품을 불러오지 못했어요.';

  @override
  String get storeBuy => '구매하기';

  @override
  String get storeDetail => '자세히';

  @override
  String storeDiscount(int percent) {
    return '$percent% 할인';
  }

  @override
  String storePurchased(String item, String option) {
    return '$item $option 구매 완료!';
  }

  @override
  String get storeLunaBalance => '보유 루나';

  @override
  String get storeCharge => '충전하기';

  @override
  String boostOwnedTitle(String item) {
    return '보유 $item';
  }

  @override
  String boostItemHour(String item) {
    return '$item (1시간)';
  }

  @override
  String boostStock(int count) {
    return '보유 $count매';
  }

  @override
  String boostActiveRemaining(String remaining) {
    return '사용 중 — $remaining 남음';
  }

  @override
  String boostRemainHourMinute(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String boostRemainMinute(int minutes) {
    return '$minutes분';
  }

  @override
  String get boostRemainUnderMinute => '1분 미만';

  @override
  String get boostEffectTitle => '예상 효과';

  @override
  String get boostEffectExposure => '최대 노출 증가';

  @override
  String get boostEffectExposureValue => '약 3배';

  @override
  String get boostEffectExposureDetail => '더 많은 사용자에게 노출돼요';

  @override
  String get boostEffectVisit => '프로필 방문 증가';

  @override
  String get boostEffectVisitValue => '약 2.5배';

  @override
  String get boostEffectVisitDetail => '프로필 방문 및 유입이 늘어나요';

  @override
  String get boostEffectLike => '좋아요 증가';

  @override
  String get boostEffectLikeValue => '약 2배';

  @override
  String get boostEffectLikeDetail => '좋아요와 관심을 더 많이 받아요';

  @override
  String get boostHourHighlight => '1시간';

  @override
  String get boostHourSuffix => ' 동안 추천 우선순위가 올라가\n더 많은 사용자에게 노출돼요!';

  @override
  String get boostUse => '부스트 사용하기 (1매)';

  @override
  String get boostInUse => '사용 중이에요';

  @override
  String get boostNoneShort => '보유한 부스트가 없어요';

  @override
  String get boostNone => '보유한 부스트가 없어요.';

  @override
  String get boostBuyHint => '루나상점에서 부스트를 구매할 수 있어요.';

  @override
  String get boostGoStore => '루나상점 가기';

  @override
  String get boostUsed => '부스트를 사용했어요. 1시간 동안 우선 노출됩니다!';

  @override
  String passBuy(String item) {
    return '$item 구매';
  }

  @override
  String passExtend(String item) {
    return '$item 연장';
  }

  @override
  String passPurchased(String item, int days) {
    return '$item $days일 구매 완료!';
  }

  @override
  String get passPeriodSection => '기간 선택';

  @override
  String passDays(int days) {
    return '$days일';
  }

  @override
  String passDaysPass(int days) {
    return '$days일 패스';
  }

  @override
  String passPriceLuna(int price) {
    return '$price 루나';
  }

  @override
  String get passAmount => '구매 금액';

  @override
  String get passUsageInfo => '이용 정보';

  @override
  String get passStatus => '보유 상태';

  @override
  String get passStatusActive => '이용 중';

  @override
  String get passStatusNone => '미보유';

  @override
  String get passStatusPending => '구매 대기';

  @override
  String get passRemaining => '남은 기간';

  @override
  String passValidUntil(String date) {
    return '$date까지';
  }

  @override
  String get passValidPeriod => '유효 기간';

  @override
  String get passExtendNotice => '이미 이용 중이에요. 지금 구매하면 남은 기간에 이어서 연장됩니다.';

  @override
  String get passAlbumHeadline => '더 많은 포스트 사진을 등록하고 다양한 매력을 보여주세요!';

  @override
  String get passAlbumBenefit1 => '포스트 사진 최대 9장까지 등록';

  @override
  String get passAlbumBenefit1Desc => '기본 2장에서 최대 9장까지 여러 장의 사진을 등록할 수 있어요.';

  @override
  String get passAlbumBenefit2 => '등록 시간 제한 없음 (24시간 자유롭게)';

  @override
  String get passAlbumBenefit2Desc => '시간 제약 없이 언제든지 자유롭게 포스트를 등록할 수 있어요.';

  @override
  String get passAlbumBenefit3 => '휴대폰 갤러리 사진까지 업로드 가능';

  @override
  String get passAlbumBenefit3Desc => '카메라로 찍은 사진뿐만 아니라 갤러리 사진도 올릴 수 있어요.';

  @override
  String get passTranslateHeadline => '언어의 장벽 없이 더 많은 사람과 대화해보세요!';

  @override
  String get passTranslateBenefit1 => '채팅 자동 번역 무제한';

  @override
  String get passTranslateBenefit1Desc => '상대방의 메시지를 자동으로 번역해 실시간으로 소통할 수 있어요.';

  @override
  String get passTranslateBenefit2 => '댓글 자동 번역 무제한';

  @override
  String get passTranslateBenefit2Desc => '달빛가든과 포스트의 댓글을 자동으로 번역해줘요.';

  @override
  String get passTranslateBenefit3 => '프로필 자동 번역 무제한';

  @override
  String get passTranslateBenefit3Desc => '상대방의 프로필 정보와 하루 한마디를 자동으로 번역해줘요.';

  @override
  String get primeTitle => 'PRIME 멤버십';

  @override
  String get primeSubtitle => 'PRIME으로 더 특별한 경험을 즐겨보세요.';

  @override
  String get primeHeadline => '달빛톡을 완벽하게 즐기는 방법';

  @override
  String get primeHeadlineDetail => '모든 기능을 제한 없이!';

  @override
  String get primePlanSection => '요금제 선택하기';

  @override
  String primeMonths(int months) {
    return '$months개월';
  }

  @override
  String get primeBestValue => '가성비 끝판왕';

  @override
  String get primeStorePrice => '스토어 가격';

  @override
  String get primePay => '결제하기';

  @override
  String get primeStarted => 'PRIME 멤버십이 시작됐어요!';

  @override
  String get primeActive => 'PRIME 이용 중';

  @override
  String primeActiveMonths(int months) {
    return '$months개월 이용 중';
  }

  @override
  String primeRemainingDays(int days) {
    return '남은 기간 $days일';
  }

  @override
  String primeNextBilling(String date) {
    return '다음 결제 예정일  $date';
  }

  @override
  String primeEndDate(String date) {
    return '이용 종료일  $date';
  }

  @override
  String get primeAutoRenew => '자동 갱신';

  @override
  String get primeAutoRenewOff => '갱신 안 함';

  @override
  String get primeCancelRenew => '자동 갱신 해지';

  @override
  String get primeCancelConfirm => '자동 갱신을 해지할까요?';

  @override
  String get primeCancelDetail => '남은 기간 동안은 혜택이 그대로 유지되고, 만료일에 갱신되지 않아요.';

  @override
  String get primeCancelDone => '자동 갱신을 해지했어요.';

  @override
  String get commonUnsubscribe => '해지';

  @override
  String get primeBenefitsSection => '프라임 혜택';

  @override
  String get primeCurrentPlan => '현재 적용 중';

  @override
  String primeAlbumBenefit(int days) {
    return '포스트 사진 앨범 패스 $days일';
  }

  @override
  String get primeAlbumBenefitDesc => '하루에 여러 장의 사진을 자유롭게 업로드!';

  @override
  String primeBoostBenefit(String item, int count) {
    return '$item 1시간, $count매';
  }

  @override
  String primeBoostSummary(String item, int count) {
    return '$item $count매';
  }

  @override
  String get primePostBoostDesc => '내 포스트를 더 많은 사람에게 노출! (일일제한 없음)';

  @override
  String get primeUnlimitedChat => '대화 신청 무제한';

  @override
  String get primeUnlimitedChatDesc => '하루 무료 횟수에 관계없이 대화를 신청할 수 있어요.';

  @override
  String get primeAutoRenewNotice => '* PRIME은 선택하신 기간 동안 혜택이 자동 갱신됩니다.';

  @override
  String get primeSubscriptionNotice =>
      '구독 서비스는 동일한 기간, 동일한 가격으로 자동 갱신되며,\n언제든 구독을 해지할 수 있습니다.';

  @override
  String get chargeTitle => '루나 충전';

  @override
  String get chargeSubtitle => '루나로 더 특별한 경험을 즐겨보세요.';

  @override
  String get chargeLunaPrefix => '루나 ';

  @override
  String get chargeLunaSuffix => ' 개';

  @override
  String chargeBaseBonus(int luna, int bonus) {
    return '기본 $luna개 + 보너스 $bonus개';
  }

  @override
  String chargeBonusBadge(int bonus) {
    return '보너스 $bonus';
  }

  @override
  String get chargeBuy => '구매';

  @override
  String get chargeSecure => '안전한 결제';

  @override
  String get chargeNotice =>
      '결제는 스토어를 통해 처리되며, 구매한 루나는 즉시 지급됩니다.\n가격은 스토어 연동 후 표시됩니다.';

  @override
  String chargeDone(int total) {
    return '루나 $total개가 충전됐어요.';
  }

  @override
  String get navPost => '포스트';

  @override
  String get navGarden => '달빛가든';

  @override
  String get navChat => '대화방';

  @override
  String get navFriend => '친구';

  @override
  String get navProfile => '프로필';

  @override
  String get blockConfirmSuffix => '님을 차단하시겠습니까?';

  @override
  String get blockDescription =>
      '차단하면 상대방과의 채팅이 중단되고,\n상대방은 더 이상 나에게 메시지를 보낼 수 없습니다.';

  @override
  String get blockEffectChat => '채팅 차단';

  @override
  String get blockEffectChatDesc => '상대방과의 채팅이 중단되며,\n더 이상 메시지를 주고받을 수 없습니다.';

  @override
  String get blockEffectProfile => '프로필 비공개';

  @override
  String get blockEffectProfileDesc => '상대방이 내 프로필과 소식을\n볼 수 없게 됩니다.';

  @override
  String get blockAction => '차단하기';

  @override
  String get reportSelectReason => '신고 이유를 선택해주세요.';

  @override
  String get reportPrivacyNotice => '공유해 주신 내용은 안전을 위해\n철저히 비밀로 유지됩니다.';

  @override
  String get reportDetailHint => '어떤 점이 문제였는지 알려주세요.';

  @override
  String reportWarning(String nickname) {
    return '신고하면 $nickname님과의 대화가 종료되고 친구 관계도 해제돼요.';
  }

  @override
  String get reportAction => '신고하기';

  @override
  String get reportReasonIllegalAd => '불법 광고 및 홍보';

  @override
  String get reportReasonRomanceScam => '로맨스 스캠 (연애 사기)';

  @override
  String get reportReasonSexualDeepfake => '허위 합성/편집한 성인물';

  @override
  String get reportReasonAbusive => '욕설 및 비매너';

  @override
  String get reportReasonCoercion => '강요 및 협박';

  @override
  String get reportReasonPrivacyLeak => '개인정보 유출';

  @override
  String get reportReasonOther => '기타';

  @override
  String get interestGroupHobby => '취미';

  @override
  String get interestGroupLifestyle => '라이프스타일';

  @override
  String get interestGroupCulture => '문화/엔터테인먼트';

  @override
  String get interestGroupSports => '스포츠';

  @override
  String get interestTravel => '여행';

  @override
  String get interestPhoto => '사진';

  @override
  String get interestArt => '그림/미술';

  @override
  String get interestReading => '독서';

  @override
  String get interestMusic => '음악';

  @override
  String get interestMovie => '영화';

  @override
  String get interestDrama => '드라마';

  @override
  String get interestGame => '게임';

  @override
  String get interestWorkout => '운동';

  @override
  String get interestCooking => '요리';

  @override
  String get interestCafe => '카페 탐방';

  @override
  String get interestPet => '반려동물';

  @override
  String get interestCamping => '자연/캠핑';

  @override
  String get interestExhibition => '공연/전시';

  @override
  String get interestSinging => '노래/악기';

  @override
  String get interestSelfDev => '자기계발';

  @override
  String get interestFinance => '재테크';

  @override
  String get interestIt => 'IT/기술';

  @override
  String get interestFashion => '패션';

  @override
  String get interestBeauty => '뷰티';

  @override
  String get interestWellbeing => '건강/웰빙';

  @override
  String get interestMinimal => '정리/미니멀';

  @override
  String get interestSustainable => '지속가능성';

  @override
  String get interestKpop => 'K-POP';

  @override
  String get interestJpop => 'J-POP';

  @override
  String get interestAnime => '애니메이션';

  @override
  String get interestWebtoon => '웹툰/만화';

  @override
  String get interestMusical => '뮤지컬/연극';

  @override
  String get interestFestival => '페스티벌';

  @override
  String get interestSoccer => '축구';

  @override
  String get interestBaseball => '야구';

  @override
  String get interestBasketball => '농구';

  @override
  String get interestGolf => '골프';

  @override
  String get interestTennis => '테니스';

  @override
  String get interestSwimming => '수영';

  @override
  String get interestClimbing => '등산/클라이밍';

  @override
  String get interestCycling => '자전거';

  @override
  String get cityKrSeoul => '서울';

  @override
  String get cityKrBusan => '부산';

  @override
  String get cityKrDaegu => '대구';

  @override
  String get cityKrIncheon => '인천';

  @override
  String get cityKrGwangju => '광주';

  @override
  String get cityKrDaejeon => '대전';

  @override
  String get cityKrUlsan => '울산';

  @override
  String get cityKrSejong => '세종';

  @override
  String get cityKrSuwon => '수원';

  @override
  String get cityKrGoyang => '고양';

  @override
  String get cityKrSeongnam => '성남';

  @override
  String get cityJpTokyo => '도쿄';

  @override
  String get cityJpOsaka => '오사카';

  @override
  String get cityJpKyoto => '교토';

  @override
  String get cityJpNagoya => '나고야';

  @override
  String get cityJpYokohama => '요코하마';

  @override
  String get cityJpFukuoka => '후쿠오카';

  @override
  String get cityJpSapporo => '삿포로';

  @override
  String get cityJpKobe => '고베';

  @override
  String get cityJpSendai => '센다이';

  @override
  String get errorUserNotFound => '사용자를 찾을 수 없어요.';

  @override
  String get errorProviderDisabled => '지금은 이 방법으로 로그인할 수 없어요.';

  @override
  String get errorNicknameInvalid => '사용할 수 없는 닉네임이에요.';

  @override
  String get errorNicknameDuplicate => '이미 사용 중인 닉네임이에요.';

  @override
  String get errorNicknameFormat => '닉네임은 특수문자·이모지 없이 10자 이내여야 해요.';

  @override
  String get errorAgeRestricted => '만 18세 이상만 가입할 수 있어요.';

  @override
  String get errorPostPhotoRequired => '새로운 포스트 사진을 등록해 주세요.';

  @override
  String get errorPostPhotoNotFound => '사진을 찾을 수 없어요.';

  @override
  String get errorPostPhotoNotMine => '내 사진만 삭제할 수 있어요.';

  @override
  String errorPostPhotoLimit(int count) {
    return '사진은 최대 $count장까지 등록할 수 있어요. 기존 사진을 먼저 삭제해 주세요.';
  }

  @override
  String errorPostReplaceLimit(int count) {
    return '오늘의 사진 교체 횟수($count회)를 모두 썼어요. 내일 다시 이용해 주세요.';
  }

  @override
  String errorPostReplaceFreeLimit(int count) {
    return '사진은 하루 $count번까지 교체할 수 있어요. 내일 다시 이용해 주세요.';
  }

  @override
  String get errorPostNotPublishedToday => '오늘 등록된 포스트가 없어요.';

  @override
  String get errorGardenTargetBlocked => '지금은 이 사용자에게 댓글을 남길 수 없어요.';

  @override
  String get errorTranslateQuotaExceeded =>
      '오늘의 무료 번역을 모두 사용했어요. 자동 번역 패스를 이용해 보세요.';

  @override
  String get errorTranslateTargetRequired => '번역할 상대를 지정해 주세요.';

  @override
  String get errorChatSelf => '자신에게는 대화를 신청할 수 없어요.';

  @override
  String get errorChatTargetBlocked => '지금은 이 사용자에게 대화를 신청할 수 없어요.';

  @override
  String get errorChatRequestPending => '이미 대화를 신청했어요. 상대의 응답을 기다려 주세요.';

  @override
  String get errorChatRequestNotFound => '신청을 찾을 수 없어요.';

  @override
  String get errorChatRequestAlreadyHandled => '이미 처리된 신청이에요.';

  @override
  String get errorChatAcceptNotReceiver => '내가 받은 신청만 수락할 수 있어요.';

  @override
  String get errorChatRejectNotReceiver => '내가 받은 신청만 거절할 수 있어요.';

  @override
  String get errorRoomAlreadyActive => '이미 진행 중인 대화가 있어요.';

  @override
  String get errorChatRoomNotFound => '대화방을 찾을 수 없어요.';

  @override
  String get errorChatRoomClosed => '종료된 대화방이에요.';

  @override
  String get errorChatNotMember => '참여 중인 대화방이 아니에요.';

  @override
  String get errorFriendSelf => '자신에게는 친구 요청을 보낼 수 없어요.';

  @override
  String get errorFriendTargetBlocked => '지금은 이 사용자에게 친구 요청을 보낼 수 없어요.';

  @override
  String get errorFriendAlready => '이미 친구예요.';

  @override
  String get errorFriendNotYet => '아직 친구가 아니에요.';

  @override
  String get errorFriendNotMine => '내 친구 관계가 아니에요.';

  @override
  String get errorFriendRequestPending => '이미 친구 요청이 오갔어요. 응답을 기다려 주세요.';

  @override
  String get errorFriendRequestAlreadyAccepted => '이미 친구가 된 요청이에요.';

  @override
  String get errorFriendRequestNotFound => '친구 요청을 찾을 수 없어요.';

  @override
  String get errorFriendAcceptNotReceiver => '내가 받은 요청만 수락할 수 있어요.';

  @override
  String get errorFriendRejectNotReceiver => '내가 받은 요청만 거절할 수 있어요.';

  @override
  String get errorFriendCancelNotSender => '내가 보낸 요청만 취소할 수 있어요.';

  @override
  String errorFriendLimitExceeded(int limit) {
    return '친구는 최대 $limit명까지예요.';
  }

  @override
  String get errorFriendNoTodayPost => '친구가 아직 오늘의 포스트를 공유하지 않았어요.';

  @override
  String get errorLunaInsufficient => '루나가 부족해요.';

  @override
  String get errorStoreProductNotFound => '존재하지 않는 상품이에요.';

  @override
  String get errorStoreProductInvalid => '상품 구성이 잘못됐어요.';

  @override
  String get errorStoreBoostNone => '보유한 부스트가 없어요.';

  @override
  String get errorStoreBoostAlreadyActive => '이미 사용 중인 부스트예요.';

  @override
  String get errorStoreAlreadySubscribed => '이미 프라임을 구독 중이에요.';

  @override
  String get errorStoreNotSubscribed => '구독 중이 아니에요.';

  @override
  String get errorStoreAlreadyCanceled => '이미 자동 갱신을 해지했어요.';

  @override
  String get errorStoreReceiptInvalid => '결제 정보를 확인할 수 없어요.';

  @override
  String get errorStorePurchaseFailed => '지금은 결제를 처리할 수 없어요.';

  @override
  String get errorModerationSelf => '자기 자신은 대상이 될 수 없어요.';

  @override
  String get errorTargetBlockedOrReported => '지금은 이 사용자에게 요청할 수 없어요.';

  @override
  String get errorNetworkTimeout => '서버 응답이 늦어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorNetworkUnreachable => '서버에 연결할 수 없어요. 네트워크를 확인해 주세요.';

  @override
  String get errorNetworkUnknown => '통신 중 문제가 발생했어요.';

  @override
  String get errorSocketDisconnected => '연결이 끊겼어요. 잠시 후 다시 보내주세요.';

  @override
  String get errorSocketSendTimeout => '메시지를 보내지 못했어요. 다시 시도해 주세요.';

  @override
  String get errorUnknown => '요청을 처리하지 못했어요.';

  @override
  String regionLabelFormat(String country, String city) {
    return '$country, $city';
  }

  @override
  String get voiceStop => '녹음 정지';

  @override
  String get voicePlay => '미리 듣기';

  @override
  String get voiceDelete => '녹음 삭제';

  @override
  String get voiceSend => '메시지 올리기';

  @override
  String get voiceRecord => '음성 메시지';

  @override
  String get voicePermissionDenied => '마이크 권한이 필요해요. 설정에서 허용해 주세요.';

  @override
  String get errorChatVoiceKeyRequired => '음성 파일이 업로드되지 않았어요.';

  @override
  String get errorChatVoiceKeyInvalid => '잘못된 음성 파일이에요.';

  @override
  String errorChatVoiceTooLong(String seconds) {
    return '음성 메시지는 최대 $seconds초까지예요.';
  }

  @override
  String get chatRoomsVoicePreview => '음성 메시지';
}
