import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/direct/pages/direct_page.dart';

final GlobalKey<NavigatorState> maranathaNavigatorKey =
    GlobalKey<NavigatorState>();

String _pendingDirectId = '';
Timer? _navigationRetry;

void openMaranathaDirect(String id) {
  _pendingDirectId = id.trim();
  _navigationRetry?.cancel();
  _tryOpenDirect();
}

void _tryOpenDirect([int attempt = 0]) {
  final navigator = maranathaNavigatorKey.currentState;

  if (navigator == null) {
    if (attempt >= 30) {
      return;
    }

    _navigationRetry = Timer(const Duration(milliseconds: 200), () {
      _tryOpenDirect(attempt + 1);
    });

    return;
  }

  final id = _pendingDirectId;
  _pendingDirectId = '';

  navigator.push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: id.isEmpty ? '/direct' : '/direct/$id'),
      builder: (_) {
        return DirectPage(focusId: id.isEmpty ? null : id);
      },
    ),
  );
}
