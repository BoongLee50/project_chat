import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../chat/presentation/widgets/request_popup.dart';
import '../../../chat/presentation/widgets/talk_art.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../postinfo/presentation/providers/post_info_provider.dart';
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../data/models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../widgets/friend_art.dart';

/// [친구 요청 상세] — 받은 친구 신청을 누르면 뜬다(기획서 260919 7-2).
///
/// 대화방 받은 신청 팝업과 **같은 화면**이다(시안 둘을 겹치면 수락 버튼 그림만 다르다).
/// - 신청 한마디는 **번역문이 기본**, `[원문보기]`로 원문과 함께 본다. 번역은 **무료**(scope `REQUEST`) —
///   기획사항 *"받은 신청에서 번역은 무조건 공짜"* 는 대화방 문장이지만, 7-2가 "대화 목록창과 동일"이라 따른다.
/// - `[프로필]` → [프로필 보기] · `[✕ 요청 거절]` → 목록에서 삭제 · `[✓ 요청 수락]` → 친구가 된다.
///
/// 여는 것만으로 서버가 이 신청을 '확인함'으로 바꾼다(V27) — 목록의 `N`이 꺼진다.
///
/// 돌려주는 값: 수락했으면 `true`(부르는 쪽이 [친구 목록] 탭으로 넘긴다 — 새 친구가 맨 위에 N과 함께 보인다).
class FriendRequestScreen extends ConsumerStatefulWidget {
  const FriendRequestScreen({super.key, required this.request});

  final FriendRequest request;

  static Route<bool> route(FriendRequest request) => MaterialPageRoute(
    builder: (_) => FriendRequestScreen(request: request),
    fullscreenDialog: true,
  );

  @override
  ConsumerState<FriendRequestScreen> createState() =>
      _FriendRequestScreenState();
}

class _FriendRequestScreenState extends ConsumerState<FriendRequestScreen> {
  final _pages = PageController();
  int _page = 0;

  String? _translated;
  bool _showOriginal = false;
  bool _busy = false;

  FriendRequest get _r => widget.request;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _translate());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _r.message ?? '';
    if (text.trim().isEmpty || !mounted) return;
    final target = Localizations.localeOf(context).languageCode;
    try {
      final result = await ref
          .read(gardenApiProvider)
          .translateRequestMessage(text, target);
      if (mounted) setState(() => _translated = result);
    } catch (_) {
      // 번역이 안 되면 원문만 보인다.
    }
  }

  Future<void> _decide({required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = L10n.of(context);
    final actions = ref.read(friendActionsProvider);
    final error = accept
        ? await actions.accept(_r.id)
        : await actions.reject(_r.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage(l10n, error))));
      return;
    }
    // 기획서 7-2: 수락 → "[받은 신청] 목록에서 삭제하고, [친구 목록]으로 이동 처리" / 거절 → 삭제.
    Navigator.of(context).pop(accept);
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final info = ref.watch(postInfoProvider(_r.requesterId));

    return Scaffold(
      backgroundColor: AppColors.night,
      body: info.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        // [포스트 정보]를 못 읽어도 신청 자체는 보여 줄 수 있다 — 목록에서 받은 값으로 그린다.
        error: (error, stack) => _body(context, s, null),
        data: (data) => _body(context, s, data),
      ),
    );
  }

  Widget _body(BuildContext context, double s, PostInfo? info) {
    final message = _r.message ?? '';
    final translated = _translated;
    final hasTranslation =
        translated != null && translated.trim() != message.trim();

    // 🚨 스크롤하지 않는다 — 대화방 받은 신청 팝업과 같은 이유다(사진 칸이 남는 높이를 차지한다).
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
              fallbackPhoto: _r.partnerPhotoUrl,
              nickname: info?.nickname ?? _r.partnerNickname,
              age: info?.age ?? _r.partnerAge,
              country: info?.country ?? _r.partnerCountry,
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
              onTap: () => showProfileView(context, _r.requesterId),
            ),
            original: message,
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
              asset: FriendArt.acceptFriend,
              onTap: _busy ? null : () => _decide(accept: true),
            ),
          ),
        ],
      ),
    );
  }
}
