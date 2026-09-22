import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onMenuPressed});
  final VoidCallback onMenuPressed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          _HeaderIconButton(icon: AppIcons.menu, onPressed: onMenuPressed),
          const SizedBox(width: 7),
          SizedBox(
            width: 43,
            height: 43,
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CEMM Maranatha',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'IL VIENT BIENTÔT',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(icon: AppIcons.notification, onPressed: () {}),
          const SizedBox(width: 5),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.profile,
              color: AppColors.primary,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 35,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 18,
        onPressed: onPressed,
        icon: Icon(icon, size: 21, color: AppColors.primary),
      ),
    );
  }
}
