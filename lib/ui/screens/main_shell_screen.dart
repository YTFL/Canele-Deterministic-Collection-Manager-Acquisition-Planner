import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../models/app_update_model.dart';
import '../../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'dashboard_screen.dart';
import 'collection_screen.dart';
import 'rule_studio_screen.dart';
import 'settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  final UpdateService _updateService = UpdateService();
  AppUpdate? _pendingUpdate;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final update = await _updateService.checkForUpdate();
      if (update != null && mounted) {
        setState(() {
          _pendingUpdate = update;
        });
        _showUpdateScreen(update);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  void _showUpdateScreen(AppUpdate update) {
    var downloadProgress = 0.0;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => StatefulBuilder(
          builder: (routeContext, routeSetState) => FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (routeContext, snapshot) {
              final currentVersion = snapshot.data?.version ?? '1.0.0';
              return UpdateFullScreen(
                update: update,
                currentVersion: currentVersion,
                isDownloading: _isDownloading,
                downloadProgress: downloadProgress,
                onInstallNow: () async {
                  routeSetState(() {
                    _isDownloading = true;
                    downloadProgress = 0.0;
                  });

                  final navigator = Navigator.of(routeContext);
                  final messenger = ScaffoldMessenger.of(routeContext);

                  try {
                    final apkFile = await _updateService.downloadAPK(
                      _pendingUpdate?.version ?? update.version,
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
                      if (mounted) {
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
                        _isDownloading = false;
                      });
                    }
                  }
                },
                onRemindLater: () async {
                  final navigator = Navigator.of(routeContext);
                  try {
                    await _updateService.deferUpdate();
                    if (mounted) {
                      navigator.pop();
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

  final _screens = const [
    DashboardScreen(),
    CollectionScreen(),
    RuleStudioScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark_rounded),
            label: 'Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Rule Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
