import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../postinfo/presentation/providers/post_info_provider.dart';
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../widgets/request_popup.dart';
import '../widgets/talk_art.dart';
import 'chat_screen.dart';

/// 받은 신청 팝업 — 기획서 260919 6-2의 **[포스트 정보]**(시안 image16 · `대화방_받은신청_팝업창`).
///
/// 위: 보낸 사람의 **포스트 사진**(좌우로 넘긴다, `1/9`) · 이름·나이 · 국기·지역.
/// 가운데 흰 패널: 편지 아이콘 · `[원문보기]` · `[프로필]` · **신청 한마디**.
/// 아래: `[✕ 거절하기]` · `[💬 대화하기]`.
///
/// - 🚨 **번역은 무조건 공짜**(기획사항 2026-09-19). 서버 scope `REQUEST`로 부른다 — 쿼터를 세지 않는다.
/// - 기본은 **번역문**만 보인다(기획서 — "번역은 자동 번역 지원"). `[원문보기]`를 누르면
///   **원문 위 · 구분선 · 번역문 아래(파란 글)** 로 함께 보인다(시안 image16의 모양).
///   번역문이 원문과 같으면(같은 언어이거나 공급자가 꺼져 있으면) `[원문보기]`를 감춘다.
/// - 글이 길면 **패널이 아래로 늘어나고 그만큼 사진이 줄어든다**(기획사항). 🚨 **스크롤은 없다**(기획 결정).
/// - 🚨 화살표는 **뒤로가기 하나뿐**이다(기획사항 — "뒤로가기말고는 대화방에는 화살표가 없음").
///
/// 여는 것만으로 서버가 이 신청을 '확인함'으로 바꾼다(V26) — 목록의 `N`이 꺼진다.
class ReceivedRequestScreen extends ConsumerStatefulWidget {
  const ReceivedRequestScreen({super.key, required this.request});

  final ChatRequest request;

  static Route<void> route(ChatRequest request) => MaterialPageRoute(
    builder: (_) => ReceivedRequestScreen(request: request),
    fullscreenDialog: true,
  );

  @override
  ConsumerState<ReceivedRequestScreen> createState() =>
      _ReceivedRequestScreenState();
}

class _ReceivedRequestScreenState extends ConsumerState<ReceivedRequestScreen> {
  final _pages = PageController();
  int _page = 0;

  String? _translated;
  bool _showOriginal = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 내 언어(Localizations)는 initState에서 못 읽는다 — 첫 프레임 뒤에 부른다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _translate());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// 신청 한마디를 내 언어로 옮긴다. 실패해도 원문으로 보여 주면 되므로 조용히 넘긴다.
  Future<void> _translate() async {
    final text = widget.request.message;
    if (text.isEmpty || !mounted) return;
    final target = Localizations.localeOf(context).languageCode;
    try {
      final result = await ref
          .read(gardenApiProvider)
          .translateRequestMessage(text, target);
      if (mounted) setState(() => _translated = result);
    } catch (_) {
      // 번역이 안 되면 원문만 보인다 — 신청을 못 읽게 막을 이유는 없다.
    }
  }

  Future<void> _decide({required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = L10n.of(context);
    final actions = ref.read(chatActionsProvider);
    final requestId = widget.request.id;

    if (!accept) {
      final error = await actions.reject(requestId);
      if (!mounted) return;
      setState(() => _busy = false);
      if (error != null) return _toast(errorMessage(l10n, error));
      Navigator.of(context).pop();
      return;
    }

    final (roomId, error) = await actions.acceptOpening(requestId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null || roomId == null) {
      if (error != null) _toast(errorMessage(l10n, error));
      return;
    }
    // 기획서 260919 6-2: "[대화하기] 버튼 클릭 시 상대방과의 **신규 채팅창** 호출."
    final r = widget.request;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          room: ChatRoomSummary(
            roomId: roomId,
            type: 'MATCH',
            partnerId: r.fromUserId,
            partnerNickname: r.partnerNickname,
            partnerAge: r.partnerAge,
            partnerCountry: r.partnerCountry,
            partnerPhotoUrl: r.partnerPhotoUrl,
            partnerOnline: r.partnerOnline,
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final info = ref.watch(postInfoProvider(widget.request.fromUserId));

    return Scaffold(
      backgroundColor: AppColors.night,
      body: info.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        // [포스트 정보]를 못 읽어도(차단 409 등) 신청 자체는 보여 줄 수 있다 —
        // 목록에서 받은 값으로 그린다. 사진만 비고 결정은 그대로 할 수 있다.
        error: (error, stack) => _body(context, s, null),
        data: (data) => _body(context, s, data),
      ),
    );
  }

  Widget _body(BuildContext context, double s, PostInfo? info) {
    final r = widget.request;
    final translated = _translated;
    final hasTranslation =
        translated != null && translated.trim() != r.message.trim();

    // 🚨 **이 화면은 스크롤하지 않는다**(기획 결정 2026-09-19 — 끌면 "울렁울렁" 움직였다).
    //
    // 시안(1080×2640)을 그대로 쌓으면 2344px라 **세로가 짧은 폰에서 조금 넘치고**, 그래서
    // 스크롤뷰가 살짝 움직였다. 스크롤을 막기만 하면 아래 버튼이 잘린다 —
    // 대신 **사진 칸이 남는 높이를 차지**하게 했다. 흰 패널·버튼은 시안 크기 그대로고,
    // 글이 길어져 패널이 늘어나면 **그만큼 사진이 줄어든다**(기획사항 "문구가 길어지면 아래로 늘어남").
    // 한마디가 100자로 묶여 있어 패널이 사진을 다 밀어낼 일은 없다.
    return Padding(
      padding: EdgeInsets.only(
        top:
            DesignCanvas.titleTopInSafeArea(context) +
            MediaQueryData.fromView(View.of(context)).padding.top,
        bottom: MediaQuery.paddingOf(context).bottom + 32 * s,
      ),
      child: Column(
        children: [
          Expanded(
            child: PopupPhotoArea(
              info: info,
              fallbackPhoto: r.partnerPhotoUrl,
              nickname: info?.nickname ?? r.partnerNickname,
              age: info?.age ?? r.partnerAge,
              country: info?.country ?? r.partnerCountry,
              controller: _pages,
              page: _page,
              onPageChanged: (i) => setState(() => _page = i),
            ),
          ),
          PopupPanel(
            leading: const PanelItem(
              asset: TalkArt.message,
              size: TalkArt.messageSize,
              left: TalkArt.messageLeft,
            ),
            trailing: PanelItem(
              asset: TalkArt.profile,
              size: TalkArt.profileSize,
              left: TalkArt.profileLeft,
              onTap: () => showProfileView(context, r.fromUserId),
            ),
            original: r.message,
            translated: hasTranslation ? translated : null,
            showOriginal: _showOriginal,
            onToggleOriginal: () =>
                setState(() => _showOriginal = !_showOriginal),
          ),
          SizedBox(height: TalkArt.panelToButtons * s),
          PopupDecideRow(
            left: PopupDecide(
              asset: TalkArt.refuse,
              onTap: _busy ? null : () => _decide(accept: false),
            ),
            right: PopupDecide(
              asset: TalkArt.accept,
              onTap: _busy ? null : () => _decide(accept: true),
            ),
          ),
        ],
      ),
    );
  }
}
