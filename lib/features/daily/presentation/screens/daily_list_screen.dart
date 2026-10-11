import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../shared/widgets/image_viewer.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../chat/presentation/widgets/talk_cell.dart'
    show timeAgoWithin30Days;
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../data/models/daily_models.dart';
import '../providers/daily_provider.dart';
import '../widgets/word_art.dart';
import 'daily_detail_screen.dart';

/// 달빛 한마디 [답글 목록](기획서 261011 **9-2**, `Scene_Word/Reply List`).
///
/// - **아래에서 올라온다**(기획 9-2 "하단에서 올라오는 Bottom Sheet 형태로 전체 목록 열람") — 화면 전체가
///   시트처럼 올라오는 전환으로 옮겼다. 시안에 시트 손잡이·위 여백이 없어 전체 화면이다.
/// - [최신](기본)·[인기] · [내 한마디] · 셀을 누르면 [답글 상세] · 얼굴을 누르면 [프로필 보기].
/// - [나가기] → 메인(가든). [타이틀]은 바꿔 끼워져 있어 한 번 닫으면 가든이다.
/// - 내 답을 등록해야 열린다(9-1) — 서버도 같은 문을 지킨다(`DAILY_ANSWER_NOT_YET`).
class DailyListScreen extends ConsumerWidget {
  const DailyListScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => const DailyListScreen(),
    transitionsBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );

  /// [내 한마디] — 아직 안 썼으면 서버가 `DAILY_ANSWER_NOT_YET`을 준다.
  /// 오류가 아니라 **안내**라서 문구만 띄우고 화면은 그대로 둔다(기획 9-2).
  Future<void> _openMine(BuildContext context, WidgetRef ref) async {
    try {
      final mine = await ref.read(dailyApiProvider).myAnswer();
      if (!context.mounted) return;
      await Navigator.of(context).push(DailyDetailScreen.route(mine.id));
      if (context.mounted) ref.read(dailyListProvider.notifier).refresh();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(errorMessage(L10n.of(context), e))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final today = ref.watch(dailyTodayProvider).valueOrNull;
    final sort = ref.watch(dailySortProvider);
    final list = ref.watch(dailyListProvider);
    final pad = MediaQuery.paddingOf(context);

    void setSort(DailySort value) =>
        ref.read(dailySortProvider.notifier).state = value;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF3E6),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(WordArt.listBack, fit: BoxFit.cover),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시안의 102는 상태바 높이와 거의 같다 — 상태바가 더 크면 그 아래부터.
              SizedBox(
                height: WordArt.questionFrameTop * s > pad.top
                    ? WordArt.questionFrameTop * s
                    : pad.top,
              ),
              Padding(
                padding: EdgeInsets.only(left: DesignCanvas.contentLeft * s),
                child: Semantics(
                  label: l10n.dailyTodayQuestion,
                  child: Stack(
                    children: [
                      ArtImage(
                        WordArt.questionFrame,
                        width: WordArt.questionFrameSize.width,
                        height: WordArt.questionFrameSize.height,
                      ),
                      Positioned(
                        left: WordArt.questionTextInset.dx * s,
                        top: WordArt.questionTextInset.dy * s,
                        width: 620 * s,
                        child: Text(
                          today?.question ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34 * s,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height:
                    (WordArt.filterTop -
                        WordArt.questionFrameTop -
                        WordArt.questionFrameSize.height) *
                    s,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: WordArt.recentLeft * s),
                  _ArtButton(
                    asset: sort == DailySort.latest
                        ? WordArt.recentOn
                        : WordArt.recentOff,
                    size: WordArt.recentSize,
                    label: l10n.dailySortLatest,
                    pill: true,
                    onTap: () => setSort(DailySort.latest),
                  ),
                  SizedBox(
                    width:
                        (WordArt.popularLeft -
                            WordArt.recentLeft -
                            WordArt.recentSize.width) *
                        s,
                  ),
                  _ArtButton(
                    asset: sort == DailySort.popular
                        ? WordArt.popularOn
                        : WordArt.popularOff,
                    size: WordArt.popularSize,
                    label: l10n.dailySortPopular,
                    pill: true,
                    onTap: () => setSort(DailySort.popular),
                  ),
                  SizedBox(
                    width:
                        (WordArt.myWordLeft -
                            WordArt.popularLeft -
                            WordArt.popularSize.width) *
                        s,
                  ),
                  _ArtButton(
                    asset: WordArt.myWord,
                    size: WordArt.myWordSize,
                    label: l10n.dailyMine,
                    onTap: () => _openMine(context, ref),
                  ),
                ],
              ),
              SizedBox(
                height:
                    (WordArt.listTop -
                        WordArt.filterTop -
                        WordArt.popularSize.height) *
                    s,
              ),
              // 늘어나는 칸 — 세로가 짧은 폰에서는 목록 칸이 줄어든다(고정 화면 원칙).
              Expanded(
                child: list.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.moonlight,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      error is ApiException
                          ? errorMessage(l10n, error)
                          : l10n.dailyLoadFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WordArt.muted, fontSize: 34 * s),
                    ),
                  ),
                  // 내 답을 등록해야 들어오므로 **비는 일이 없다**(적어도 내 것이 있다).
                  // 차단·신고로 다 걸러진 경우만 남아 문구 한 줄로 둔다.
                  data: (items) => RefreshIndicator(
                    color: AppColors.moonlight,
                    onRefresh: () =>
                        ref.read(dailyListProvider.notifier).refresh(),
                    child: items.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 200 * s),
                              Center(
                                child: Text(
                                  l10n.dailyEmpty,
                                  style: TextStyle(
                                    color: WordArt.muted,
                                    fontSize: 34 * s,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: EdgeInsets.only(
                              left: DesignCanvas.contentLeft * s,
                              right:
                                  (DesignCanvas.width -
                                      DesignCanvas.contentLeft -
                                      WordArt.cellFrameSize.width) *
                                  s,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: WordArt.cellGap * s),
                            itemBuilder: (context, i) =>
                                _AnswerCell(answer: items[i]),
                          ),
                  ),
                ),
              ),
              SizedBox(height: (2435 - WordArt.listBottom) * s),
              Padding(
                padding: EdgeInsets.only(
                  left: WordArt.exitLeft * s,
                  bottom: WordArt.exitBottom * s + pad.bottom,
                ),
                child: _ArtButton(
                  asset: WordArt.exit,
                  size: WordArt.exitSize,
                  label: l10n.commonBack,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtButton extends StatelessWidget {
  const _ArtButton({
    required this.asset,
    required this.size,
    required this.label,
    required this.onTap,
    this.pill = false,
  });

  final String asset;
  final Size size;
  final String label;
  final VoidCallback onTap;

  /// 알약 모양으로 잘라 그린다. ⚠️ 눌린 [최신]·[인기](`button_*_color.png`)는 **투명 배경이 아니라**
  /// (RGB) 미색 바탕 위에서 네 모서리가 하얗게 드러났다 — 그림이 다시 오기 전까지 잘라서 가린다.
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final image = ArtImage(asset, width: size.width, height: size.height);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: pill
            ? ClipRRect(
                borderRadius: BorderRadius.circular(
                  size.height / 2 * DesignCanvas.scaleOf(context),
                ),
                child: image,
              )
            : image,
      ),
    );
  }
}

