import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 온보딩 3단계(닉네임·출생년도·성별/국가)가 공유하는 공통 레이아웃.
///
/// 상단 배경 풍경 + 하단 다크 패널(제목·부제·콘텐츠·완료 버튼) + 뒤로가기.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.backgroundAsset,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onSubmit,
    this.note,
    this.submitLabel = '완료',
    this.submitEnabled = true,
  });

  final String backgroundAsset;
  final String title;
  final String subtitle;
  final String? note;
  final Widget child;
  final VoidCallback onSubmit;
  final String submitLabel;
  final bool submitEnabled;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      // 키보드가 올라오면 완료 버튼이 그 위로 올라오도록 리사이즈.
      resizeToAvoidBottomInset: true,
      // 빈 곳을 탭하면 키보드를 닫는다.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 상단 배경 풍경
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: h * 0.42,
              child: Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            // 하단 패널
            Positioned(
              top: h * 0.30,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.pagePad,
                      AppDimens.gapXl,
                      AppDimens.pagePad,
                      AppDimens.gapLg,
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.moonlight,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppDimens.gapMd),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        if (note != null) ...[
                          const SizedBox(height: AppDimens.gapSm),
                          Text(
                            note!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppDimens.gapXl),
                        Expanded(child: SingleChildScrollView(child: child)),
                        const SizedBox(height: AppDimens.gapMd),
                        _SubmitButton(
                          label: submitLabel,
                          enabled: submitEnabled,
                          onPressed: onSubmit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 뒤로가기
            Positioned(
              top: 0,
              left: 4,
              child: SafeArea(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textPrimary,
                  ),
                  label: const Text(
                    '뒤로',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.moonlight,
          disabledBackgroundColor: AppColors.surfaceHigh,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
