import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/main_shell.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../shared/widgets/photo_source_sheet.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../data/datasources/profile_api.dart';
import '../../data/models/me_profile.dart';
import '../../data/models/profile_catalog.dart';
import '../providers/profile_edit_provider.dart';
import '../widgets/interests_edit_sheet.dart';
import '../widgets/profile_notice_dialog.dart';
import '../widgets/profile_tag_chip.dart';
import '../widgets/regions_edit_sheet.dart';
import 'profile_preview_screen.dart';

/// 프로필 — 메인 셸의 다섯째 탭. **[작성하기]** 화면이다(기획서 261002 8-1, `Scene_Profile/Create`).
///
/// - 어떤 경로로 들어오든 **기본 상태는 작성하기**다. [미리 보기]는 위에 덮는 창이라
///   닫으면 늘 여기로 돌아온다(기획 2026-10-04).
/// - 네 단계(프로필 사진 · 자기소개 · 관심사 · 활동 지역)를 하나 끝낼 때마다 진행도가
///   25%씩 찬다. 모두 **언제든 다시 고칠 수 있다.**
/// - 아래가 길어 **스크롤한다**(기획 2026-10-04 — 고정 화면 무스크롤 원칙의 예외).
/// - `프로필 사진`·`자기소개` 같은 제목은 **그림**(`mark_*`), 회색 설명은 **글자**(RGB 178,178,183).
///
/// 좌표는 시안 `프로필_프로필 작성 화면 좌표.png`(1080 캔버스)를 그대로 옮겼다.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _intro = TextEditingController(
    text: ref.read(sessionProvider).profile?.intro ?? '',
  );
  final FocusNode _introFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  /// 한도 팝업이 이미 떠 있으면 또 띄우지 않는다(자판을 연타하면 쌓인다).
  bool _noticeOpen = false;

  /// 입력이 멈추고 잠시 뒤 저장한다.
  ///
  /// ⚠️ 안드로이드 뒤로 키는 **자판만 내리고 포커스는 그대로 둔다** — 포커스가 풀릴 때만
  /// 저장하면 뒤로 키로 마친 사람의 소개가 저장되지 않는다(실기 확인).
  Timer? _introDebounce;

  @override
  void initState() {
    super.initState();
    // 다른 곳을 누르면 바로 저장한다 — 글자마다 서버를 부르지는 않는다.
    _introFocus.addListener(() {
      if (!_introFocus.hasFocus) _saveIntro();
    });
    _intro.addListener(() {
      _introDebounce?.cancel();
      if (!_introFocus.hasFocus) return;
      _introDebounce = Timer(const Duration(milliseconds: 1200), _saveIntro);
    });
  }

  @override
  void dispose() {
    _introDebounce?.cancel();
    _intro.dispose();
    _introFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 자기소개 저장 — 바뀐 게 없으면 부르지 않는다.
  Future<void> _saveIntro() async {
    _introDebounce?.cancel();
    final text = _intro.text.trim();
    final saved = ref.read(sessionProvider).profile?.intro ?? '';
    if (text == saved) return;

    final error = await ref.read(profileEditActionsProvider).updateIntro(text);
    if (error != null && mounted) _showError(error);
  }

  void _showError(ApiException error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(errorMessage(L10n.of(context), error))),
      );
  }

  Future<void> _notice(String message) async {
    if (_noticeOpen) return;
    _noticeOpen = true;
    await showProfileNotice(context, message);
    _noticeOpen = false;
  }

  /// [미리 보기] — 쓰던 소개를 먼저 저장해야 미리 보기에 그대로 나온다.
  Future<void> _openPreview() async {
    FocusScope.of(context).unfocus();
    await _saveIntro();
    if (!mounted) return;
    await Navigator.of(context).push(ProfilePreviewScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider).profile;

    // 서버 값이 바뀌었는데(새로고침 등) 지금 쓰고 있지 않으면 칸을 따라가게 한다.
    ref.listen(sessionProvider.select((s) => s.profile?.intro), (_, next) {
      if (!_introFocus.hasFocus && _intro.text != (next ?? '')) {
        _intro.text = next ?? '';
      }
    });
    // 다른 탭으로 옮기면 자판을 내린다 — 내리는 순간 소개가 저장된다.
    ref.listen<int>(selectedTabProvider, (_, next) {
      if (next != MainTab.profile) _introFocus.unfocus();
    });

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.moonlight),
      );
    }

    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);

    return GestureDetector(
      // 빈 곳을 누르면 자판을 내린다(= 소개 저장).
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ColoredBox(
        color: Colors.white,
        // 머리(사진 · 작성하기/미리 보기 · 진행도)는 **고정**이고, 진행도와 `프로필 사진` 제목
        // 사이부터 아래만 스크롤한다(기획 2026-10-04).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Top(profile: profile, onPreview: _openPreview),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.moonlight,
                onRefresh: () => ref.read(sessionProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // 위: 머리 아랫변(_Top.height) → `프로필 사진` 제목(917).
                  padding: EdgeInsets.fromLTRB(
                    65 * s,
                    (917 - _Top.height) * s,
                    65 * s,
                    140 * s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 프로필 사진(917) ────────────────────────────
                      const _Mark('mark_picture.png', 327, 67),
                      SizedBox(height: 30 * s),
                      _Desc(l10n.profileCreatePhotoDesc),
                      SizedBox(height: 31 * s),
                      Row(
                        children: [
                          _PhotoSlot(
                            slot: ProfilePhotoSlot.face,
                            url: profile.photoUrl,
                            emptyAsset: 'button_face.png',
                          ),
                          const Spacer(),
                          _PhotoSlot(
                            slot: ProfilePhotoSlot.main,
                            url: profile.mainPhotoUrl,
                            emptyAsset: 'button_photo.png',
                          ),
                        ],
                      ),

                      // ── 자기소개(1574) ──────────────────────────────
                      SizedBox(height: 68 * s),
                      const _Mark('mark_aboutme.png', 278, 74),
                      SizedBox(height: 28 * s),
                      _Desc(l10n.profileCreateIntroDesc),
                      SizedBox(height: 32 * s),
                      _IntroBox(
                        controller: _intro,
                        focusNode: _introFocus,
                        onLimit: () => _notice(
                          l10n.profileIntroLimit(ProfileCatalog.maxIntro),
                        ),
                      ),

                      // ── 관심사(2136) ────────────────────────────────
                      SizedBox(height: 70 * s),
                      const _Mark('mark_Interests.png', 240, 66),
                      SizedBox(height: 30 * s),
                      _Desc(
                        l10n.profileCreateInterestsDesc(
                          ProfileCatalog.maxInterests,
                        ),
                      ),
                      SizedBox(height: 25 * s),
                      _TagRow(
                        chips: [
                          for (final code in profile.interests)
                            ProfileTagChip.interest(code),
                        ],
                        onEdit: () {
                          // 포커스를 먼저 푼다 — 안 그러면 시트가 닫힐 때 포커스가
                          // 소개 칸으로 돌아와 자판이 다시 올라온다.
                          FocusScope.of(context).unfocus();
                          InterestsEditSheet.show(context, profile.interests);
                        },
                      ),

                      // ── 활동 지역 ───────────────────────────────────
                      SizedBox(height: 72 * s),
                      const _Mark('mark_area.png', 264, 75),
                      SizedBox(height: 30 * s),
                      _Desc(l10n.profileCreateRegionDesc),
                      SizedBox(height: 25 * s),
                      _TagRow(
                        chips: [
                          for (final code in profile.regions)
                            ProfileTagChip.region(code),
                        ],
                        onEdit: () {
                          FocusScope.of(context).unfocus();
                          RegionsEditSheet.show(
                            context,
                            initial: profile.regions,
                            homeCountry: profile.country,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _dir = 'assets/images/scene_profile/create';

/// 회색 설명 글자 — 기획 지정 RGB(178,178,183). (시안 그림은 조금 더 진하지만 지정값을 따른다)
const _gray = Color(0xFFB2B2B7);

/// 머리 — 밤 사진 · 흰 판(`back_upper`) · [작성하기]/[미리 보기] · 진행도.
class _Top extends ConsumerStatefulWidget {
  const _Top({required this.profile, required this.onPreview});

  final MeProfile profile;
  final VoidCallback onPreview;

  /// 고정 머리의 높이(1080 캔버스) — 진행도 아랫변(850)과 `프로필 사진` 제목(917)의 가운데.
  static const double height = 884;

  @override
  ConsumerState<_Top> createState() => _TopState();
}

class _TopState extends ConsumerState<_Top> {
  /// [미리 보기]를 누르고 있는 동안만 노란 그림(`_color`)으로 바꾼다.
  bool _previewDown = false;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);
    final filled = widget.profile.filledSteps;

    return SizedBox(
      height: _Top.height * s,
      child: Stack(
        children: [
          // 밤 사진(1080×771). 일본어판은 틀이 커서(1426×1103) 폭에 맞추고 위에서부터 자른다 —
          // 넘치는 아래쪽은 어차피 흰 판에 덮인다.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 772 * s,
            child: Image.asset(
              DesignCanvas.localizedAsset(context, '$_dir/back_profile.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 629 * s,
            height: 144 * s,
            // 흰 판의 둥근 윗변. 그림 자체는 아이보리(250,248,245)라 아래 흰 본문과 이음매가
            // 보인다 — 시안(참고 화면)은 판과 본문이 같은 흰색이라 **모양만 쓰고 흰색으로 칠한다.**
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                '$_dir/back_upper.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 772 * s,
            bottom: 0,
            child: const ColoredBox(color: Colors.white),
          ),

          // [작성하기]는 이 화면이 곧 작성하기라 늘 켜진 그림이다.
          const DesignPositioned(
            left: 65,
            top: 679,
            child: ArtImage(
              '$_dir/button_write_color.png',
              width: 418,
              height: 103,
            ),
          ),
          DesignPositioned(
            left: 594,
            top: 679,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _previewDown = true),
              onTapCancel: () => setState(() => _previewDown = false),
              onTapUp: (_) => setState(() => _previewDown = false),
              onTap: widget.onPreview,
              child: ArtImage(
                _previewDown
                    ? '$_dir/button_preview_color.png'
                    : '$_dir/button_preview_normal.png',
                width: 418,
                height: 103,
              ),
            ),
          ),

          // 진행도 네 칸(65 · 279 · 493 · 707, 832) + 백분율.
          for (var i = 0; i < 4; i++)
            DesignPositioned(
              left: 65 + 214.0 * i,
              top: 832,
              child: ArtImage(
                i < filled
                    ? '$_dir/mark_progress_color.png'
                    : '$_dir/mark_progress_normal.png',
                width: 207,
                height: 18,
              ),
            ),
          Positioned(
            right: 65 * s,
            top: 812 * s,
            child: Text(
              '${filled * 25}%',
              style: TextStyle(
                color: _gray,
                fontSize: 42 * s,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),

          // 🚧 로그아웃 — 새 시안에는 자리가 없다. 다른 곳으로 옮길 때까지 머리 오른쪽 위에 둔다.
          Positioned(
            right: 20 * s,
            top: 20 * s,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              color: AppColors.surfaceHigh,
              onSelected: (value) {
                if (value == 'signOut') {
                  ref.read(sessionProvider.notifier).signOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'signOut',
                  child: Text(
                    l10n.profileLogout,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
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

/// 단계 제목 그림(`mark_*`) — 아이콘과 글자가 한 장이다.
class _Mark extends StatelessWidget {
  const _Mark(this.file, this.width, this.height);

  final String file;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      ArtImage('$_dir/$file', width: width, height: height);
}

/// 회색 설명 한 줄.
class _Desc extends StatelessWidget {
  const _Desc(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return Text(
      text,
      style: TextStyle(
        color: _gray,
        fontSize: 40 * s,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

/// 사진 칸(418×401) — 비었으면 점선 그림(`button_face`·`button_photo`), 차 있으면 그 사진.
///
/// 누르면 [프로필 사진 변경](앨범·카메라·제거). 프로필 사진은 포스트와 달리
/// **운영시간 게이트도 앨범 패스도 없다**(서버 `ProfileService`에 검사가 없다).
class _PhotoSlot extends ConsumerStatefulWidget {
  const _PhotoSlot({
    required this.slot,
    required this.url,
    required this.emptyAsset,
  });

  final ProfilePhotoSlot slot;
  final String? url;
  final String emptyAsset;

  @override
  ConsumerState<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends ConsumerState<_PhotoSlot> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final l10n = L10n.of(context);

    final choice = await PhotoSourceSheet.show(
      context,
      title: l10n.photoSheetProfileTitle,
      subtitle: l10n.photoSheetProfileSubtitle,
      showRemove: true,
      // 제거는 사진이 있을 때만 — 없는데 눌리면 할 일이 없다.
      removeEnabled: widget.url != null,
    );
    if (choice == null || !mounted) return;

    final actions = ref.read(profileEditActionsProvider);
    if (choice == PhotoSource.remove) {
      return _run(() => actions.deletePhoto(widget.slot));
    }

    final file = await ImagePicker().pickImage(
      source: choice == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _run(() => actions.updatePhoto(bytes, slot: widget.slot));
  }

  /// 통신하는 동안 칸 위에 스피너를 얹고, 실패하면 이유를 알려 준다.
  Future<void> _run(Future<ApiException?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(errorMessage(L10n.of(context), error))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final empty = ArtImage(
      '$_dir/${widget.emptyAsset}',
      width: 418,
      height: 401,
    );

    return GestureDetector(
      onTap: _pick,
      child: SizedBox(
        width: 418 * s,
        height: 401 * s,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.url == null)
              empty
            else
              // 점선 칸의 모서리(≈40)에 맞춰 둥글게 자른다.
              ClipRRect(
                borderRadius: BorderRadius.circular(40 * s),
                // 맨 `Image.network`는 안 된다 — `/files?key=`는 상대경로 + JWT라 AuthedImage로.
                child: AuthedImage(url: widget.url!, fallback: empty),
              ),
            if (_busy)
              ClipRRect(
                borderRadius: BorderRadius.circular(40 * s),
                child: const ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 자기소개 입력 칸 — `aboutme_testbox`(950×298) 위에 바로 쓴다.
///
/// - 최대 300자(띄어쓰기 포함). 넘치면 **안내 팝업**(8-1)
/// - 오른쪽 아래에 **남은 자수**
/// - 글이 길어지면 칸이 **아래로 늘어난다**(8-1) — 그림은 `centerSlice`로 모서리를 지킨 채 늘린다
class _IntroBox extends StatelessWidget {
  const _IntroBox({
    required this.controller,
    required this.focusNode,
    required this.onLimit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onLimit;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    final l10n = L10n.of(context);

    return Container(
      width: 950 * s,
      constraints: BoxConstraints(minHeight: 298 * s),
      child: Stack(
        children: [
          // 회색 칸은 **입력 칸과 같이 늘어난다** — `centerSlice`로 모서리(≈33)는 지키고 가운데만 늘린다.
          //
          // 🚨 `centerSlice`에 `scale`을 같이 주면 안 된다 — Flutter가 조각 경계를 계산할 때
          // **그림 픽셀과 논리 픽셀을 섞어 빼서** 늘이기가 틀어지고, 칸이 커져도 회색이 처음 크기에
          // 머물러 글자가 밖으로 넘쳤다(실기 확인, `BoxDecoration.image`도 같았다).
          // 그래서 **시안 픽셀 크기(950 × 높이/s)로 늘려 그린 뒤 통째로 배율만큼 줄인다**(`FittedBox`).
          Positioned.fill(
            child: LayoutBuilder(
              builder: (_, box) => FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: 950,
                  height: box.maxHeight / s,
                  child: Image.asset(
                    '$_dir/aboutme_testbox.png',
                    fit: BoxFit.fill,
                    centerSlice: const Rect.fromLTRB(48, 48, 902, 250),
                  ),
                ),
              ),
            ),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 1,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [_MaxLength(ProfileCatalog.maxIntro, onLimit)],
            cursorColor: AppColors.moonlightDeep,
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 40 * s,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: l10n.profileCreateIntroHint,
              hintStyle: TextStyle(
                color: _gray,
                fontSize: 40 * s,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              // 시안: 글자 85,1795 · 칸 65,1768 → 안쪽 20·27. 아래는 남은 자수 자리.
              contentPadding: EdgeInsets.fromLTRB(
                22 * s,
                24 * s,
                30 * s,
                96 * s,
              ),
            ),
          ),
          Positioned(
            right: 30 * s,
            bottom: 22 * s,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) => Text(
                '${ProfileCatalog.maxIntro - value.text.runes.length}',
                style: TextStyle(
                  color: _gray,
                  fontSize: 42 * s,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 글자 수 상한 — 넘는 입력은 **잘라 넣고 알린다**(붙여 넣은 긴 글이 통째로 사라지지 않게).
///
/// 서버(`ProfileService.updateIntro`)·DB와 같은 **코드포인트**로 센다 — 이모지도 한 글자다.
/// 자를 때는 글자 모양 단위로 잘라 결합 이모지가 반쪽으로 남지 않게 한다
/// (신청 한마디의 `RequestMessageInput`과 같은 방식, 줄바꿈은 허용).
class _MaxLength extends TextInputFormatter {
  _MaxLength(this.max, this.onExceeded);

  final int max;
  final VoidCallback onExceeded;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= max) return newValue;
    // 조합 중인 한글은 건드리지 않는다 — 조합이 끝나면 다시 들어온다.
    if (newValue.composing.isValid) return newValue;

    WidgetsBinding.instance.addPostFrameCallback((_) => onExceeded());
    if (oldValue.text.runes.length >= max) return oldValue;

    final buffer = StringBuffer();
    var used = 0;
    for (final ch in newValue.text.characters) {
      final n = ch.runes.length;
      if (used + n > max) break;
      buffer.write(ch);
      used += n;
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// 칩들 + 오른쪽 끝 [+](`button_addinterests`, 181×95). 칩을 눌러도 같은 선택 창이 뜬다.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.chips, required this.onEdit});

  final List<Widget> chips;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = DesignCanvas.scaleOf(context);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: chips.isEmpty ? null : onEdit,
            child: Wrap(
              // 시안: 65 → 279 → … (칩 204 + 10)
              spacing: 10 * s,
              runSpacing: 16 * s,
              children: chips,
            ),
          ),
        ),
        SizedBox(width: 16 * s),
        GestureDetector(
          onTap: onEdit,
          child: const ArtImage(
            '$_dir/button_addinterests.png',
            width: 181,
            height: 95,
          ),
        ),
      ],
    );
  }
}
