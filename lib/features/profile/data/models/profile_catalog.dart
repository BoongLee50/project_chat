import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// 관심사·지역 선택지. (기획서 화면 22·24)
///
/// 서버에는 **코드**를 저장한다(`user_interests.code` / `user_regions.code`).
/// 화면 문구가 바뀌거나 일본어가 추가돼도 저장값이 흔들리지 않게 하려는 것이며,
/// 신고 사유(`ReportReason`)와 같은 방식이다.
///
/// 그래서 이 파일에는 **코드와 아이콘만** 두고, 표시 문구는 전부 ARB에 있다.
/// 관심사 37종·지역 20곳은 UI 문구라기보다 데이터 라벨에 가깝지만,
/// 번역 자원을 ARB 한곳에 모아 두려고 여기 넣었다. 선택지가 자주 바뀔 성격이면
/// 나중에 카탈로그 API로 옮기면 되고, 그때도 저장된 코드는 그대로 쓸 수 있다.

class InterestItem {
  const InterestItem(this.code, this.icon);

  final String code;
  final IconData icon;
}

class InterestGroup {
  const InterestGroup(this.code, this.icon, this.items);

  final String code;
  final IconData icon;
  final List<InterestItem> items;
}

abstract final class ProfileCatalog {
  /// 관심사는 최대 8개(서버 `InterestsRequest`도 8로 검증).
  static const maxInterests = 8;

  /// 활동 지역은 최대 2곳.
  static const maxRegions = 2;

  static const interestGroups = <InterestGroup>[
    InterestGroup('HOBBY', Icons.palette_outlined, [
      InterestItem('TRAVEL', Icons.flight_takeoff),
      InterestItem('PHOTO', Icons.photo_camera_outlined),
      InterestItem('ART', Icons.brush_outlined),
      InterestItem('READING', Icons.menu_book_outlined),
      InterestItem('MUSIC', Icons.music_note_outlined),
      InterestItem('MOVIE', Icons.movie_outlined),
      InterestItem('DRAMA', Icons.tv_outlined),
      InterestItem('GAME', Icons.sports_esports_outlined),
      InterestItem('WORKOUT', Icons.directions_run),
      InterestItem('COOKING', Icons.restaurant_outlined),
      InterestItem('CAFE', Icons.local_cafe_outlined),
      InterestItem('PET', Icons.pets_outlined),
      InterestItem('CAMPING', Icons.terrain_outlined),
      InterestItem('EXHIBITION', Icons.confirmation_number_outlined),
      InterestItem('SINGING', Icons.mic_none_outlined),
    ]),
    InterestGroup('LIFESTYLE', Icons.spa_outlined, [
      InterestItem('SELF_DEV', Icons.school_outlined),
      InterestItem('FINANCE', Icons.trending_up),
      InterestItem('IT', Icons.computer_outlined),
      InterestItem('FASHION', Icons.checkroom_outlined),
      InterestItem('BEAUTY', Icons.face_retouching_natural),
      InterestItem('WELLBEING', Icons.favorite_outline),
      InterestItem('MINIMAL', Icons.inventory_2_outlined),
      InterestItem('SUSTAINABLE', Icons.eco_outlined),
    ]),
    InterestGroup('CULTURE', Icons.theater_comedy_outlined, [
      InterestItem('KPOP', Icons.headphones_outlined),
      InterestItem('JPOP', Icons.headphones),
      InterestItem('ANIME', Icons.animation),
      InterestItem('WEBTOON', Icons.auto_stories_outlined),
      InterestItem('MUSICAL', Icons.theaters_outlined),
      InterestItem('FESTIVAL', Icons.celebration_outlined),
    ]),
    InterestGroup('SPORTS', Icons.sports_soccer, [
      InterestItem('SOCCER', Icons.sports_soccer),
      InterestItem('BASEBALL', Icons.sports_baseball),
      InterestItem('BASKETBALL', Icons.sports_basketball),
      InterestItem('GOLF', Icons.sports_golf),
      InterestItem('TENNIS', Icons.sports_tennis),
      InterestItem('SWIMMING', Icons.pool_outlined),
      InterestItem('CLIMBING', Icons.landscape_outlined),
      InterestItem('CYCLING', Icons.pedal_bike_outlined),
    ]),
  ];

  static String groupTitle(L10n l10n, String code) => switch (code) {
    'HOBBY' => l10n.interestGroupHobby,
    'LIFESTYLE' => l10n.interestGroupLifestyle,
    'CULTURE' => l10n.interestGroupCulture,
    'SPORTS' => l10n.interestGroupSports,
    _ => code,
  };

