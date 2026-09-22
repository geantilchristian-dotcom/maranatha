import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10002A6A),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: const TextField(
        style: TextStyle(
          fontFamily: 'Manrope',
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Que cherches-tu aujourdâ€™hui ?',
          hintStyle: TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.textMuted,
            fontSize: 12,
          ),
          prefixIcon: Icon(AppIcons.search, color: AppColors.navy, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
