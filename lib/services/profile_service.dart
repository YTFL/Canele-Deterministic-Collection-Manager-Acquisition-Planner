import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/database/database_migrator.dart';
import '../core/database/hive_boxes.dart';
import '../models/profile.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  static ProfileService get instance => _instance;

  factory ProfileService() => _instance;

  ProfileService._internal();

  static const String profilesBoxName = 'profiles_box';
  static const String appStateBoxName = 'app_state_box';
  static const String activeProfileKey = 'active_profile_id';
  static const String defaultBooksProfileId = 'profile_default_books';

  Box<Map>? _profilesBox;
  Box<dynamic>? _appStateBox;

  final ValueNotifier<String> activeProfileNotifier = ValueNotifier<String>(defaultBooksProfileId);
  final ValueNotifier<List<Profile>> profilesListNotifier = ValueNotifier<List<Profile>>([]);

  Box<Map> get profilesBox => _profilesBox!;
  Box<dynamic> get appStateBox => _appStateBox!;

  String get activeProfileId => activeProfileNotifier.value;

  Profile get activeProfile {
    final list = profilesListNotifier.value;
    return list.firstWhere(
      (p) => p.id == activeProfileId,
      orElse: () => list.isNotEmpty
          ? list.first
          : Profile(
              id: defaultBooksProfileId,
              name: 'Books & Manga',
              type: ProfileType.books,
              icon: 'book',
              createdAt: DateTime.now(),
            ),
    );
  }

  /// Initializes profile boxes, seeds default profile if empty,
  /// performs legacy migration, and resolves active profile.
  Future<void> init() async {
    _profilesBox = await Hive.openBox<Map>(profilesBoxName);
    _appStateBox = await Hive.openBox<dynamic>(appStateBoxName);

    // Check if profiles are empty
    if (_profilesBox!.isEmpty) {
      debugPrint('[ProfileService] No profiles found. Initializing default books workspace.');
      final defaultProfile = Profile(
        id: defaultBooksProfileId,
        name: 'Books & Manga',
        type: ProfileType.books,
        icon: 'book',
        createdAt: DateTime.now(),
      );
      await _profilesBox!.put(defaultProfile.id, defaultProfile.toMap());
      await _appStateBox!.put(activeProfileKey, defaultBooksProfileId);
    }

    // Determine active profile
    String? storedActiveId = _appStateBox!.get(activeProfileKey) as String?;
    if (storedActiveId == null || !_profilesBox!.containsKey(storedActiveId)) {
      storedActiveId = _profilesBox!.keys.first.toString();
      await _appStateBox!.put(activeProfileKey, storedActiveId);
    }

    _refreshNotifiers(storedActiveId);

    // Pre-open boxes for the default/target profile before running migration
    await HiveBoxes.preOpenBoxesForProfile(defaultBooksProfileId);

    // Perform migration of legacy un-scoped boxes if needed
    await DatabaseMigrator.migrateLegacyBoxesIfNeeded(defaultBooksProfileId);
  }

  void _refreshNotifiers([String? newActiveId]) {
    final list = _profilesBox!.values
        .map((m) => Profile.fromMap(m))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    profilesListNotifier.value = list;

    final targetId = newActiveId ?? activeProfileNotifier.value;
    if (list.any((p) => p.id == targetId)) {
      activeProfileNotifier.value = targetId;
    } else if (list.isNotEmpty) {
      activeProfileNotifier.value = list.first.id;
    }
  }

  List<Profile> getAllProfiles() {
    return List<Profile>.from(profilesListNotifier.value);
  }

  Profile? getProfileById(String id) {
    final map = _profilesBox?.get(id);
    if (map == null) return null;
    return Profile.fromMap(map);
  }

  /// Switches active workspace profile and notifies listeners
  Future<void> switchProfile(String id) async {
    if (!_profilesBox!.containsKey(id)) {
      throw ArgumentError('Profile with ID $id does not exist');
    }
    await HiveBoxes.preOpenBoxesForProfile(id);

    if (activeProfileId == id) return;

    await _appStateBox!.put(activeProfileKey, id);
    activeProfileNotifier.value = id;
    _refreshNotifiers(id);
    debugPrint('[ProfileService] Switched active profile to: $id (${activeProfile.name})');
  }

  /// Creates a new workspace profile and automatically switches to it
  Future<Profile> createProfile({
    required String name,
    required ProfileType type,
    String? icon,
    CustomWorkspaceSchema? customSchema,
    bool autoSwitch = true,
  }) async {
    final cleanName = name.trim().isEmpty
        ? (type == ProfileType.books
            ? 'Books & Manga'
            : (type == ProfileType.games ? 'Game Backlog' : 'My Collection'))
        : name.trim();

    final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final effectiveIcon = icon ?? (type == ProfileType.games ? 'gamepad' : (type == ProfileType.books ? 'book' : 'layers'));

    final newProfile = Profile(
      id: id,
      name: cleanName,
      type: type,
      icon: effectiveIcon,
      createdAt: DateTime.now(),
      customSchema: customSchema,
    );

    await _profilesBox!.put(newProfile.id, newProfile.toMap());

    // Pre-open all scoped boxes and seed default RuleConfig for this profile
    await HiveBoxes.preOpenBoxesForProfile(id);

    _refreshNotifiers(autoSwitch ? id : null);

    if (autoSwitch) {
      await switchProfile(id);
    }

    return newProfile;
  }

  /// Renames an existing workspace
  Future<void> renameProfile(String id, String newName) async {
    final existing = getProfileById(id);
    if (existing == null) return;

    final updated = existing.copyWith(name: newName.trim());
    await _profilesBox!.put(id, updated.toMap());
    _refreshNotifiers();
  }

  /// Updates profile metadata (name, icon, schema)
  Future<void> updateProfile(Profile profile) async {
    await _profilesBox!.put(profile.id, profile.toMap());
    _refreshNotifiers();
  }

  /// Deletes a workspace profile along with all its scoped Hive data boxes
  Future<bool> deleteProfile(String id) async {
    final all = getAllProfiles();
    if (all.length <= 1) {
      // Cannot delete the only workspace
      return false;
    }

    // Delete profile entry
    await _profilesBox!.delete(id);

    // Delete scoped boxes if opened
    final boxNames = [
      '${id}_series',
      '${id}_volumes',
      '${id}_transactions',
      '${id}_rules',
      '${id}_rule_config',
      '${id}_cadence',
    ];

    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box<Map>(boxName);
          await box.clear();
          await box.close();
        }
        await Hive.deleteBoxFromDisk(boxName);
      } catch (e) {
        debugPrint('[ProfileService] Error deleting scoped box $boxName: $e');
      }
    }

    // If active profile was deleted, switch to the first remaining profile
    if (activeProfileId == id) {
      final remaining = getAllProfiles();
      final nextId = remaining.first.id;
      await _appStateBox!.put(activeProfileKey, nextId);
      activeProfileNotifier.value = nextId;
      _refreshNotifiers(nextId);
    } else {
      _refreshNotifiers();
    }

    return true;
  }
}
