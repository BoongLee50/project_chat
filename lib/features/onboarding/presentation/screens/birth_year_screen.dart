import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_scaffold.dart';

/// 온보딩 2/3 — 출생년도 설정.
/// 가입 가능 연령은 만 18세 이상이므로 선택 가능한 최소 출생년도를 제한한다.
class BirthYearScreen extends ConsumerStatefulWidget {
  const BirthYearScreen({super.key});

  @override
  ConsumerState<BirthYearScreen> createState() => _BirthYearScreenState();
}

class _BirthYearScreenState extends ConsumerState<BirthYearScreen> {
  // 만 18세 이상만 가입 가능 → 올해 - 18 이 최대 출생년도.
  static final int _maxYear = DateTime.now().year - 18;
  static const int _minYear = 1960;
  late final List<int> _years = List.generate(
    _maxYear - _minYear + 1,
    (i) => _maxYear - i,
  );

  int _selectedIndex = 5; // 기본값(대략 20대 초반)

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      backgroundAsset: 'assets/images/onboarding_2.jpg',
      title: '출생년도 설정',
      subtitle: '정확한 나이 확인을 위해 출생년도를 선택해주세요.',
      note: '* 이 정보는 다른 사용자에게 공개되지 않습니다.',
      onSubmit: () {
        ref
            .read(onboardingProvider.notifier)
            .setBirthYear(_years[_selectedIndex]);
        context.go(Routes.onboardingGender);
      },
      child: SizedBox(
        height: 280,
        child: CupertinoPicker(
          itemExtent: 56,
          scrollController: FixedExtentScrollController(
            initialItem: _selectedIndex,
          ),
          onSelectedItemChanged: (i) => setState(() => _selectedIndex = i),
          selectionOverlay: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.moonlight, width: 1.5),
            ),
          ),
          children: [
            for (final year in _years)
              Center(
                child: Text(
                  '$year',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
