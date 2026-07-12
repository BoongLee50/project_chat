import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 홈 — 오늘의 포스트 (정적 UI). 메인 셸의 '포스트' 탭 본문.
///
/// 사진 등록/타이머/좋아요 등의 실제 동작은 서버 연동 단계에서 붙인다.
/// (docs/01, 기획서 3장)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePad,
        AppDimens.gapMd,
        AppDimens.pagePad,
        AppDimens.gapMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _TopBar(),
          SizedBox(height: AppDimens.gapMd),
          _InfoCards(),
          SizedBox(height: AppDimens.gapMd),
          _PostPhotoCard(),
          SizedBox(height: AppDimens.gapMd),
          _NameLikeRow(),
          SizedBox(height: AppDimens.gapLg),
          _OneLiner(),
          SizedBox(height: AppDimens.gapLg),
          _ShareButton(),
        ],
      ),
    );
  }
}

// ── 상단 바 ──────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '오늘의 포스트',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.moonlight,
            shape: BoxShape.circle,
          ),
        ),
        const Spacer(),
        // 보유 루나
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.moonlight),
          ),
          child: Row(
            children: const [
              Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
              SizedBox(width: 8),
              Text(
                '80',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 달 정보 / 남은 시간 카드 ─────────────────────────────
class _InfoCards extends StatelessWidget {
  const _InfoCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            child: Row(
              children: const [
                Icon(Icons.nightlight_round, color: AppColors.gold, size: 30),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '오늘의 달',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '초승달',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimens.gapMd),
        Expanded(
          child: _InfoCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '포스트 등록 남은 시간',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '09:32',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.moonlight.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

// ── 포스트 사진 카드 ─────────────────────────────────────
class _PostPhotoCard extends StatelessWidget {
  const _PostPhotoCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: AspectRatio(
        aspectRatio: 0.86,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/post_sample.jpg', fit: BoxFit.cover),
            // 삭제 버튼
            Positioned(
              left: 14,
              bottom: 14,
              child: _RoundIconButton(
                icon: Icons.delete_outline,
                background: Colors.black.withValues(alpha: 0.5),
                iconColor: AppColors.textPrimary,
                size: 44,
              ),
            ),
            // 촬영 버튼
            Align(
              alignment: const Alignment(0, 0.92),
              child: _RoundIconButton(
                icon: Icons.photo_camera_rounded,
                background: AppColors.moonlight,
                iconColor: Colors.white,
                size: 60,
              ),
            ),
            // 페이지 인디케이터
            Positioned(
              right: 16,
              bottom: 24,
              child: Row(
                children: List.generate(5, (i) {
                  final active = i == 0;
                  return Container(
                    width: active ? 18 : 8,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.moonlight
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.size,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: size * 0.5),
    );
  }
}

// ── 이름 + 좋아요/댓글 ───────────────────────────────────
class _NameLikeRow extends StatelessWidget {
  const _NameLikeRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '채원 27',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        const Text('🇰🇷', style: TextStyle(fontSize: 20)),
        const Spacer(),
        _StatPill(
          icon: Icons.favorite,
          iconColor: Color(0xFFE85D6E),
          label: '87',
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.textSecondary,
          label: '32',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하루 한 마디 ─────────────────────────────────────────
class _OneLiner extends StatelessWidget {
  const _OneLiner();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              '하루 한 마디',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '15/50',
              style: TextStyle(color: AppColors.gold, fontSize: 14),
            ),
            Spacer(),
            Text(
              '오늘 9:04 PM 작성',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gapSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  '조용한 밤, 내 마음도 조금 정리되는 기분이야.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
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
        ),
      ],
    );
  }
}

// ── 공유 버튼 ────────────────────────────────────────────
class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: FilledButton.icon(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3A3E9E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        icon: const Icon(Icons.ios_share, size: 20),
        label: const Text(
          '포스트 공유하기',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
