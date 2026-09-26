import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/database/json_backup_service.dart';
import '../../models/app_update_model.dart';
import '../../providers/quota_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/update_service.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import 'package:hive/hive.dart';
import '../../core/database/hive_boxes.dart';
import '../../core/utils/workspace_terminology.dart';
import '../widgets/add_workspace_dialog.dart';
import '../widgets/edit_custom_schema_sheet.dart';
import '../widgets/canele_card.dart';
import '../widgets/update_dialog.dart';
import 'import_export_screen.dart';
import 'onboarding_screen.dart';
import 'whats_new_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final UpdateService _updateService = UpdateService();
  late Future<PackageInfo> _packageInfoFuture;
  late Future<DateTime?> _currentVersionReleaseDateFuture;

  AppUpdate? _availableUpdate;
  bool _isCheckingForUpdate = false;
  bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _currentVersionReleaseDateFuture = _loadBundledReleaseDate();
  }

  Future<DateTime?> _loadBundledReleaseDate() async {
    try {
      final releaseNotes = await rootBundle.loadString('RELEASE_NOTES.md');
      final lines = releaseNotes.replaceAll('\r\n', '\n').split('\n');
      for (final line in lines) {
        final match = RegExp(
          r'Release Date[:\*]*\s*([A-Za-z]+ \d{1,2}, \d{4}|\d{4}-\d{2}-\d{2})',
          caseSensitive: false,
        ).firstMatch(line);
        if (match != null) {
          final dateText = match.group(1)?.trim();
          if (dateText != null) {
            try {
              return DateFormat('MMMM d, y').parse(dateText);
            } catch (_) {
              try {
                return DateTime.parse(dateText);
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    // Fallback to latest GitHub release published date
    try {
      return await _updateService.fetchLatestReleaseDate();
    } catch (_) {
      return null;
    }
  }

  Future<AppUpdate?> _checkForUpdateManually() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    final update = await _updateService.checkForUpdate(respectDeferral: false);
    if (!mounted) return null;

    setState(() {
      _isCheckingForUpdate = false;
      _hasCheckedForUpdate = true;
      _availableUpdate = update;
    });

    return update;
  }

  Future<void> _onUpdateTileTap() async {
    if (_isCheckingForUpdate) return;

    final update = await _checkForUpdateManually();
    if (!mounted) return;

    if (update == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('You are already on the latest version.'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      return;
    }

    await _showUpdateScreen(update);
    if (!mounted) return;

    setState(() {
      _availableUpdate = update;
      _hasCheckedForUpdate = true;
    });
  }

  Future<void> _showUpdateScreen(AppUpdate update) async {
    var isDownloading = false;
    var downloadProgress = 0.0;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => StatefulBuilder(
          builder: (routeContext, routeSetState) => FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (routeContext, snapshot) {
              final currentVersion = snapshot.data?.version ?? '1.0.0';
              return UpdateFullScreen(
                update: update,
                currentVersion: currentVersion,
                isDownloading: isDownloading,
                downloadProgress: downloadProgress,
                onInstallNow: () async {
                  routeSetState(() {
                    isDownloading = true;
                    downloadProgress = 0.0;
                  });

                  final navigator = Navigator.of(routeContext);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    final apkFile = await _updateService.downloadAPK(
                      update.version,
                      onProgress: (progress) {
                        if (mounted) {
                          routeSetState(() {
                            downloadProgress = progress;
                          });
                        }
                      },
                    );

                    if (apkFile != null && mounted) {
                      final installResult = await _updateService.installAPK(apkFile);
                      if (!mounted) return;
                      switch (installResult) {
                        case InstallResult.installerStarted:
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Installer opened. Complete the update to continue.')),
                          );
                          break;
                        case InstallResult.permissionRequired:
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Allow installs from this source, then tap Install Now again.'),
                            ),
                          );
                          break;
                        case InstallResult.installerUnavailable:
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('No installer found to open the APK on this device.'),
                            ),
                          );
                          break;
                        case InstallResult.failed:
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to launch installer. APK saved for retry.'),
                            ),
                          );
                          break;
                      }
                    } else if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Failed to download update')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      routeSetState(() {
                        isDownloading = false;
                      });
                    }
                  }
                },
                onRemindLater: () async {
                  try {
                    await _updateService.deferUpdate();
                    if (routeContext.mounted) {
                      Navigator.of(routeContext).pop();
                    }
                  } catch (e) {
                    debugPrint('Error deferring update: $e');
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context, String currentCurrency) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPastryCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Currency',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...CurrencyHelper.supportedCurrencies.map((opt) {
                final isSelected = opt.code == currentCurrency;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.caramelizedAmber
                          : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                      width: isSelected ? 1.5 : 0.8,
                    ),
                  ),
                  child: ListTile(
                    leading: CurrencySymbolBox(
                      currencyCode: opt.code,
                      isSelected: isSelected,
                    ),
                    title: Text(
                      opt.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('Code: ${opt.code} · Symbol: ${opt.symbol}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.caramelizedAmber)
                        : null,
                    onTap: () async {
                      final currentConfig = ref.read(ruleConfigNotifierProvider);
                      final updatedConfig = currentConfig.copyWith(currency: opt.code);
                      await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updatedConfig);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('Currency updated to ${opt.name}!'),
                              backgroundColor: AppColors.caramelizedAmber,
                            ),
                          );
                      }
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  IconData _getProfileIcon(String? iconName, ProfileType type) {
    if (type == ProfileType.games) {
      return Icons.sports_esports_rounded;
    }
    if (type == ProfileType.custom) {
      switch (iconName) {
        case 'movie':
        case 'film':
          return Icons.movie_rounded;
        case 'music':
          return Icons.music_note_rounded;
        case 'album':
          return Icons.album_rounded;
        case 'palette':
        case 'art':
          return Icons.palette_rounded;
        case 'coffee':
          return Icons.coffee_rounded;
        case 'wine':
          return Icons.wine_bar_rounded;
        case 'sneaker':
        case 'shoes':
          return Icons.roller_skating_rounded;
        case 'toy':
        case 'figure':
          return Icons.smart_toy_rounded;
        case 'watch':
          return Icons.watch_rounded;
        case 'camera':
          return Icons.camera_alt_rounded;
        case 'card':
          return Icons.style_rounded;
        default:
          return Icons.layers_rounded;
      }
    }
    return Icons.auto_stories_rounded;
  }

  void _showRenameWorkspaceDialog(BuildContext context, Profile profile) {
    final controller = TextEditingController(text: profile.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Workspace'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Workspace Name',
            hintText: 'Enter new workspace name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != profile.name) {
                await ref.read(profileNotifierProvider.notifier).renameProfile(profile.id, newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Workspace renamed to "$newName"'),
                        backgroundColor: AppColors.caramelizedAmber,
                      ),
                    );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.caramelizedAmber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearWorkspaceDialog(BuildContext context, Profile profile) {
    final terminology = WorkspaceTerminology(profile);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear ${profile.name}?'),
        content: Text(
          'Are you sure you want to remove all ${terminology.itemsLabel.toLowerCase()} and acquisition history from "${profile.name}"?\n\n'
          'Your custom rules, quotas, and workspace settings will be kept intact.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveBoxes.clearAllUserData(profile.id);
              final activeProfile = ref.read(profileNotifierProvider).activeProfile;
              if (activeProfile.id == profile.id) {
                ref.read(profileNotifierProvider.notifier).reloadAll();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('All ${terminology.itemsLabel.toLowerCase()} in "${profile.name}" have been cleared.'),
                      backgroundColor: AppColors.statusDanger,
                    ),
                  );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Items'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWorkspaceDialog(BuildContext context, Profile profile, int totalProfilesCount) {
    if (totalProfilesCount <= 1 || profile.isDefault) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete Workspace'),
          content: Text(
            profile.isDefault
                ? 'The primary default workspace cannot be deleted.'
                : 'You must have at least one active workspace. Create or switch to another workspace before deleting this one.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final terminology = WorkspaceTerminology(profile);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${profile.name}"?'),
        content: Text(
          'Are you sure you want to permanently delete the "${profile.name}" workspace?\n\n'
          'All ${terminology.itemsLabel.toLowerCase()}, rules, quotas, and logs in this workspace will be deleted forever.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(profileNotifierProvider.notifier).deleteProfile(profile.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Workspace "${profile.name}" permanently deleted.'
                            : 'Could not delete workspace.',
                      ),
                      backgroundColor: success ? AppColors.statusDanger : AppColors.caramelizedAmber,
                    ),
                  );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Workspace'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSettingsTile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    Profile activeProfile,
    int totalProfilesCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = profile.id == activeProfile.id;
    final terminology = WorkspaceTerminology(profile);

    int itemCount = 0;
    final boxName = HiveBoxes.getSeriesBoxName(profile.id);
    if (Hive.isBoxOpen(boxName)) {
      itemCount = HiveBoxes.getSeriesBox(profile.id).length;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.caramelizedAmber
              : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
          width: isActive ? 1.5 : 0.8,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.caramelizedAmber
                : (isDark ? AppColors.darkPastryCard : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getProfileIcon(profile.icon, profile.type),
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                profile.name,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.caramelizedAmber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${profile.type.displayName} · $itemCount ${terminology.itemsLabel.toLowerCase()}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
            size: 20,
          ),
          onSelected: (value) async {
            switch (value) {
              case 'switch':
                await ref.read(profileNotifierProvider.notifier).switchProfile(profile.id);
                break;
              case 'rename':
                _showRenameWorkspaceDialog(context, profile);
                break;
              case 'schema':
                if (context.mounted) {
                  showEditCustomSchemaSheet(context, profile);
                }
                break;
              case 'clear':
                _showClearWorkspaceDialog(context, profile);
                break;
              case 'delete':
                _showDeleteWorkspaceDialog(context, profile, totalProfilesCount);
                break;
            }
          },
          itemBuilder: (ctx) => [
            if (!isActive)
              const PopupMenuItem(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Switch to Workspace'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Rename Workspace'),
                ],
              ),
            ),
            if (profile.type == ProfileType.custom)
              const PopupMenuItem(
                value: 'schema',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Customize Schema'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services_rounded, size: 18, color: AppColors.statusWarning),
                  const SizedBox(width: 8),
                  Text('Clear ${terminology.itemsLabel}', style: const TextStyle(color: AppColors.statusWarning)),
                ],
              ),
            ),
            if (!profile.isDefault && totalProfilesCount > 1)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusDanger),
                    SizedBox(width: 8),
                    Text('Delete Workspace', style: TextStyle(color: AppColors.statusDanger)),
                  ],
                ),
              ),
          ],
        ),
        onTap: () async {
          if (!isActive) {
            await ref.read(profileNotifierProvider.notifier).switchProfile(profile.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Switched to "${profile.name}" workspace'),
                    backgroundColor: AppColors.caramelizedAmber,
                    duration: const Duration(seconds: 2),
                  ),
                );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final ruleConfig = ref.watch(ruleConfigNotifierProvider);
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);
    final currentCurrencyOption = CurrencyHelper.getOption(ruleConfig.currency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workspaces & Profiles Management
            Text(
              'Workspaces & Profiles',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (ctx, ref, _) {
                final profileState = ref.watch(profileNotifierProvider);
                final activeProfile = profileState.activeProfile;
                final allProfiles = profileState.allProfiles;

                return CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Workspaces (${allProfiles.length})',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              AddWorkspaceDialog.show(
                                context: ctx,
                                onCreate: ({
                                  required String name,
                                  required ProfileType type,
                                  String? icon,
                                  CustomWorkspaceSchema? customSchema,
                                }) async {
                                  await ref.read(profileNotifierProvider.notifier).createProfile(
                                        name: name,
                                        type: type,
                                        icon: icon,
                                        customSchema: customSchema,
                                      );
                                },
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.caramelizedAmber,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...allProfiles.map(
                        (p) => _buildWorkspaceSettingsTile(
                          ctx,
                          ref,
                          p,
                          activeProfile,
                          allProfiles.length,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Theme Selector & Preferences
            Text(
              'Appearance & Preferences',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
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
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CurrencySymbolBox(
                      currencyCode: currentCurrencyOption.code,
                      size: 36,
                      backgroundColor: AppColors.caramelizedAmber.withValues(alpha: 0.12),
                      textColor: AppColors.caramelizedAmber,
                    ),
                    title: const Text('Primary Currency', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${currentCurrencyOption.name} (${currentCurrencyOption.symbol})'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _showCurrencyPicker(context, ruleConfig.currency),
                  ),
                  const Divider(height: 20),
                  Builder(
                    builder: (context) {
                      final canSync = ExchangeRateService.canSync(rates: exchangeRates);
                      final remaining = ExchangeRateService.timeUntilNextSync(rates: exchangeRates);
                      final cooldownText = ExchangeRateService.formatCooldownRemaining(remaining);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.caramelizedAmber, size: 24),
                        title: const Text('Exchange Rates Sync', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          exchangeRates.isSeed
                              ? 'Using baseline offline rates. Tap to sync live.'
                              : 'Synced: ${DateFormatter.formatDisplay(exchangeRates.lastUpdated)} ${canSync ? "· Sync available" : "· Next in $cooldownText"}',
                        ),
                        trailing: canSync
                            ? IconButton(
                                icon: const Icon(Icons.sync_rounded, color: AppColors.caramelizedAmber),
                                tooltip: 'Sync Exchange Rates Now',
                                onPressed: () async {
                                  ScaffoldMessenger.of(context)
                                    ..clearSnackBars()
                                    ..showSnackBar(
                                      const SnackBar(content: Text('Syncing latest exchange rates...')),
                                    );
                                  final success = await ref.read(exchangeRatesNotifierProvider.notifier).manualSync();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Exchange rates successfully updated and saved offline!'
                                                : 'Could not reach exchange rate servers. Using stored offline rates.',
                                          ),
                                          backgroundColor: success ? AppColors.statusSuccess : AppColors.statusWarning,
                                        ),
                                      );
                                  }
                                },
                              )
                            : Tooltip(
                                message: '24-hour rate limit active. Next sync in $cooldownText.',
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.sync_disabled_rounded,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkPastryBorder
                                        : AppColors.pastryCrustBorder,
                                    size: 22,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // System & Updates Section (AttendMate style)
            Text(
              'System & Updates',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // What's New
                  FutureBuilder<PackageInfo>(
                    future: _packageInfoFuture,
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.new_releases_outlined,
                          color: AppColors.caramelizedAmber,
                          size: 26,
                        ),
                        title: const Text("What's New", style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          version == null
                              ? 'See updates in your installed version'
                              : 'See updates in v$version',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WhatsNewScreen()),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 12),

                  // App updates
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _availableUpdate != null
                          ? Icons.system_update_alt_rounded
                          : Icons.system_update_rounded,
                      color: AppColors.caramelizedAmber,
                      size: 26,
                    ),
                    title: const Text('App updates', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      _isCheckingForUpdate
                          ? 'Checking for updates...'
                          : _availableUpdate != null
                              ? 'Update to v${_availableUpdate!.version}'
                              : _hasCheckedForUpdate
                                  ? 'You are on the latest version'
                                  : 'Tap to check for updates',
                    ),
                    trailing: _isCheckingForUpdate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _availableUpdate != null
                            ? const _UpdateAvailableBadge()
                            : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _isCheckingForUpdate ? null : _onUpdateTileTap,
                  ),
                  const Divider(height: 12),

                  // App version
                  FutureBuilder<PackageInfo>(
                    future: _packageInfoFuture,
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? 'Loading...';
                      final buildNumber = snapshot.data?.buildNumber ?? 'Loading...';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.caramelizedAmber,
                          size: 26,
                        ),
                        title: const Text('App version', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('v$version (Build $buildNumber)'),
                      );
                    },
                  ),
                  const Divider(height: 12),

                  // Current version release date
                  FutureBuilder<DateTime?>(
                    future: _currentVersionReleaseDateFuture,
                    builder: (context, snapshot) {
                      final releaseDate = snapshot.data;
                      final subtitle = releaseDate != null
                          ? DateFormat.yMMMd().format(releaseDate)
                          : (snapshot.connectionState == ConnectionState.waiting
                              ? 'Loading...'
                              : 'Unavailable');

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.update_rounded,
                          color: AppColors.caramelizedAmber,
                          size: 26,
                        ),
                        title: const Text(
                          'Current version release date',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(subtitle),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data Portability & Database Management Section
            Text(
              'Data Portability & Database Management',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (ctx, ref, _) {
                final activeProfile = ref.watch(profileNotifierProvider).activeProfile;
                final terminology = WorkspaceTerminology(activeProfile);

                return CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.sync_lock_rounded, color: AppColors.caramelizedAmber, size: 28),
                        title: const Text('File Hub & Auto-Backup', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Backups, spreadsheet exports, and restoration'),
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
                        leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.statusWarning, size: 26),
                        title: Text(
                          'Clear Active Workspace Items',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('Erase all ${terminology.itemsLabel.toLowerCase()} and history in "${activeProfile.name}" while keeping rules'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => _showClearWorkspaceDialog(context, activeProfile),
                      ),
                      const Divider(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_forever_rounded, color: AppColors.statusDanger, size: 26),
                        title: const Text('Wipe Complete App Database', style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.w700)),
                        subtitle: const Text('Permanently erase all workspaces, items, rules, and reset to fresh default'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Wipe Complete App Database?'),
                              content: const Text(
                                'Are you sure you want to permanently wipe the entire app database across ALL workspaces?\n\n'
                                'This will delete all books, games, custom collections, acquisition logs, rules, and custom workspaces, resetting Canelé back to a fresh install.\n\n'
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
                                  child: const Text('Wipe Database'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await JsonBackupService.wipeCompleteDatabase();
                            ref.read(profileNotifierProvider.notifier).reloadAll();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('App database completely wiped! Reset to default workspace.'),
                                    backgroundColor: AppColors.statusDanger,
                                  ),
                                );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _UpdateAvailableBadge extends StatelessWidget {
  const _UpdateAvailableBadge();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Update Available',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
