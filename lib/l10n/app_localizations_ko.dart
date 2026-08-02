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
  String get homeUploadRemaining => '포스트 등록 남은 시간';

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
  String get homeGateClosed => '지금은 포스트를 등록할 수 있는 시간이 아니에요.';

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
  String get homeBoost => '부스트';

  @override
  String get homeBoostActive => '부스트 사용 중';

  @override
  String homeBoostStock(int count) {
    return '보유 $count매';
  }

  @override
  String get homeOneLiner => '하루 한 마디';

  @override
  String get homeOneLinerHint => '오늘의 기분을 한 줄로 남겨보세요';

  @override
  String get homeOneLinerEmpty => '하루 한 마디를 입력해 주세요.';

  @override
  String get homeOneLinerWrite => '작성';

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
  String get gardenSpotlight => '스포트라이트';

  @override
  String get gardenLoadFailed => '피드를 불러오지 못했어요.';

  @override
  String get gardenEmptyTitle => '지금은 보여줄 포스트가 없어요.';

  @override
  String get gardenEmptyDetail => '필터를 바꾸거나 잠시 후 다시 확인해 주세요.';

  @override
  String get gardenGateTitle => '달빛가든은 아직 문을 열지 않았어요.';

  @override
  String get gardenGateDescription =>
      '달빛이 찾아오는 오후 5시부터\n다음날 오전 6시까지 이용할 수 있어요.';

  @override
  String gardenChatRequestTitle(String nickname) {
    return '$nickname님에게 대화 신청';
  }

  @override
  String get gardenChatRequestHint => '첫 인사를 남겨보세요 (최대 100자)';

  @override
  String get gardenChatRequestSent => '대화 신청을 보냈어요. 상대의 응답을 기다려 주세요.';

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
  String get gateOpensIn => '문 열리기까지';

  @override
  String gateOpensAfter(String remaining) {
    return '$remaining 뒤에 열려요.';
  }

  @override
  String durationHourMinute(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String durationMinuteSecond(int minutes, int seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String durationSecond(int seconds) {
    return '$seconds초';
  }

  @override
  String get chatRoomsTitle => '대화방';

  @override
  String get chatRoomsSubtitle => '마음이 통하는 사람들과 이야기를 나눠보세요.';

  @override
  String get chatTabMatch => '매칭 대화';

  @override
  String get chatTabFriend => '친구';

  @override
  String get chatTabReceived => '받은 신청';

  @override
  String get chatTabSent => '보낸 신청';

  @override
  String get chatRoomsEmpty => '아직 대화가 없어요.\n달빛가든에서 마음에 드는 사람에게 말을 걸어보세요.';

  @override
  String get chatRoomsEmptySent => '보낸 대화 신청이 없어요.';

  @override
  String get chatRoomsStart => '대화를 시작해보세요.';

  @override
  String get chatRoomsOngoing => '대화 중';

  @override
  String get chatGateClosed =>
      '지금은 매칭 대화를 나눌 수 있는 시간이 아니에요.\n친구와의 대화는 언제든 가능해요.';

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
}
