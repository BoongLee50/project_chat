// 다국어 자원 회귀 테스트.
//
// 화면을 띄우지 않고 L10n 인스턴스를 직접 만들어 검사한다. 화면 테스트는
// 문구가 바뀔 때마다 같이 깨지지만, 여기서 보는 건 **자원 자체의 건전성**이다.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_chat/features/moderation/data/models/report_reason.dart';
import 'package:project_chat/features/profile/data/models/profile_catalog.dart';
import 'package:project_chat/features/store/data/models/store_models.dart';
import 'package:project_chat/l10n/app_localizations.dart';

void main() {
  late L10n ko;
  late L10n ja;

  setUpAll(() async {
    ko = await L10n.delegate.load(const Locale('ko'));
    ja = await L10n.delegate.load(const Locale('ja'));
  });

  test('지원 언어는 한국어와 일본어다', () {
    expect(
      L10n.supportedLocales.map((l) => l.languageCode).toSet(),
      {'ko', 'ja'},
    );
  });

  test('일본어에 빠진 키가 없다 (있으면 한국어로 폴백돼 섞여 보인다)', () {
    // 폴백은 안전장치일 뿐 정상 상태가 아니다. 같은 값이면 번역이 없다는 뜻.
    // 언어 중립이라 같아도 되는 것만 예외로 둔다.
    const languageNeutral = {'K-POP', 'J-POP'};

    final same = <String>[];
    for (final entry in _samples(ko).entries) {
      final jaValue = _samples(ja)[entry.key]!;
      if (entry.value == jaValue && !languageNeutral.contains(entry.value)) {
        same.add(entry.key);
      }
    }
    expect(same, isEmpty, reason: '일본어 번역이 비어 있는 키: $same');
  });

  test('placeholder가 값을 실제로 끼워 넣는다', () {
    expect(ko.homeAlbumPassRemaining(3), contains('3'));
    expect(ja.homeAlbumPassRemaining(3), contains('3'));
    expect(ko.gardenChatRequestTitle('하늘'), contains('하늘'));
    expect(ja.gardenChatRequestTitle('そら'), contains('そら'));
  });

  test('모델·enum 라벨이 언어를 따라간다', () {
    expect(StoreKind.label(ko, StoreKind.postBoost), '포스트 부스트');
    expect(StoreKind.label(ja, StoreKind.postBoost), 'ポストブースト');

    expect(ReportReason.abusive.label(ko), '욕설 및 비매너');
    expect(ReportReason.abusive.label(ja), '暴言・マナー違反');

    expect(ProfileCatalog.interestLabel(ko, 'TRAVEL'), '여행');
    expect(ProfileCatalog.interestLabel(ja, 'TRAVEL'), '旅行');

    // "한국, 서울" / "韓国、ソウル" — 구분자까지 언어를 탄다.
    expect(ProfileCatalog.regionLabel(ko, 'KR_SEOUL'), '한국, 서울');
    expect(ProfileCatalog.regionLabel(ja, 'KR_SEOUL'), '韓国、ソウル');
  });

  test('카탈로그에 없는 코드는 코드 그대로 보여준다', () {
    // 구버전 앱이 저장한 코드가 내려와도 빈칸이 되지 않아야 한다.
    expect(ProfileCatalog.interestLabel(ko, 'UNKNOWN_CODE'), 'UNKNOWN_CODE');
    expect(ProfileCatalog.regionLabel(ja, 'XX_NOWHERE'), 'XX_NOWHERE');
  });

  test('카탈로그 전 항목에 번역이 있다', () {
    for (final group in ProfileCatalog.interestGroups) {
      expect(ProfileCatalog.groupTitle(ja, group.code), isNot(group.code));
      for (final item in group.items) {
        expect(
          ProfileCatalog.interestLabel(ja, item.code),
          isNot(item.code),
          reason: '${item.code}의 일본어 라벨이 없다',
        );
      }
    }
    for (final items in ProfileCatalog.regionsByCountry.values) {
      for (final item in items) {
        expect(
          ProfileCatalog.cityLabel(ja, item.code),
          isNot(item.code),
          reason: '${item.code}의 일본어 라벨이 없다',
        );
      }
    }
  });
}

/// 언어별로 비교할 대표 문구들. 전 키를 도는 API가 없어 손으로 고른다 —
/// 슬라이스마다 한두 개씩 넣어 두면 통째로 빠뜨린 화면을 잡아낼 수 있다.
Map<String, String> _samples(L10n l) => {
  'loginTagline': l.loginTagline,
  'nicknameTitle': l.nicknameTitle,
  'birthYearTitle': l.birthYearTitle,
  'homeTitle': l.homeTitle,
  'gardenTitle': l.gardenTitle,
  'commentsSection': l.commentsSection,
  'gateOpensIn': l.gateOpensIn,
  'chatRoomsTitle': l.chatRoomsTitle,
  'chatInputHint': l.chatInputHint,
  'friendsTitle': l.friendsTitle,
  'friendPostTitle': l.friendPostTitle,
  'profileTitle': l.profileTitle,
  'interestsEditTitle': l.interestsEditTitle,
  'regionsEditTitle': l.regionsEditTitle,
  'lunaStoreTitle': l.lunaStoreTitle,
  'boostEffectTitle': l.boostEffectTitle,
  'passPeriodSection': l.passPeriodSection,
  'primeTitle': l.primeTitle,
  'chargeTitle': l.chargeTitle,
  'reportAction': l.reportAction,
  'blockAction': l.blockAction,
  'navPost': l.navPost,
  'interestKpop': l.interestKpop,
  'interestTravel': l.interestTravel,
  'cityJpTokyo': l.cityJpTokyo,
};