  /// 코드 → 표시 문구. 서버가 준 코드를 화면에 그릴 때 쓴다.
  ///
  /// 카탈로그에 없는 코드(구버전 등)는 코드 그대로 보여준다 — 빈칸보다는 낫다.
  static String interestLabel(L10n l10n, String code) => switch (code) {
    'TRAVEL' => l10n.interestTravel,
    'PHOTO' => l10n.interestPhoto,
    'ART' => l10n.interestArt,
    'READING' => l10n.interestReading,
    'MUSIC' => l10n.interestMusic,
    'MOVIE' => l10n.interestMovie,
    'DRAMA' => l10n.interestDrama,
    'GAME' => l10n.interestGame,
    'WORKOUT' => l10n.interestWorkout,
    'COOKING' => l10n.interestCooking,
    'CAFE' => l10n.interestCafe,
    'PET' => l10n.interestPet,
    'CAMPING' => l10n.interestCamping,
    'EXHIBITION' => l10n.interestExhibition,
    'SINGING' => l10n.interestSinging,
    'SELF_DEV' => l10n.interestSelfDev,
    'FINANCE' => l10n.interestFinance,
    'IT' => l10n.interestIt,
    'FASHION' => l10n.interestFashion,
    'BEAUTY' => l10n.interestBeauty,
    'WELLBEING' => l10n.interestWellbeing,
    'MINIMAL' => l10n.interestMinimal,
    'SUSTAINABLE' => l10n.interestSustainable,
    'KPOP' => l10n.interestKpop,
    'JPOP' => l10n.interestJpop,
    'ANIME' => l10n.interestAnime,
    'WEBTOON' => l10n.interestWebtoon,
    'MUSICAL' => l10n.interestMusical,
    'FESTIVAL' => l10n.interestFestival,
    'SOCCER' => l10n.interestSoccer,
    'BASEBALL' => l10n.interestBaseball,
    'BASKETBALL' => l10n.interestBasketball,
    'GOLF' => l10n.interestGolf,
    'TENNIS' => l10n.interestTennis,
    'SWIMMING' => l10n.interestSwimming,
    'CLIMBING' => l10n.interestClimbing,
    'CYCLING' => l10n.interestCycling,
    _ => code,
  };

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
      InterestItem('KR_SEOUL', Icons.location_city),
      InterestItem('KR_BUSAN', Icons.location_city),
      InterestItem('KR_DAEGU', Icons.location_city),
      InterestItem('KR_INCHEON', Icons.location_city),
      InterestItem('KR_GWANGJU', Icons.location_city),
      InterestItem('KR_DAEJEON', Icons.location_city),
      InterestItem('KR_ULSAN', Icons.location_city),
      InterestItem('KR_SEJONG', Icons.location_city),
      InterestItem('KR_SUWON', Icons.location_city),
      InterestItem('KR_GOYANG', Icons.location_city),
      InterestItem('KR_SEONGNAM', Icons.location_city),
    ],
    'JP': [
      InterestItem('JP_TOKYO', Icons.location_city),
      InterestItem('JP_OSAKA', Icons.location_city),
      InterestItem('JP_KYOTO', Icons.location_city),
      InterestItem('JP_NAGOYA', Icons.location_city),
      InterestItem('JP_YOKOHAMA', Icons.location_city),
      InterestItem('JP_FUKUOKA', Icons.location_city),
      InterestItem('JP_SAPPORO', Icons.location_city),
      InterestItem('JP_KOBE', Icons.location_city),
      InterestItem('JP_SENDAI', Icons.location_city),
    ],
  };

  static String countryLabel(L10n l10n, String code) => switch (code) {
    'KR' => l10n.countryKorea,
    'JP' => l10n.countryJapan,
    _ => code,
  };

  static String countryFlag(String code) => switch (code) {
    'KR' => '🇰🇷',
    'JP' => '🇯🇵',
    _ => '',
  };

  /// 도시 이름만. 국가까지 붙은 문구는 [regionLabel].
  static String cityLabel(L10n l10n, String code) => switch (code) {
    'KR_SEOUL' => l10n.cityKrSeoul,
    'KR_BUSAN' => l10n.cityKrBusan,
    'KR_DAEGU' => l10n.cityKrDaegu,
    'KR_INCHEON' => l10n.cityKrIncheon,
    'KR_GWANGJU' => l10n.cityKrGwangju,
    'KR_DAEJEON' => l10n.cityKrDaejeon,
    'KR_ULSAN' => l10n.cityKrUlsan,
    'KR_SEJONG' => l10n.cityKrSejong,
    'KR_SUWON' => l10n.cityKrSuwon,
    'KR_GOYANG' => l10n.cityKrGoyang,
    'KR_SEONGNAM' => l10n.cityKrSeongnam,
    'JP_TOKYO' => l10n.cityJpTokyo,
    'JP_OSAKA' => l10n.cityJpOsaka,
    'JP_KYOTO' => l10n.cityJpKyoto,
    'JP_NAGOYA' => l10n.cityJpNagoya,
    'JP_YOKOHAMA' => l10n.cityJpYokohama,
    'JP_FUKUOKA' => l10n.cityJpFukuoka,
    'JP_SAPPORO' => l10n.cityJpSapporo,
    'JP_KOBE' => l10n.cityJpKobe,
    'JP_SENDAI' => l10n.cityJpSendai,
    _ => code,
  };

  /// 코드 → "한국, 서울" 형태의 표시 문구.
  static String regionLabel(L10n l10n, String code) {
    final country = countryOf(code);
    if (country == null) return code;
    return l10n.regionLabelFormat(
      countryLabel(l10n, country),
      cityLabel(l10n, code),
    );
  }

  /// 지역 코드가 속한 국가(`KR`/`JP`). 알 수 없으면 null.
  static String? countryOf(String regionCode) {
    for (final entry in regionsByCountry.entries) {
      if (entry.value.any((item) => item.code == regionCode)) return entry.key;
    }
    return null;
  }
}
