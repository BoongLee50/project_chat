import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../data/models/store_models.dart';
import '../providers/store_provider.dart';
import '../widgets/store_widgets.dart';

/// 화면 29(포스트 앨범 패스) · 30(자동 번역 패스).
///
/// 두 화면은 혜택 문구만 다르고 구조가 같아 [kind]로 한 화면을 공유한다.
/// 보유 중이면 남은 기간과 이용 정보를, 아니면 "구매 대기" 상태를 보여준다.
class PassScreen extends ConsumerStatefulWidget {
  const PassScreen({super.key, required this.kind});

  final String kind;

  static Route<void> route(String kind) =>
      MaterialPageRoute(builder: (_) => PassScreen(kind: kind));

  @override
  ConsumerState<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends ConsumerState<PassScreen> {
  int _selected = 0;
  bool _busy = false;

  bool get _isAlbum => widget.kind == StoreKind.albumPass;

  Color get _accent =>
      _isAlbum ? const Color(0xFF2F7BF6) : const Color(0xFF23A455);

  Future<void> _purchase(LunaProduct product) async {
    setState(() => _busy = true);
    final error = await ref
        .read(storeActionsProvider)
        .purchaseWithLuna(product.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ?? '${StoreKind.label(widget.kind)} ${product.durationDays}일 구매 완료!',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final wallet = ref.watch(walletProvider).valueOrNull ?? Wallet.empty;

    final active = wallet.has(widget.kind);
    final remaining = wallet.remainingDays(widget.kind);
    final expires = wallet.expiresAt(widget.kind);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: StoreAppBar(
        icon: _isAlbum ? Icons.photo_library_outlined : Icons.language,
        title: StoreKind.label(widget.kind),
        subtitle: _isAlbum
            ? '더 많은 포스트 사진을 등록하고 다양한 매력을 보여주세요!'
            : '언어의 장벽 없이 더 많은 사람과 대화해보세요!',
        iconColor: _accent,
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.moonlight),
        ),
        error: (error, _) => const Center(
          child: Text('상품을 불러오지 못했어요.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (data) {
          final options = data.optionsOf(widget.kind);
          final selected = options.isEmpty
              ? null
              : options[_selected.clamp(0, options.length - 1)];

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.pagePad,
              AppDimens.gapMd,
              AppDimens.pagePad,
              AppDimens.gapLg,
            ),
            children: [
              StoreCard(
                accent: _accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(
                          label: active ? '이용 중' : '구매 대기',
                          color: _accent,
                          filled: active,
                        ),
                        const Spacer(),
                        if (active && remaining != null)
                          _RemainingBadge(days: remaining, accent: _accent),
                      ],
                    ),
                    const SizedBox(height: AppDimens.gapMd),
                    Text(
                      selected == null
                          ? StoreKind.label(widget.kind)
                          : '${selected.durationDays}일 패스',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimens.gapMd),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 6),
                    ..._benefits(),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.gapMd),
              const _SectionTitle('기간 선택'),
              const SizedBox(height: AppDimens.gapSm),
              for (var i = 0; i < options.length; i++)
                PriceOptionTile(
                  label: '${options[i].durationDays}일',
                  price: options[i].price,
                  selected: i == _selected,
                  accent: _accent,
                  onTap: () => setState(() => _selected = i),
                ),
              const SizedBox(height: AppDimens.gapMd),
              const _SectionTitle('이용 정보'),
              const SizedBox(height: AppDimens.gapSm),
              StoreCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.star_outline,
                      label: '구매 금액',
                      value: selected == null ? '-' : '${selected.price} 루나',
                      valueColor: AppColors.gold,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    InfoRow(
                      icon: Icons.schedule,
                      label: '보유 상태',
                      value: active ? '이용 중' : '미보유',
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    InfoRow(
                      icon: Icons.event_available,
                      label: '유효 기간',
                      value: expires == null ? '-' : '${_date(expires)}까지',
                    ),
                  ],
                ),
              ),
              if (active) ...[
                const SizedBox(height: AppDimens.gapSm),
                Text(
                  '이미 이용 중이에요. 지금 구매하면 남은 기간에 이어서 연장됩니다.',
                  style: TextStyle(color: _accent, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: catalog.valueOrNull == null
          ? null
          : Builder(
              builder: (context) {
                final options = catalog.value!.optionsOf(widget.kind);
                if (options.isEmpty) return const SizedBox.shrink();
                final selected =
                    options[_selected.clamp(0, options.length - 1)];
                return StoreBottomButton(
                  label: active
                      ? '${StoreKind.label(widget.kind)} 연장'
                      : '${StoreKind.label(widget.kind)} 구매',
                  price: selected.price,
                  color: _accent,
                  busy: _busy,
                  onPressed: () => _purchase(selected),
                );
              },
            ),
    );
  }

  List<Widget> _benefits() {
    if (_isAlbum) {
      return const [
        BenefitRow(
          icon: Icons.photo_library_outlined,
          title: '포스트 사진 최대 8장까지 등록',
          description: '기본 1장에서 최대 8장까지 여러 장의 사진을 등록할 수 있어요.',
          accent: Color(0xFF2F7BF6),
          checked: false,
        ),
        BenefitRow(
          icon: Icons.photo_camera_back_outlined,
          title: '휴대폰 갤러리 사진까지 업로드 가능',
          description: '카메라로 찍은 사진뿐만 아니라 갤러리 사진도 올릴 수 있어요.',
          accent: Color(0xFF2F7BF6),
          checked: false,
        ),
        BenefitRow(
          icon: Icons.access_time,
          title: '등록 시간 제한 없음 (24시간 자유롭게)',
          description: '시간 제약 없이 언제든지 자유롭게 포스트를 등록할 수 있어요.',
          accent: Color(0xFF2F7BF6),
          checked: false,
        ),
      ];
    }
    return const [
      BenefitRow(
        icon: Icons.chat_bubble_outline,
        title: '채팅 자동 번역 무제한',
        description: '상대방의 메시지를 자동으로 번역해 실시간으로 소통할 수 있어요.',
        accent: Color(0xFF23A455),
        checked: false,
      ),
      BenefitRow(
        icon: Icons.person_outline,
        title: '프로필 자동 번역 무제한',
        description: '상대방의 프로필 정보와 하루 한마디를 자동으로 번역해줘요.',
        accent: Color(0xFF23A455),
        checked: false,
      ),
      BenefitRow(
        icon: Icons.forum_outlined,
        title: '댓글 자동 번역 무제한',
        description: '달빛가든과 포스트의 댓글을 자동으로 번역해줘요.',
        accent: Color(0xFF23A455),
        checked: false,
      ),
    ];
  }

  String _date(DateTime value) =>
      '${value.year}. ${value.month.toString().padLeft(2, '0')}. '
      '${value.day.toString().padLeft(2, '0')}';
}

/// 시안의 원형 "남은 기간" 배지.
class _RemainingBadge extends StatelessWidget {
  const _RemainingBadge({required this.days, required this.accent});

  final int days;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '남은 기간',
            style: TextStyle(color: accent, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            '$days일',
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
