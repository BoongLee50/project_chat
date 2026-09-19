import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/art_top_bar.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../widgets/talk_art.dart';
import '../widgets/talk_cell.dart';
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
/// - 프로필 사진을 누르면 [포스트 정보]로 가던 것 → 셀을 누르면 **바로 채팅창**(확인창은 안 하기로 했다)
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
              ArtTabs(
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
                leftOn: TalkArt.tabListOn,
                leftOff: TalkArt.tabListOff,
                rightOn: TalkArt.tabReceiveOn,
                rightOff: TalkArt.tabReceiveOff,
                leftCount: unreadMessages,
                rightCount: unviewedRequests,
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

// ── 목록 ───────────────────────────────────────────────────
class _RoomGrid extends StatelessWidget {
  const _RoomGrid({required this.rooms});

  final AsyncValue<List<ChatRoomSummary>> rooms;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final list = rooms.valueOrNull ?? const <ChatRoomSummary>[];
    if (rooms.isLoading && list.isEmpty) return const CellLoading();
    if (list.isEmpty) return CellEmpty(message: l10n.chatRoomsEmpty);

    return CellGrid(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final room = list[i];
        return TalkCell(
          photoUrl: room.partnerPhotoUrl,
          nickname: room.partnerNickname,
          age: room.partnerAge,
          country: room.partnerCountry,
          online: room.partnerOnline,
          unconfirmed: room.unreadCount > 0,
          at: room.lastMessageAt,
          text: room.lastMessage,
          // 🚨 **확인 없이 바로 들어간다**(기획 결정 2026-09-19).
          // 기획서 260919 6-1에는 *"'대화방으로 이동할까요?' 안내 메세지 출력 후 사용자 확인"* 이
          // 있지만 **안 하기로 했고, 기획서에서도 추후 지워질 문장**이다. 되살리지 말 것.
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
          ),
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
    if (requests.isLoading && list.isEmpty) return const CellLoading();
    if (list.isEmpty) return CellEmpty(message: l10n.chatRequestsEmpty);

    return CellGrid(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final request = list[i];
        return TalkCell(
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
