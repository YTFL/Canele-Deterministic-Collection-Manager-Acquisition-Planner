import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/hive_boxes.dart';
import 'core/theme/app_theme.dart';
import 'providers/backup_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/quota_provider.dart';
import 'services/backup_service.dart';
import 'ui/screens/main_shell_screen.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Boxes
  await HiveBoxes.init();

  // Initialize BackupService listener from persisted settings
  BackupService.instance.initFromStorage();

  runApp(
    const ProviderScope(
      child: CaneleApp(),
    ),
  );
}

class CaneleApp extends ConsumerWidget {
  const CaneleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final config = ref.watch(ruleConfigNotifierProvider);
    ref.watch(backupNotifierProvider); // Keep auto-backup state notifier active across entire app

    return MaterialApp(
      title: 'Project Canelé',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: config.isOnboardingCompleted
          ? const MainShellScreen()
          : const OnboardingScreen(),
    );
  }
}
