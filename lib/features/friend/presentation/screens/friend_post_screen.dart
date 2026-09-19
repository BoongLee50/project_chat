import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../chat/data/models/chat_models.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/widgets/request_popup.dart';
import '../../../chat/presentation/widgets/talk_art.dart';
import '../../../garden/presentation/widgets/garden_art.dart';
import '../../../moderation/presentation/widgets/block_dialog.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../../postinfo/presentation/providers/post_info_provider.dart';
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../widgets/friend_art.dart';

/// [친구 포스트 정보] — 친구 목록에서 프로필 사진을 누르면 뜬다(기획서 260919 7-1).
///
/// 대화방 받은 신청 팝업과 **같은 골격**이다(테두리·흰 패널·버튼 자리가 픽셀까지 같다).
/// 다른 것만 적는다:
/// - 왼쪽 위: 뒤로가기 화살표 대신 **고정 핀**(고정했을 때만). 닫기는 `[나가기]`다.
/// - 흰 패널: 연필(소개) · `[원문보기]` · **`[친구 관리]`** / 본문은 친구의 **소개** / 아래에 하트 + **관심사**.
/// - 아래 버튼: `[나가기]` · `[💬 대화하기]`.
///
/// 소개 번역은 **무료**(scope `PROFILE`) — 같은 글을 [프로필 보기]에서 보면 무료인데 여기서 깎이면 말이 안 된다.
///
/// `[친구 관리]` → 목록 상단 고정 · 프로필 보기 · 신고하기 · 차단하기 · 친구해제.
/// 차단·해제는 **안내 팝업 후** 목록에서 지운다(기획서).
class FriendPostScreen extends ConsumerStatefulWidget {
  const FriendPostScreen({super.key, required this.friend});

  final Friend friend;

  static Route<void> route(Friend friend) => MaterialPageRoute(
    builder: (_) => FriendPostScreen(friend: friend),
    fullscreenDialog: true,
  );

  @override
  ConsumerState<FriendPostScreen> createState() => _FriendPostScreenState();
}

enum _Manage { pin, profile, report, block, unfriend }

class _FriendPostScreenState extends ConsumerState<FriendPostScreen> {
  final _pages = PageController();
  final _photoKey = GlobalKey();
  int _page = 0;

  String? _translated;
  bool _showOriginal = false;
  late bool _pinned = widget.friend.pinned;
  bool _busy = false;

  Friend get _friend => widget.friend;

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