/// [답글 목록] 셀 하나 — 얼굴 · 이름 · 국기 · `ON`/시간 · [원문보기] · `>` · 글 · 사진 · 좋아요·댓글 수.
///
/// 🌐 **나라가 다르면 글을 자동 번역해 보여 주고 `[원문보기]`로 원문을 본다**(기획 9-2, 2026-10-11 사용자 결정).
/// - `[원문보기]`는 셀 **오른쪽 위**(`>` 왼쪽). 나와 글쓴이 나라가 **같으면 보이지도 눌리지도 않는다** —
///   대화방·친구·프로필은 "흐리게 자리만"인데 여기는 **아예 없다**(사용자 결정이 다르다).
/// - 🚧 **번역은 아직 없다** — 지금은 번역문 자리에도 원문이 나간다. 버튼은 원문 ↔ 번역문 상태만 바꾼다.
///   번역이 붙으면 [_translated]만 채우면 된다.
/// - 그림은 `Reply List/button_view trans_m`(182×53, 2026-10-11 두 번째 전달) — 그 전엔 대화방 것을 빌려 썼다.
class _AnswerCell extends ConsumerStatefulWidget {
  const _AnswerCell({required this.answer});

  final DailyAnswer answer;

  @override
  ConsumerState<_AnswerCell> createState() => _AnswerCellState();
}

class _AnswerCellState extends ConsumerState<_AnswerCell> {
  bool _showOriginal = false;

  /// 번역문. 🚧 번역 기능이 붙기 전이라 늘 null이다.
  String? get _translated => null;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final a = widget.answer;
    final myCountry = ref.watch(sessionProvider).profile?.country;
    final foreign =
        !a.mine &&
        myCountry != null &&
        a.country != null &&
        myCountry != a.country;
    final body = foreign && !_showOriginal ? (_translated ?? a.body) : a.body;

