import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/main_shell.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../garden/presentation/widgets/photo_lock.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../profile/data/models/profile_catalog.dart';
import 'talk_art.dart';

// 받은 신청 팝업(대화방 6-2의 [포스트 정보])의 조각들 — **친구 화면도 그대로 쓴다.**
//
// 세 팝업이 같은 골격이다(시안 셋을 겹쳐 보면 테두리·패널·버튼 자리가 픽셀까지 같다).
//   - 대화 받은 신청 팝업     — 편지 · [원문보기] · [프로필]     / [✕] [💬]
//   - 친구 요청 상세(7-2)     — 편지 · [원문보기] · [프로필]     / [✕] [✓]
//   - 친구 포스트 정보(7-1)   — 연필 · [원문보기] · [친구 관리] / [나가기] [💬] + 관심사 줄
// 원래 received_request_screen.dart 안에 있던 것을 꺼냈다 — 한곳이어야 셋이 같이 움직인다.

// ── 사진 ───────────────────────────────────────────────────
/// 사진 칸 그늘 — 위 55%는 사진 그대로, 이름·나라 줄에서만 60%까지 어두워진다.
const _photoScrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x000B0A14), Color(0x000B0A14), Color(0x990B0A14)],
  stops: [0.0, 0.55, 1.0],
);

/// 위 칸 — 사진(좌우로 넘김) · `1/9` · 이름·나이 · 국기·지역, 테두리 그림은 `frame_popup_top`.
///
/// [topLeft]가 없으면 **뒤로가기 화살표**를 둔다(대화방·친구 요청 상세).
/// 친구 포스트 정보는 그 자리에 **고정 핀**(고정했을 때만)을 두고 화살표가 없다 — 닫기는 [나가기] 버튼이다.
class PopupPhotoArea extends StatelessWidget {
  const PopupPhotoArea({
    super.key,
    required this.info,
    required this.fallbackPhoto,
    required this.nickname,
    required this.age,
    required this.country,
    required this.controller,
    required this.page,
    required this.onPageChanged,
    this.topLeft,
  });

  final PostInfo? info;
  final String? fallbackPhoto;
  final String nickname;
  final int? age;
  final String? country;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;