  Future<void> _translate() async {
    final text = _friend.intro ?? '';
    if (text.trim().isEmpty || !mounted) return;
    final target = Localizations.localeOf(context).languageCode;
    try {
      final result = await ref
          .read(gardenApiProvider)
          .translateProfileText(text, target);
      if (mounted) setState(() => _translated = result);
    } catch (_) {
      // 번역이 안 되면 원문만 보인다 — 소개를 못 읽게 막을 이유는 없다.
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// `[💬 대화하기]` — 채팅창을 연다(기획서 7-1).
  ///
  /// ⚠️ **방이 없을 수 있다** — 30일간 대화가 없으면 방이 닫힌다(2026-09-06 규칙).
  /// 친구이므로 서버가 새 방을 만들어 준다(`POST /chat/rooms:with/{userId}`).
  Future<void> _openChat() async {
    if (_busy) return;
    final l10n = L10n.of(context);
    final info = ref.read(postInfoProvider(_friend.userId)).valueOrNull;
    var roomId = info?.chatRoomId ?? _friend.roomId;
    if (roomId == null) {
      setState(() => _busy = true);
      try {
        roomId = await ref.read(chatApiProvider).ensureFriendRoom(_friend.userId);
      } on ApiException catch (e) {
        if (mounted) _toast(errorMessage(l10n, e));
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          room: ChatRoomSummary(
            roomId: roomId!,
            type: 'FRIEND',
            partnerId: _friend.userId,
            partnerNickname: _friend.nickname,
            partnerAge: _friend.age,
            partnerCountry: _friend.country,
            partnerPhotoUrl: _friend.photoUrl,
            partnerOnline: _friend.online,
            unreadCount: 0,
          ),
        ),
      ),
    );
  }

  /// `[친구 관리]` — 사진 칸 오른쪽 아래에 붙는 메뉴(시안 — 흰 카드, 손잡이, 파란 아이콘 다섯 줄).
  ///
  /// 📌 **메뉴 그림은 오지 않았다** — 흰 카드·아이콘은 코드로 그린다(문구는 ARB). 아이콘 그림이
  /// 오면 `_ManageMenu`의 `Icon`만 `ArtImage`로 바꾸면 된다(08 참고).
  Future<void> _openManage() async {
    final box = _photoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    final s = DesignCanvas.scaleOf(context);

    final choice = await showGeneralDialog<_Manage>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (ctx, _, _) => Stack(
        children: [
          Positioned(
            // 시안: 메뉴 오른쪽 끝 `1007`, 팝업 오른쪽 끝 `1056` — 49 안쪽. 아래 끝은 흰 패널 윗선.
            right: screen.width - rect.right + 49 * s,
            bottom: screen.height - rect.bottom,
            child: _ManageMenu(pinned: _pinned),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    await _onManage(choice);
  }

  Future<void> _onManage(_Manage choice) async {
    final l10n = L10n.of(context);
    switch (choice) {
      case _Manage.pin:
        final next = !_pinned;
        final error = await ref
            .read(friendActionsProvider)
            .setPinned(_friend.friendshipId, pinned: next);
        if (!mounted) return;
        if (error != null) return _toast(errorMessage(l10n, error));
        setState(() => _pinned = next);
      case _Manage.profile:
        await showProfileView(context, _friend.userId);
      case _Manage.report:
        final done = await ReportDialog.show(
          context,
          targetUserId: _friend.userId,
          targetNickname: _friend.nickname,
        );
        // 신고하면 친구 관계가 끊기므로 이 화면에 남아 있을 이유가 없다.
        if (done == true && mounted) Navigator.of(context).pop();
      case _Manage.block:
        // 차단은 BlockDialog가 **안내 팝업**이다(기획서 — "안내 팝업 출력 후 친구 목록에서 삭제").
        final done = await BlockDialog.show(
          context,
          targetUserId: _friend.userId,
          targetNickname: _friend.nickname,
        );
        if (done == true && mounted) Navigator.of(context).pop();
      case _Manage.unfriend:
        final ok = await ConfirmDialog.show(
          context,
          l10n.friendsDeleteConfirm(_friend.nickname),
        );
        if (!ok || !mounted) return;
        final error = await ref
            .read(friendActionsProvider)
            .remove(_friend.friendshipId);
        if (!mounted) return;
        if (error != null) return _toast(errorMessage(l10n, error));
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final info = ref.watch(postInfoProvider(_friend.userId)).valueOrNull;
    final intro = _friend.intro ?? '';
    final translated = _translated;
    final hasTranslation =
        translated != null && translated.trim() != intro.trim();
    final interests = info?.interests ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.night,
      // 🚨 스크롤하지 않는다 — 대화방 받은 신청 팝업과 같다(끌면 "울렁울렁" 움직였다, 2026-09-19).
      // 사진 칸이 남는 높이를 차지하고, 흰 패널·버튼은 시안 크기 그대로다.
      body: Padding(
        padding: EdgeInsets.only(
          top:
              DesignCanvas.titleTopInSafeArea(context) +
              MediaQueryData.fromView(View.of(context)).padding.top,
          bottom: MediaQuery.paddingOf(context).bottom + 32 * s,
        ),
        child: Column(
          children: [
            Expanded(
              child: KeyedSubtree(
                key: _photoKey,
                child: PopupPhotoArea(
                  info: info,
                  fallbackPhoto: _friend.photoUrl,
                  nickname: info?.nickname ?? _friend.nickname,
                  age: info?.age ?? _friend.age,
                  country: info?.country ?? _friend.country,
                  controller: _pages,
                  page: _page,
                  onPageChanged: (i) => setState(() => _page = i),
                  // 화살표가 없다 — 고정했으면 **큰 핀**이 그 자리에 선다(시안 `76, 174`).
                  topLeft: _pinned
                      ? const ArtImage(
                          FriendArt.pinLarge,
                          width: 120,
                          height: 119,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            PopupPanel(
              leading: const PanelItem(
                asset: FriendArt.bio,
                size: FriendArt.bioSize,
                left: FriendArt.bioLeft,
                top: FriendArt.bioTop,
              ),
              trailing: PanelItem(
                asset: FriendArt.manage,
                size: FriendArt.manageSize,
                left: FriendArt.manageLeft,
                onTap: _openManage,
              ),
              original: intro,
              translated: hasTranslation ? translated : null,
              showOriginal: _showOriginal,
              onToggleOriginal: () =>
                  setState(() => _showOriginal = !_showOriginal),
              footer: _InterestsRow(codes: interests),
              footerHeight: FriendArt.footerHeight,
              footerBottom: FriendArt.footerBottom,
            ),
            SizedBox(height: TalkArt.panelToButtons * s),
            PopupDecideRow(
              left: PopupDecide(
                asset: FriendArt.exit,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              right: PopupDecide(
                asset: TalkArt.accept,
                onTap: _busy ? null : _openChat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 관심사 줄 ───────────────────────────────────────────────
/// 흰 패널 아래 — 파란 하트(관심사 표시) + 관심사 칩 최대 셋(관심사는 3개까지 — V25 무렵 확정).
///
/// 🚨 **관심사 칩은 그림이 정본이다**(기획 2026-09-19 — "관심사 버튼·아이콘은 전부 이미지").
/// 지금 받은 것은 `영화` 한 장뿐이라 나머지는 **자리를 지키는 임시 칩**(같은 규격 204×89)으로 그린다.
/// 37종 그림이 오면 코드 → 에셋 표로 바꾸면 되고, 달빛가든 카드도 같은 자리를 고친다.
class _InterestsRow extends StatelessWidget {
  const _InterestsRow({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);
    return Stack(
      children: [
        Positioned(
          left: FriendArt.interestsIconLeft * s,
          top: (FriendArt.footerHeight - FriendArt.interestsIconSize.height) /
              2 *
              s,
          child: ArtImage(
            FriendArt.interestsIcon,
            width: FriendArt.interestsIconSize.width,
            height: FriendArt.interestsIconSize.height,
          ),
        ),
        for (var i = 0; i < codes.length && i < FriendArt.chipLefts.length; i++)
          Positioned(
            left: FriendArt.chipLefts[i] * s,
            top: 0,
            child: codes[i] == 'MOVIE'
                ? ArtImage(
                    GardenArt.interestMovie,
                    width: GardenArt.interestSize.width,
                    height: GardenArt.interestSize.height,
                  )
                : _PlaceholderChip(
                    label: ProfileCatalog.interestLabel(l10n, codes[i]),
                  ),
          ),
      ],
    );
  }
}

/// 그림이 아직 없는 관심사의 **임시 칩** — `영화` 칩 그림과 같은 규격·색(짙은 회색 알약, 흰 글자).
class _PlaceholderChip extends StatelessWidget {
  const _PlaceholderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return Container(
      width: GardenArt.interestSize.width * s,
      height: GardenArt.interestSize.height * s,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(GardenArt.interestSize.height * s),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
            fontSize: 38 * s,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── [친구 관리] 메뉴 ─────────────────────────────────────────
class _ManageMenu extends StatelessWidget {
  const _ManageMenu({required this.pinned});

  final bool pinned;

  /// 시안 아이콘 색(파랑).
  static const Color _blue = Color(0xFF3A5BF0);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);

    Widget row(_Manage value, IconData icon, String label, {bool last = false}) =>
        InkWell(
          onTap: () => Navigator.of(context).pop(value),
          child: Container(
            height: 114 * s,
            padding: EdgeInsets.symmetric(horizontal: 40 * s),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: const Color(0xFFE3E4EA),
                        width: 2 * s,
                      ),
                    ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _blue, size: 60 * s),
                SizedBox(width: 36 * s),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1C1C1E),
                      fontSize: 38 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(34 * s),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 515 * s,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20 * s),
            // 손잡이 — 시안의 짧은 회색 막대.
            Container(
              width: 100 * s,
              height: 12 * s,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C8CE),
                borderRadius: BorderRadius.circular(6 * s),
              ),
            ),
            SizedBox(height: 8 * s),
            row(
              _Manage.pin,
              Icons.push_pin_rounded,
              pinned ? l10n.friendMenuUnpin : l10n.friendMenuPin,
            ),
            row(_Manage.profile, Icons.person_rounded, l10n.postInfoMenuProfile),
            row(_Manage.report, Icons.report_outlined, l10n.chatMenuReport),
            row(_Manage.block, Icons.block_rounded, l10n.chatMenuBlock),
            row(
              _Manage.unfriend,
              Icons.person_remove_rounded,
              l10n.postInfoMenuUnfriend,
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}
