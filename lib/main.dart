import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.load();
  runApp(const ToolboxApp());
}

class ToolboxApp extends StatelessWidget {
  const ToolboxApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Color>(
        valueListenable: AppTheme.accent,
        builder: (_, accent, __) => ValueListenableBuilder<int>(
          valueListenable: AppTheme.mode,
          builder: (_, m, __) => MaterialApp(
            title: 'Toolbox Vault',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(Brightness.light, accent),
            darkTheme: AppTheme.build(Brightness.dark, accent, amoled: m == 3),
            themeMode: m == 1 ? ThemeMode.light : (m == 0 ? ThemeMode.system : ThemeMode.dark),
            home: const HomeScreen(),
          ),
        ),
      );
}
