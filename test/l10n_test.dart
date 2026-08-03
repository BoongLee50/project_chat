// 다국어 자원 회귀 테스트.
//
// 화면을 띄우지 않고 L10n 인스턴스를 직접 만들어 검사한다. 화면 테스트는
// 문구가 바뀔 때마다 같이 깨지지만, 여기서 보는 건 **자원 자체의 건전성**이다.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_chat/core/error/api_exception.dart';
import 'package:project_chat/core/error/error_messages.dart';
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

  test('서버 ErrorCode가 전부 클라 매핑에 있다', () {
    // 서버에 코드를 추가하고 클라 매핑을 잊으면 일본어 사용자에게
    // 한국어 문장이 그대로 나간다. 두 쪽이 어긋나는 걸 잡는 유일한 장치다.
    final codes = _serverErrorCodes();
    expect(codes, isNotEmpty, reason: '서버 ErrorCode.java를 읽지 못했다');

    // 폴백 전용 코드는 매핑하지 않는 게 정상이다.
    const fallbackOnly = {'VALIDATION_FAILED', 'NOT_FOUND', 'INTERNAL_ERROR'};

    final unmapped = <String>[];
    for (final code in codes.difference(fallbackOnly)) {
      final mapped = errorMessage(ko, ApiException(message: _rawMarker, code: code));
      if (mapped == _rawMarker) unmapped.add(code);
    }
    expect(unmapped, isEmpty, reason: '클라 매핑이 없어 서버 문장이 그대로 나간다');
  });

  test('오류 문구도 언어를 따라간다', () {
    const e = ApiException(message: '이미 친구예요.', code: 'FRIEND_ALREADY');
    expect(errorMessage(ko, e), '이미 친구예요.');
    expect(errorMessage(ja, e), 'すでに友だちです。');
  });

  test('친구 한도는 서버가 준 숫자로 조립된다', () {
    // 일본어는 어순이 달라 문자열 이어붙이기로는 성립하지 않는다.
    const e = ApiException(
      message: '친구는 최대 30명까지예요.',
      code: 'FRIEND_LIMIT_EXCEEDED',
      field: '30',
    );
    expect(errorMessage(ko, e), contains('30'));
    expect(errorMessage(ja, e), contains('30'));
    expect(errorMessage(ja, e), contains('友だち'));
  });
}

/// 매핑이 걸리지 않았을 때만 화면에 나가는 값. 이 문자열이 그대로 돌아오면
/// 해당 코드는 아직 ARB로 옮겨지지 않았다는 뜻이다.
const _rawMarker = '__RAW__';

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

/// 서버 `ErrorCode` enum의 값들. 서버 파일을 직접 읽어 비교하므로
/// 서버에 코드를 추가하고 클라 매핑을 잊으면 여기서 걸린다.
///
/// (서버가 별도 프로젝트라 코드 공유가 안 된다 — 파일을 읽는 게
/// 두 쪽이 어긋나는 걸 잡는 유일한 방법이다.)
Set<String> _serverErrorCodes() {
  final file = File(
    'server/src/main/java/com/moonlighttalk/server/common/response/ErrorCode.java',
  );
  if (!file.existsSync()) return {};

  final body = file.readAsStringSync();
  final start = body.indexOf('{', body.indexOf('enum ErrorCode'));
  final end = body.lastIndexOf('}');
  if (start < 0 || end <= start) return {};

  return RegExp(r'^\s*([A-Z][A-Z0-9_]*)\s*,?\s*$', multiLine: true)
      .allMatches(body.substring(start + 1, end))
      .map((m) => m.group(1)!)
      .toSet();
}
