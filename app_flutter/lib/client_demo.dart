import 'package:flutter/material.dart';

import 'client_demo/demo_app.dart';

/// Isolated static preview. Never initialize Supabase or load product config.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClientDemoApp());
}
