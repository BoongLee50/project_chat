import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/design_canvas.dart';
import '../../../../shared/widgets/request_message_input.dart';
import 'word_art.dart';

/// [내 한마디 등록] 시트(기획서 261011 **9-1**, `Scene_Word/Reply Register`).
///
/// [타이틀] 위로 아래에서 올라온다 — 올리고 내리는 것은 부르는 쪽([DailyIntroScreen])이 한다.
/// 이 위젯은 **닫히면 트리에서 빠진다** → 쓰던 글·고른 사진이 남지 않는다(`✕` = 초기화, 사용자 결정).
///
/// - 답변글 **200자**(띄어쓰기 포함). 시안의 `0 / 300`은 오류다(2026-10-11 기획자 확인).
///   🚨 **코드포인트로 센다** — 서버(`codePointCount`)·DB(`VARCHAR`)와 같은 단위(함정 #82).
///   Flutter `maxLength`는 글자 모양 단위라 이모지가 섞이면 앱은 받고 서버는 거절했다.
/// - 사진 **1장, 선택**. 고르는 즉시 올리고 키만 들고 있다(포스트 사진과 같은 흐름).
///   ⚠️ 올린 뒤 `✕`로 닫으면 저장소에 사진이 남는다 — 키가 어디에도 안 붙어 화면에는 안 나온다.
/// - 그림 한 장(`back_word`)에 초승달·「오늘의 질문」·🔒 잠금 안내·`📷 사진 추가`가 구워져 있다.
class DailyWriteSheet extends ConsumerStatefulWidget {
  const DailyWriteSheet({
    super.key,
    required this.canvasScale,
    required this.canvasLeft,
    required this.screen,
    required this.question,
    required this.onClose,
    required this.onRegistered,
  });

  /// [타이틀] 배경과 같은 배율·왼쪽 끝 — 시트가 배경 그림과 같은 자리에 앉게.
  final double canvasScale;
  final double canvasLeft;
  final Size screen;
  final String question;
  final VoidCallback onClose;
  final VoidCallback onRegistered;

  /// 서버 설정(`app.daily-question.max-length`)과 같은 값. 최종 판정은 서버가 한다.
  static const int maxLength = 200;

  /// 시트 아래 여백(시안 2640 - 578 - 1976).
  static const double _bottomGap = 86;

  @override
  ConsumerState<DailyWriteSheet> createState() => _DailyWriteSheetState();
}

