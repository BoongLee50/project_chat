import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/image_viewer.dart';
import '../../../../shared/widgets/translate_pass_button.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../chat/presentation/widgets/talk_cell.dart'
    show timeAgoWithin30Days;
import '../../../postinfo/presentation/screens/profile_view_screen.dart';
import '../../data/models/feed_item.dart';
import '../../data/models/translate_access.dart';
import '../providers/garden_provider.dart';
import 'chat_request_flow.dart';
import 'garden_art.dart';

/// 댓글이 달릴 대상. 서버의 `CommentTarget`과 짝이다.
///
/// 포스트와 달빛 한마디의 댓글 규칙이 **문장까지 같아**(기획 4-2 / 8-2 / 8-3)
/// 화면도 한 벌만 둔다 — 두 벌이면 언젠가 조용히 갈라진다.
enum CommentTargetKind { post, dailyAnswer }

/// 댓글 시트(기획 4-2 [포스트 댓글]). **3단계 답글** · 최대 50자 · 이미지 1장.
///
/// 🎨 **흰 시트다** — `Scene_Garden`에 댓글 그림이 오지 않아 **기획서 260919/261002의 4-2 화면**을 따랐다
/// (두 판의 그림은 바이트까지 같다). 머리글 `댓글 N` · `[★ 번역 | 구매]` · `✕`,
/// 줄마다 얼굴 사진 · 이름 · 국기 · `N분 전` · `⋯`(프로필 보기 / 대화 신청), 번역문은 원문 아래 회색 한 줄.
///
/// [targetId]는 포스트 주인의 userId(포스트) 또는 한마디 id다.
/// [ownerId]는 **글쓴이**다 — 답글 자격을 가리는 데 쓴다(아래 [_CommentsSheetState._canReply]).
/// [title]은 예전 머리글(`○○님의 포스트`)이다. 시안 머리글은 `댓글 N`이라 **더는 그리지 않는다** —
/// 부르는 곳(오늘의 포스트·달빛 한마디)이 아직 넘기므로 받아만 둔다.
Future<void> showCommentsSheet(
  BuildContext context, {
  required CommentTargetKind kind,
  required String targetId,
  required String ownerId,
  String? title,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: _Palette.sheet,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) =>
        _CommentsSheet(kind: kind, targetId: targetId, ownerId: ownerId),
  );
}

/// 포스트 카드에서 여는 지름길 — 대상이 [FeedItem] 하나로 정해져 있다.
Future<void> showPostCommentsSheet(BuildContext context, FeedItem item) =>
    showCommentsSheet(
      context,
      kind: CommentTargetKind.post,
      targetId: item.userId,
      // 포스트는 대상 id가 곧 글쓴이다.
      ownerId: item.userId,
    );

/// 시안(4-2)에서 뽑은 색. 앱의 어두운 팔레트(`AppColors`)와 따로 둔다 — 이 시트만 흰 바탕이다.
class _Palette {
  static const sheet = Color(0xFFF8F8F8);
  static const ink = Color(0xFF212121);
  static const body = Color(0xFF333333);
  static const muted = Color(0xFF9E9E9E);
  static const line = Color(0xFFEDEDED);
  static const thread = Color(0xFFE9E2EB);
  static const purple = Color(0xFF8E30C8);

  /// 답글 대상으로 고른 줄(8-2 시안 "댓글 타겟 선택").
  static const selectedFill = Color(0xFFF6EEFB);
  static const selectedBorder = Color(0xFFE2C8F2);
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({
    required this.kind,
    required this.targetId,
    required this.ownerId,
  });

  final CommentTargetKind kind;
  final String targetId;
  final String ownerId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  /// 서버 설정(`app.comment.*`)과 같은 값. 클라는 **미리 막아 주는 역할**이고
  /// 최종 판정은 서버가 한다 — 화면만 막으면 API를 직접 부르는 것으로 뚫린다.
  static const int _maxLength = 50;
  static const int _maxDepth = 3;

  final _controller = TextEditingController();
  bool _sending = false;

