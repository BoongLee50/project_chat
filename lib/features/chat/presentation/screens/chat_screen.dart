import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../shared/widgets/translate_pass_button.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../garden/data/models/translate_access.dart';
import '../../../moderation/presentation/widgets/block_dialog.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/screens/pass_screen.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/voice_player.dart';
import '../providers/voice_recorder.dart';
import '../widgets/chat_art.dart';
import '../widgets/voice_message.dart';

/// 채팅창 — 기획서 261011 **5장**, 시안 `Scene_Chat`(2026-10-25).
///
/// 히스토리는 REST로 읽고, 이후 메시지는 WebSocket으로 실시간 송수신한다.
/// 소켓 화면이라 공통 갱신 방침("낡았으면 1분마다 다시 읽기")의 예외다.
///
/// 위에서부터 머리(뒤로·사진·이름 나이 국기·[⋯]) → 안내 줄(문구 · [번역 | …]) →
/// 메시지 → 입력줄([GIF] · 칸 · [음성]/[보내기]). 시안은 **밝은 바탕**이다 — 앱의 다른 화면과 달리.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.room});

  final ChatRoomSummary room;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  /// 음성 전송 중. 올리기 버튼을 두 번 눌러 같은 녹음이 두 번 가는 걸 막는다.
  bool _sendingVoice = false;

  /// 이 방에서 번역이 되는가(기획 5장 — "대화방 5개까지, 삭제 전까지 계속").
  ///
  /// **방에 들어올 때 한 번** 자리를 잡는다. 이미 연 방이면 자리를 더 쓰지 않는다.
  TranslateAccess? _translate;

  @override
  void initState() {
    super.initState();
    _openTranslate();
  }

  Future<void> _openTranslate() async {
    try {
      final access = await ref
          .read(gardenApiProvider)
          .openRoomTranslate(widget.room.roomId);
      if (!mounted) return;
      setState(() => _translate = access);

      // 다 썼으면 기획서가 정해 둔 문구를 하단에 띄운다.
      // 공급자가 아직 없을 때는 "다 썼다"가 아니다 — 자리도 안 깎였다.
      if (!access.granted && !access.unlimited && access.providerReady) {
        _toast(L10n.of(context).translateRoomExhausted);
      }
    } on ApiException {
      // 번역은 곁가지다 — 실패해도 대화는 그대로 한다.
      if (mounted) setState(() => _translate = TranslateAccess.unavailable);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// [음성] — 녹음 시작. 권한이 없으면 안내만 하고 아무것도 바꾸지 않는다.
  Future<void> _startRecording() async {
    // 듣고 있던 게 있으면 멈춘다. 녹음과 재생이 겹치면 마이크에 그 소리가 섞인다.
    await ref.read(voicePlayerProvider.notifier).stop();
    final ok = await ref.read(voiceRecorderProvider.notifier).start();
    if (!mounted || ok) return;
    _toast(L10n.of(context).voicePermissionDenied);
  }

  /// [녹음 삭제] — 파일을 지우고 기본 입력줄로 돌아간다.
  Future<void> _discardVoice() async {
    await ref.read(voicePlayerProvider.notifier).stop();
    await ref.read(voiceRecorderProvider.notifier).discard();
  }

  /// 녹음본의 [보내기] — 녹음 파일을 올리고 메시지로 보낸다.
  Future<void> _sendVoice() async {
    final myId = ref.read(sessionProvider).profile?.id;
    if (myId == null) return;

    final recorder = ref.read(voiceRecorderProvider.notifier);
    final take = ref.read(voiceRecorderProvider);
    final bytes = await recorder.readBytes();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      // 파일이 사라졌거나 길이가 0. 남은 상태만 정리하고 끝낸다.
      await recorder.discard();
      return;
    }

    setState(() => _sendingVoice = true);
    // 재생 중이던 미리듣기를 멈춰야 보낸 뒤 상태가 깨끗해진다.
    await ref.read(voicePlayerProvider.notifier).stop();
    final error = await ref
        .read(chatMessagesProvider(widget.room.roomId).notifier)
        .sendVoice(
          bytes: bytes,
          durationMs: take.elapsed.inMilliseconds,
          myUserId: myId,
        );
    if (!mounted) return;
    setState(() => _sendingVoice = false);

    if (error != null) {
      // 실패해도 녹음은 남겨 둔다 — 다시 누르면 그대로 재전송할 수 있다.
      _toast(errorMessage(L10n.of(context), error));
      return;
    }
    await recorder.discard();
    if (!mounted) return;
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final myId = ref.read(sessionProvider).profile?.id;
    if (myId == null) return;

    _controller.clear();
    final error = await ref
        .read(chatMessagesProvider(widget.room.roomId).notifier)
        .send(text, myId);
    if (!mounted) return;
    if (error != null) {
      _controller.text = text; // 사라지지 않게 입력칸에 되돌려 준다
      _toast(errorMessage(L10n.of(context), error));
      return;
    }
    _scrollToBottom();
  }

  /// [GIF] — 🚧 검색 API 키(KLIPY·Tenor)가 아직 없다. 버튼을 죽이지 않고 이유를 말한다
  /// (사용자 결정 2026-10-25: GIF는 되살리고 키는 나중에).
  void _openGif() => _toast(L10n.of(context).chatGifNotReady);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// [친구 신청] — 상대가 수락하면 친구가 된다.
  Future<void> _requestFriend() async {
    final l10n = L10n.of(context);
    final error = await ref
        .read(friendActionsProvider)
        .request(widget.room.partnerId);
    if (!mounted) return;
    _toast(error == null ? l10n.chatFriendRequestSent : errorMessage(l10n, error));
  }

  /// 신고·차단은 서버가 대화방을 종료시키므로, 성공하면 화면을 닫고 목록으로 돌아간다.
  Future<void> _report() async {
    final l10n = L10n.of(context);
    final done = await ReportDialog.show(
      context,
      targetUserId: widget.room.partnerId,
      targetNickname: widget.room.partnerNickname,
    );
    if (done != true || !mounted) return;
    _toast(l10n.chatReportDone);
    Navigator.of(context).pop();
  }

  Future<void> _block() async {
    final l10n = L10n.of(context);
    final done = await BlockDialog.show(
      context,
      targetUserId: widget.room.partnerId,
      targetNickname: widget.room.partnerNickname,
    );
    if (done != true || !mounted) return;
    _toast(l10n.chatBlockDone(widget.room.partnerNickname));
    Navigator.of(context).pop();
  }

  /// [대화방 나가기] — 기획서 5장 *"방 나가기 안내 팝업 출력 및 채팅방 삭제"*.
  /// 되돌릴 수 없으니 한 번 묻는다(예전에는 누르자마자 나갔다).
  Future<void> _leave() async {
    final l10n = L10n.of(context);
    final ok = await ConfirmDialog.show(context, l10n.chatLeaveConfirm);
    if (!ok || !mounted) return;
    final error = await ref
        .read(chatActionsProvider)
        .leave(widget.room.roomId);
    if (!mounted) return;
    if (error != null) {
      _toast(errorMessage(L10n.of(context), error));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final messages = ref.watch(chatMessagesProvider(widget.room.roomId));
    final myId = ref.watch(sessionProvider).profile?.id;

    // 새 메시지가 오면 아래로 스크롤.
    ref.listen(chatMessagesProvider(widget.room.roomId), (_, _) {
      _scrollToBottom();
    });

    // 밝은 바탕이라 상태바 글자를 어둡게 — 앱의 다른 화면은 어두운 바탕이다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ChatArt.paper,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(ChatArt.background),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              _Header(
                room: widget.room,
                onLeave: _leave,
                onRequestFriend: _requestFriend,
                onReport: _report,
                onBlock: _block,
              ),
              Image.asset(
                ChatArt.headerShadow,
                width: double.infinity,
                height: ChatArt.headerShadowHeight * s,
                fit: BoxFit.fill,
              ),
              _NoticeRow(translate: _translate),
              Expanded(
                child: messages.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: ChatArt.sloganInk),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      l10n.chatLoadFailed,
                      style: TextStyle(
                        color: ChatArt.timeInk,
                        fontSize: ChatArt.timeFont * s,
                      ),
                    ),
                  ),
                  data: (list) => ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: (ChatArt.listTop -
                              ChatArt.noticeTop -
                              ChatArt.infoTransSize.height) *
                          s,
                      bottom: 30 * s,
                    ),
                    children: [
                      // 날짜가 바뀌는 자리마다 구분 글자를 넣는다.
                      // 없으면 어제 밤 대화와 오늘 대화가 한 덩어리로 붙어 보인다.
                      for (var i = 0; i < list.length; i++) ...[
                        if (_startsNewDay(list, i))
                          _DateDivider(date: list[i].createdAt),
                        _MessageRow(
                          message: list[i],
                          mine: list[i].senderId == myId,
                          avatarUrl: widget.room.partnerPhotoUrl,
                          onAvatar: () =>
                              showProfileView(context, widget.room.partnerId),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _InputBar(
                controller: _controller,
                phase: ref.watch(voiceRecorderProvider).phase,
                sendingVoice: _sendingVoice,
                onGif: _openGif,
                onSend: _send,
                onRecord: _startRecording,
                onStopRecording: () =>
                    ref.read(voiceRecorderProvider.notifier).stop(),
                onDiscardVoice: _discardVoice,
                onSendVoice: _sendVoice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 둥근 사진 + 그 위에 얹는 얇은 틀(`frame_chat_profile` · `frame_chat_commentprofile_`).
class _RingedPhoto extends StatelessWidget {
  const _RingedPhoto({
    required this.url,
    required this.ring,
    required this.size,
  });

  final String? url;
  final String ring;

  /// 논리 픽셀(배율 적용 후).
  final double size;

  @override
  Widget build(BuildContext context) {
    // 틀 선이 사진 가장자리를 덮도록 사진을 아주 조금 안쪽으로.
    final inset = size * 0.02;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            left: inset,
            top: inset,
            right: inset,
            bottom: inset,
            child: ClipOval(
              child: url == null
                  ? const ColoredBox(color: Color(0xFFEDE7DD))
                  : AuthedImage(url: url!),
            ),
          ),
          Positioned.fill(
            child: Image.asset(ring, filterQuality: FilterQuality.medium),
          ),
        ],
      ),
    );
  }
}

