import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/hive_boxes.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import 'quota_provider.dart';
import 'rule_provider.dart';
import 'series_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService.instance;
});

class ProfileState {
  final Profile activeProfile;
  final List<Profile> allProfiles;

  const ProfileState({
    required this.activeProfile,
    required this.allProfiles,
  });

  ProfileState copyWith({
    Profile? activeProfile,
    List<Profile>? allProfiles,
  }) {
    return ProfileState(
      activeProfile: activeProfile ?? this.activeProfile,
      allProfiles: allProfiles ?? this.allProfiles,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  final ProfileService _service;

  ProfileNotifier(this._ref, this._service)
      : super(ProfileState(
          activeProfile: _service.activeProfile,
          allProfiles: _service.getAllProfiles(),
        )) {
    _service.profilesListNotifier.addListener(_syncFromService);
    _service.activeProfileNotifier.addListener(_syncFromService);
  }

  void _syncFromService() {
    state = ProfileState(
      activeProfile: _service.activeProfile,
      allProfiles: _service.getAllProfiles(),
    );
  }

  /// Switches workspace profile, ensures boxes are opened, and triggers reload on all stores
  Future<void> switchProfile(String id) async {
    if (state.activeProfile.id == id) return;

    // 1. Ensure target boxes are pre-opened in Hive
    await HiveBoxes.preOpenBoxesForProfile(id);

    // 2. Perform switch in ProfileService
    await _service.switchProfile(id);

    // 3. Reload all Riverpod store notifiers for new workspace scoping
    _reloadStores();
  }

  /// Creates a new workspace profile, seeds defaults, and switches into it
  Future<Profile> createProfile({
    required String name,
    required ProfileType type,
    String? icon,
    CustomWorkspaceSchema? customSchema,
  }) async {
    final profile = await _service.createProfile(
      name: name,
      type: type,
      icon: icon,
      customSchema: customSchema,
      autoSwitch: true,
    );

    await HiveBoxes.preOpenBoxesForProfile(profile.id);
    _reloadStores();
    return profile;
  }

  /// Renames a workspace
  Future<void> renameProfile(String id, String newName) async {
    await _service.renameProfile(id, newName);
  }

  /// Updates profile metadata
  Future<void> updateProfile(Profile profile) async {
    await _service.updateProfile(profile);
  }

  /// Deletes a workspace
  Future<bool> deleteProfile(String id) async {
    final success = await _service.deleteProfile(id);
    if (success) {
      final activeId = _service.activeProfileId;
      await HiveBoxes.preOpenBoxesForProfile(activeId);
      _reloadStores();
    }
    return success;
  }

  void _reloadStores() {
    try {
      _ref.read(seriesNotifierProvider.notifier).load();
      _ref.read(volumesNotifierProvider.notifier).load();
      _ref.read(transactionsNotifierProvider.notifier).load();
      _ref.read(ruleConfigNotifierProvider.notifier).load();
      _ref.read(rulesNotifierProvider.notifier).load();
      debugPrint('[ProfileNotifier] Successfully reloaded all stores for active workspace.');
    } catch (e) {
      debugPrint('[ProfileNotifier] Error reloading stores on profile switch: $e');
    }
  }

  @override
  void dispose() {
    _service.profilesListNotifier.removeListener(_syncFromService);
    _service.activeProfileNotifier.removeListener(_syncFromService);
    super.dispose();
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref, ref.watch(profileServiceProvider));
});