  /// 왼쪽 위 자리(시안 `76, 174`). null이면 뒤로가기 화살표.
  final Widget? topLeft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // 높이는 **남는 만큼**이다 — 시안 1381px로 고정하지 않는다(부르는 쪽 주석 참고).
      builder: (context, constraints) => _build(context, constraints.maxHeight),
    );
  }

  Widget _build(BuildContext context, double h) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final w = TalkArt.popupTopSize.width * s;

    // 오늘 포스트가 없으면 서버가 **프로필 사진 한 장**을 준다(PostInfo.photoUrls).
    // [포스트 정보]를 못 읽었으면 목록이 가진 프로필 사진으로 버틴다.
    final photos =
        info?.photoUrls ??
        (fallbackPhoto == null ? const <String>[] : [fallbackPhoto!]);
    final total = info?.totalPhotos ?? photos.length;
    final showPage = (info?.hasTodayPost ?? false) && total > 0;
    // 넘길 수 있는 장수 — **잠긴 장도 센다**(달빛가든 카드와 같은 규칙, 기획 4-1).
    // 서버는 열람 제한이 걸리면 메인 1장만 주고 `totalPhotos`로 원래 장수를 알린다 —
    // 받은 것보다 뒤의 장은 흐린 안내 장([사진 등록 안내])이 된다.
    final pageCount = total > photos.length ? total : photos.length;

    final region = info?.regions.isNotEmpty == true
        ? info!.regions.first
        : null;
    final place = region != null
        ? ProfileCatalog.regionLabel(l10n, region)
        : (country == null
              ? null
              : ProfileCatalog.countryLabel(l10n, country!));
    final flag = TalkArt.flagOf(country);

    // 사진은 테두리 **안쪽**부터 — 위 모서리만 둥글다(아래는 흰 패널과 붙는다).
    //
    // ⚠️ 칸 높이가 시안(1381)과 달라지면 테두리 그림이 **세로로만** 늘거나 줄어 모서리가
    // 타원이 된다. 사진 모서리도 **같은 비율의 타원**으로 잘라야 테두리 밖으로 안 삐져나온다(함정 #51·#52).
    final inset = TalkArt.popupLine * 0.7 * s;
    final r = (TalkArt.popupRadius - TalkArt.popupLine) * s;
    final stretch = h / (TalkArt.popupTopSize.height * s);
    final radius = Radius.elliptical(r, r * stretch);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: radius,
                topRight: radius,
              ),
              child: photos.isEmpty
                  ? const ColoredBox(color: AppColors.surfaceHigh)
                  // 포스트 사진 넘기기 — 달빛가든 카드와 같다(기획 4-1 "우측 영역 탭은 다음 사진,
                  // 좌측 탭은 이전 사진"). 이 팝업은 좌우로 밀어도 사람이 넘어가지 않으니 밀기도 그대로 둔다.
                  // 끝에서 더 누르면 그 자리에 머문다(`1/9`가 위치를 알려 준다).
                  : GestureDetector(
                      // opaque가 없으면 사진 위 탭이 안 들어온다(함정 #38).
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) {
                        final next =
                            page + (d.localPosition.dx > w / 2 - inset ? 1 : -1);
                        if (next < 0 || next >= pageCount) return;
                        controller.animateToPage(
                          next,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      child: PageView.builder(
                        controller: controller,
                        itemCount: pageCount,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, i) => i < photos.length
                            ? AuthedImage(url: photos[i])
                            : PhotoLockBackdrop(mainPhotoUrl: photos.first),
                      ),
                    ),
            ),
          ),
          // 아래쪽 글자(이름·나라)를 살리는 그늘. 탭을 삼키지 않게(함정 #38).
          // 🚨 공용 `nightScrim`(가운데부터 70%, 아래는 완전 검정)은 여기선 너무 세다 —
          // 시안은 이름 뒤만 살짝 어둡고 사진이 끝까지 보인다.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: _photoScrim),
            ),
          ),
          IgnorePointer(child: Image.asset(TalkArt.popupTop, fit: BoxFit.fill)),
          // 잠긴 장(2번째부터, 오늘 내 포스트가 없을 때)이면 안내 + [새 사진 등록하기].
          if (page >= photos.length && photos.isNotEmpty) const _PopupLockGuide(),
          Positioned(
            left: TalkArt.backAt.dx * s,
            top: TalkArt.backAt.dy * s,
            child: topLeft ?? const PopupBackButton(),
          ),
          if (showPage)
            Positioned(
              right: (TalkArt.popupTopSize.width - TalkArt.pageAt.dx - 120) * s,
              top: TalkArt.pageAt.dy * s,
              child: Text(
                '${page + 1}/$total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 58 * s,
                  fontWeight: FontWeight.w700,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            ),
          Positioned(
            left: 52 * s,
            right: 52 * s,
            bottom: 40 * s,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 72 * s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (age != null) ...[
                      SizedBox(width: 18 * s),
                      Text(
                        '$age',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64 * s,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
                if (place != null) ...[
                  SizedBox(height: 12 * s),
                  Row(
                    children: [
                      if (flag != null) ...[
                        ArtImage(
                          flag,
                          width: TalkArt.flagSize.width,
                          height: TalkArt.flagSize.height,
                        ),
                        SizedBox(width: 14 * s),
                      ],
                      Flexible(
                        child: Text(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38 * s,
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
      ),
    );
  }
}

/// 달빛가든의 [사진 등록 안내]를 그대로 쓴다 — 문구·버튼·가는 곳(포스트 탭)이 같다.
///
/// 가든 카드는 탭 화면 안이라 탭만 바꾸면 되지만, 이 팝업은 그 위에 **떠 있는 화면**이다.
/// 탭이 바뀌면(버튼을 눌렀으면) 떠 있는 화면을 모두 닫아 포스트 탭이 보이게 한다.
class _PopupLockGuide extends ConsumerWidget {
  const _PopupLockGuide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(selectedTabProvider, (prev, next) {
      if (prev != next) Navigator.of(context).popUntil((r) => r.isFirst);
    });
    return const PhotoLockGuide();
  }
}

/// 뒤로가기 — 이 팝업들의 **유일한 화살표**다(기획사항 "뒤로가기 말고는 화살표가 없음").
class PopupBackButton extends StatelessWidget {
  const PopupBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Padding(
        // 그림이 가늘어(52px) 손가락이 빗나가기 쉽다 — 누르는 자리만 넓힌다.
        padding: EdgeInsets.all(16 * s),
        child: ArtImage(
          TalkArt.back,
          width: TalkArt.backSize.width,
          height: TalkArt.backSize.height,
        ),
      ),
    );
  }
}

// ── 흰 패널 ────────────────────────────────────────────────
/// 흰 패널의 첫 줄에 놓이는 그림 하나(시안 좌표 그대로).
class PanelItem {
  const PanelItem({
    required this.asset,
    required this.size,
    required this.left,
    this.top = TalkArt.panelRowTop,
    this.onTap,
  });

  final String asset;
  final Size size;

  /// 팝업 왼쪽 기준.
  final double left;

  /// 패널 윗선(`1487`) 기준 — 대부분 `1526`줄에 서지만 친구 포스트의 연필은 `1515`다.
  final double top;
  final VoidCallback? onTap;
}

/// 가운데 흰 패널 — 첫 줄(왼쪽 아이콘 · `[원문보기]` · 오른쪽 버튼) + 본문 + (선택) 아래 줄.
///
/// - 본문 기본은 **번역문**. `[원문보기]`를 누르면 **원문으로 바뀌고**, 다시 누르면 번역문으로 돌아온다
///   (기획서 261002 6-2·7-2 "번역문을 신청 메시지 원문으로 전환하여 표시"). 260919판의
///   "원문 위 · 구분선 · 번역문 아래"는 버렸다.
/// - `[원문보기]`를 누를 수 있는지는 [canViewOriginal] — 못 누를 때도 **흐리게 자리는 지킨다**.
///   주지 않으면 옛 규칙(번역문이 원문과 다를 때만 보이고, 그때는 누를 수 있다).
/// - 글이 길면 **패널이 아래로 늘어난다**(기획사항 "문구가 길어지면 아래로 늘어남").
/// - [footer]는 패널 **아래쪽에 붙는** 줄이다(친구 포스트의 하트 + 관심사). 본문이 그 줄을
///   덮지 않도록 [footerHeight]만큼 자리를 비운다.
class PopupPanel extends StatelessWidget {
  const PopupPanel({
    super.key,
    required this.leading,
    required this.trailing,
    required this.original,
    required this.translated,
    required this.showOriginal,
    required this.onToggleOriginal,
    this.canViewOriginal,
    this.footer,
    this.footerHeight = 0,
    this.footerBottom = 0,
  });

  final PanelItem leading;
  final PanelItem trailing;
  final String original;

  /// 번역문. 아직 없으면 null — 원문을 보여 준다.
  final String? translated;
  final bool showOriginal;
  final VoidCallback onToggleOriginal;

  /// `[원문보기]`를 누를 수 있나. 받은 신청은 **상대와 내 나라가 다를 때만** 누를 수 있다.
  ///
  /// - true → 보이고 눌린다(원문 ↔ 번역문)
  /// - false → **흐리게 보이고 눌러도 반응이 없다**(2026-10-04 사용자 결정). 기획서 261002 6-2는
  ///   "동일 국가 사용자일 경우는 미노출"이지만 신뢰 순서상 대화 중 결정이 앞선다.
  ///   📌 나중에 **회색 아이콘**(비활성 그림)이 오면 흐리게 한 것을 그 그림으로 바꾼다.
  /// - null → 옛 규칙. [translated]가 있을 때만 보이고 눌린다(번역문이 원문과 같으면 부르는 쪽이 null을 준다).
  final bool? canViewOriginal;

  final Widget? footer;

  /// 아래 줄의 높이와, 패널 **바닥(마개 아래 끝)** 에서 그 줄 아래 끝까지의 거리(시안 픽셀).
  final double footerHeight;
  final double footerBottom;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final w = TalkArt.popupTopSize.width * s;
    final textStyle = TextStyle(
      color: const Color(0xFF222222),
      // 시안 38px에서 20% 키웠다(2026-10-04 사용자 결정 — 신청 한마디가 작아 읽기 힘들었다).
      fontSize: 45.6 * s,
      height: 1.6,
    );

    final showViewOriginal = canViewOriginal != null || translated != null;
    final viewOriginalEnabled = canViewOriginal ?? true;
    // 원문 ↔ 번역문을 **바꿔 끼운다**(기획서 261002). 번역이 아직 없으면 원문뿐이다.
    final body = Text(
      showOriginal || translated == null ? original : translated!,
      style: textStyle,
    );

    Widget item(PanelItem it, {double opacity = 1}) => Positioned(
      left: it.left * s,
      top: (it.top - TalkArt.panelRowTop) * s,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: it.onTap,
        child: ArtImage(
          it.asset,
          width: it.size.width,
          height: it.size.height,
          opacity: opacity,
        ),
      ),
    );

    // 본문이 아래 줄을 덮지 않게 비워 둘 높이 — 마개가 먹는 높이는 이미 빈 자리다.
    final reserve =
        (footerHeight + footerBottom - TalkArt.popupBottomSize.height)
            .clamp(0.0, double.infinity);

    final panel = Column(
      children: [
        Container(
          width: w,
          color: Colors.white,
          constraints: BoxConstraints(minHeight: TalkArt.panelMinBody * s),
          padding: EdgeInsets.only(top: TalkArt.panelRowTop * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: TalkArt.profileSize.height * s,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    item(leading),
                    if (showViewOriginal)
                      item(
                        PanelItem(
                          asset: TalkArt.viewOriginal,
                          size: TalkArt.viewOriginalSize,
                          left: TalkArt.viewOriginalLeft,
                          onTap: viewOriginalEnabled ? onToggleOriginal : null,
                        ),
                        // 못 누를 때(같은 나라)만 흐리게. 회색 그림이 오면 그 그림으로 바꾼다.
                        // 📌 전엔 "원문이 보이는 동안" 0.55로 흐렸는데 지웠다 — 못 누르는 흐림과
                        // 헷갈린다. 눌렀다는 표시는 글이 원문 ↔ 번역문으로 바뀌는 것으로 충분하다.
                        opacity: viewOriginalEnabled
                            ? 1
                            : TalkArt.viewOriginalDisabledOpacity,
                      ),
                    item(trailing),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  TalkArt.panelTextLeft * s,
                  40 * s,
                  TalkArt.panelTextLeft * s,
                  reserve * s,
                ),
                child: body,
              ),
            ],
          ),
        ),
        // 아래 마개(둥근 아래 모서리).
        Image.asset(
          TalkArt.popupBottom,
          width: w,
          height: TalkArt.popupBottomSize.height * s,
          fit: BoxFit.fill,
        ),
      ],
    );

    if (footer == null) return panel;
    return Stack(
      children: [
        panel,
        Positioned(
          left: 0,
          right: 0,
          bottom: footerBottom * s,
          height: footerHeight * s,
          child: footer!,
        ),
      ],
    );
  }
}

/// 아래 두 버튼 하나(177×176 원형 그림).
class PopupDecide extends StatelessWidget {
  const PopupDecide({super.key, required this.asset, required this.onTap});

  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ArtImage(
        asset,
        width: TalkArt.decideSize.width,
        height: TalkArt.decideSize.height,
        opacity: onTap == null ? 0.5 : 1,
      ),
    );
  }
}

/// 아래 두 버튼 줄 — 시안 `260, 2168` / `636, 2168`.
class PopupDecideRow extends StatelessWidget {
  const PopupDecideRow({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return Row(
      children: [
        SizedBox(width: TalkArt.refuseLeft * s),
        left,
        SizedBox(
          width:
              (TalkArt.acceptLeft - TalkArt.refuseLeft - TalkArt.decideSize.width) *
              s,
        ),
        right,
      ],
    );
  }
}