/// 머리 — 뒤로(`52`) · 사진(`155`) · `미유 24 🇯🇵`(`319`) · [⋯](`967`). 모두 `y 190` 선에 맞춘다.
class _Header extends StatelessWidget {
  const _Header({
    required this.room,
    required this.onLeave,
    required this.onRequestFriend,
    required this.onReport,
    required this.onBlock,
  });

  final ChatRoomSummary room;
  final VoidCallback onLeave;
  final VoidCallback onRequestFriend;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final top = MediaQuery.paddingOf(context).top;
    const rowTop = ChatArt.headerCenter - ChatArt.profileSize / 2;
    final rowHeight = ChatArt.profileSize * s;
    final flag = ChatArt.flagOf(room.partnerCountry);

    return SizedBox(
      // 시안의 상태바 자리(100) 대신 실제 상태바 높이를 쓴다.
      height:
          top + (ChatArt.headerBottom - ChatArt.statusBarInDesign) * s,
      child: Padding(
        padding: EdgeInsets.only(
          top: top + (rowTop - ChatArt.statusBarInDesign) * s,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: rowHeight,
            child: Stack(
              children: [
                // 뒤로 — 그림(32×54)이 작아서 누르는 자리를 사진 앞까지 넓힌다.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: (ChatArt.profileLeft - 10) * s,
                  child: Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Padding(
                        padding: EdgeInsets.only(left: ChatArt.backLeft * s),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ArtImage(
                            ChatArt.back,
                            width: ChatArt.backSize.width,
                            height: ChatArt.backSize.height,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: ChatArt.profileLeft * s,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => showProfileView(context, room.partnerId),
                    child: _RingedPhoto(
                      url: room.partnerPhotoUrl,
                      ring: ChatArt.profileRing,
                      size: ChatArt.profileSize * s,
                    ),
                  ),
                ),
                Positioned(
                  left: ChatArt.nameLeft * s,
                  right: (DesignCanvas.width - ChatArt.viewMoreLeft + 20) * s,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: room.partnerNickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (room.partnerAge != null)
                                TextSpan(text: ' ${room.partnerAge}'),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ChatArt.nameInk,
                            fontSize: ChatArt.nameFont * s,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (flag != null) ...[
                        SizedBox(width: ChatArt.flagGap * s),
                        ArtImage(
                          flag,
                          width: ChatArt.flagSize,
                          height: ChatArt.flagSize,
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: (ChatArt.viewMoreLeft - 30) * s,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _ManageMenu(
                    room: room,
                    onLeave: onLeave,
                    onRequestFriend: onRequestFriend,
                    onReport: onReport,
                    onBlock: onBlock,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [⋯] 채팅 관리 패널 — 프로필 보기 · 신고하기 · 차단하기 · 친구 신청 · 대화방 나가기.
///
/// 🚧 패널 시안·그림은 아직 안 왔다 — 글자만 있는 흰 메뉴로 자리를 채운다(예전 `Icons.*` 아이콘은 뺐다).
class _ManageMenu extends StatelessWidget {
  const _ManageMenu({
    required this.room,
    required this.onLeave,
    required this.onRequestFriend,
    required this.onReport,
    required this.onBlock,
  });

  final ChatRoomSummary room;
  final VoidCallback onLeave;
  final VoidCallback onRequestFriend;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    PopupMenuItem<String> item(String value, String label) => PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: const TextStyle(color: ChatArt.nameInk, fontSize: 15),
      ),
    );

    return PopupMenuButton<String>(
      color: Colors.white,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'leave') onLeave();
        if (value == 'friend') onRequestFriend();
        if (value == 'report') onReport();
        if (value == 'block') onBlock();
        if (value == 'profile') showProfileView(context, room.partnerId);
      },
      // 순서는 기획서 5장 — 보기 → 신고 → 차단 → 친구 → 나가기.
      itemBuilder: (context) => [
        item('profile', l10n.chatMenuProfile),
        item('report', l10n.chatMenuReport),
        item('block', l10n.chatMenuBlock),
        // 이미 친구인 방(FRIEND)에서는 신청 항목을 숨긴다.
        if (room.type != 'FRIEND') item('friend', l10n.chatMenuFriendRequest),
        item('leave', l10n.chatMenuLeave),
      ],
      child: Padding(
        padding: EdgeInsets.only(left: 30 * s),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ArtImage(
            ChatArt.viewMore,
            width: ChatArt.viewMoreSize.width,
            height: ChatArt.viewMoreSize.height,
          ),
        ),
      ),
    );
  }
}

/// `작은 배려, 아름다운 대화` · [⭐ 번역 | 4일] (`52, 338` · `757, 312`).
class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.translate});

  final TranslateAccess? translate;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final state = translate;
    final label = state == null
        ? null
        : TranslatePassButton.labelOf(l10n, state).$1;
    final top = ChatArt.noticeTop - ChatArt.headerBottom - ChatArt.headerShadowHeight;

    return Padding(
      padding: EdgeInsets.only(top: top * s),
      child: SizedBox(
        height: ChatArt.infoTransSize.height * s,
        child: Row(
          children: [
            SizedBox(width: ChatArt.sloganLeft * s),
            Expanded(
              child: Text(
                l10n.chatSlogan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ChatArt.sloganInk,
                  fontSize: ChatArt.sloganFont * s,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // [번역] — 기획서 10-2-3 *"[채팅창] 화면의 [번역 패스] 버튼 클릭 시 [자동 번역 구매] 화면 호출"*.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(
                context,
              ).push(PassScreen.route(StoreKind.translatePass)),
              child: SizedBox(
                width: ChatArt.infoTransSize.width * s,
                height: ChatArt.infoTransSize.height * s,
                child: Stack(
                  children: [
                    ArtImage(
                      ChatArt.infoTrans,
                      width: ChatArt.infoTransSize.width,
                      height: ChatArt.infoTransSize.height,
                    ),
                    if (label != null)
                      Positioned(
                        left: ChatArt.infoTransLabel.left * s,
                        width: ChatArt.infoTransLabel.width * s,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: ChatArt.infoTransInk,
                                fontSize: 34 * s,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width:
                  (DesignCanvas.width -
                      ChatArt.infoTransLeft -
                      ChatArt.infoTransSize.width) *
                  s,
            ),
          ],
        ),
      ),
    );
  }
}

/// 앞 메시지와 **날짜가 다른가**. 첫 메시지는 언제나 새 날이다.
bool _startsNewDay(List<ChatMessage> list, int i) {
  if (i == 0) return true;
  final a = list[i - 1].createdAt;
  final b = list[i].createdAt;
  return a.year != b.year || a.month != b.month || a.day != b.day;
}

/// `오늘` / `어제` / `2026. 08. 28.` — 시안에는 없지만(하루치만 그렸다) 날이 바뀌는 자리를 알려야 한다.
/// 시간 글자와 같은 색·크기로 가운데에 조용히 둔다.
class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final today = DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;

    final label = switch (days) {
      0 => l10n.chatDateToday,
      1 => l10n.chatDateYesterday,
      _ => '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
          '${date.day.toString().padLeft(2, '0')}.',
    };

    return Padding(
      padding: EdgeInsets.only(bottom: ChatArt.rowGap * s),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: ChatArt.timeInk,
            fontSize: ChatArt.timeFont * s,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 말풍선 그림을 **9조각으로 늘려** 글 길이에 맞춘다.
///
/// 그림은 1080 캔버스 픽셀로 그려져 있으므로 캔버스를 `s`배로 줄인 채 원본 픽셀 좌표로
/// `drawImageNine`을 부른다 — 모서리·꼬리가 화면 배율대로 줄어든다.
///
/// ⚠️ `DecorationImage(centerSlice:)`는 쓰지 않는다. 배율(`scale: 1/s`)을 걸면 내부에서
/// `원본/배율×배율 == 원본`을 단언하는데, 부동소수 오차로 **깨진다**(실제로 깨졌다).
class _SlicedBubble extends StatefulWidget {
  const _SlicedBubble({
    required this.asset,
    required this.slice,
    required this.padding,
    required this.child,
  });

  final String asset;

  /// 늘어나는 가운데 조각(그림 원본 픽셀).
  final Rect slice;
  final EdgeInsets padding;
  final Widget child;

  @override
  State<_SlicedBubble> createState() => _SlicedBubbleState();
}

class _SlicedBubbleState extends State<_SlicedBubble> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final _listener = ImageStreamListener((info, _) {
    if (mounted) setState(() => _image = info);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _SlicedBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final size = ChatArt.bubbleSize;
    final slice = widget.slice;
    return CustomPaint(
      painter: _NinePainter(image: _image?.image, slice: slice, scale: s),
      child: ConstrainedBox(
        // 모서리 조각보다 작아지면 9조각이 뭉개진다 — 가장 작은 크기를 지킨다.
        constraints: BoxConstraints(
          minWidth: (size.width - slice.width + 1) * s,
          minHeight: (size.height - slice.height + 1) * s,
        ),
        child: Padding(padding: widget.padding * s, child: widget.child),
      ),
    );
  }
}

class _NinePainter extends CustomPainter {
  _NinePainter({required this.image, required this.slice, required this.scale});

  final ui.Image? image;
  final Rect slice;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) return;
    canvas
      ..save()
      ..scale(scale);
    canvas.drawImageNine(
      img,
      slice,
      Rect.fromLTWH(0, 0, size.width / scale, size.height / scale),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NinePainter old) =>
      old.image != image || old.slice != slice || old.scale != scale;
}

/// 메시지 한 줄. 상대는 `[얼굴][말풍선] 시간`, 나는 `시간 [말풍선]`.
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.mine,
    required this.onAvatar,
    this.avatarUrl,
  });

  final ChatMessage message;
  final bool mine;
  final String? avatarUrl;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);