  /// 시트 **안에** 스낵바를 띄운다 — 바깥 Scaffold에 띄우면 시트에 가려 안 보인다.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  /// 답글 대상. null이면 1단계 댓글이다.
  Comment? _replyTo;

  /// 목록 프로바이더의 키. 대상 종류가 다르면 같은 id라도 다른 목록이다.
  String get _key => '${widget.kind.name}:${widget.targetId}';

  /// 이 댓글에 **내가** 답글을 달 수 있는가.
  ///
  /// 한 스레드는 **글쓴이와 그 스레드를 시작한 사람**의 1:1 대화이고 답글은 **번갈아** 달린다:
  /// `A가 글 → B가 댓글 → A가 답글 → B가 답글`. 그래서 조건은 셋이다.
  /// 1. 3단계에는 더 못 단다
  /// 2. **내 댓글에는 내가 못 단다**(자기 말에 자기가 답하면 대화가 아니다)
  /// 3. 나는 이 스레드의 두 사람 중 하나여야 한다 — 제3자는 **1단계 댓글로 새 스레드**를 연다
  ///
  /// 서버가 같은 규칙으로 다시 판정한다(`COMMENT_REPLY_NOT_ALLOWED`).
  /// 여기서 가리는 건 **헛걸음을 막으려는 것**이지 방어가 아니다.
  bool _canReply(Comment comment, List<Comment> all) {
    final me = ref.read(sessionProvider).profile?.id;
    if (me == null) return false;
    if (comment.depth >= _maxDepth) return false;
    if (comment.authorId == me) return false;
    return me == widget.ownerId || me == _threadStarterId(comment, all);
  }

  /// 스레드를 시작한 사람(1단계 댓글의 작성자). 깊이가 3까지라 한 번만 거슬러 올라가면 된다.
  String? _threadStarterId(Comment comment, List<Comment> all) {
    if (comment.depth == 1) return comment.authorId;
    for (final c in all) {
      if (c.id == comment.parentId) {
        return c.depth == 1 ? c.authorId : null;
      }
    }
    return null;
  }

  /// 줄을 누르면 **답글 대상으로 고른다**(8-2 시안 "댓글 타겟 선택" · 4-2 "3단계 이상은 선택이 안 됨").
  /// 다시 누르면 풀린다. 고를 수 없는 줄은 **왜 안 되는지 말한다**(서버 `ErrorCode` 문장 그대로).
  void _select(Comment comment, List<Comment> all) {
    if (_replyTo?.id == comment.id) {
      setState(() => _replyTo = null);
      return;
    }
    if (_canReply(comment, all)) {
      setState(() => _replyTo = comment);
      return;
    }
    final l10n = L10n.of(context);
    _toast(
      comment.depth >= _maxDepth
          ? l10n.errorCommentDepthExceeded(_maxDepth)
          : l10n.errorCommentReplyNotAllowed,
    );
  }

  /// 첨부한 사진 — 올린 뒤 받은 키와, 미리보기용 바이트.
  String? _imageKey;
  List<int>? _imageBytes;

  /// 이 창에서 번역이 되는가(기획 4-2 · 8-3 — "댓글창 5회 호출까지 무료").
  ///
  /// **창을 열 때 한 번** 자리를 잡는다. 댓글 하나하나가 아니라 창이 단위라
  /// 여기서 한 번 물으면 그 안의 댓글은 몇 개든 번역된다.
  TranslateAccess? _translate;

  /// 댓글 id → 번역문. 원문과 같으면(공급자 없음 · 이미 내 말) 담지 않는다.
  final Map<String, String> _translated = {};

  /// 이미 물어본 댓글 — 목록을 다시 읽어도 같은 줄을 또 보내지 않는다.
  final Set<String> _asked = {};

  @override
  void initState() {
    super.initState();
    _openTranslate();
  }

  Future<void> _openTranslate() async {
    try {
      final access = await ref
          .read(gardenApiProvider)
          .openCommentSheetTranslate();
      if (!mounted) return;
      setState(() => _translate = access);

      // 다 썼으면 기획서가 정해 둔 문구로 알려 준다.
      // 공급자가 아직 없을 때는 "다 썼다"가 아니라 "준비 중"이다 — 자리도 안 깎였다.
      if (!access.granted && !access.unlimited && access.providerReady) {
        _toast(L10n.of(context).translateCommentExhausted);
      }
      _translateVisible();
    } on ApiException {
      // 번역은 곁가지다 — 실패해도 댓글창은 그대로 쓴다.
      if (mounted) setState(() => _translate = TranslateAccess.unavailable);
    }
  }

