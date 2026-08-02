import 'package:flutter/material.dart';

/// 관심사·지역 선택지. (기획서 화면 22·24)
///
/// 서버에는 **코드**를 저장한다(`user_interests.code` / `user_regions.code`).
/// 화면 문구가 바뀌거나 일본어가 추가돼도 저장값이 흔들리지 않게 하려는 것이며,
/// 신고 사유(`ReportReason`)와 같은 방식이다.
///
/// 코드 목록 자체는 아직 서버가 내려주지 않는다. 선택지가 자주 바뀔 성격이면
/// 나중에 카탈로그 API로 옮기면 되고, 그때도 저장된 코드는 그대로 쓸 수 있다.

class InterestItem {
  const InterestItem(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;
}

class InterestGroup {
  const InterestGroup(this.title, this.icon, this.items);

  final String title;
  final IconData icon;
  final List<InterestItem> items;
}

abstract final class ProfileCatalog {
  /// 관심사는 최대 8개(서버 `InterestsRequest`도 8로 검증).
  static const maxInterests = 8;

  /// 활동 지역은 최대 2곳.
  static const maxRegions = 2;

  static const interestGroups = <InterestGroup>[
    InterestGroup('취미', Icons.palette_outlined, [
      InterestItem('TRAVEL', '여행', Icons.flight_takeoff),
      InterestItem('PHOTO', '사진', Icons.photo_camera_outlined),
      InterestItem('ART', '그림/미술', Icons.brush_outlined),
      InterestItem('READING', '독서', Icons.menu_book_outlined),
      InterestItem('MUSIC', '음악', Icons.music_note_outlined),
      InterestItem('MOVIE', '영화', Icons.movie_outlined),
      InterestItem('DRAMA', '드라마', Icons.tv_outlined),
      InterestItem('GAME', '게임', Icons.sports_esports_outlined),
      InterestItem('WORKOUT', '운동', Icons.directions_run),
      InterestItem('COOKING', '요리', Icons.restaurant_outlined),
      InterestItem('CAFE', '카페 탐방', Icons.local_cafe_outlined),
      InterestItem('PET', '반려동물', Icons.pets_outlined),
      InterestItem('CAMPING', '자연/캠핑', Icons.terrain_outlined),
      InterestItem('EXHIBITION', '공연/전시', Icons.confirmation_number_outlined),
      InterestItem('SINGING', '노래/악기', Icons.mic_none_outlined),
    ]),
    InterestGroup('라이프스타일', Icons.spa_outlined, [
      InterestItem('SELF_DEV', '자기계발', Icons.school_outlined),
      InterestItem('FINANCE', '재테크', Icons.trending_up),
      InterestItem('IT', 'IT/기술', Icons.computer_outlined),
      InterestItem('FASHION', '패션', Icons.checkroom_outlined),
      InterestItem('BEAUTY', '뷰티', Icons.face_retouching_natural),
      InterestItem('WELLBEING', '건강/웰빙', Icons.favorite_outline),
      InterestItem('MINIMAL', '정리/미니멀', Icons.inventory_2_outlined),
      InterestItem('SUSTAINABLE', '지속가능성', Icons.eco_outlined),
    ]),
    InterestGroup('문화/엔터테인먼트', Icons.theater_comedy_outlined, [
      InterestItem('KPOP', 'K-POP', Icons.headphones_outlined),
      InterestItem('JPOP', 'J-POP', Icons.headphones),
      InterestItem('ANIME', '애니메이션', Icons.animation),
      InterestItem('WEBTOON', '웹툰/만화', Icons.auto_stories_outlined),
      InterestItem('MUSICAL', '뮤지컬/연극', Icons.theaters_outlined),
      InterestItem('FESTIVAL', '페스티벌', Icons.celebration_outlined),
    ]),
    InterestGroup('스포츠', Icons.sports_soccer, [
      InterestItem('SOCCER', '축구', Icons.sports_soccer),
      InterestItem('BASEBALL', '야구', Icons.sports_baseball),
      InterestItem('BASKETBALL', '농구', Icons.sports_basketball),
      InterestItem('GOLF', '골프', Icons.sports_golf),
      InterestItem('TENNIS', '테니스', Icons.sports_tennis),
      InterestItem('SWIMMING', '수영', Icons.pool_outlined),
      InterestItem('CLIMBING', '등산/클라이밍', Icons.landscape_outlined),
      InterestItem('CYCLING', '자전거', Icons.pedal_bike_outlined),
    ]),
  ];

  /// 코드 → 표시 문구. 서버가 준 코드를 화면에 그릴 때 쓴다.
  static String interestLabel(String code) {
    for (final group in interestGroups) {
      for (final item in group.items) {
        if (item.code == code) return item.label;
      }
    }
    return code; // 카탈로그에 없는 코드(구버전 등)는 코드 그대로 보여준다
  }

  static IconData interestIcon(String code) {
    for (final group in interestGroups) {
      for (final item in group.items) {
        if (item.code == code) return item.icon;
      }
    }
    return Icons.tag;
  }

  // ── 지역 ──────────────────────────────────────────────
  // 코드는 `KR_SEOUL` 형태. 국가 접두사가 있어 목록을 국가별로 나눌 수 있다.

  static const regionsByCountry = <String, List<InterestItem>>{
    'KR': [
      InterestItem('KR_SEOUL', '서울', Icons.location_city),
      InterestItem('KR_BUSAN', '부산', Icons.location_city),
      InterestItem('KR_DAEGU', '대구', Icons.location_city),
      InterestItem('KR_INCHEON', '인천', Icons.location_city),
      InterestItem('KR_GWANGJU', '광주', Icons.location_city),
      InterestItem('KR_DAEJEON', '대전', Icons.location_city),
      InterestItem('KR_ULSAN', '울산', Icons.location_city),
      InterestItem('KR_SEJONG', '세종', Icons.location_city),
      InterestItem('KR_SUWON', '수원', Icons.location_city),
      InterestItem('KR_GOYANG', '고양', Icons.location_city),
      InterestItem('KR_SEONGNAM', '성남', Icons.location_city),
    ],
    'JP': [
      InterestItem('JP_TOKYO', '도쿄', Icons.location_city),
      InterestItem('JP_OSAKA', '오사카', Icons.location_city),
      InterestItem('JP_KYOTO', '교토', Icons.location_city),
      InterestItem('JP_NAGOYA', '나고야', Icons.location_city),
      InterestItem('JP_YOKOHAMA', '요코하마', Icons.location_city),
      InterestItem('JP_FUKUOKA', '후쿠오카', Icons.location_city),
      InterestItem('JP_SAPPORO', '삿포로', Icons.location_city),
      InterestItem('JP_KOBE', '고베', Icons.location_city),
      InterestItem('JP_SENDAI', '센다이', Icons.location_city),
    ],
  };

  static String countryLabel(String code) => switch (code) {
    'KR' => '한국',
    'JP' => '일본',
    _ => code,
  };

  static String countryFlag(String code) => switch (code) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  /// 코드 → "한국, 서울" 형태의 표시 문구.
  static String regionLabel(String code) {
    for (final entry in regionsByCountry.entries) {
      for (final item in entry.value) {
        if (item.code == code) {
          return '${countryLabel(entry.key)}, ${item.label}';
        }
      }
    }
    return code;
  }

  /// 지역 코드가 속한 국가(`KR`/`JP`). 알 수 없으면 null.
  static String? countryOf(String regionCode) {
    for (final entry in regionsByCountry.entries) {
      if (entry.value.any((item) => item.code == regionCode)) return entry.key;
    }
    return null;
  }
}