    final body = message.isVoice
        ? VoiceBubbleContent(message: message, scale: s)
        : Text(
            message.body,
            style: TextStyle(
              color: ChatArt.messageInk,
              fontSize: ChatArt.messageFont * s,
              height: ChatArt.messageLineHeight,
            ),
          );

    final bubble = _SlicedBubble(
      asset: mine ? ChatArt.myBubble : ChatArt.counterBubble,
      slice: mine ? ChatArt.mySlice : ChatArt.counterSlice,
      padding: message.isVoice
          ? ChatArt.voicePad
          : (mine ? ChatArt.myPad : ChatArt.counterPad),
      child: body,
    );

    final timeText = Padding(
      padding: EdgeInsets.only(bottom: ChatArt.timeLift * s),
      child: Text(
        time,
        style: TextStyle(color: ChatArt.timeInk, fontSize: ChatArt.timeFont * s),
      ),
    );

    final padding = EdgeInsets.only(
      left: ChatArt.sidePad * s,
      right: (DesignCanvas.width - ChatArt.myBubbleRight) * s,
      bottom: ChatArt.rowGap * s,
    );

    // 시간은 늘 보이고, 말풍선은 남은 폭 안에서 늘어난다(Flexible).
    // 내 말풍선은 왼쪽에 [ChatArt.myReserve]를 더 비워 둔다 — 시안에서 가장 긴 것이 700쯤이다.
    if (mine) {
      return Padding(
        padding: padding.copyWith(top: ChatArt.bubbleDrop * s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: ChatArt.myReserve * s),
            timeText,
            SizedBox(width: ChatArt.timeGap * s),
            Flexible(child: bubble),
          ],
        ),
      );
    }

    // 상대: 얼굴은 위에 붙고, 말풍선은 23 아래에서 시작하며, 시간은 말풍선 아랫변에 맞춘다.
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onAvatar,
            child: _RingedPhoto(
              url: avatarUrl,
              ring: ChatArt.avatarRing,
              size: ChatArt.avatarSize * s,
            ),
          ),
          SizedBox(width: ChatArt.avatarToBubble * s),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(top: ChatArt.bubbleDrop * s),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: bubble),
                  SizedBox(width: ChatArt.timeGap * s),
                  timeText,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력줄(`2373`) — 기획서 5장 *"메세지 입력부 구성"*의 세 모습.
