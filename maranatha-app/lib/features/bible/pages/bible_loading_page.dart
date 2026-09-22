import 'dart:async';

import 'package:flutter/material.dart';

import 'bible_page.dart';

class BibleLoadingPage extends StatefulWidget {
  const BibleLoadingPage({super.key});
  @override
  State<BibleLoadingPage> createState() => _BibleLoadingPageState();
}

class _BibleLoadingPageState extends State<BibleLoadingPage> {
  bool _showBible = false;
  bool _showSpinner = true;
  Timer? _openTimer;
  Timer? _spinnerTimer;
  @override
  void initState() {
    super.initState();
    _openTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _showBible = true;
      });
      _spinnerTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          _showSpinner = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    _spinnerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (_showBible)
          const BiblePage()
        else
          const ColoredBox(color: Colors.white, child: SizedBox.expand()),
        if (_showSpinner)
          const Positioned.fill(
            child: Material(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF003DF0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
