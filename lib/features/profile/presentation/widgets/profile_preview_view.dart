import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/profile_catalog.dart';
import 'profile_tag_chip.dart';

/// [미리 보기]에 그릴 것 — 내 것(`MeProfile`)이든 남의 것(`PostInfo`)이든 이 모양으로 옮겨 담는다.
class ProfilePreviewData {
  const ProfilePreviewData({
    required this.nickname,
    this.age,
    this.country,
    this.facePhotoUrl,
    this.mainPhotoUrl,
    this.intro,
    this.interests = const [],
    this.regions = const [],
  });

  final String nickname;
  final int? age;

  /// KR | JP
  final String? country;

  /// 얼굴 사진(동그란 칸) — 8-1 첫째 칸.
  final String? facePhotoUrl;

  /// 자유 사진(큰 칸) — 8-1 둘째 칸.
  final String? mainPhotoUrl;

  final String? intro;
  final List<String> interests;
  final List<String> regions;
}

/// 프로필 **[미리 보기] 창**(Scene_Profile/Preview) — 흰 바탕, 위에 `<`·`프로필`.
///
/// 🚨 **이 창은 남도 본다.** 내가 [미리 보기]를 눌러 볼 때도, 다른 사람이 내 프로필을
/// 눌렀을 때도 같은 창이 뜬다(기획 2026-10-04). 그래서 내 화면(`ProfilePreviewScreen`)과
/// 남의 화면(`ProfileViewScreen`)이 **이 위젯 하나**를 쓴다 — 갈라지면 내가 본 것과
/// 남이 보는 것이 달라진다.
///
/// 좌표는 시안 `프로필_미리보기 화면 좌표.png`(1080 캔버스). 아래가 길어 **스크롤한다**(기획 2026-10-04).
/// [bottom]은 남의 프로필일 때만 들어가는 하단 버튼 자리다(시안에는 없다).
class ProfilePreviewView extends StatefulWidget {
  const ProfilePreviewView({
    super.key,
    required this.data,
    this.onBack,
    this.bottom,
  });

  final ProfilePreviewData data;
  final VoidCallback? onBack;
  final Widget? bottom;

  static const _dir = 'assets/images/scene_profile/preview';

  /// 이름·소개 글자색 — 시안 실측(거의 검정).
  static const Color ink = Color(0xFF212121);

  @override
  State<ProfilePreviewView> createState() => _ProfilePreviewViewState();
}

class _ProfilePreviewViewState extends State<ProfilePreviewView> {
  ProfilePreviewData get data => widget.data;