  /// 내 말이 아닌 댓글을 내 언어로 옮긴다(시안: 원문 아래 회색 한 줄).
  ///
  /// 자리를 받았을 때만 — 없으면 서버가 거절한다. **같은 나라 사람의 댓글은 보내지 않는다**
  /// (같은 말을 두 번 보여 줄 이유가 없다 — 받은 신청의 [원문보기]와 같은 규칙).
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
        // 한 줄이 실패해도 원문은 보인다 — 나머지는 계속 옮긴다.
      }
    }
  }

  static String? _languageOf(String? country) => switch (country) {
    'KR' => 'ko',
    'JP' => 'ja',
    _ => null,
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _sending = true);
    try {
      // 등록 버튼을 누르기 전에 올려 둔다 — 전송 순간이 짧아야 답답하지 않다.
      // 이미지는 어느 쪽이든 같은 저장소(`comment-images/{userId}/`)를 쓴다.
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
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      switch (widget.kind) {
        case CommentTargetKind.post:
          await ref
              .read(gardenApiProvider)
              .addComment(
                widget.targetId,
                text,
                parentId: _replyTo?.id,
                imageKey: _imageKey,
              );
          // 가든 카드의 댓글 수(말풍선 옆 숫자)를 올린다 — 창 뒤에 그대로 떠 있는 카드다.
          // 오늘의 포스트(내 글)에서 열었을 수도 있다 — 피드를 아직 안 읽었으면 깨우지 않는다.
          if (ref.exists(feedProvider)) {
            ref.read(feedProvider.notifier).commentAdded(widget.targetId);
          }
        case CommentTargetKind.dailyAnswer:
          await ref
              .read(dailyApiProvider)
              .addComment(
                widget.targetId,
                text,
                parentId: _replyTo?.id,
                imageKey: _imageKey,
              );
      }
      _controller.clear();
      setState(() {
        _replyTo = null;
        _imageKey = null;
        _imageBytes = null;
      });
      ref.invalidate(commentsProvider(_key));
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(L10n.of(context), e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String message) {
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final comments = ref.watch(commentsProvider(_key));
    final me = ref.watch(sessionProvider).profile?.id;

    // 목록이 (다시) 오면 새 줄을 번역한다.
    ref.listen(commentsProvider(_key), (_, next) {
      if (next.hasValue) _translateVisible();
    });

    final count = comments.valueOrNull?.length;

    // ⚠️ 높이를 **Scaffold 바깥에서** 정해야 한다 — Scaffold는 받은 만큼 다 차지해서,
    // 안에서 정하면 시트가 화면 꼭대기까지 늘어난다(실기 확인).
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ScaffoldMessenger(
          key: _messenger,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            // 키보드는 바깥 Padding이 직접 피한다 — 둘 다 하면 두 배로 밀린다.
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        count == null
                            ? l10n.commentsSection
                            : l10n.commentsCount(count),
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      // 시안(4-2)의 `[★ 번역 | …]`. 누르면 자동 번역 패스 화면으로 간다.
                      TranslatePassButton(access: _translate, light: true),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.commonClose,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _Palette.ink,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: comments.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: _Palette.purple),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        l10n.commentsLoadFailed,
                        style: const TextStyle(color: _Palette.muted),
                      ),
                    ),
                    data: (list) => list.isEmpty
                        ? Center(
                            child: Text(
                              l10n.commentsEmpty,
                              style: const TextStyle(color: _Palette.muted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final c = list[i];
                              // 스레드(1단계 댓글 + 그 답글) 사이에만 가는 선 — 시안이 그렇다.
                              final threadEnds =
                                  i + 1 < list.length && list[i + 1].depth == 1;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CommentTile(
                                    comment: c,
                                    translated: _translated[c.id],
                                    selected: _replyTo?.id == c.id,
                                    showMenu: c.authorId != me,
                                    onTap: () => _select(c, list),
                                    onMenu: (action) => _onMenu(action, c),
                                  ),
                                  if (threadEnds)
                                    const Divider(
                                      height: 20,
                                      thickness: 1,
                                      indent: 8,
                                      endIndent: 8,
                                      color: _Palette.line,
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                if (_replyTo != null)
                  _ReplyBanner(
                    nickname: _replyTo!.authorNickname,
                    onCancel: () => setState(() => _replyTo = null),
                  ),
                if (_imageBytes != null)
                  _AttachedImageBar(
                    bytes: _imageBytes!,
                    onRemove: () => setState(() {
                      _imageKey = null;
                      _imageBytes = null;
                    }),
                  ),
                _InputBar(
                  controller: _controller,
                  sending: _sending,
                  canAttach: !_sending && _imageBytes == null,
                  maxLength: _maxLength,
                  onPickImage: _pickImage,
                  onSend: _send,
                  // 기획 4-2: "50자 초과 시 '댓글은 50자까지 입력할 수 있어요'라는 안내 메세지 출력".
                  onOverflow: () =>
                      _toast(l10n.errorCommentTooLong(_maxLength)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CommentMenu { profile, chatRequest }

/// 댓글 한 줄. [Comment.depth]만큼 들여쓰고, 답글은 왼쪽에 **스레드 선**을 긋는다 —
/// 서버가 트리 순서로 평탄화해 주므로 화면은 깊이만 보면 된다.
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.translated,
    required this.selected,
    required this.showMenu,
    required this.onTap,
    required this.onMenu,
  });

  final Comment comment;

  /// 내 언어로 옮긴 문장(없으면 원문만).
  final String? translated;

  /// 답글 대상으로 고른 줄.
  final bool selected;

  /// `⋯` 메뉴 — **내 댓글에는 없다**(나에게 대화 신청할 일은 없다).
  final bool showMenu;

  final VoidCallback onTap;
  final ValueChanged<_CommentMenu> onMenu;

  static const double _indentStep = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final reply = comment.depth > 1;
    final avatar = reply ? 40.0 : 48.0;
    final indent = (comment.depth - 1) * _indentStep;
    final time = timeAgoWithin30Days(l10n, comment.createdAt);
    final flag = GardenArt.flagOf(comment.authorCountry);

    final content = Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      decoration: BoxDecoration(
        color: selected ? _Palette.selectedFill : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _Palette.selectedBorder : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(url: comment.authorPhotoUrl, size: avatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorNickname,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Palette.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (flag != null) ...[
                      const SizedBox(width: 6),
                      Image.asset(flag, width: 18, height: 18),
                    ],
                    if (time.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: _Palette.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: _Palette.body,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                if (translated != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    translated!,
                    style: const TextStyle(
                      color: _Palette.muted,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
                if (comment.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  // 누르면 원본만 팝업으로 띄운다(기획 4-2).
                  TappableImage(
                    url: comment.imageUrl!,
                    width: 150,
                    height: 84,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: showMenu
                ? _MoreMenu(onSelected: onMenu)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );

    return GestureDetector(
      // 빈 자리를 눌러도 고를 수 있게(Row·Column은 스스로 히트테스트하지 않는다 — 함정 #38).
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: indent),
        child: reply
            // 답글 왼쪽의 세로 선 — 어느 댓글에 달린 말인지 들여쓰기만으로는 약하다.
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 2,
                      margin: const EdgeInsets.only(right: 8),
                      color: _Palette.thread,
                    ),
                    Expanded(child: content),
                  ],
                ),
              )
            : content,
      ),
    );
  }
}

/// 줄 오른쪽 `⋯` → [프로필 보기] / [대화 신청](기획 4-2).
class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onSelected});

  final ValueChanged<_CommentMenu> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    const style = TextStyle(
      color: _Palette.ink,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
    // 구분선이 앱의 어두운 테마색을 따라가면 흰 메뉴에 검은 줄이 된다 — 시안처럼 옅게.
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(dividerTheme: const DividerThemeData(color: _Palette.line)),
      child: PopupMenuButton<_CommentMenu>(
        tooltip: l10n.commentsMore,
        padding: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: onSelected,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _CommentMenu.profile,
            child: Text(l10n.postInfoMenuProfile, style: style),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem(
            value: _CommentMenu.chatRequest,
            child: Text(l10n.postInfoRequestChat, style: style),
          ),
        ],
        icon: const Icon(Icons.more_horiz_rounded, color: _Palette.ink),
      ),
    );
  }
}

