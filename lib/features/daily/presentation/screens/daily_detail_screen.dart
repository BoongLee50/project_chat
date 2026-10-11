import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../shared/widgets/image_viewer.dart';
import '../../../../shared/widgets/photo_source_sheet.dart';
import '../../../../shared/widgets/request_message_input.dart';
import '../../../../shared/widgets/translate_pass_button.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../chat/presentation/widgets/talk_cell.dart'
    show timeAgoWithin30Days;
import '../../../garden/data/models/feed_item.dart' show Comment;
import '../../../garden/data/models/translate_access.dart';
import '../../../garden/presentation/providers/garden_provider.dart'
    show commentsProvider;
import '../../../garden/presentation/widgets/chat_request_flow.dart';
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../../store/data/models/store_models.dart';
import '../../../store/presentation/screens/pass_screen.dart';
import '../../data/models/daily_models.dart';
import '../providers/daily_provider.dart';
import '../widgets/word_art.dart';

/// 달빛 한마디 [답글 상세](기획서 261011 9-2 · `Scene_Word/Reply Detail`, 2026-10-11 두 번째 전달).
///
/// 🧱 **한 화면에 다 있다** — 261011 본문은 "댓글 정보는 하단에서 올라오는 Bottom Sheet"였지만,
/// 전달된 시안과 기획 메모(2026-10-11 사용자 전달)가 **댓글을 본문 아래에 이어 그리고**
/// *"해당 유저의 이름 바로 아래부터 스크롤"* 이라 그쪽을 따랐다(신뢰 순서: 대화 중 결정 > 기획서).
/// - 고정: 머리(`<` · 얼굴 · 이름 나이 · 국기) / 아래 입력줄([사진] · 메시지 칸 · 보내기)
/// - 스크롤: 본문 · 큰 사진 · ♥·💬 수 · [번역] · `댓글 N` · 댓글들
///
/// 댓글 규칙은 포스트와 같다(docs/01 §댓글): 1단계 = 글쓴이 빼고 누구나 · 2단계 = 글쓴이만 ·
/// 3단계 = 그 1단계 쓴 사람만(A → B → A). 줄을 누르면 답글 대상을 고른다 — 판정은 가든 댓글 창과 같은 식이고
/// 최종 판정은 서버다. 답글 앞에는 `ㄴ`(`icon_link`)이 붙는다.
///
/// 🚧 그림이 안 온 것: 입력줄 왼쪽 **[사진] 버튼**(노란 원 + 아이콘 자리 채움) · 줄 오른쪽 **`•••`**(아이콘 자리 채움).
/// 시안 메모의 "시스템 이모티콘 호출"은 **사진 첨부** 단추다(기획 메모). 이모지는 자판의 이모지로 넣는다.
class DailyDetailScreen extends ConsumerStatefulWidget {
  const DailyDetailScreen({super.key, required this.answerId});

  final String answerId;

  static Route<void> route(String answerId) =>
      MaterialPageRoute(builder: (_) => DailyDetailScreen(answerId: answerId));

  @override
  ConsumerState<DailyDetailScreen> createState() => _DailyDetailScreenState();
}

class _DailyDetailScreenState extends ConsumerState<DailyDetailScreen> {
  /// 서버 설정(`app.comment.*`)과 같은 값 — 미리 막아 주는 것이고 최종 판정은 서버다.
  static const int _maxLength = 50;
  static const int _maxDepth = 3;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;
  bool _uploading = false;

  /// 답글 대상. null이면 1단계 댓글.
  Comment? _replyTo;
  String? _imageKey;
  Uint8List? _imageBytes;

  /// 이 창의 번역 자리(기획 9-2 "[답글 상세] 화면 번역은 해당 창 5회 호출까지 무료") — 들어올 때 한 번 묻는다.
  TranslateAccess? _translate;
  final Map<String, String> _translated = {};
  final Set<String> _asked = {};

  String get _key => 'dailyAnswer:${widget.answerId}';

