import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';

class VerseOfDayCard extends StatelessWidget {
  const VerseOfDayCard({super.key, this.height = 185});
  final double height;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop = width >= 900;
        final tablet = width >= 600 && width < 900;
        final sideWidth = desktop
            ? 155.0
            : tablet
            ? 125.0
            : 92.0;
        final quoteSize = desktop
            ? 17.0
            : tablet
            ? 15.0
            : 12.3;
        final titleSize = desktop
            ? 12.0
            : tablet
            ? 10.5
            : 9.0;
        final refSize = desktop
            ? 12.0
            : tablet
            ? 10.0
            : 9.0;
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: sideWidth,
                height: double.infinity,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 22 : 14,
                    vertical: desktop ? 22 : 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2F79FF), Color(0xFF003DF0)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VERSET\nDU JOUR',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: titleSize,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.7,
                        ),
                      ),
                      SizedBox(height: desktop ? 14 : 10),
                      Container(
                        width: desktop ? 34 : 26,
                        height: 2,
                        color: Colors.white,
                      ),
                      const Spacer(),
                      Icon(
                        AppIcons.leaf,
                        color: Colors.white,
                        size: desktop ? 31 : 24,
                      ),
                      const Spacer(),
                      Text(
                        'UNE FOI\nUN PEUPLE\nUNE MISSION',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.white,
                          fontSize: desktop ? 8.5 : 6.5,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppAssets.verseBackground,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomRight,
                      filterQuality: FilterQuality.high,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF8FBFF),
                            Color(0xDDF8FBFF),
                            Color(0x55FFFFFF),
                          ],
                          stops: [0.0, 0.42, 0.72, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? 28 : 18,
                        desktop ? 28 : 20,
                        desktop ? 30 : 17,
                        desktop ? 24 : 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Â« Car je connais les projets que jâ€™ai formÃ©s '
                            'sur vous, projets de paix et non de mal, afin '
                            'de vous donner un avenir et une espÃ©rance. Â»',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.navy,
                              fontSize: quoteSize,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: desktop ? 13 : 9),
                          Text(
                            'JÃ©rÃ©mie 29:11',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.textSecondary,
                              fontSize: refSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
