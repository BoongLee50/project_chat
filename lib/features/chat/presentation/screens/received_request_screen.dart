import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../postinfo/data/models/post_info.dart';
import '../../../postinfo/presentation/providers/post_info_provider.dart';
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../../profile/data/models/profile_catalog.dart';
import '../../data/models/chat_models.dart';
import '../providers/chat_provider.dart';
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
/// - 글이 길면 **패널이 아래로 늘어난다**(기획사항). 화면을 넘치면 화면 전체가 스크롤된다.
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

    return SingleChildScrollView(
      // 기본 physics — **넘칠 때만** 스크롤된다(포스트 화면에서 겪은 '움직이는데 갈 데가 없는'
      // 오버스크롤을 피한다, 함정 #79).
      padding: EdgeInsets.only(
        top: DesignCanvas.titleTopInSafeArea(context) +
            MediaQueryData.fromView(View.of(context)).padding.top,
        bottom: 48 * s,
      ),
      child: Column(
        children: [
          _PhotoArea(
            info: info,
            fallbackPhoto: r.partnerPhotoUrl,
            nickname: info?.nickname ?? r.partnerNickname,
            age: info?.age ?? r.partnerAge,
            country: info?.country ?? r.partnerCountry,
            controller: _pages,
            page: _page,
            onPageChanged: (i) => setState(() => _page = i),
          ),
          _MessagePanel(
            original: r.message,
            translated: hasTranslation ? translated : null,
            showOriginal: _showOriginal,
            onToggleOriginal: () =>
                setState(() => _showOriginal = !_showOriginal),
            onProfile: () => showProfileView(context, r.fromUserId),
          ),
          SizedBox(height: TalkArt.panelToButtons * s),
          Row(
            children: [
              SizedBox(width: TalkArt.refuseLeft * s),
              _Decide(
                asset: TalkArt.refuse,
                onTap: _busy ? null : () => _decide(accept: false),
              ),
              SizedBox(
                width:
                    (TalkArt.acceptLeft -
                        TalkArt.refuseLeft -
                        TalkArt.decideSize.width) *
                    s,
              ),
              _Decide(
                asset: TalkArt.accept,
                onTap: _busy ? null : () => _decide(accept: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 사진 ───────────────────────────────────────────────────
class _PhotoArea extends StatelessWidget {
  const _PhotoArea({
    required this.info,
    required this.fallbackPhoto,
    required this.nickname,
    required this.age,
    required this.country,
    required this.controller,
    required this.page,
    required this.onPageChanged,
  });

  final PostInfo? info;
  final String? fallbackPhoto;
  final String nickname;
  final int? age;
  final String? country;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final w = TalkArt.popupTopSize.width * s;
    final h = TalkArt.popupTopSize.height * s;

    // 오늘 포스트가 없으면 서버가 **프로필 사진 한 장**을 준다(PostInfo.photoUrls).
    // [포스트 정보]를 못 읽었으면 목록이 가진 프로필 사진으로 버틴다.
    final photos = info?.photoUrls ??
        (fallbackPhoto == null ? const <String>[] : [fallbackPhoto!]);
    final total = info?.totalPhotos ?? photos.length;
    final showPage = (info?.hasTodayPost ?? false) && total > 0;

    final region = info?.regions.isNotEmpty == true ? info!.regions.first : null;
    final place = region != null
        ? ProfileCatalog.regionLabel(l10n, region)
        : (country == null ? null : ProfileCatalog.countryLabel(l10n, country!));
    final flag = TalkArt.flagOf(country);

    // 사진은 테두리 **안쪽**부터 — 위 모서리만 둥글다(아래는 흰 패널과 붙는다).
    final inset = TalkArt.popupLine * 0.7 * s;
    final radius = Radius.circular((TalkArt.popupRadius - TalkArt.popupLine) * s);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
              child: photos.isEmpty
                  ? const ColoredBox(color: AppColors.surfaceHigh)
                  : PageView.builder(
                      controller: controller,
                      itemCount: photos.length,
                      onPageChanged: onPageChanged,
                      itemBuilder: (context, i) => AuthedImage(url: photos[i]),
                    ),
            ),
          ),
          // 아래쪽 글자를 살리는 그늘. 탭을 삼키지 않게(함정 #38).
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.nightScrim),
            ),
          ),
          IgnorePointer(
            child: Image.asset(TalkArt.popupTop, fit: BoxFit.fill),
          ),
          // 뒤로가기 — 이 화면의 **유일한 화살표**다.
          Positioned(
            left: TalkArt.backAt.dx * s,
            top: TalkArt.backAt.dy * s,
            child: GestureDetector(
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
            ),
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
                          style: TextStyle(color: Colors.white, fontSize: 38 * s),
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

// ── 흰 패널 ────────────────────────────────────────────────
class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.original,
    required this.translated,
    required this.showOriginal,
    required this.onToggleOriginal,
    required this.onProfile,
  });

  final String original;

  /// 원문과 **다른** 번역문. 같거나 아직 없으면 null — 그때는 `[원문보기]`를 감춘다.
  final String? translated;
  final bool showOriginal;
  final VoidCallback onToggleOriginal;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final w = TalkArt.popupTopSize.width * s;
    final textStyle = TextStyle(
      color: const Color(0xFF222222),
      fontSize: 38 * s,
      height: 1.6,
    );
    final translatedStyle = textStyle.copyWith(color: const Color(0xFF3D4FD6));

    final Widget body;
    if (translated == null) {
      body = Text(original, style: textStyle);
    } else if (!showOriginal) {
      body = Text(translated!, style: textStyle);
    } else {
      // 원문 위 · 구분선 · 번역문 아래(파란 글) — 시안 image16의 모양.
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(original, style: textStyle),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 22 * s),
            child: Divider(height: 1, thickness: 2 * s, color: const Color(0xFFCAD0F5)),
          ),
          Text(translated!, style: translatedStyle),
        ],
      );
    }

    return Column(
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
                  children: [
                    Positioned(
                      left: TalkArt.messageLeft * s,
                      top: 0,
                      child: ArtImage(
                        TalkArt.message,
                        width: TalkArt.messageSize.width,
                        height: TalkArt.messageSize.height,
                      ),
                    ),
                    if (translated != null)
                      Positioned(
                        left: TalkArt.viewOriginalLeft * s,
                        top: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggleOriginal,
                          // 누른 동안(원문이 보이는 동안)은 살짝 흐리게 — 켜져 있음을 알린다.
                          // 그림이 한 장뿐이라 상태를 그림으로 바꿀 수 없다.
                          child: ArtImage(
                            TalkArt.viewOriginal,
                            width: TalkArt.viewOriginalSize.width,
                            height: TalkArt.viewOriginalSize.height,
                            opacity: showOriginal ? 0.55 : 1,
                          ),
                        ),
                      ),
                    Positioned(
                      left: TalkArt.profileLeft * s,
                      top: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onProfile,
                        child: ArtImage(
                          TalkArt.profile,
                          width: TalkArt.profileSize.width,
                          height: TalkArt.profileSize.height,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  TalkArt.panelTextLeft * s,
                  40 * s,
                  TalkArt.panelTextLeft * s,
                  0,
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
  }
}

class _Decide extends StatelessWidget {
  const _Decide({required this.asset, required this.onTap});

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
