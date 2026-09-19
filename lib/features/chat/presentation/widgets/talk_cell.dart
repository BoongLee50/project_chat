import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import 'talk_art.dart';

// 대화방(`Scene_Talk`)에서 만든 셀·탭을 **친구 화면도 그대로 쓴다.**
//
// 기획서 260919 7-2: *"[받은 신청]의 화면 구성과 기능은 [대화 목록]창과 동일."*
// 6-2(대화방 받은 신청)에도 같은 문장이 있다 — 세 곳이 한 셀이다. 한곳에 두어야
// 한쪽만 고치고 나머지가 낡는 일이 없다(원래 chat_rooms_screen.dart 안에 있었다).

// ── 탭 ────────────────────────────────────────────────────
/// 그림 탭 두 개(고른 쪽 노랑 `_color` / 아닌 쪽 흰색 `_normal`) + 빨간 점 숫자.
///
/// 빨간 점은 **숫자가 있을 때만** 붙고, 숫자는 **99가 최대**다(기획사항 2026-09-19 —
/// "레드닷은 숫자표기 99가 최대치"). 기획서는 "99개를 넘으면 숫자 표시를 하지 않음"이라
/// 서로 다른데, 신뢰 순서상 기획사항을 따랐다(넘으면 `99`로 멈춘다).
///
/// 탭 자리(`23, 356` / `571, 356`)·빨간 점 자리(`430, 377` / `977, 377`)는
/// 대화방과 친구 화면 시안이 **같다**.
class ArtTabs extends StatelessWidget {
  const ArtTabs({
    super.key,
    required this.index,
    required this.onChanged,
    required this.leftOn,
    required this.leftOff,
    required this.rightOn,
    required this.rightOff,
    required this.leftCount,
    required this.rightCount,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final String leftOn;
  final String leftOff;
  final String rightOn;
  final String rightOff;
  final int leftCount;
  final int rightCount;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final gap =
        TalkArt.tabReceiveLeft - TalkArt.tabListLeft - TalkArt.tabSize.width;

    Widget tab(int i, String on, String off, int count) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(i),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ArtImage(
            index == i ? on : off,
            width: TalkArt.tabSize.width,
            height: TalkArt.tabSize.height,
          ),
          if (count > 0)
            Positioned(
              left: TalkArt.redDotInTab.dx * s,
              top: TalkArt.redDotInTab.dy * s,
              child: RedDot(count: count),
            ),
        ],
      ),
    );

    return Row(
      children: [
        SizedBox(width: TalkArt.tabListLeft * s),
        tab(0, leftOn, leftOff, leftCount),
        SizedBox(width: gap * s),
        tab(1, rightOn, rightOff, rightCount),
      ],
    );
  }
}