    final flag = switch (a.country) {
      'KR' => WordArt.flagKr,
      'JP' => WordArt.flagJp,
      _ => null,
    };
    final time = timeAgoWithin30Days(l10n, a.createdAt);
    final nameStyle = TextStyle(
      color: WordArt.ink,
      fontSize: 40 * s,
      fontWeight: FontWeight.w800,
    );
    final countStyle = TextStyle(color: WordArt.ink, fontSize: 30 * s);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 상세에서 좋아요·댓글이 늘었을 수 있다 — 돌아오면 목록 숫자를 다시 읽는다.
      onTap: () async {
        await Navigator.of(context).push(DailyDetailScreen.route(a.id));
        if (mounted) ref.read(dailyListProvider.notifier).refresh();
      },
      child: Stack(
        children: [
          // 틀은 9조각으로 늘린다 — 글 길이·사진 유무로 셀 높이가 다르다.
          // 🚨 `centerSlice`에 `scale`을 같이 주면 원래 크기보다 **커지지 않는다**(함정 #90) —
          // 시안 픽셀 크기로 늘려 그린 뒤 통째로 줄인다(프로필 자기소개 칸과 같은 방법).
          Positioned.fill(
            child: LayoutBuilder(
              builder: (_, box) => FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: WordArt.cellFrameSize.width,
                  height: box.maxHeight / s,
                  child: Image.asset(
                    WordArt.cellFrame,
                    centerSlice: WordArt.cellFrameSlice,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              WordArt.avatarAt.dx * s,
              WordArt.avatarAt.dy * s,
              (WordArt.cellFrameSize.width - WordArt.cellRight) * s + 26 * s,
              34 * s,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(answer: a),
                SizedBox(
                  width:
                      (WordArt.textLeft -
                          WordArt.avatarAt.dx -
                          WordArt.avatarSize.width) *
                      s,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: (WordArt.nameTop - WordArt.avatarAt.dy) * s,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 이름 쪽이 남는 폭을 다 갖는다 — `[원문보기]`·`>`는 늘 오른쪽 끝에 붙는다.
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      a.nickname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: nameStyle,
                                    ),
                                  ),
                                  if (flag != null) ...[
                                    SizedBox(width: 14 * s),
                                    ArtImage(
                                      flag,
                                      width: WordArt.flagSize.width,
                                      height: WordArt.flagSize.height,
                                    ),
                                  ],
                                  SizedBox(width: 18 * s),
                                  // 시안 첫 칸은 `3분 전`, 둘째 칸은 `● ON` — 접속 중이면 ON, 아니면 쓴 지 얼마.
                                  if (a.online)
                                    ArtImage(
                                      WordArt.online,
                                      width: WordArt.onlineSize.width,
                                      height: WordArt.onlineSize.height,
                                    )
                                  else if (time.isNotEmpty)
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: WordArt.muted,
                                        fontSize: 30 * s,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (foreign) ...[
                              Semantics(
                                button: true,
                                label: l10n.dailyViewOriginal,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _showOriginal = !_showOriginal,
                                  ),
                                  child: ArtImage(
                                    WordArt.viewOriginal,
                                    width: WordArt.viewOriginalSize.width,
                                    height: WordArt.viewOriginalSize.height,
                                  ),
                                ),
                              ),
                              SizedBox(width: 20 * s),
                            ],
                            ArtImage(
                              WordArt.detail,
                              width: WordArt.detailSize.width,
                              height: WordArt.detailSize.height,
                            ),
                          ],
                        ),
                        SizedBox(height: 14 * s),
                        Text(
                          body,
                          style: TextStyle(
                            color: WordArt.ink,
                            fontSize: 32 * s,
                            height: 1.62,
                          ),
                        ),
                        if (a.imageUrl != null) ...[
                          SizedBox(height: 16 * s),
                          // 사진을 누르면 **원본만 화면 가운데 팝업**(배경을 누르면 닫힘, 2026-10-11 사용자 지시).
                          // 사진 밖 셀을 누르면 그대로 상세로 간다.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque, // 함정 #38
                            onTap: () =>
                                showOriginalImage(context, a.imageUrl!),
                            child: SizedBox(
                              width: WordArt.photoSize.width * s,
                              height: WordArt.photoSize.height * s,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18 * s),
                                    child: AuthedImage(url: a.imageUrl!),
                                  ),
                                  ArtImage(
                                    WordArt.photoFrame,
                                    width: WordArt.photoSize.width,
                                    height: WordArt.photoSize.height,
                                    fit: BoxFit.fill,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 17 * s),
                        Row(
                          children: [
                            SizedBox(
                              width: WordArt.countGap * s,
                              child: Row(
                                children: [
                                  ArtImage(
                                    WordArt.heart,
                                    width: WordArt.heartSize.width,
                                    height: WordArt.heartSize.height,
                                  ),
                                  SizedBox(width: 22 * s),
                                  Text('${a.likes}', style: countStyle),
                                ],
                              ),
                            ),
                            ArtImage(
                              WordArt.comment,
                              width: WordArt.commentSize.width,
                              height: WordArt.commentSize.height,
                            ),
                            SizedBox(width: 18 * s),
                            Text('${a.comments}', style: countStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 얼굴 동그라미 — 누르면 그 사람의 [프로필 보기](기획 9-2). 내 것은 열지 않는다.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.answer});

  final DailyAnswer answer;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final size = WordArt.avatarSize.width * s;
    final url = answer.photoUrl;
    return GestureDetector(
      onTap: answer.mine ? null : () => showProfileView(context, answer.userId),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(3 * s),
              child: ClipOval(
                child: url == null
                    ? const ColoredBox(color: Color(0xFFEDE4D8))
                    : AuthedImage(url: url),
              ),
            ),
            ArtImage(
              WordArt.avatarFrame,
              width: WordArt.avatarSize.width,
              height: WordArt.avatarSize.height,
            ),
          ],
        ),
      ),
    );
  }
}
