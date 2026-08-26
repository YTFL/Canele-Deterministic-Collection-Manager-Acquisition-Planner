import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/json_backup_service.dart';
import '../../providers/quota_provider.dart';
import '../../providers/rule_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/canele_card.dart';
import 'import_export_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Selector
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('App Theme'),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                        tooltip: 'System Auto',
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded, size: 18),
                        tooltip: 'Light Mode',
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded, size: 18),
                        tooltip: 'Dark Mode',
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (set) =>
                        ref.read(themeNotifierProvider.notifier).setThemeMode(set.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.caramelizedAmber;
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data Portability & Auto-Backup Section
            Text(
              'Data Portability & Auto-Backup',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sync_lock_rounded, color: AppColors.caramelizedAmber, size: 28),
                    title: const Text('File Hub & Auto-Backup', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Auto-backups, spreadsheets, and imports'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ImportExportScreen()),
                      );
                    },
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.statusDanger),
                    title: const Text('Wipe App Database', style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Permanently erase all books, history, custom rules, and settings'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Wipe Complete App Database?'),
                          content: const Text(
                            'Are you sure you want to permanently wipe the entire database? This will delete all series, volumes, transactions, custom rules, and cadence timeline settings.\n\nThis action cannot be undone.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
                              child: const Text('Wipe Database'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await JsonBackupService.wipeCompleteDatabase();
                        ref.read(seriesNotifierProvider.notifier).load();
                        ref.read(volumesNotifierProvider.notifier).load();
                        ref.read(transactionsNotifierProvider.notifier).load();
                        ref.read(ruleConfigNotifierProvider.notifier).load();
                        ref.read(rulesNotifierProvider.notifier).load();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('App database completely wiped!'),
                              backgroundColor: AppColors.statusDanger,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Wizard & Setup Options
            Text('Setup Wizard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.caramelizedAmber),
                title: const Text('Re-run Setup Wizard'),
                subtitle: const Text('Reconfigure timeline start, cadence, and recurring bonuses'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Specification & About Card
            Text('About Project Canelé', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.caramelizedAmber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Deterministic Acquisition Architecture',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Local-First: 100% of your data stays on this device.\n'
                    '• Zero AI: Transparent arithmetic and multi-pass pipeline rules.\n'
                    '• Auto-Skip Resolution: Automatically advances schedule timeline when ahead on quota.\n'
                    '• Universal Importer: Native support for Goodreads, StoryGraph, CSV, and XLSX.\n'
                    '• Fractional Volumes: Native support for .5 side-stories.\n'
                    '• Canelé Palette: Custard cream, caramelized amber, and warm pastry crust.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
