import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import 'chat_screen.dart';

/// 대화방 목록 (정적 UI). 메인 셸의 '대화방' 탭 본문.
/// 매칭 목록/보낸 신청/실시간 갱신은 서버 연동 단계에서 붙인다. (docs/01, 기획서 5장)
class ChatRoomsScreen extends StatelessWidget {
  const ChatRoomsScreen({super.key});

  static const _rooms = <_Room>[
    _Room(
      '지우',
      27,
      '🇰🇷',
      '2분 전',
      '오늘 하루 있었던 일들을 편하게 나눠요 :)',
      'assets/images/avatar1.jpg',
      true,
    ),
    _Room(
      '유리',
      25,
      '🇰🇷',
      '15분 전',
      '좋아하는 음악을 추천하고 함께 들어요!',
      'assets/images/avatar2.jpg',
      true,
    ),
    _Room(
      'ゆい',
      24,
      '🇯🇵',
      '1시간 전',
      '綺麗な風景や日常をシェアして癒されましょう！',
      'assets/images/avatar3.jpg',
      true,
    ),
    _Room(
      '민서',
      26,
      '🇰🇷',
      '2시간 전',
      '요즘 읽고 있는 책, 추천하고 싶어요.',
      'assets/images/avatar1.jpg',
      false,
    ),
    _Room(
      'さくら',
      23,
      '🇯🇵',
      '3시간 전',
      '気軽におしゃべりして、友達を作りましょう！',
      'assets/images/avatar2.jpg',
      false,
    ),
    _Room(
      '하린',
      22,
      '🇰🇷',
      '5시간 전',
      '주말 계획 함께 공유하고 약속을 잡아요!',
      'assets/images/avatar3.jpg',
      false,
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
                    '대화방',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  _Dot(),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '마음이 통하는 사람들과 이야기를 나눠보세요.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppDimens.gapMd),
              const _TabPills(),
              const SizedBox(height: AppDimens.gapMd),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              0,
              AppDimens.pagePad,
              AppDimens.gapMd,
            ),
            itemCount: _rooms.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gapSm),
            itemBuilder: (context, i) => _RoomTile(room: _rooms[i]),
          ),
        ),
      ],
    );
  }
}

class _Room {
  const _Room(
    this.name,
    this.age,
    this.flag,
    this.time,
    this.message,
    this.avatar,
    this.unread,
  );
  final String name;
  final int age;
  final String flag;
  final String time;
  final String message;
  final String avatar;
  final bool unread;
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final _Room room;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(name: room.name, avatar: room.avatar),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  room.avatar,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${room.name} ${room.age}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(room.flag, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Text(
                          room.time,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (room.unread) ...[
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.moonlight,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPills extends StatelessWidget {
  const _TabPills();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _Pill(
            icon: Icons.chat_bubble_outline,
            label: '매칭 대화',
            count: 6,
            active: true,
          ),
          SizedBox(width: 10),
          _Pill(icon: Icons.send_outlined, label: '보낸 신청', count: 6),
          SizedBox(width: 10),
          _Pill(icon: Icons.translate, label: '번역'),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    this.count,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: active ? AppColors.moonlight.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active ? AppColors.moonlight : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? AppColors.moonlight : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.moonlight,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
