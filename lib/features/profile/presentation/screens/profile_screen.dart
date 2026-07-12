import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 프로필 (정적 UI, 다크 테마로 적용). 메인 셸의 '프로필' 탭 본문.
/// 사진/관심사/소개/지역 편집은 서버 연동 단계에서 붙인다. (기획서 7장)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        AppDimens.gapMd,
        AppDimens.pagePad,
        AppDimens.gapLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: const [
              Text(
                '프로필',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8),
              _Dot(),
              Spacer(),
              Icon(Icons.more_horiz, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          // 프로필 사진
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/profile_photo.jpg',
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          // 이름 + 접속 상태
          Row(
            children: [
              const Text(
                '지우 27',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Text('🇰🇷', style: TextStyle(fontSize: 20)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF3FCF6B), size: 9),
                    SizedBox(width: 6),
                    Text(
                      '접속 중',
                      style: TextStyle(color: Color(0xFF3FCF6B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapLg),
          // 관심사
          _SectionCard(
            icon: Icons.favorite_border,
            title: '관심사',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Chip(icon: Icons.flight, label: '여행'),
                _Chip(icon: Icons.music_note, label: '음악'),
                _Chip(icon: Icons.movie_outlined, label: '드라이브'),
                _Chip(icon: Icons.sports_esports, label: '게임'),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          // 소개 한마디
          _SectionCard(
            icon: Icons.format_quote,
            title: '소개 한마디',
            child: const Text(
              '조용한 밤, 내 마음도 조금 정리되는 기분이야. 🌙\n오늘도 수고한 나에게 작은 쉼표를 선물해줘야지.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          // 활동 지역
          _SectionCard(
            icon: Icons.location_on_outlined,
            title: '활동 지역',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Chip(label: '한국, 서울'),
                _Chip(label: '일본, 도쿄'),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.gapLg),
          const _PremiumBanner(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.moonlight, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.moonlight.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.moonlight,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.moonlight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.moonlight, size: 17),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        gradient: const LinearGradient(
          colors: [Color(0xFF241E4E), Color(0xFF1A1730)],
        ),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.moonlightDeep,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프리미엄으로 더 특별하게 ✨',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '더 많은 친구 추천, 프로필 방문자 확인 등',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gapMd),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moonlightDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: const Text(
                '자세히 보기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.gapMd),
          Row(
            children: const [
              _Feature(icon: Icons.bolt, label: '매칭 부스트'),
              _Feature(icon: Icons.cloud_upload_outlined, label: '무료 업로드'),
              _Feature(icon: Icons.visibility_outlined, label: '방문자 확인'),
              _Feature(icon: Icons.block, label: '광고 제거'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.moonlight, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.moonlight,
        shape: BoxShape.circle,
      ),
    );
  }
}
