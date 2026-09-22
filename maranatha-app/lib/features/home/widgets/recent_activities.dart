import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});
  @override
  Widget build(BuildContext context) {
    const activities = <_ActivityData>[
      _ActivityData(
        title: 'Moment de priÃ¨re',
        date: 'Hier',
        image: AppAssets.prayer,
        icon: AppIcons.prayer,
      ),
      _ActivityData(
        title: 'Enseignement',
        date: 'Il y a 2 jours',
        image: AppAssets.teaching,
        icon: AppIcons.teaching,
      ),
      _ActivityData(
        title: 'Louange',
        date: 'Il y a 3 jours',
        image: AppAssets.worship,
        icon: AppIcons.worship,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'ActivitÃ©s rÃ©centes',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Text(
              'Voir tout',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 3),
            Icon(AppIcons.next, color: AppColors.primary, size: 13),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 9.0;
            final cardWidth = (constraints.maxWidth - (gap * 2)) / 3;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < activities.length; i++) ...[
                  SizedBox(
                    width: cardWidth,
                    child: _ActivityCard(data: activities[i]),
                  ),
                  if (i < activities.length - 1) const SizedBox(width: gap),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActivityData {
  const _ActivityData({
    required this.title,
    required this.date,
    required this.image,
    required this.icon,
  });
  final String title;
  final String date;
  final String image;
  final IconData icon;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.data});
  final _ActivityData data;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 78,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  data.image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Positioned(
              left: 7,
              bottom: -13,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: AppColors.primary, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.navy,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.date,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
