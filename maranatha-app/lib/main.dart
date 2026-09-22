import 'package:flutter/material.dart';

import 'app/maranatha_app.dart';
import 'features/live/widgets/maranatha_live_bootstrap.dart';
import 'features/live/widgets/maranatha_live_setup_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaranathaLiveBootstrap(
      child: MaranathaLiveSetupGate(child: MaranathaApp()),
    ),
  );
}
