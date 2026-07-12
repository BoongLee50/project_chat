import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// 채팅창 (정적 UI). 대화방 목록에서 항목을 탭하면 열린다.
/// 실시간 송수신은 소켓 연동 단계에서 붙인다. (docs/01 WebSocket, 기획서 5-1)
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.name, required this.avatar});

  final String name;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ChatAppBar(name: name, avatar: avatar),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimens.pagePad),
                children: [
                  const _SystemMessage('매칭되었습니다. 예의 있는 멋진 대화를 나눠보세요.'),
                  const SizedBox(height: AppDimens.gapMd),
                  const _DateDivider('오늘'),
                  const SizedBox(height: AppDimens.gapMd),
                  _ReceivedBubble(
                    avatar: avatar,
                    lines: const ['안녕하세요! 😊', '1:1 대화 신청해주셔서 감사합니다.'],
                    time: '오후 8:58',
                  ),
                  const _SentBubble(
                    lines: ['안녕하세요! 반가워요 😊', '저도 반가워요!'],
                    time: '오후 8:59',
                  ),
                  _ReceivedBubble(
                    avatar: avatar,
                    lines: const ['今日は送ってくれた写真、本当にきれいですね！', 'どこで撮ったんですか？'],
                    translated: const ['오늘 보내주신 사진 정말 예쁘네요!', '어디에서 찍은 건가요?'],
                    time: '오후 8:59',
                  ),
                  const _SentBubble(
                    lines: ['네! 풍경 사진 찍는 걸 좋아해요 📷', '주로 어떤 사진 찍으세요?'],
                    time: '오후 9:00',
                  ),
                ],
              ),
            ),
            const _InputBar(),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.name, required this.avatar});

  final String name;
  final String avatar;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.night,
      titleSpacing: 0,
      leadingWidth: 40,
      title: Row(
        children: [
          ClipOval(
            child: Image.asset(
              avatar,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🇰🇷', style: TextStyle(fontSize: 14)),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.circle, color: Color(0xFF3FCF6B), size: 9),
                  SizedBox(width: 5),
                  Text(
                    '온라인',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: const [
              Icon(Icons.language, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 4),
              Text(
                '번역',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
          color: AppColors.surfaceHigh,
          onSelected: (_) {},
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: _MenuRow(Icons.person_outline, '프로필 보기'),
            ),
            PopupMenuItem(
              value: 'report',
              child: _MenuRow(Icons.flag_outlined, '신고하기'),
            ),
            PopupMenuItem(value: 'block', child: _MenuRow(Icons.block, '차단하기')),
            PopupMenuItem(
              value: 'leave',
              child: _MenuRow(Icons.logout, '대화방 나가기'),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ],
    );
  }
}

class _SystemMessage extends StatelessWidget {
  const _SystemMessage(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

class _ReceivedBubble extends StatelessWidget {
  const _ReceivedBubble({
    required this.avatar,
    required this.lines,
    required this.time,
    this.translated,
  });

  final String avatar;
  final List<String> lines;
  final List<String>? translated;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              avatar,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF2EAD8),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final l in lines)
                    Text(
                      l,
                      style: const TextStyle(
                        color: Color(0xFF2A2620),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  if (translated != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(
                          Icons.translate,
                          color: Color(0xFF6C5CE7),
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '번역',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Divider(color: Color(0x33000000), height: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final l in translated!)
                      Text(
                        l,
                        style: const TextStyle(
                          color: Color(0xFF4A463E),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF8A857A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SentBubble extends StatelessWidget {
  const _SentBubble({required this.lines, required this.time});

  final List<String> lines;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gapMd),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final l in lines)
                        Text(
                          l,
                          style: const TextStyle(
                            color: Color(0xFF20202A),
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all,
                      color: AppColors.moonlight,
                      size: 15,
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

class _InputBar extends StatelessWidget {
  const _InputBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.moonlight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                '메시지를 입력하세요...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.call_outlined,
            color: AppColors.textSecondary,
            size: 26,
          ),
        ],
      ),
    );
  }
}