/// 빨간 점 그림 위에 숫자(폰트 — 값이 변한다). 99가 최대.
class RedDot extends StatelessWidget {
  const RedDot({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final text = count > 99 ? '99' : '$count';
    return Stack(
      alignment: Alignment.center,
      children: [
        ArtImage(
          TalkArt.redDot,
          width: TalkArt.redDotSize.width,
          height: TalkArt.redDotSize.height,
        ),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            // 두 자리(`99`)도 점 안에 들어가게 — 점 지름(55)의 절반 남짓.
            fontSize: (text.length > 1 ? 26 : 30) * s,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── 목록 ───────────────────────────────────────────────────
/// 두 열 격자. 셀은 시안 규격(504×522)을 **그대로 비율로** 쓴다.
class CellGrid extends StatelessWidget {
  const CellGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return GridView.builder(
      // 목록은 실제로 넘길 것이 있는 자리라 당겨서 새로고침을 남긴다.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        TalkArt.cellLeft * s,
        0,
        TalkArt.cellLeft * s,
        TalkArt.cellGapY * s,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: TalkArt.cellGapX * s,
        mainAxisSpacing: TalkArt.cellGapY * s,
        childAspectRatio: TalkArt.cellSize.width / TalkArt.cellSize.height,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

// ── 셀 ────────────────────────────────────────────────────
/// 대화 목록 · 대화 받은 신청 · **친구 받은 신청**이 함께 쓰는 셀(`frame_list.png` 504×522).
///
/// 겹치는 순서: **상대 프로필 사진** → 외곽선·아래 어둠 그림 → 접속·미확인 표시 → 글.
/// - 사진은 **프로필 사진**이다(기획사항 — "cell안의 사진은 프로필 사진").
/// - `ON`은 **접속 중일 때만**(기획서 — "온라인 접속 상태일 경우에만"). 오프라인은 아무것도 없다.
///   예시 그림의 `온라인`/`오프라인` 글자 표기는 따르지 않았다(이미지는 신뢰 순위가 가장 낮다).
/// - `N`은 **확인 안 한 것이 있을 때만**.
/// - 시간은 분·시간·일, **30일이 넘으면 표시하지 않는다.**
/// - 글은 **25자까지 + `…`**. 넘치는 글자는 두 줄까지 흐른다.
class TalkCell extends StatelessWidget {
  const TalkCell({
    super.key,
    required this.photoUrl,
    required this.nickname,
    required this.age,
    required this.country,
    required this.online,
    required this.unconfirmed,
    required this.at,
    required this.text,
    required this.onTap,
  });

  final String? photoUrl;
  final String nickname;
  final int? age;
  final String? country;
  final bool online;
  final bool unconfirmed;
  final DateTime? at;
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final flag = TalkArt.flagOf(country);
    final time = timeAgoWithin30Days(l10n, at);

    // 사진은 외곽선 **안쪽**까지만 — 선 두께만큼 밀어 넣고 곡률도 그만큼 줄인다(함정 #51·#52).
    final inset = TalkArt.cellLine * s;
    final radius = (TalkArt.cellRadius - TalkArt.cellLine) * s;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(inset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              // 사진이 없으면 **빈 칸 그대로** 둔다 — 예시 그림의 빈 셀과 같은 모습이다.
              // (아이콘을 그려 넣지 않는다: 아이콘도 그림이 정본이다 — 14 §3)
              child: photoUrl == null
                  ? const ColoredBox(color: AppColors.night)
                  : AuthedImage(url: photoUrl!),
            ),
          ),
          // 외곽선 + 아래쪽 어둠. 탭을 삼키지 않게 IgnorePointer(함정 #38).
          IgnorePointer(
            child: Image.asset(TalkArt.cellFrame, fit: BoxFit.fill),
          ),
          if (online)
            Positioned(
              left: TalkArt.onlineAt.dx * s,
              top: TalkArt.onlineAt.dy * s,
              child: ArtImage(
                TalkArt.online,
                width: TalkArt.onlineSize.width,
                height: TalkArt.onlineSize.height,
              ),
            ),
          if (unconfirmed)
            Positioned(
              left: TalkArt.newMarkAt.dx * s,
              top: TalkArt.newMarkAt.dy * s,
              child: ArtImage(
                TalkArt.newMark,
                width: TalkArt.newMarkSize.width,
                height: TalkArt.newMarkSize.height,
              ),
            ),
          Positioned(
            left: TalkArt.textLeft * s,
            right: TalkArt.timeRight * s,
            top: TalkArt.nameTop * s,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40 * s,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                if (age != null) ...[
                  SizedBox(width: 12 * s),
                  Text(
                    '$age',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 34 * s,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
                if (flag != null) ...[
                  SizedBox(width: 14 * s),
                  ArtImage(
                    flag,
                    width: TalkArt.flagSize.width,
                    height: TalkArt.flagSize.height,
                  ),
                ],
                const Spacer(),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 28 * s,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          if (text != null && text!.isNotEmpty)
            Positioned(
              left: TalkArt.textLeft * s,
              right: TalkArt.timeRight * s,
              top: TalkArt.messageTop * s,
              child: Text(
                clip25(text!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 30 * s,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 25자까지 + `…`(기획서·기획사항 공통). 이모지가 반쪽으로 잘리지 않게 **글자 단위**로 자른다.
String clip25(String text) {
  final chars = text.characters;
  return chars.length <= 25 ? text : '${chars.take(25)}…';
}

/// 분·시간·일 단위. **30일이 넘으면 표시하지 않는다**(기획서 260919 6-1).
String timeAgoWithin30Days(L10n l10n, DateTime? at) {
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inDays >= 30) return '';
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  return l10n.timeDaysAgo(diff.inDays);
}

class CellLoading extends StatelessWidget {
  const CellLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.moonlight),
  );
}

/// 빈 목록 — 안내 한 줄(폰트). 시안에 빈 상태가 없어 기존 문구를 그대로 쓴다.
///
/// 당겨서 새로고침이 되도록 스크롤 가능한 목록으로 둔다.
class CellEmpty extends StatelessWidget {
  const CellEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