  late final List<TextInputFormatter> _formatters = [
    // 50자 — 코드포인트로(서버·DB와 같은 단위, 함정 #82). 넘치면 잘라 내고 이유를 말한다.
    TextInputFormatter.withFunction((oldValue, newValue) {
      if (RequestMessageInput.length(newValue.text) > _maxLength) {
        _toast(L10n.of(context).errorCommentTooLong(_maxLength));
      }
      return newValue;
    }),
    RequestMessageInput.codePointLimit(_maxLength),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {})); // 보내기 색(회색 ↔ 노랑)
    _openTranslate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── 번역(가든 댓글 창과 같은 규칙) ─────────────────────────

  Future<void> _openTranslate() async {
    try {
      final access = await ref
          .read(gardenApiProvider)
          .openCommentSheetTranslate();
      if (!mounted) return;
      setState(() => _translate = access);
      if (!access.granted && !access.unlimited && access.providerReady) {
        _toast(L10n.of(context).translateCommentExhausted);
      }
      _translateVisible();
    } on ApiException {
      // 번역은 곁가지다 — 실패해도 화면은 그대로 쓴다.
      if (mounted) setState(() => _translate = TranslateAccess.unavailable);
    }
  }

  /// 내 말이 아닌 댓글을 내 언어로(원문 아래 회색 한 줄). 같은 나라 사람 댓글은 보내지 않는다.
  Future<void> _translateVisible() async {
    final access = _translate;
    if (access == null || !(access.granted || access.unlimited)) return;
    final list = ref.read(commentsProvider(_key)).valueOrNull;
    if (list == null || !mounted) return;
    final target = Localizations.localeOf(context).languageCode;
    final api = ref.read(gardenApiProvider);
    for (final c in list) {
      if (_asked.contains(c.id) || c.body.isEmpty) continue;
      if (_languageOf(c.authorCountry) == target) continue;
      _asked.add(c.id);
      try {
        final text = await api.translateComment(c.body, target);
        if (!mounted) return;
        if (text.trim() != c.body.trim()) {
          setState(() => _translated[c.id] = text);
        }
      } on ApiException {
        // 한 줄이 실패해도 원문은 보인다.
      }
    }
  }

  static String? _languageOf(String? country) => switch (country) {
    'KR' => 'ko',
    'JP' => 'ja',
    _ => null,
  };

  // ── 답글 대상 ──────────────────────────────────────────

  /// 이 댓글에 **내가** 답글을 달 수 있는가 — 3단계 미만 · 내 댓글 아님 · 나는 글쓴이이거나 그 스레드를 연 사람.
  bool _canReply(Comment comment, List<Comment> all, String ownerId) {
    final me = ref.read(sessionProvider).profile?.id;
    if (me == null) return false;
    if (comment.depth >= _maxDepth) return false;
    if (comment.authorId == me) return false;
    return me == ownerId || me == _threadStarterId(comment, all);
  }

  String? _threadStarterId(Comment comment, List<Comment> all) {
    if (comment.depth == 1) return comment.authorId;
    for (final c in all) {
      if (c.id == comment.parentId) return c.depth == 1 ? c.authorId : null;
    }
    return null;
  }

  /// 줄을 누르면 답글 대상으로 고른다. 다시 누르면 풀린다. 못 고르는 줄은 이유를 말한다.
  void _select(Comment comment, List<Comment> all, String ownerId) {
    if (_replyTo?.id == comment.id) {
      setState(() => _replyTo = null);
      return;
    }
    if (_canReply(comment, all, ownerId)) {
      setState(() => _replyTo = comment);
      _focus.requestFocus();
      return;
    }
    final l10n = L10n.of(context);
    _toast(
      comment.depth >= _maxDepth
          ? l10n.errorCommentDepthExceeded(_maxDepth)
          : l10n.errorCommentReplyNotAllowed,
    );
  }

  // ── 보내기 ────────────────────────────────────────────

  Future<void> _pickImage() async {
    if (_sending || _uploading) return;
    FocusScope.of(context).unfocus(); // 함정 #88
    final l10n = L10n.of(context);
    final choice = await PhotoSourceSheet.show(
      context,
      title: l10n.commentsAttachImage,
      subtitle: l10n.dailyPhotoSheetSubtitle,
    );
    if (choice == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: choice == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() => _uploading = true);
    try {
      final key = await ref
          .read(gardenApiProvider)
          .uploadCommentImage(bytes: bytes);
      if (!mounted) return;
      setState(() {
        _imageKey = key;
        _imageBytes = bytes;
      });
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(L10n.of(context), e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// 보내기는 **글이 있을 때만 노랗고, 노랄 때만 눌린다**(기획 메모 2026-10-11).
  bool get _canSend =>
      _controller.text.trim().isNotEmpty && !_sending && !_uploading;

  Future<void> _send(DailyAnswer answer) async {
    if (!_canSend) return;
    final l10n = L10n.of(context);
    // 내 한마디에는 먼저 댓글을 못 단다 — 서버도 막는다(`DAILY_ANSWER_SELF_COMMENT`). 답글은 된다.
    if (answer.mine && _replyTo == null) {
      return _toast(l10n.errorDailyAnswerSelfComment);
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(dailyApiProvider)
          .addComment(
            widget.answerId,
            _controller.text.trim(),
            parentId: _replyTo?.id,
            imageKey: _imageKey,
          );
      _controller.clear();
      setState(() {
        _replyTo = null;
        _imageKey = null;
        _imageBytes = null;
      });
      ref.invalidate(commentsProvider(_key));
      ref.invalidate(dailyAnswerProvider(widget.answerId)); // 💬 수
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// ♥ — 사람마다 한 번. **내 한마디에는 못 누른다**(서버도 막는다, `DAILY_ANSWER_SELF_LIKE`).
  Future<void> _like(DailyAnswer answer) async {
    final l10n = L10n.of(context);
    if (answer.mine) return _toast(l10n.errorDailyAnswerSelfLike);
    if (answer.likedByMe) return;
    try {
      await ref.read(dailyApiProvider).like(answer.id);
      ref.invalidate(dailyAnswerProvider(widget.answerId));
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(l10n, e));
    }
  }

  void _onMenu(_CommentMenu action, Comment comment) {
    switch (action) {
      case _CommentMenu.profile:
        showProfileView(context, comment.authorId);
      case _CommentMenu.chatRequest:
        runChatRequestFlow(
          context,
          ref,
          userId: comment.authorId,
          onError: _toast,
        );
    }
  }

  // ── 화면 ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = DesignCanvas.scaleOf(context);
    final answer = ref.watch(dailyAnswerProvider(widget.answerId));
    final comments = ref.watch(commentsProvider(_key));
    final me = ref.watch(sessionProvider).profile?.id;
    ref.listen(commentsProvider(_key), (_, next) {
      if (next.hasValue) _translateVisible();
    });

    return Scaffold(
      backgroundColor: WordArt.paper,
      // 스크롤 화면이라 자판이 오르면 입력줄이 따라 오르고 본문 칸이 줄어든다.
      resizeToAvoidBottomInset: true,
      body: answer.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: WordArt.gold)),
        error: (error, _) => SafeArea(
          child: Stack(
            children: [
              _BackButton(scale: s),
              Center(
                child: Text(
                  error is ApiException
                      ? errorMessage(l10n, error)
                      : l10n.dailyLoadFailed,
                  style: TextStyle(color: WordArt.muted, fontSize: 34 * s),
                ),
              ),
            ],
          ),
        ),
        data: (a) {
          final list = comments.valueOrNull ?? const <Comment>[];
          return Column(
            children: [
              _Header(answer: a, scale: s),
              Image.asset(
                WordArt.titleDivider,
                width: WordArt.titleDividerSize.width * s,
                height: WordArt.titleDividerSize.height * s,
                fit: BoxFit.fill,
              ),
              // 🚧 이름 바로 아래부터 스크롤(기획 메모) — 머리와 입력줄은 그대로 있다.
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: 40 * s),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _Body(answer: a, scale: s),
                    _Counts(
                      answer: a,
                      scale: s,
                      access: _translate,
                      onLike: () => _like(a),
                      onComment: () {
                        setState(() => _replyTo = null);
                        _focus.requestFocus();
                      },
                    ),
                    SizedBox(height: 12 * s),
                    Center(
                      child: Image.asset(
                        WordArt.listDivider,
                        width: WordArt.listDividerSize.width * s,
                        height: WordArt.listDividerSize.height * s,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(61 * s, 22 * s, 0, 14 * s),
                      child: Text(
                        l10n.commentsCount(
                          comments.valueOrNull?.length ?? a.comments,
                        ),
                        style: TextStyle(
                          color: WordArt.ink,
                          fontSize: 42 * s,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final c in list)
                      _CommentRow(
                        comment: c,
                        scale: s,
                        translated: _translated[c.id],
                        selected: _replyTo?.id == c.id,
                        showMenu: c.authorId != me,
                        onTap: () => _select(c, list, a.userId),
                        onMenu: (m) => _onMenu(m, c),
                      ),
                  ],
                ),
              ),
              if (_replyTo != null)
                _StripBar(
                  scale: s,
                  label: l10n.commentsReplyingTo(_replyTo!.authorNickname),
                  cancelLabel: l10n.commentsCancelReply,
                  onCancel: () => setState(() => _replyTo = null),
                ),
              // 기획서 261011(갱신판) image26 "답글 사진 등록 썸네일" — 보낼 때까지 남는다.
              if (_imageBytes != null)
                _PhotoStrip(
                  scale: s,
                  bytes: _imageBytes!,
                  onRemove: () => setState(() {
                    _imageKey = null;
                    _imageBytes = null;
                  }),
                ),
              _InputBar(
                scale: s,
                controller: _controller,
                focus: _focus,
                formatters: _formatters,
                // 내 한마디에선 새 댓글이 안 되므로 "댓글을 눌러 답글 달기"로 안내한다(포스트와 같은 문구).
                hint: a.mine && _replyTo == null
                    ? l10n.commentsHintOwnPost
                    : l10n.dailyCommentHint,
                canSend: _canSend,
                uploading: _uploading,
                onPickImage: _pickImage,
                onSend: () => _send(a),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _CommentMenu { profile, chatRequest }

class _BackButton extends StatelessWidget {
  const _BackButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: L10n.of(context).commonBack,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: ArtImage(
          WordArt.detailBack,
          width: WordArt.detailBackSize.width,
          height: WordArt.detailBackSize.height,
        ),
      ),
    ),
  );
}

/// 머리(고정) — `<` · 얼굴(누르면 [프로필 보기], 내 것 빼고) · 이름 나이 · 국기.
class _Header extends StatelessWidget {
  const _Header({required this.answer, required this.scale});

  final DailyAnswer answer;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final flag = switch (answer.country) {
      'KR' => WordArt.detailFlagKr,
      'JP' => WordArt.detailFlagJp,
      _ => null,
    };
    final avatar = WordArt.detailAvatarSize.width * s;
    return SizedBox(
      height: WordArt.detailHeaderHeight * s,
      child: Stack(
        children: [
          Positioned(
            left: (WordArt.detailBackAt.dx - 14) * s,
            top: (WordArt.detailBackAt.dy - 14) * s,
            child: _BackButton(scale: s),
          ),
          Positioned(
            left: WordArt.detailAvatarAt.dx * s,
            top: WordArt.detailAvatarAt.dy * s,
            child: GestureDetector(
              onTap: answer.mine
                  ? null
                  : () => showProfileView(context, answer.userId),
              child: SizedBox(
                width: avatar,
                height: avatar,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(3 * s),
                      child: ClipOval(
                        child: answer.photoUrl == null
                            ? const ColoredBox(color: Color(0xFFEDE4D8))
                            : AuthedImage(url: answer.photoUrl!),
                      ),
                    ),
                    ArtImage(
                      WordArt.detailAvatar,
                      width: WordArt.detailAvatarSize.width,
                      height: WordArt.detailAvatarSize.height,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 이름 줄은 얼굴 가운데 높이에 맞춘다(시안 이름 `393, 164` · 국기 `632, 156`).
          Positioned(
            left: WordArt.detailNameLeft * s,
            right: 40 * s,
            top: WordArt.detailAvatarAt.dy * s,
            height: avatar,
            child: Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: answer.nickname,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (answer.age != null)
                          TextSpan(text: ' ${answer.age}'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: WordArt.ink, fontSize: 58 * s),
                  ),
                ),
                if (flag != null) ...[
                  SizedBox(width: 22 * s),
                  ArtImage(
                    flag,
                    width: WordArt.detailFlagSize.width,
                    height: WordArt.detailFlagSize.height,
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

/// 본문 + 큰 사진(있을 때만 — 없으면 빈 틀을 그리지 않는다). 사진을 누르면 원본만 팝업.
class _Body extends StatelessWidget {
  const _Body({required this.answer, required this.scale});

  final DailyAnswer answer;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            WordArt.detailTextLeft * s,
            20 * s,
            50 * s,
            0,
          ),
          child: Text(
            answer.body,
            style: TextStyle(
              color: WordArt.ink,
              fontSize: 32 * s,
              height: 1.62,
            ),
          ),
        ),
        if (answer.imageUrl != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              WordArt.detailPhotoLeft * s,
              28 * s,
              0,
              0,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // 함정 #38
              onTap: () => showOriginalImage(context, answer.imageUrl!),
              child: SizedBox(
                width: WordArt.detailPhotoSize.width * s,
                height: WordArt.detailPhotoSize.height * s,
                child: Stack(
                  fit: StackFit.expand,
                  // ⚠️ 틀(`frame_commentphoto`)은 테두리가 아니라 **속이 흰 카드**다 — 위에 얹으면 사진을 덮는다.
                  // 카드를 깔고 사진을 그 안쪽(테두리 두께만큼)에 얹는다(실기 확인).
                  children: [
                    ArtImage(
                      WordArt.detailPhotoFrame,
                      width: WordArt.detailPhotoSize.width,
                      height: WordArt.detailPhotoSize.height,
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      // 카드 가장자리(알파 실측 ≈ 10px 안쪽)에 맞춘다.
                      padding: EdgeInsets.all(10 * s),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26 * s),
                        child: AuthedImage(url: answer.imageUrl!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ♥ 수 · 💬 수 · [번역 | …]. [번역]은 그림(`button_infotrans`) 위 오른쪽 칸에 상태 글자를 얹는다.
class _Counts extends StatelessWidget {
  const _Counts({
    required this.answer,
    required this.scale,
    required this.access,
    required this.onLike,
    required this.onComment,
  });

  final DailyAnswer answer;
  final double scale;
  final TranslateAccess? access;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = scale;
    final count = TextStyle(
      color: WordArt.ink,
      fontSize: 46 * s,
      fontWeight: FontWeight.w800,
    );
    final state = access;
    final label = state == null
        ? null
        : TranslatePassButton.labelOf(l10n, state).$1;
    return Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: SizedBox(
        height: WordArt.infoTransSize.height * s,
        child: Stack(
          children: [
            Positioned(
              left: WordArt.detailHeartLeft * s,
              top: 8 * s,
              child: Semantics(
                button: true,
                label: l10n.dailyLike,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLike,
                  child: Row(
                    children: [
                      ArtImage(
                        WordArt.detailHeart,
                        width: WordArt.detailHeartSize.width,
                        height: WordArt.detailHeartSize.height,
                      ),
                      SizedBox(width: 26 * s),
                      Text('${answer.likes}', style: count),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: WordArt.detailCommentLeft * s,
              top: 8 * s,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onComment,
                child: Row(
                  children: [
                    ArtImage(
                      WordArt.detailComment,
                      width: WordArt.detailCommentSize.width,
                      height: WordArt.detailCommentSize.height,
                    ),
                    SizedBox(width: 26 * s),
                    Text('${answer.comments}', style: count),
                  ],
                ),
              ),
            ),
            if (label != null)
              Positioned(
                left: WordArt.infoTransLeft * s,
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).push(PassScreen.route(StoreKind.translatePass)),
                  child: SizedBox(
                    width: WordArt.infoTransSize.width * s,
                    height: WordArt.infoTransSize.height * s,
                    child: Stack(
                      children: [
                        ArtImage(
                          WordArt.infoTrans,
                          width: WordArt.infoTransSize.width,
                          height: WordArt.infoTransSize.height,
                        ),
                        Positioned(
                          left: WordArt.infoTransLabel.left * s,
                          width: WordArt.infoTransLabel.width * s,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: WordArt.infoTransInk,
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
              ),
          ],
        ),
      ),
    );
  }
}

/// 댓글 한 줄 — 깊이만큼 오른쪽으로, 답글 앞엔 `ㄴ`. 이름 · 나이 · 국기 · `N분 전` · `•••`, 글 · 번역(회색) · 사진.
class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.scale,
    required this.translated,
    required this.selected,
    required this.showMenu,
    required this.onTap,
    required this.onMenu,
  });

  final Comment comment;
  final double scale;
  final String? translated;
  final bool selected;
  final bool showMenu;
  final VoidCallback onTap;
  final ValueChanged<_CommentMenu> onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = scale;
    final d = comment.depth.clamp(1, 3) - 1;
    final avatarLeft = WordArt.commentAvatarLeft[d];
    final time = timeAgoWithin30Days(l10n, comment.createdAt);
    final flag = switch (comment.authorCountry) {
      'KR' => WordArt.commentFlagKr,
      'JP' => WordArt.commentFlagJp,
      _ => null,
    };
    final size = WordArt.commentAvatarSize * s;
    final muted = TextStyle(color: WordArt.muted, fontSize: 30 * s);

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 함정 #38
      onTap: onTap,
      child: Container(
        // 답글 대상으로 고른 줄은 옅게 칠한다.
        color: selected ? const Color(0x22F6B73C) : null,
        padding: EdgeInsets.fromLTRB(0, 12 * s, 24 * s, 12 * s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d == 0)
              SizedBox(width: avatarLeft * s)
            else ...[
              SizedBox(width: WordArt.linkLeft[d] * s),
              Padding(
                padding: EdgeInsets.only(top: 6 * s),
                child: ArtImage(
                  WordArt.link,
                  width: WordArt.linkSize.width,
                  height: WordArt.linkSize.height,
                ),
              ),
              SizedBox(
                width:
                    (avatarLeft -
                        WordArt.linkLeft[d] -
                        WordArt.linkSize.width) *
                    s,
              ),
            ],
            GestureDetector(
              onTap: showMenu
                  ? () => showProfileView(context, comment.authorId)
                  : null,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(3 * s),
                      child: ClipOval(
                        child: comment.authorPhotoUrl == null
                            ? const ColoredBox(color: Color(0xFFEDE4D8))
                            : AuthedImage(url: comment.authorPhotoUrl!),
                      ),
                    ),
                    Image.asset(
                      WordArt.commentAvatar,
                      width: size,
                      height: size,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 45 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8 * s),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.authorNickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: WordArt.ink,
                            fontSize: 33 * s,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (comment.authorAge != null) ...[
                        SizedBox(width: 18 * s),
                        Text('${comment.authorAge}', style: muted),
                      ],
                      if (flag != null) ...[
                        SizedBox(width: 14 * s),
                        ArtImage(
                          flag,
                          width: WordArt.flagSize.width,
                          height: WordArt.flagSize.height,
                        ),
                      ],
                      if (time.isNotEmpty) ...[
                        SizedBox(width: 30 * s),
                        Text(time, style: muted),
                      ],
                    ],
                  ),
                  SizedBox(height: 10 * s),
                  Text(
                    comment.body,
                    style: TextStyle(
                      color: WordArt.ink,
                      fontSize: 33 * s,
                      height: 1.4,
                    ),
                  ),
                  if (translated != null) ...[
                    SizedBox(height: 6 * s),
                    Text(translated!, style: muted.copyWith(height: 1.4)),
                  ],
                  if (comment.imageUrl != null) ...[
                    SizedBox(height: 14 * s),
                    TappableImage(
                      url: comment.imageUrl!,
                      width: WordArt.commentPhotoSize.width * s,
                      height: WordArt.commentPhotoSize.height * s,
                      borderRadius: BorderRadius.circular(10 * s),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 70 * s,
              child: showMenu ? _MoreMenu(scale: s, onSelected: onMenu) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// `•••` → [프로필 보기] / [대화 신청](가든 댓글 창과 같다). 🚧 그림이 안 와서 아이콘 자리 채움.
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.scale, required this.onSelected});

  final double scale;
  final ValueChanged<_CommentMenu> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    const style = TextStyle(
      color: WordArt.ink,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
    return PopupMenuButton<_CommentMenu>(
      tooltip: l10n.commentsMore,
      padding: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _CommentMenu.profile,
          child: Text(l10n.postInfoMenuProfile, style: style),
        ),
        PopupMenuItem(
          value: _CommentMenu.chatRequest,
          child: Text(l10n.postInfoRequestChat, style: style),
        ),
      ],
      icon: Icon(
        Icons.more_horiz_rounded,
        color: WordArt.muted,
        size: 56 * scale,
      ),
    );
  }
}

/// 첨부할 사진 썸네일 줄(기획서 261011 갱신판 9-2 · image26) — 입력줄 바로 위.
///
/// *"첨부될 사진을 선택하면 메시지 입력창 위에 썸네일 사진을 표시. 썸네일 사진 영역에서 사용자가 올릴 사진
/// 확인 및 제거 가능. 썸네일 사진 영역은 댓글 전송 완료전까지 유지."*
/// - 썸네일을 누르면 **크게 본다**(확인) · 오른쪽 ✕(등록 시트의 `button_wordclose`를 같이 쓴다)로 **지운다**
/// - 글자는 시안 그대로 `사진 1/1` · `사진이 첨부되었습니다.` — 한 장까지라 분모가 1이다
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.scale,
    required this.bytes,
    required this.onRemove,
  });

  final double scale;
  final Uint8List bytes;
  final VoidCallback onRemove;

  void _preview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = scale;
    final thumb = 150 * s;
    return Container(
      // 시안 실측 — 미색 판 + 아래 옅은 선.
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8EE),
        border: Border(bottom: BorderSide(color: Color(0xFFF0E3CE))),
      ),
      padding: EdgeInsets.fromLTRB(40 * s, 16 * s, 30 * s, 16 * s),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _preview(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14 * s),
              child: Image.memory(
                bytes,
                width: thumb,
                height: thumb,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 22 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dailyCommentPhotoTitle,
                  style: TextStyle(color: WordArt.ink, fontSize: 30 * s),
                ),
                SizedBox(height: 10 * s),
                Text(
                  l10n.dailyCommentPhotoAttached,
                  style: TextStyle(
                    color: const Color(0xFFB08A5A),
                    fontSize: 26 * s,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.commentsRemoveImage,
            child: GestureDetector(
              onTap: onRemove,
              child: ArtImage(WordArt.close, width: 96, height: 96),
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력줄 위의 얇은 줄 — "○○님에게 답글". ✕로 푼다.
class _StripBar extends StatelessWidget {
  const _StripBar({
    required this.scale,
    required this.label,
    required this.cancelLabel,
    required this.onCancel,
  });

  final double scale;
  final String label;
  final String cancelLabel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      color: const Color(0xFFF7E9D6),
      padding: EdgeInsets.fromLTRB(40 * s, 8 * s, 10 * s, 8 * s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: WordArt.ink, fontSize: 30 * s),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            tooltip: cancelLabel,
            icon: const Icon(Icons.close_rounded, color: WordArt.muted),
          ),
        ],
      ),
    );
  }
}

/// 아래 입력줄(고정) — [사진] · 메시지 칸 · 보내기.
/// 보내기는 **글이 없으면 회색(`normal`)이고 눌리지 않는다**, 글이 들어가면 노랑(`color`)으로 바뀌고 눌린다.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.scale,
    required this.controller,
    required this.focus,
    required this.formatters,
    required this.hint,
    required this.canSend,
    required this.uploading,
    required this.onPickImage,
    required this.onSend,
  });

  final double scale;
  final TextEditingController controller;
  final FocusNode focus;
  final List<TextInputFormatter> formatters;
  final String hint;
  final bool canSend;
  final bool uploading;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = scale;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24 * s, 20 * s, 24 * s, 30 * s + bottom),
      child: Row(
        children: [
          // 🚧 [사진] 버튼 그림이 안 왔다 — 보내기와 같은 노란 원에 아이콘으로 자리만 채운다.
          Semantics(
            button: true,
            label: l10n.commentsAttachImage,
            child: GestureDetector(
              onTap: onPickImage,
              child: Container(
                width: WordArt.photoButtonSize * s,
                height: WordArt.photoButtonSize * s,
                decoration: const BoxDecoration(
                  color: WordArt.yellow,
                  shape: BoxShape.circle,
                ),
                child: uploading
                    ? Padding(
                        padding: EdgeInsets.all(34 * s),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WordArt.ink,
                        ),
                      )
                    : Icon(
                        Icons.add_photo_alternate_outlined,
                        color: const Color(0xFF3A3A44),
                        size: 64 * s,
                      ),
              ),
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: SizedBox(
              height: WordArt.messageFrameSize.height * s,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(WordArt.messageFrame, fit: BoxFit.fill),
                  ),
                  Positioned.fill(
                    left: 44 * s,
                    right: 30 * s,
                    child: Center(
                      child: TextField(
                        controller: controller,
                        focusNode: focus,
                        inputFormatters: formatters,
                        cursorColor: WordArt.gold,
                        style: TextStyle(color: WordArt.ink, fontSize: 36 * s),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                            color: WordArt.muted,
                            fontSize: 36 * s,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 21 * s),
          Semantics(
            button: true,
            enabled: canSend,
            label: l10n.dailyCommentSend,
            child: GestureDetector(
              onTap: canSend ? onSend : null,
              child: ArtImage(
                canSend ? WordArt.sendOn : WordArt.sendOff,
                width: WordArt.sendSize.width,
                height: WordArt.sendSize.height,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
