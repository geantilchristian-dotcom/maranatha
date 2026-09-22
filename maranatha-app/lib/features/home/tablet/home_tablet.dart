import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/become_member_button.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/church_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/maranatha_drawer.dart';
import '../widgets/recent_activities.dart';
import '../widgets/verse_of_day_card.dart';

class HomeTablet extends StatefulWidget {
  const HomeTablet({super.key});
  @override
  State<HomeTablet> createState() => _HomeTabletState();
}

class _HomeTabletState extends State<HomeTablet> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const MaranathaDrawer(),
      bottomNavigationBar: const HomeBottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  HomeHeader(
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  const SizedBox(height: 12),
                  const ChurchBanner(),
                  const SizedBox(height: 18),
                  const HomeSearchBar(),
                  const SizedBox(height: 18),
                  const BecomeMemberButton(),

                  const SizedBox(height: 14),

                  const VerseOfDayCard(height: 245),
                  const SizedBox(height: 26),
                  const RecentActivities(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
