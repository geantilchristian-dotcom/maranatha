import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeShortcut extends StatelessWidget {
  const HomeShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F8FD),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 112,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: primary
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2D7DFF), Color(0xFF003DF0)],
                          )
                        : null,
                    color: primary ? null : const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: primary
                        ? const [
                            BoxShadow(
                              color: Color(0x26003DF0),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 27,
                    color: primary ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 22,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
