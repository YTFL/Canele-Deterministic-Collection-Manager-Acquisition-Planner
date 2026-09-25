import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile.dart';

class AddWorkspaceDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required ProfileType type,
    String? icon,
    CustomWorkspaceSchema? customSchema,
  }) onCreate;

  const AddWorkspaceDialog({super.key, required this.onCreate});

  static Future<void> show({
    required BuildContext context,
    required Future<void> Function({
      required String name,
      required ProfileType type,
      String? icon,
      CustomWorkspaceSchema? customSchema,
    }) onCreate,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddWorkspaceDialog(onCreate: onCreate),
    );
  }

  @override
  State<AddWorkspaceDialog> createState() => _AddWorkspaceDialogState();
}

class _AddWorkspaceDialogState extends State<AddWorkspaceDialog> {
  int _currentStep = 0; // 0: Preset, 1: Name, 2: Icon
  ProfileType _selectedType = ProfileType.books;
  late final TextEditingController _nameController;
  String _selectedIcon = 'book';
  bool _isCreating = false;

  final List<Map<String, dynamic>> _iconChoices = const [
    {'name': 'book', 'icon': Icons.auto_stories_rounded, 'label': 'Book'},
    {'name': 'gamepad', 'icon': Icons.sports_esports_rounded, 'label': 'Gamepad'},
    {'name': 'layers', 'icon': Icons.layers_rounded, 'label': 'Layers'},
    {'name': 'music', 'icon': Icons.album_rounded, 'label': 'Music'},
    {'name': 'movie', 'icon': Icons.movie_filter_rounded, 'label': 'Movies'},
    {'name': 'stars', 'icon': Icons.auto_awesome_rounded, 'label': 'Stars'},
    {'name': 'bookmark', 'icon': Icons.bookmark_rounded, 'label': 'Bookmark'},
    {'name': 'collection', 'icon': Icons.collections_bookmark_rounded, 'label': 'Collection'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Books & Manga');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSelectPreset(ProfileType type) {
    setState(() {
      _selectedType = type;
      switch (type) {
        case ProfileType.books:
          _nameController.text = 'Books & Manga';
          _selectedIcon = 'book';
          break;
        case ProfileType.games:
          _nameController.text = 'Game Backlog';
          _selectedIcon = 'gamepad';
          break;
        case ProfileType.custom:
          _nameController.text = 'My Collection';
          _selectedIcon = 'layers';
          break;
      }
      _currentStep = 1;
    });
  }

  Future<void> _handleFinish() async {
    final name = _nameController.text.trim().isEmpty
        ? (_selectedType == ProfileType.books
            ? 'Books & Manga'
            : (_selectedType == ProfileType.games ? 'Game Backlog' : 'My Collection'))
        : _nameController.text.trim();

    setState(() => _isCreating = true);

    try {
      await widget.onCreate(
        name: name,
        type: _selectedType,
        icon: _selectedIcon,
        customSchema: _selectedType == ProfileType.custom
            ? const CustomWorkspaceSchema()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create workspace: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkPastryCard : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Step Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Create Workspace',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.caramelizedAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                valueColor: const AlwaysStoppedAnimation(AppColors.caramelizedAmber),
                borderRadius: BorderRadius.circular(2),
                minHeight: 3,
              ),
              const SizedBox(height: 18),

              // Step 1: Preset Choice
              if (_currentStep == 0) ...[
                Text(
                  'Choose a Workspace Preset',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildPresetCard(
                  type: ProfileType.books,
                  title: 'Books & Manga',
                  description: 'Track volumes, spine view, book acquisition rules, and cadence.',
                  icon: Icons.auto_stories_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildPresetCard(
                  type: ProfileType.games,
                  title: 'Video Games',
                  description: 'Game backlog, cover art grid view, platforms, and completion states.',
                  icon: Icons.sports_esports_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildPresetCard(
                  type: ProfileType.custom,
                  title: 'Custom Workspace',
                  description: 'Dynamic schema with custom terminology and toggleable metadata fields.',
                  icon: Icons.layers_rounded,
                  isDark: isDark,
                ),
              ],

              // Step 2: Name Input
              if (_currentStep == 1) ...[
                Text(
                  'Name Your Workspace',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Provide a distinct name for this collection context.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('workspace_name_field'),
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Workspace Name',
                    hintText: 'e.g. Manga & Light Novels',
                    filled: true,
                    fillColor: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.caramelizedAmber,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ],

              // Step 3: Icon Selection
              if (_currentStep == 2) ...[
                Text(
                  'Pick an Accent Icon',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'This icon will appear on headers and the switcher badge.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _iconChoices.length,
                  itemBuilder: (ctx, idx) {
                    final item = _iconChoices[idx];
                    final isSelected = item['name'] == _selectedIcon;
                    return InkWell(
                      key: Key('icon_choice_${item['name']}'),
                      onTap: () => setState(() => _selectedIcon = item['name'] as String),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.caramelizedAmber
                              : (isDark
                                  ? AppColors.darkPastryCardElevated
                                  : AppColors.pastryCrustLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.caramelizedAmber
                                : (isDark
                                    ? AppColors.darkPastryBorder
                                    : AppColors.pastryCrustBorder),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.deepCaramel),
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isCreating
                        ? null
                        : () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                    child: Text(_currentStep > 0 ? 'Back' : 'Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_currentStep < 2)
                    ElevatedButton(
                      key: const Key('workspace_step_next_button'),
                      onPressed: () {
                        if (_currentStep == 0) {
                          _onSelectPreset(_selectedType);
                        } else {
                          setState(() => _currentStep++);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramelizedAmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      key: const Key('workspace_create_finish_button'),
                      onPressed: _isCreating ? null : _handleFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramelizedAmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Create & Open'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required ProfileType type,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      key: Key('preset_card_${type.name}'),
      onTap: () => _onSelectPreset(type),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.caramelizedAmber.withValues(alpha: 0.22)
                  : AppColors.warmPastryCrust.withValues(alpha: 0.55))
              : (isDark
                  ? AppColors.darkPastryCardElevated
                  : AppColors.pastryCrustLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.caramelizedAmber
                : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.caramelizedAmber
                    : (isDark ? AppColors.darkPastryBorder : AppColors.warmPastryCrust),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.caramelizedAmberLight
                        : AppColors.caramelizedAmber),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.deepCaramelMuted),
          ],
        ),
      ),
    );
  }
}