  /// 닫을 때 상태바 글자를 **밝게 되돌린다.**
  ///
  /// ⚠️ 메인 셸은 상태바 자리를 `SafeArea`로 비워 두어 그 자리에 스타일을 정하는 위젯이 없다 —
  /// 그래서 이 창이 남긴 "어두운 글자"가 그대로 남아 **검은 바탕에 시계가 묻혔다**(실기 확인).
  /// 이 창을 여는 곳(프로필·대화방·친구·가든)은 모두 어두운 화면이다.
  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final statusBar = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 흰 바탕이라 상태바 글자를 어둡게.
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            // 머리 줄(`<` 33,103 · `프로필` 421,103)은 고정 — 긴 본문을 내려도 돌아갈 길이 보인다.
            SizedBox(height: statusBar),
            SizedBox(
              height: (103 + 101 + 20) * s - statusBar.clamp(0.0, 103 * s),
              child: Stack(
                children: [
                  // 손가락 자리를 넓히는 여백(10)만큼 바깥으로 — 그림 자체는 33,103에 선다.
                  Positioned(
                    left: 23 * s,
                    bottom: 10 * s,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                          widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                      child: Padding(
                        padding: EdgeInsets.all(10 * s),
                        child: const ArtImage(
                          '${ProfilePreviewView._dir}/button_previewback.png',
                          width: 60,
                          height: 101,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 50 * s,
                    child: const Center(
                      child: ArtImage(
                        '${ProfilePreviewView._dir}/title_profile.png',
                        width: 232,
                        height: 71,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(33 * s, 15 * s, 33 * s, 120 * s),
                child: _Body(data: data),
              ),
            ),
            ?widget.bottom,
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final ProfilePreviewData data;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final intro = data.intro?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Head(data: data),
        // 얼굴 칸 아랫변(239+211=450) → 메인 사진 윗변(477).
        SizedBox(height: 27 * s),
        _MainPhoto(url: data.mainPhotoUrl ?? data.facePhotoUrl),
        if (intro != null && intro.isNotEmpty) ...[
          // 메인 사진 아랫변(477+1521≈1998) → 소개(2067).
          SizedBox(height: 60 * s),
          Text(
            intro,
            style: TextStyle(
              color: ProfilePreviewView.ink,
              fontSize: 42 * s,
              height: 1.5,
            ),
          ),
        ],
        if (data.interests.isNotEmpty) ...[
          SizedBox(height: 60 * s),
          Wrap(
            // 시안: 33 → 272 → … (칩 204 + 35)
            spacing: 35 * s,
            runSpacing: 24 * s,
            children: [
              for (final code in data.interests) ProfileTagChip.interest(code),
            ],
          ),
        ],
      ],
    );
  }
}

/// 얼굴 사진(동그라미) + 이름·나이 + 국기·지역.
class _Head extends StatelessWidget {
  const _Head({required this.data});

  final ProfilePreviewData data;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);
    final country = data.country;
    final region = data.regions.isEmpty ? null : data.regions.first;
    // "일본, 도쿄" — 지역을 안 골랐으면 나라만.
    final place = region != null
        ? ProfileCatalog.regionLabel(l10n, region)
        : (country == null ? null : ProfileCatalog.countryLabel(l10n, country));
    final flag = switch (country) {
      'KR' => '${ProfilePreviewView._dir}/icon_mflag_kor.png',
      'JP' => '${ProfilePreviewView._dir}/icon_mflag_jap.png',
      _ => null,
    };

    return Row(
      children: [
        SizedBox(
          width: 213 * s,
          height: 211 * s,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipOval(
                child: data.facePhotoUrl == null
                    ? const _EmptyPhoto()
                    : AuthedImage(
                        url: data.facePhotoUrl!,
                        fallback: const _EmptyPhoto(),
                      ),
              ),
              const ArtImage(
                '${ProfilePreviewView._dir}/frame_facephoto.png',
                width: 213,
                height: 211,
              ),
            ],
          ),
        ),
        // 33+213=246 → 이름(291).
        SizedBox(width: 45 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: data.nickname,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (data.age != null) TextSpan(text: ' ${data.age}'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ProfilePreviewView.ink,
                  fontSize: 78 * s,
                  height: 1.15,
                ),
              ),
              if (place != null) ...[
                SizedBox(height: 4 * s),
                Row(
                  children: [
                    if (flag != null) ...[
                      ArtImage(flag, width: 60, height: 60),
                      SizedBox(width: 14 * s),
                    ],
                    Flexible(
                      child: Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ProfilePreviewView.ink,
                          fontSize: 44 * s,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 큰 메인 사진 — 2:3 칸(1014×1521)을 둥글게 자르고 `frame_profile`(흰 테두리)을 얹는다.
class _MainPhoto extends StatelessWidget {
  const _MainPhoto({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    // frame_profile.png(1024×1536)의 모서리 반지름 실측 ≈ 44.
    final radius = BorderRadius.circular(44 * s);

    return AspectRatio(
      aspectRatio: 1024 / 1536,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: url == null
                ? const _EmptyPhoto()
                : AuthedImage(url: url!, fallback: const _EmptyPhoto()),
          ),
          Image.asset(
            '${ProfilePreviewView._dir}/frame_profile.png',
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }
}

/// 사진이 없는 칸 — 옅은 회색 + 사람 모양(🚧 자리 표시, 그림이 따로 오지 않았다).
class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE6E8EC),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.4,
          child: FittedBox(
            child: Icon(Icons.person_rounded, color: Color(0xFFB2B2B7)),
          ),
        ),
      ),
    );
  }
}
