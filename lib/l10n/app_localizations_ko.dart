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
  String get commonBack => '뒤로';

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
  String get homeMainPhoto => 'TOP';

  @override
  String get homeSetMainPhoto => 'TOP';

  @override
  String get homeMainPhotoSet => 'TOP 사진으로 지정했어요.';

  @override
  String get homeDeletePhotoConfirm => '이 사진을 삭제할까요?';

  @override
  String get homeSharePostConfirm => '예쁘게 완성된 포스트를 공유해 볼까요?';

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
  String get homeShareAgain => '다시 공유';

  @override
  String get homeShared => '포스트를 공유했어요 🌙';

  @override
  String get homeBuy => '구매';

  @override
  String get homeBoostReady => '가능';

  @override
  String homeBoostRemaining(int minutes) {
    return '$minutes분';
  }

  @override
  String homePassRemainingDays(int days) {
    return '$days일';
  }

  @override
  String get homePick => 'PICK';

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
  String get gardenChatRequestHint => '첫 인사를 남겨보세요';

  @override
  String get gardenChatRequestSent => '대화 신청을 보냈어요. 상대의 응답을 기다려 주세요.';

  @override
  String get gardenChatRequestShort => '대화 신청';

  @override
  String gardenChatRequestPrompt(String nickname) {
    return '$nickname님에게 대화를 신청해 보세요.\n상대방이 수락해야 대화를 시작할 수 있어요.';
  }

  @override
  String gardenChatRequestFree(int count) {
    return '대화 신청 (무료 $count회)';
  }

  @override
  String gardenChatRequestCost(int luna) {
    return '대화 신청 (루나 $luna)';
  }

  @override
  String gardenChatRequestFreeNotice(int count) {
    return '처음 $count회까지는 무료로 대화 신청 가능해요.';
  }

  @override
  String gardenChatRequestCostNotice(int luna) {
    return '이후 대화는 $luna 루나가 필요해요. ✨';
  }

  @override
  String get gardenChatRequestPrimeNotice => 'Prime 구독 시 대화 신청 무제한!';

  @override
  String get gardenChatRequestUnlimited => '대화 신청을 무제한으로 보낼 수 있어요.';

  @override
  String get gardenChatRequestSentTitle => '대화 신청을 보냈어요! ✨';

  @override
  String get gardenChatRequestWhere =>
      '상대방의 수락 여부는 하단 메뉴 \'대화방 > 받은 신청\'에서 확인할 수 있어요.';

  @override
  String gardenPhotoLockedTitle(int count) {
    return '사진 $count장이 더 있어요';
  }

  @override
  String get gardenPhotoLockedBody => '오늘 내 포스트를 공유하면 상대의 사진을 모두 볼 수 있어요.';

  @override
  String get gardenPhotoLockedAction => '내 포스트 등록하기';

  @override
  String get dailyTitle => '달빛 한마디';

  @override
  String get dailyTodayQuestion => '오늘의 질문';

  @override
  String get dailyRemaining => '남은시간';

  @override
  String get dailyJoin => '참여하기';

  @override
  String get dailySortLatest => '최신';

  @override
  String get dailySortPopular => '인기';

  @override
  String get dailyMine => '내 한마디';

  @override
  String get dailyMineEmpty => '아직 작성한 내 한마디가 없어요. 오늘의 질문에 답해 보세요.';

  @override
  String get dailyWriteTitle => '내 한마디 등록';

  @override
  String get dailyWriteHint => '여기에 당신의 이야기를\n자유롭게 남겨주세요.';

  @override
  String get dailyWriteImage => '사진 추가 (선택 사항)';

  @override
  String get dailyWriteSubmit => '등록하기';

  @override
  String get dailyEmpty => '아직 한마디가 없어요. 첫 번째로 답해 보세요.';

  @override
  String get dailyLoadFailed => '달빛 한마디를 불러오지 못했어요.';

  @override
  String get dailyDetailTitle => '내 달빛 한마디';

  @override
  String get dailyWriteEmpty => '답변을 입력해 주세요.';

  @override
  String get dailyWriteUploading => '사진을 올리는 중이에요. 잠시만 기다려 주세요.';

  @override
  String get dailyViewOriginal => '원문보기';

  @override
  String get dailyCommentHint => '메시지를 입력해 주세요';

  @override
  String get dailyCommentPhotoTitle => '사진 1/1';

  @override
  String get dailyCommentPhotoAttached => '사진이 첨부되었습니다.';

  @override
  String get dailyCommentSend => '보내기';

  @override
  String get dailyLike => '좋아요';

  @override
  String get dailyPhotoSheetTitle => '한마디 사진 등록';

  @override
  String get dailyPhotoSheetSubtitle => '오늘의 질문에 어울리는 사진 한 장을 남겨보세요.';

  @override
  String commentsTitle(String nickname) {
    return '$nickname님의 포스트';
  }

  @override
  String get commentsSection => '댓글';

  @override
  String get commentsHint => '따뜻한 댓글을 남겨보세요 😊';

  @override
  String get commentsHintOwnPost => '댓글을 눌러 답글 달기';

  @override
  String commentsCount(int count) {
    return '댓글 $count';
  }

  @override
  String get commentsSend => '등록';

  @override
  String get commentsMore => '더보기';

  @override
  String get commentsEmpty => '첫 댓글을 남겨보세요.';

  @override
  String get commentsLoadFailed => '댓글을 불러오지 못했어요.';

  @override
  String get commentsReply => '답글';

  @override
  String commentsReplyingTo(String name) {
    return '$name님에게 답글 남기는 중';
  }

  @override
  String get commentsCancelReply => '답글 취소';

  @override
  String get commentsAttachImage => '사진 첨부';

  @override
  String get commentsImageAttached => '사진 1장 첨부됨';

  @override
  String get commentsRemoveImage => '첨부 사진 삭제';

  @override
  String get commentsImageViewer => '첨부 사진';

  @override
  String get chatRoomsTitle => '대화방';

  @override
  String get chatRoomsSubtitle => '마음이 통하는 사람들과 이야기를 나눠보세요.';

  @override
  String get chatTabFriend => '친구';

  @override
  String get chatTabReceived => '받은 신청';

  @override
  String get chatTabChats => '대화';

  @override
  String get chatRequestsEmpty => '받은 신청이 없어요.';

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
  String get chatSlogan => '작은 배려, 아름다운 대화';

  @override
  String get chatGifNotReady => 'GIF 검색은 아직 준비 중이에요.';

  @override
  String get chatLeaveConfirm => '대화방을 나가면 대화 내용이 모두 사라지고 되돌릴 수 없어요. 나갈까요?';

  @override
  String get chatInputHint => '메시지를 입력해 주세요';

  @override
  String get chatMenuProfile => '프로필 보기';

  @override
  String get chatMenuFriendRequest => '친구 신청';

  @override
  String get chatMenuReport => '신고하기';

  @override
  String get chatMenuBlock => '차단하기';

  @override
  String get chatMenuLeave => '대화방 나가기';

  @override
  String get chatTranslatePass => '번역';

  @override
  String get chatTranslateUnlimited => '무제한';

  @override
  String get chatDateToday => '오늘';

  @override
  String get chatDateYesterday => '어제';

  @override
  String get translateNotReady => '준비 중';

  @override
  String translateFreeLeft(int count) {
    return '무료 $count회';
  }

  @override
  String translateHours(int hours) {
    return '$hours시간';
  }

  @override
  String get translateCommentExhausted =>
      '무료 번역을 모두 사용했어요. 번역 기능을 계속 사용하시려면 자동 번역 패스를 이용해 주세요.';

  @override
  String get translateRoomExhausted =>
      '무료 번역 대화방을 모두 사용했어요. PRIME 구독 시 모든 대화에서 자동 번역을 이용할 수 있어요.';

  @override
  String get translateProviderNotReady => '번역 기능은 아직 준비 중이에요.';

  @override
  String get voiceQuotaExhausted =>
      '무료 음성 메시지를 모두 사용했어요.\nPRIME 구독 시 음성 메시지를 계속 이용할 수 있어요.';

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
  String get friendsTabList => '친구 목록';

  @override
  String get friendsRequestsEmpty => '받은 친구 신청이 없어요.';

  @override
  String friendsLastSeen(String time) {
    return '$time 접속';
  }

  @override
  String get friendsNeverSeen => '접속 기록 없음';

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
  String get friendMenuPin => '목록 상단 고정';

  @override
  String get friendMenuUnpin => '상단 고정 해제';

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
  String get friendRequestTitle => '친구 신청';

  @override
  String friendRequestPrompt(String nickname, int max) {
    return '$nickname님에게 친구 신청과 함께\n메시지를 보내세요. (최대 $max자)';
  }

  @override
  String get friendRequestHint => '메시지를 입력하세요 (선택)';

  @override
  String get friendRequestNotice => '상대방이 친구 신청을 수락해야 친구가 될 수 있습니다.';

  @override
  String get friendRequestIncomingTitle => '친구 신청이 도착했어요';

  @override
  String friendRequestIncomingBody(String nickname) {
    return '$nickname님과 한 걸음 더 가까워져 보세요.\n친구가 되면 서로의 최신 포스트를 만나고,\n언제든지 편하게 이야기를 나눌 수 있어요.';
  }

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
  String get postInfoMenuProfile => '프로필 보기';

  @override
  String get postInfoMenuUnfriend => '친구 해제';

  @override
  String get postInfoLoadFailed => '상대 정보를 불러오지 못했어요.';

  @override
  String get postInfoNoPost => '오늘 올린 포스트가 없어요.';

  @override
  String get postInfoChat => '대화하기';

  @override
  String get postInfoRequestChat => '대화 신청';

  @override
  String get postInfoFriendAdd => '친구 신청';

  @override
  String get postInfoFriendPending => '신청 대기';

  @override
  String get postInfoFriendIncoming => '친구 수락';

  @override
  String get postInfoFriendLabel => '친구';

  @override
  String postInfoProfileTitle(String nickname) {
    return '$nickname님의 프로필';
  }

  @override
  String get postInfoRegions => '활동 지역';

  @override
  String get profileTitle => '프로필';

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
  String get profilePrimeBenefitTranslate => '자동 번역 무제한';

  @override
  String get profileIntro => '소개 한마디';

  @override
  String get profileInterests => '관심사';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get profileCreatePhotoDesc => '얼굴 사진과 나를 표현할 사진 한 장씩을 담아 주세요.';

  @override
  String get profileCreateIntroDesc => '당신에 대해 간단히 소개해 주세요.';

  @override
  String get profileCreateIntroHint => '취미나 관심사, 좋아하는 것 등을 알려 주세요.';

  @override
  String profileCreateInterestsDesc(int max) {
    return '내가 좋아하는 것들을 최대 $max개까지 선택해 주세요.';
  }

  @override
  String get profileCreateRegionDesc => '내가 주로 활동하고 있는 지역을 선택해 주세요.';

  @override
  String profileIntroLimit(int max) {
    return '자기소개 작성은 최대 $max자까지만 입력할 수 있어요.';
  }

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
    return '관심사 등록은 $max개까지만 선택할 수 있습니다.';
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
    return '지역 선택은 $max군데만 선택할 수 있습니다.';
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
  String get lunaStoreSubtitle => '루나로 더 편리하고 특별한 경험을 누려 보세요.';

  @override
  String get lunaShopDescBoost =>
      '포스트에 추천 마크를 붙이고\n1시간 동안 우선 노출해요.\n더 많은 관심과 매칭 기회를\n만나 보세요.';

  @override
  String lunaShopDescAlbum(int count) {
    return '포스트 사진을 최대 $count장까지\n등록하고 무지개빛 테두리로\n꾸며 보세요. 모든 포스트를\n제한없이 감상해 보세요.';
  }

  @override
  String get lunaShopDescTrans =>
      '언어 걱정 없이 대화와\n댓글을 자동으로 번역해요.\n정해진 기간 동안\n편리하게 이용해 보세요.';

  @override
  String get lunaItemBoost => '포스트 부스트';

  @override
  String get lunaItemAlbum => '포스트 앨범 패스';

  @override
  String get lunaItemTrans => '자동 번역';

  @override
  String lunaItemCount(String item, int count) {
    return '$item $count개';
  }

  @override
  String lunaItemDays(String item, int days) {
    return '$item $days일';
  }

  @override
  String get lunaPurchasedTitle => '구매가 완료되었어요!';

  @override
  String lunaRemainDays(int days) {
    return '$days일';
  }

  @override
  String lunaRemainMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get lunaBenefitHeadBoost => '포스트 부스트 혜택 (1시간)';

  @override
  String get lunaBenefitHeadAlbum => '포스트 앨범 패스 혜택';

  @override
  String get lunaBenefitHeadTrans => '자동 번역 혜택';

  @override
  String get lunaBoostBenefit1 => '포스트 사진 우선 노출';

  @override
  String get lunaBoostBenefit1Desc => '포스트 사진을 1시간 동안 더 많은 사람에게\n우선적으로 노출해요.';

  @override
  String get lunaBoostBenefit2 => '포스트 사진에 추천 마크(PICK) 표시';

  @override
  String get lunaBoostBenefit2Desc =>
      '자신의 포스트 사진에 특별한 추천 마크(PICK)\n가 표시되어 더 눈에 띄게 노출돼요.';

  @override
  String get lunaBoostBenefit3 => '더 많은 관심과 반응 확보';

  @override
  String get lunaBoostBenefit3Desc =>
      '포스트가 더 많은 사람에게 노출되어, 더 많은\n관심과 반응을 받을 기회가 늘어나요.';

  @override
  String lunaAlbumBenefit1(int count) {
    return '포스트 사진 최대 $count장 등록';
  }

  @override
  String lunaAlbumBenefit1Desc(int count) {
    return '하나의 포스트에 사진을 최대 $count장까지 등록해\n더 풍성하게 일상을 공유해 보세요.';
  }

  @override
  String get lunaAlbumBenefit2 => '무지개빛 사진 테두리';

  @override
  String get lunaAlbumBenefit2Desc =>
      '포스트 사진 테두리를 아름다운 무지개빛으로\n꾸며 나만의 포스트를 완성해 보세요.';

  @override
  String get lunaAlbumBenefit3 => '모든 포스트 제한 없이 열람';

  @override
  String get lunaAlbumBenefit3Desc =>
      '다른 사람들이 올린 모든 포스트를 제한 없이\n열람하고 다양한 일상을 감상할 수 있어요.';

  @override
  String get lunaTransBenefit1 => '대화 자동 번역';

  @override
  String get lunaTransBenefit1Desc =>
      '채팅 내용을 원하는 언어로 자동 번역해\n언어가 달라도 편리하게 대화할 수 있어요.';

  @override
  String get lunaTransBenefit2 => '댓글 자동 번역';

  @override
  String get lunaTransBenefit2Desc => '포스트 댓글도 자동으로 번역해\n다른 사람들의 이야기를 쉽게 이해해요.';

  @override
  String get lunaTransBenefit3 => '언어 걱정 없는 소통';

  @override
  String get lunaTransBenefit3Desc =>
      '번역 기능으로 한국어와 일본어 대화를\n더 편리하고 자연스럽게 이어가 보세요.';

  @override
  String get chargeTag1 => '부담 없이 루나를 시작해 보세요';

  @override
  String get chargeTag2 => '대화의 즐거움을 한층 더 풍성하게!';

  @override
  String get chargeTag3 => '가장 많이 선택하는 인기 충전 상품';

  @override
  String get chargeTag4 => '자주 이용할수록 더욱 실속 있는 선택!';

  @override
  String get chargeTag5 => '루나를 가장 실속 있게 충전하는 방법!';

  @override
  String chargePrice(String price) {
    return '₩$price';
  }

  @override
  String chargeDiscountPercent(int percent) {
    return '$percent%';
  }

  @override
  String get storeLoadFailed => '상품을 불러오지 못했어요.';

  @override
  String storeDiscount(int percent) {
    return '$percent% 할인';
  }

  @override
  String boostStock(int count) {
    return '보유 $count매';
  }

  @override
  String get boostEffectTitle => '예상 효과';

  @override
  String get boostUsed => '부스트를 사용했어요. 1시간 동안 우선 노출됩니다!';

  @override
  String get passPeriodSection => '기간 선택';

  @override
  String passDays(int days) {
    return '$days일';
  }

  @override
  String get primePlanSection => '요금제 선택하기';

  @override
  String get primeStarted => 'PRIME 멤버십이 시작됐어요!';

  @override
  String get primeCancelDone => '자동 갱신을 해지했어요.';

  @override
  String get commonUnsubscribe => '해지';

  @override
  String get primeBenefitsSection => 'PRIME 혜택';

  @override
  String get primeSubscriptionNotice =>
      '구독 서비스는 동일한 기간, 동일한 가격으로 자동 갱신되며,\n회원님이 언제든 구독을 해지할 수 있습니다.';

  @override
  String get primeSubInfoSection => '구독 정보';

  @override
  String primeProductName(int months) {
    return 'PRIME $months개월';
  }

  @override
  String get primeInfoPrice => '구독 요금';

  @override
  String get primeInfoStart => '구독 시작일';

  @override
  String get primeInfoNextBilling => '다음 결제일';

  @override
  String get primeInfoEndDate => '이용 종료일';

  @override
  String primeMonthlyPrice(String price) {
    return '월 $price원';
  }

  @override
  String primeBuyPrice(String price) {
    return '₩$price';
  }

  @override
  String get primeManageNotice =>
      '구독을 해지해도 현재 구독 기간까지\nPRIME 혜택을 계속 이용할 수 있습니다.';

  @override
  String primeCanceledNotice(String date) {
    return '$date까지 프라임 멤버십 혜택을 이용할 수 있으며,\n이후에는 자동으로 일반 회원으로 전환됩니다.';
  }

  @override
  String get primeCancelTitle => '프라임 구독을 해지할까요?';

  @override
  String primeCancelBody(String date) {
    return '해지 신청 시 다음 결제일부터\n자동 결제가 진행되지 않으며,\n현재 구독 기간인 $date까지는\n프라임 혜택을 계속 이용할 수 있습니다.';
  }

  @override
  String get primeResumeDone => '해지 신청을 취소했어요. 다음 결제일에 자동 갱신돼요.';

  @override
  String get primeBenefitAlbum => '포스트 앨범 패스 무제한';

  @override
  String get primeBenefitAlbumDesc => '구독 기간 동안 포스트 앨범을 제한 없이\n이용할 수 있어요.';

  @override
  String primeBenefitBoost(int count) {
    return '매달 포스트 부스트 $count개';
  }

  @override
  String get primeBenefitBoostDesc => '포스트를 1시간 동안 더 많은 사람에게\n우선적으로 노출해요.';

  @override
  String get primeBenefitChat => '대화 신청 무제한';

  @override
  String get primeBenefitChatDesc => '마음에 드는 상대에게 제한 없이 대화를 신청해요.';

  @override
  String get primeBenefitTranslate => '자동 번역 무제한';

  @override
  String get primeBenefitTranslateDesc => '채팅과 댓글을 편리하게 번역해 소통해요.';

  @override
  String get primeBenefitNoAds => '광고 제거';

  @override
  String get primeBenefitNoAdsDesc => '앱 이용 중 표시되는 광고가 제거돼요.';

  @override
  String get chargeTitle => '루나 충전';

  @override
  String get chargeSubtitle => '루나를 충전하고, 풍성한 혜택과 특별한 경험을 만나 보세요.';

  @override
  String get chargeLunaPrefix => '루나 ';

  @override
  String get chargeLunaSuffix => '개';

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
  String get errorPostPhotoRequired => '포스트 사진을 등록해 주세요.';

  @override
  String get errorPostPhotoNotFound => '사진을 찾을 수 없어요.';

  @override
  String get errorPostPhotoNotMine => '내 사진만 삭제할 수 있어요.';

  @override
  String errorPostPhotoLimit(int count) {
    return '사진은 최대 $count장까지 등록할 수 있어요. 기존 사진을 먼저 삭제해 주세요.';
  }

  @override
  String get errorPostPhotoLocked => '잠긴 사진이에요. 포스트 앨범 패스를 이용하면 다시 쓸 수 있어요.';

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
  String errorCommentTooLong(int count) {
    return '댓글은 $count자까지 입력할 수 있어요.';
  }

  @override
  String errorCommentDepthExceeded(int count) {
    return '답글은 $count단계까지만 달 수 있어요.';
  }

  @override
  String get errorCommentParentNotFound => '답글을 달 댓글을 찾을 수 없어요.';

  @override
  String get errorCommentImageKeyInvalid => '첨부한 사진이 올바르지 않아요. 다시 선택해 주세요.';

  @override
  String get errorCommentReplyNotAllowed =>
      '답글은 글쓴이와 댓글을 단 사람이 번갈아 주고받을 수 있어요.';

  @override
  String get errorCommentAlreadyReplied =>
      '이 댓글에는 이미 답글이 있어요. 댓글 하나에 답글은 하나씩만 달 수 있어요.';

  @override
  String get errorCommentOwnPost =>
      '내 포스트에는 댓글을 달 수 없어요. 받은 댓글을 눌러 답글을 남겨 보세요.';

  @override
  String get errorDailyQuestionNotReady => '오늘의 질문이 아직 준비되지 않았어요.';

  @override
  String get errorDailyAnswerNotFound => '한마디를 찾을 수 없어요.';

  @override
  String get errorDailyAnswerAlready => '오늘은 이미 한마디를 남겼어요.';

  @override
  String errorDailyAnswerTooLong(int count) {
    return '$count자까지 입력할 수 있어요.';
  }

  @override
  String get errorDailyAnswerImageKeyInvalid => '첨부한 사진이 올바르지 않아요. 다시 선택해 주세요.';

  @override
  String get errorDailyAnswerSelfLike => '내 한마디에는 좋아요를 누를 수 없어요.';

  @override
  String get errorDailyAnswerSelfComment =>
      '내 한마디에는 먼저 댓글을 달 수 없어요. 다른 사람의 댓글에 답글로 이야기해 보세요.';

  @override
  String get errorTranslateQuotaExceeded =>
      '무료 번역을 모두 사용했어요. 자동 번역 패스를 이용해 보세요.';

  @override
  String get errorTranslateTargetRequired => '번역할 상대를 지정해 주세요.';

  @override
  String get errorChatSelf => '자신에게는 대화를 신청할 수 없어요.';

  @override
  String get errorChatTargetBlocked => '지금은 이 사용자에게 대화를 신청할 수 없어요.';

  @override
  String get errorChatRequestPending => '이미 대화를 신청했어요. 상대의 응답을 기다려 주세요.';

  @override
  String errorChatRequestRejectedCooldown(int hours) {
    return '거절된 상대예요. $hours시간 뒤에 다시 신청할 수 있어요.';
  }

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
  String get errorStoreNotCanceled => '해지 신청한 구독이 아니에요.';

  @override
  String get errorStoreAlreadyOwned => '이미 이용 중인 상품이에요.';

  @override
  String get errorStoreReceiptInvalid => '결제 정보를 확인할 수 없어요.';

  @override
  String get errorStorePurchaseFailed => '지금은 결제를 처리할 수 없어요.';

  @override
  String get errorModerationSelf => '자기 자신은 대상이 될 수 없어요.';

  @override
  String get errorTargetBlockedOrReported => '지금은 이 사용자를 볼 수 없어요.';

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
