import 'package:flutter/material.dart';

import '../../user/pages/user_modules.dart';

class BecomeMemberButton extends StatelessWidget {
  const BecomeMemberButton({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: () {
          openMemberRegistration(context);
        },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF003DF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Devenir membre',
          style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
