import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

class ChurchBanner extends StatelessWidget {
  const ChurchBanner({super.key, this.height = 118});
  final double height;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(
          AppAssets.homeBanner,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
