import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 친구 목록 (정적 UI). 메인 셸의 '친구' 탭 본문.
/// 친구 등록/삭제/필터는 서버 연동 단계에서 붙인다. (기획서 6장)
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  static const _friends = <_Friend>[
    _Friend(
      '지우',
      27,
      '🇰🇷',
      'seoul',
      _Status.online,
      'assets/images/avatar1.jpg',
    ),
    _Friend(
      '하루',
      25,
      '🇰🇷',
      'busan',
      _Status.online,
      'assets/images/avatar2.jpg',
    ),
    _Friend(
      'さくら',
      23,
      '🇯🇵',
      'tokyo',
      _Status.online,
      'assets/images/avatar3.jpg',
    ),
    _Friend(
      '렌',
      24,
      '🇯🇵',
      'osaka',
      _Status.away1,
      'assets/images/avatar1.jpg',
    ),
    _Friend(
      '유나',
      26,
      '🇰🇷',
      'incheon',
      _Status.online,
      'assets/images/avatar2.jpg',
    ),
    _Friend(
      'ひなた',
      22,
      '🇯🇵',
      'fukuoka',
      _Status.away2,
      'assets/images/avatar3.jpg',
    ),
    _Friend(
      '민서',
      25,
      '🇰🇷',
      'daejeon',
      _Status.online,
      'assets/images/avatar1.jpg',
    ),
    _Friend(
      'ゆうき',
      24,
      '🇯🇵',
      'nagoya',
      _Status.online,
      'assets/images/avatar2.jpg',
    ),
    _Friend(
      '채원',
      27,
      '🇰🇷',
      'gwangju',
      _Status.online,
      'assets/images/avatar3.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.pagePad,
            AppDimens.gapMd,
            AppDimens.pagePad,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    '친구',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  _Dot(),
                  Spacer(),
                  Icon(Icons.search, color: AppColors.textPrimary, size: 26),
                  SizedBox(width: 16),
                  Icon(
                    Icons.tune_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Text(
                    '지금 접속 중 ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '36명',
                    style: TextStyle(
                      color: AppColors.moonlight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.gapMd),
              const _FilterBar(),
              const SizedBox(height: AppDimens.gapMd),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              0,
              AppDimens.pagePad,
              AppDimens.gapMd,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 20,
              mainAxisExtent: 180,
            ),
            itemCount: _friends.length,
            itemBuilder: (context, i) => _FriendCard(friend: _friends[i]),
          ),
        ),
      ],
    );
  }
}

enum _Status { online, away1, away2 }

class _Friend {
  const _Friend(
    this.name,
    this.age,
    this.flag,
    this.city,
    this.status,
    this.avatar,
  );
  final String name;
  final int age;
  final String flag;
  final String city;
  final _Status status;
  final String avatar;
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});

  final _Friend friend;

  @override
  Widget build(BuildContext context) {
    final online = friend.status == _Status.online;
    final statusText = switch (friend.status) {
      _Status.online => '온라인',
      _Status.away1 => '1시간 전 접속',
      _Status.away2 => '2시간 전 접속',
    };

    return Column(
      children: [
        // 아바타 + 국기 배지
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.moonlight.withValues(alpha: 0.5),
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(friend.avatar, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.night,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      friend.flag,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${friend.name} ${friend.age}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          friend.city,
          style: const TextStyle(color: AppColors.gold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: online ? const Color(0xFF3FCF6B) : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: online ? const Color(0xFF3FCF6B) : AppColors.gold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _FilterChip(
            leading: Icon(Icons.female, size: 18),
            label: '여자',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            leading: Icon(Icons.person_outline, size: 18),
            label: '20대',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _FilterChip(
            leading: Text('🇰🇷', style: TextStyle(fontSize: 15)),
            label: '한국',
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