/// 작성자 얼굴 사진(동그라미). 없으면 회색 자리.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: const Color(0xFFE6E6E6),
      child: Icon(
        Icons.person_rounded,
        color: const Color(0xFFBDBDBD),
        size: size * 0.6,
      ),
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : AuthedImage(url: url!, fallback: placeholder),
      ),
    );
  }
}

/// 하단 입력줄(시안: 흰 알약 안에 글자칸 + 사진 버튼, 오른쪽에 보라 `[등록]`).
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.canAttach,
    required this.maxLength,
    required this.onPickImage,
    required this.onSend,
    required this.onOverflow,
  });

  final TextEditingController controller;
  final bool sending;
  final bool canAttach;
  final int maxLength;
  final VoidCallback onPickImage;
  final VoidCallback onSend;
  final VoidCallback onOverflow;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: _Palette.sheet,
        border: Border(top: BorderSide(color: _Palette.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 18, right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE3E3E3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      // ⚠️ `maxLength`를 쓰지 않는다 — 글자 모양 단위라 서버(코드포인트)와 어긋나고,
                      // 넘쳐도 아무 말 없이 멈춘다. 기획서는 **안내 문구**를 요구한다.
                      inputFormatters: [
                        _CodePointLimit(maxLength, onOverflow: onOverflow),
                      ],
                      cursorColor: _Palette.purple,
                      style: const TextStyle(color: _Palette.ink, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: l10n.commentsHint,
                        hintStyle: const TextStyle(
                          color: _Palette.muted,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: canAttach ? onPickImage : null,
                    tooltip: l10n.commentsAttachImage,
                    icon: Icon(
                      Icons.image_outlined,
                      color: canAttach ? _Palette.ink : _Palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: sending ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: _Palette.purple,
                disabledBackgroundColor: _Palette.purple.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: const StadiumBorder(),
              ),
              child: Text(
                l10n.commentsSend,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 코드포인트 [max]개까지만 받고, 넘치려 하면 [onOverflow]로 알린다.
///
/// 서버(`CommentService`)와 DB(`VARCHAR(50)`)는 **코드포인트**로 센다. 넘친 입력은 받지 않고
/// 앞의 글을 그대로 둔다 — 결합 이모지가 반쪽으로 잘려 남지 않게 **글자 모양 단위로** 자른다.
class _CodePointLimit extends TextInputFormatter {
  _CodePointLimit(this.max, {required this.onOverflow});

  final int max;
  final VoidCallback onOverflow;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= max) return newValue;
    onOverflow();
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

/// 지금 누구에게 답글을 쓰는지 알려 주는 줄. 없으면 1단계 댓글이 된다.
class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.nickname, required this.onCancel});

  final String nickname;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      color: _Palette.selectedFill,
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
      child: Row(
        children: [
          const Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 18,
            color: _Palette.purple,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.commentsReplyingTo(nickname),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _Palette.body, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            tooltip: l10n.commentsCancelReply,
            icon: const Icon(Icons.close_rounded, color: _Palette.muted),
          ),
        ],
      ),
    );
  }
}

/// 첨부한 사진 미리보기(1장). 올리기는 이미 끝난 상태이고 키만 들고 있다.
class _AttachedImageBar extends StatelessWidget {
  const _AttachedImageBar({required this.bytes, required this.onRemove});

  final List<int> bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              Uint8List.fromList(bytes),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.commentsImageAttached,
              style: const TextStyle(color: _Palette.body, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: l10n.commentsRemoveImage,
            icon: const Icon(Icons.close_rounded, color: _Palette.muted),
          ),
        ],
      ),
    );
  }
}
