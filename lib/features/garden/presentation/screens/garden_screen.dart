import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 달빛가든 — 포스트 사진 피드 (정적 UI). 메인 셸의 '달빛가든' 탭 본문.
///
/// 스와이프/스코어 노출/좋아요/대화 신청 등의 실제 동작은 서버 연동 단계에서 붙인다.
/// (docs/01, 기획서 4장)
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        AppDimens.gapMd,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _GardenHeader(),
          SizedBox(height: AppDimens.gapMd),
          _FilterBar(),
          SizedBox(height: AppDimens.gapMd),
          Expanded(child: _FeedCard()),
        ],
      ),
    );
  }
}

// ── 헤더 ─────────────────────────────────────────────────
class _GardenHeader extends StatelessWidget {
  const _GardenHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    '달빛가든',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.nightlight_round,
                    color: AppColors.moonlight,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '달빛 아래, 우리의 하루를 나누는 공간 ✨',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
          size: 26,
        ),
        const SizedBox(width: 16),
        const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 26),
      ],
    );
  }
}

// ── 필터 바 ──────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _FilterChip(leading: Icon(Icons.female, size: 18), label: '여자'),
          SizedBox(width: 8),
          _FilterChip(
            leading: Icon(Icons.person_outline, size: 18),
            label: '20대',
          ),
          SizedBox(width: 8),
          _FilterChip(
            leading: Text('🇰🇷', style: TextStyle(fontSize: 15)),
            label: '한국',
          ),
          SizedBox(width: 8),
          _SpotlightChip(),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconTheme(
            data: const IconThemeData(color: AppColors.textSecondary),
            child: leading,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SpotlightChip extends StatelessWidget {
  const _SpotlightChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.moonlightDeep, AppColors.moonlight],
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            '스포트라이트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 피드 카드 ────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  const _FeedCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/garden_sample.jpg', fit: BoxFit.cover),
          // 가독성 스크림 (상·하단)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xE6000000),
                ],
                stops: [0.0, 0.22, 0.5, 1.0],
              ),
            ),
          ),
          // 상단: 이름 + PICK
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: const [
                Text(
                  '지우 27',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                Text('🇰🇷', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                _PickBadge(),
              ],
            ),
          ),
          // 상단 우측: 페이지 인디케이터
          Positioned(
            top: 24,
            right: 16,
            child: Row(
              children: List.generate(
                6,
                (i) => Container(
                  width: 16,
                  height: 3,
                  margin: const EdgeInsets.only(left: 4),
                  color: Colors.white.withValues(alpha: i == 0 ? 0.9 : 0.4),
                ),
              ),
            ),
          ),
          // 하단: 한마디 + 좋아요/댓글/메시지
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘도 수고했어요, 내일은 더 빛날 거예요 🌙',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFE85D6E),
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '128',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '32',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        color: Color(0xFF2A2400),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickBadge extends StatelessWidget {
  const _PickBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PICK',
        style: TextStyle(
          color: Color(0xFF2A2400),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
