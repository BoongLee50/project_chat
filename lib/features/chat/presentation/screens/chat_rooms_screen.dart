import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/art_top_bar.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../widgets/talk_art.dart';
import 'chat_screen.dart';
import 'received_request_screen.dart';

/// 대화방 — `[대화 목록]` · `[받은 신청]` 두 탭(기획서 260919 6-1·6-2, Scene_Talk 전달본).
///
/// 🚨 **판단의 우선순위**: 기획사항(2026-09-19) > 기획서 260919 > 이미지.
///
/// 두 탭은 **같은 셀**을 쓴다 — *"받은 신청의 화면 구성과 기능은 대화 목록창과 동일"*.
/// 다른 것은 셀 아래 글(마지막 대화 ↔ 신청 한마디)과 눌렀을 때 가는 곳뿐이다.
///
/// 260906판에서 **빠진 것**(기획서에 없으면 사라진 것으로 본다 — docs/12 §6):
/// - 셀 오른쪽의 `[친구]`·`[친구 신청]`·`[신청 대기]` 버튼
/// - 프로필 사진을 누르면 [포스트 정보]로 가던 것 → 셀을 누르면 **확인 후 채팅창**
/// - 🚨 화살표 — *"뒤로가기 말고는 대화방에는 화살표가 없음!"*. 예시 그림의 `>`는 따르지 않는다.
class ChatRoomsScreen extends ConsumerStatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  ConsumerState<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends ConsumerState<ChatRoomsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final rooms = ref.watch(chatRoomsProvider);
    final received = ref.watch(receivedRequestsProvider);

    final roomList = rooms.valueOrNull ?? const <ChatRoomSummary>[];
    final requestList = received.valueOrNull ?? const <ChatRequest>[];

    // 탭 빨간 점의 숫자(기획서: "미확인 메시지가 존재할 경우 그 갯수").
    // [대화 목록]은 안 읽은 **메시지** 수, [받은 신청]은 아직 **안 열어 본 신청** 수다 —
    // 받은 신청은 대화 목록과 "기능이 동일"하므로 '미확인'의 뜻을 그대로 옮겼다.
    final unreadMessages = roomList.fold<int>(0, (sum, r) => sum + r.unreadCount);
    final unviewedRequests = requestList.where((r) => !r.viewed).length;

    // 셸이 SafeArea로 상태바만큼 밀어 놨지만, 시안 배경은 **화면 맨 위까지** 올라간다.
    // SafeArea 안에서는 상태바 높이를 알 수 없으므로 화면(View)에서 직접 읽는다(함정 #32).
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -statusBar,
          left: 0,
          right: 0,
          child: Image.asset(
            TalkArt.background,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: DesignCanvas.titleTopInSafeArea(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀은 시안에서 x=47, Prime·루나 줄은 오른쪽 끝(1055)까지다.
              Padding(
                padding: EdgeInsets.only(
                  left: 47 * s,
                  right: DesignCanvas.contentLeft * s,
                ),
                child: const ArtTopBar(
                  title: TalkArt.title,
                  titleSize: TalkArt.titleSize,
                ),
              ),
              SizedBox(height: DesignCanvas.headerToRow * s),
              _Tabs(
                index: _tab,
                unreadMessages: unreadMessages,
                unviewedRequests: unviewedRequests,
                onChanged: (i) => setState(() => _tab = i),
              ),
              // 탭 아래(356 + 98) → 첫 셀(499).
              SizedBox(height: (499 - 356 - TalkArt.tabSize.height) * s),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.moonlight,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    await ref.read(chatRoomsProvider.notifier).refresh();
                    ref.invalidate(receivedRequestsProvider);
                  },
                  child: _tab == 0
                      ? _RoomGrid(rooms: rooms)
                      : _RequestGrid(requests: received),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 탭 ────────────────────────────────────────────────────
/// `[대화 목록]` `[받은 신청]` — **그림 두 벌**(고른 쪽 노랑 / 아닌 쪽 흰색).
///
/// 빨간 점은 **숫자가 있을 때만** 붙고, 숫자는 **99가 최대**다(기획사항 2026-09-19 —
/// "레드닷은 숫자표기 99가 최대치"). 기획서는 "99개를 넘으면 숫자 표시를 하지 않음"이라
/// 서로 다른데, 신뢰 순서상 기획사항을 따랐다(넘으면 `99`로 멈춘다).
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.index,
    required this.unreadMessages,
    required this.unviewedRequests,
    required this.onChanged,
  });

  final int index;
  final int unreadMessages;
  final int unviewedRequests;
  final ValueChanged<int> onChanged;

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
              child: _RedDot(count: count),
            ),
        ],
      ),
    );

    return Row(
      children: [
        SizedBox(width: TalkArt.tabListLeft * s),
        tab(0, TalkArt.tabListOn, TalkArt.tabListOff, unreadMessages),
        SizedBox(width: gap * s),
        tab(1, TalkArt.tabReceiveOn, TalkArt.tabReceiveOff, unviewedRequests),
      ],
    );
  }
}