class _DailyWriteSheetState extends ConsumerState<DailyWriteSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  bool _uploading = false;
  String? _imageKey;
  Uint8List? _imageBytes;

  late final List<TextInputFormatter> _formatters = [
    // 넘치면 잘라 내고 **왜 안 들어가는지 말한다**(막힌 UI는 이유를 말한다).
    TextInputFormatter.withFunction((oldValue, newValue) {
      if (RequestMessageInput.length(newValue.text) >
          DailyWriteSheet.maxLength) {
        _toast(errorDailyTooLong);
      }
      return newValue;
    }),
    RequestMessageInput.codePointLimit(DailyWriteSheet.maxLength),
  ];

  String get errorDailyTooLong =>
      L10n.of(context).errorDailyAnswerTooLong(DailyWriteSheet.maxLength);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {})); // 글자 수 표시
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 안내는 **키보드 위에** 띄운다 — [타이틀]이 키보드에 밀리지 않게 해 둬서(`resizeToAvoidBottomInset: false`)
  /// 그냥 띄우면 글자 수 안내가 키보드 뒤에 숨는다(실기기에서 확인).
  void _toast(String message) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, keyboard + 16),
        ),
      );
  }

  Future<void> _pickImage() async {
    if (_busy || _uploading) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    setState(() => _uploading = true);
    try {
      final key = await ref.read(dailyApiProvider).uploadImage(bytes: bytes);
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

  Future<void> _submit() async {
    final l10n = L10n.of(context);
    final text = _controller.text.trim();
    if (_busy) return;
    if (_uploading) return _toast(l10n.dailyWriteUploading);
    if (text.isEmpty) return _toast(l10n.dailyWriteEmpty);

    setState(() => _busy = true);
    try {
      await ref.read(dailyApiProvider).write(body: text, imageKey: _imageKey);
      if (mounted) widget.onRegistered();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 다른 기기에서 이미 썼다 — 막을 것 없이 목록으로 보낸다.
      if (e.code == 'DAILY_ANSWER_ALREADY') return widget.onRegistered();
      _toast(errorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final s = widget.canvasScale;
    final screen = widget.screen;

    // 시트는 화면 아래에 붙는다(시안 아래 여백 86). 세로가 짧으면 위가 [타이틀] 머리를 덮고,
    // 그래도 모자라면 위에 붙인다 — 스크롤하지 않는다(고정 화면 원칙).
    final top = math.max(
      0.0,
      screen.height / s - WordArt.sheetSize.height - DailyWriteSheet._bottomGap,
    );

    // 키보드가 글칸을 덮으면 그만큼만 시트를 올린다.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final frameBottom =
        (top + WordArt.replyFrameAt.dy + WordArt.replyFrameSize.height) * s +
        16;
    final lift = math.max(0.0, frameBottom - (screen.height - keyboard));

    Widget at(Offset o, Widget child) =>
        Positioned(left: o.dx * s, top: o.dy * s, child: child);

    final count = RequestMessageInput.length(_controller.text);

    return SizedBox.fromSize(
      size: screen,
      child: Stack(
        children: [
          Positioned(
            left: widget.canvasLeft + WordArt.sheetAt.dx * s,
            top: top * s - lift,
            width: WordArt.sheetSize.width * s,
            height: WordArt.sheetSize.height * s,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    DesignCanvas.localizedAsset(context, WordArt.sheetBack),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                at(
                  WordArt.closeAt,
                  Semantics(
                    button: true,
                    label: l10n.commonClose,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: ArtImage(
                        WordArt.close,
                        width: WordArt.closeSize.width,
                        height: WordArt.closeSize.height,
                        scale: s,
                      ),
                    ),
                  ),
                ),
                // 오늘의 질문 — 두 줄 가운데. 구워진 「오늘의 질문」 머리와 잠금 안내 사이.
                Positioned(
                  left: 70 * s,
                  right: 70 * s,
                  top: WordArt.sheetQuestionTop * s,
                  child: Text(
                    widget.question,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: WordArt.ink,
                      fontSize: 46 * s,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
                at(
                  WordArt.replyFrameAt,
                  SizedBox(
                    width: WordArt.replyFrameSize.width * s,
                    height: WordArt.replyFrameSize.height * s,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ArtImage(
                            WordArt.replyFrame,
                            width: WordArt.replyFrameSize.width,
                            height: WordArt.replyFrameSize.height,
                            scale: s,
                            fit: BoxFit.fill,
                          ),
                        ),
                        Positioned.fill(
                          left: WordArt.replyTextInset.dx * s,
                          right: WordArt.replyTextInset.dx * s,
                          top: WordArt.replyTextInset.dy * s,
                          bottom: 80 * s,
                          child: TextField(
                            controller: _controller,
                            inputFormatters: _formatters,
                            expands: true,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textAlignVertical: TextAlignVertical.top,
                            cursorColor: WordArt.gold,
                            style: TextStyle(
                              color: WordArt.ink,
                              fontSize: 38 * s,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: l10n.dailyWriteHint,
                              hintStyle: TextStyle(
                                color: WordArt.muted,
                                fontSize: 38 * s,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        // `0 / 200` — 시안(img24) 글칸 오른쪽 아래.
                        Positioned(
                          right: 40 * s,
                          bottom: 26 * s,
                          child: Text(
                            '$count / ${DailyWriteSheet.maxLength}',
                            style: TextStyle(
                              color: WordArt.muted,
                              fontSize: 30 * s,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                at(WordArt.addPhotoAt, _photoSlot(s)),
                if (_imageBytes != null)
                  at(
                    WordArt.deletePhotoAt,
                    GestureDetector(
                      onTap: () => setState(() {
                        _imageKey = null;
                        _imageBytes = null;
                      }),
                      child: ArtImage(
                        WordArt.deletePhoto,
                        width: WordArt.deletePhotoSize.width,
                        height: WordArt.deletePhotoSize.height,
                        scale: s,
                      ),
                    ),
                  ),
                // 구워진 `📷 사진 추가 (선택 사항)` 글자도 누를 수 있게 — 시안에서 버튼처럼 보인다.
                Positioned(
                  left: WordArt.addPhotoLabel.left * s,
                  top: WordArt.addPhotoLabel.top * s,
                  width: WordArt.addPhotoLabel.width * s,
                  height: WordArt.addPhotoLabel.height * s,
                  child: Semantics(
                    button: true,
                    label: l10n.dailyWriteImage,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickImage,
                    ),
                  ),
                ),
                at(
                  WordArt.registerAt,
                  Semantics(
                    button: true,
                    label: l10n.dailyWriteSubmit,
                    child: GestureDetector(
                      onTap: _submit,
                      child: ArtImage(
                        WordArt.register,
                        width: WordArt.registerSize.width,
                        height: WordArt.registerSize.height,
                        scale: s,
                        opacity: _busy ? 0.6 : 1,
                      ),
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

  /// 사진 칸 — 비었으면 `+` 틀(그림), 고르면 사진이 그 틀을 채운다.
  Widget _photoSlot(double s) {
    final size = Size(
      WordArt.addPhotoSize.width * s,
      WordArt.addPhotoSize.height * s,
    );
    final bytes = _imageBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24 * s),
        child: Image.memory(
          bytes,
          width: size.width,
          height: size.height,
          fit: BoxFit.cover,
        ),
      );
    }
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ArtImage(
            WordArt.addPhoto,
            width: WordArt.addPhotoSize.width,
            height: WordArt.addPhotoSize.height,
            scale: s,
          ),
          if (_uploading)
            const CircularProgressIndicator(color: AppColors.moonlight),
        ],
      ),
    );
  }
}
