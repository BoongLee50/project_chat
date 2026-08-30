import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/daily_provider.dart';

/// 달빛 한마디 [작성](기획 8-3). **100자** · 메인 이미지 **1장(선택)**.
///
/// ⚠️ 기획서 이미지에는 썸네일이 셋 보이지만 **본문이 "최대 1장"** 이라고 못박았다 —
/// 본문을 따른다(docs/09 §2-1).
class DailyWriteScreen extends ConsumerStatefulWidget {
  const DailyWriteScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const DailyWriteScreen());

  @override
  ConsumerState<DailyWriteScreen> createState() => _DailyWriteScreenState();
}

class _DailyWriteScreenState extends ConsumerState<DailyWriteScreen> {
  /// 서버 설정(`app.daily-question.max-length`)과 같은 값.
  /// 클라는 미리 막아 주고 최종 판정은 서버가 한다.
  static const int _maxLength = 100;

  final _controller = TextEditingController();
  bool _busy = false;
  String? _imageKey;
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _busy = true);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(dailyApiProvider).write(body: text, imageKey: _imageKey);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) _toast(errorMessage(L10n.of(context), e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final today = ref.watch(dailyTodayProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.dailyWriteTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (today != null) ...[
              Text(
                today.question,
                style: const TextStyle(
                  color: AppColors.moonlight,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimens.gapLg),
            ],
            TextField(
              controller: _controller,
              maxLength: _maxLength,
              maxLines: 5,
              cursorColor: AppColors.moonlight,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.dailyWriteHint,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.gapMd),
            Text(
              l10n.dailyWriteImage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimens.gapMd),
            if (_imageBytes != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: Image.memory(
                      _imageBytes!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _imageKey = null;
                      _imageBytes = null;
                    }),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _busy ? null : _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.add, color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: AppDimens.gapLg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(l10n.dailyWriteSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