///
/// | | 왼쪽 | 칸 | 오른쪽 |
/// |---|---|---|---|
/// | 기본 | [GIF] | 입력 | 글이 있으면 [보내기], 없으면 [음성] |
/// | 녹음 중 | (빈자리) | 실시간 파형 · 경과 | [정지] |
/// | 녹음 완료 | [녹음 삭제] | 파형 · 길이 · [녹음 재생] | [보내기] |
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.phase,
    required this.sendingVoice,
    required this.onGif,
    required this.onSend,
    required this.onRecord,
    required this.onStopRecording,
    required this.onDiscardVoice,
    required this.onSendVoice,
  });

  final TextEditingController controller;
  final VoiceRecordPhase phase;
  final bool sendingVoice;
  final VoidCallback onGif;
  final VoidCallback onSend;
  final VoidCallback onRecord;
  final VoidCallback onStopRecording;
  final VoidCallback onDiscardVoice;
  final VoidCallback onSendVoice;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget round(String asset, String label, VoidCallback? onTap) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ArtImage(
          asset,
          width: ChatArt.roundButton,
          height: ChatArt.roundButton,
        ),
      ),
    );

    final left = switch (phase) {
      VoiceRecordPhase.idle => round(ChatArt.gif, 'GIF', onGif),
      // 녹음 중에는 왼쪽 자리를 비운다 — [녹음 삭제]는 정지한 뒤에 생긴다(기획서 5장).
      VoiceRecordPhase.recording => SizedBox(width: ChatArt.roundButton * s),
      VoiceRecordPhase.preview => round(
        ChatArt.delete,
        l10n.voiceDelete,
        sendingVoice ? null : onDiscardVoice,
      ),
    };

    final inside = phase == VoiceRecordPhase.idle
        ? Padding(
            padding: EdgeInsets.only(
              left: ChatArt.inputTextLeft * s,
              right: 40 * s,
            ),
            child: Center(
              child: TextField(
                controller: controller,
                cursorColor: ChatArt.sloganInk,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: TextStyle(
                  color: ChatArt.messageInk,
                  fontSize: ChatArt.inputFont * s,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: l10n.chatInputHint,
                  hintStyle: TextStyle(
                    color: ChatArt.hintInk,
                    fontSize: ChatArt.inputFont * s,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
        : Padding(
            // 녹음 완료면 [녹음 재생](108)이 칸 오른쪽 끝에 붙는다(참고화면).
            padding: EdgeInsets.only(
              left: ChatArt.inputTextLeft * s,
              right: (phase == VoiceRecordPhase.preview ? 7 : 40) * s,
            ),
            child: VoiceRecordInside(scale: s, busy: sendingVoice),
          );

    final right = switch (phase) {
      // 글을 치면 [음성]이 [보내기]로 바뀐다(기획서 5장).
      VoiceRecordPhase.idle => ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => value.text.trim().isEmpty
            ? round(ChatArt.record, l10n.voiceRecord, onRecord)
            : round(ChatArt.sendOn, l10n.voiceSend, onSend),
      ),
      // 🚧 노란 [정지] 그림은 안 왔다 — 받은 것 중 [멈춤](`button_playstop`)을 같은 자리에 쓴다.
      VoiceRecordPhase.recording => Semantics(
        button: true,
        label: l10n.voiceStop,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onStopRecording,
          child: SizedBox(
            width: ChatArt.roundButton * s,
            height: ChatArt.roundButton * s,
            child: Center(
              child: ArtImage(
                ChatArt.pause,
                width: ChatArt.playSize,
                height: ChatArt.playSize,
              ),
            ),
          ),
        ),
      ),
      VoiceRecordPhase.preview => round(
        sendingVoice ? ChatArt.sendOff : ChatArt.sendOn,
        l10n.voiceSend,
        sendingVoice ? null : onSendVoice,
      ),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ChatArt.inputLeft * s,
        20 * s,
        ChatArt.inputLeft * s,
        30 * s + bottom,
      ),
      child: Row(
        children: [
          left,
          SizedBox(width: ChatArt.inputGap * s),
          Expanded(
            child: SizedBox(
              height: ChatArt.inputFrameSize.height * s,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(ChatArt.inputFrame, fit: BoxFit.fill),
                  ),
                  Positioned.fill(child: inside),
                ],
              ),
            ),
          ),
          SizedBox(width: ChatArt.inputGap * s),
          right,
        ],
      ),
    );
  }
}