/// 빨간 점 그림 위에 숫자(폰트 — 값이 변한다). 99가 최대.
class _RedDot extends StatelessWidget {
  const _RedDot({required this.count});

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
class _RoomGrid extends StatelessWidget {
  const _RoomGrid({required this.rooms});

  final AsyncValue<List<ChatRoomSummary>> rooms;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final list = rooms.valueOrNull ?? const <ChatRoomSummary>[];
    if (rooms.isLoading && list.isEmpty) return const _Loading();
    if (list.isEmpty) return _Empty(message: l10n.chatRoomsEmpty);

    return _CellGrid(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final room = list[i];
        return _TalkCell(
          photoUrl: room.partnerPhotoUrl,
          nickname: room.partnerNickname,
          age: room.partnerAge,
          country: room.partnerCountry,
          online: room.partnerOnline,
          unconfirmed: room.unreadCount > 0,
          at: room.lastMessageAt,
          text: room.lastMessage,
          onTap: () async {
            // 기획서 260919 6-1: *"대화 목록 선택 시 '대화방으로 이동할까요?' 안내 메세지 출력 후
            // 사용자 확인을 거쳐 채팅창 이동."*
            final go = await ConfirmDialog.show(context, l10n.chatRoomsMoveConfirm);
            if (!go || !context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
            );
          },
        );
      },
    );
  }
}

class _RequestGrid extends ConsumerWidget {
  const _RequestGrid({required this.requests});

  final AsyncValue<List<ChatRequest>> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final list = requests.valueOrNull ?? const <ChatRequest>[];
    if (requests.isLoading && list.isEmpty) return const _Loading();
    if (list.isEmpty) return _Empty(message: l10n.chatRequestsEmpty);

    return _CellGrid(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final request = list[i];
        return _TalkCell(
          photoUrl: request.partnerPhotoUrl,
          nickname: request.partnerNickname,
          age: request.partnerAge,
          country: request.partnerCountry,
          online: request.partnerOnline,
          // 받은 신청의 '미확인'은 **아직 안 열어 본 신청**이다(V26).
          unconfirmed: !request.viewed,
          at: request.createdAt,
          // 마지막 대화가 아니라 **신청 한마디**(기획사항 — "대화 신청 문구를 최대 25자까지").
          text: request.message,
          onTap: () async {
            await Navigator.of(context).push(ReceivedRequestScreen.route(request));
            // 열어 본 순간 서버가 '확인함'으로 바꾼다 — 돌아오면 N이 지워진 목록을 다시 읽는다.
            ref.invalidate(receivedRequestsProvider);
          },
        );
      },
    );
  }
}

/// 두 열 격자. 셀은 시안 규격(504×522)을 **그대로 비율로** 쓴다.
class _CellGrid extends StatelessWidget {
  const _CellGrid({required this.itemCount, required this.itemBuilder});

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
/// 대화 목록 · 받은 신청이 함께 쓰는 셀(`frame_list.png` 504×522).
///
/// 겹치는 순서: **상대 프로필 사진** → 외곽선·아래 어둠 그림 → 접속·미확인 표시 → 글.
/// - 사진은 **프로필 사진**이다(기획사항 — "cell안의 사진은 프로필 사진").
/// - `ON`은 **접속 중일 때만**(기획서 — "온라인 접속 상태일 경우에만"). 오프라인은 아무것도 없다.
///   예시 그림의 `온라인`/`오프라인` 글자 표기는 따르지 않았다(이미지는 신뢰 순위가 가장 낮다).
/// - `N`은 **확인 안 한 것이 있을 때만**.
/// - 시간은 분·시간·일, **30일이 넘으면 표시하지 않는다.**
/// - 글은 **25자까지 + `…`**. 넘치는 글자는 두 줄까지 흐른다.
class _TalkCell extends StatelessWidget {
  const _TalkCell({
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
    final time = _timeAgo(l10n, at);

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
                _clip25(text!),
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

  /// 25자까지 + `…`(기획서·기획사항 공통). 이모지가 반쪽으로 잘리지 않게 **글자 단위**로 자른다.
  static String _clip25(String text) {
    final chars = text.characters;
    return chars.length <= 25 ? text : '${chars.take(25)}…';
  }

  /// 분·시간·일 단위. **30일이 넘으면 표시하지 않는다**(기획서 260919 6-1).
  static String _timeAgo(L10n l10n, DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inDays >= 30) return '';
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppColors.moonlight),
  );
}

/// 빈 목록 — 안내 한 줄(폰트). 시안에 빈 상태가 없어 기존 문구를 그대로 쓴다.
///
/// 당겨서 새로고침이 되도록 스크롤 가능한 목록으로 둔다.
class _Empty extends StatelessWidget {
  const _Empty({required this.message});

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
