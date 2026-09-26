import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile.dart';
import '../../services/profile_service.dart';

void showEditCustomSchemaSheet(BuildContext context, Profile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditCustomSchemaSheet(profile: profile),
  );
}

class EditCustomSchemaSheet extends StatefulWidget {
  final Profile profile;

  const EditCustomSchemaSheet({super.key, required this.profile});

  @override
  State<EditCustomSchemaSheet> createState() => _EditCustomSchemaSheetState();
}

class _EditCustomSchemaSheetState extends State<EditCustomSchemaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _itemLabelController;
  late final TextEditingController _groupLabelController;

  late Map<String, bool> _enabledFields;
  late List<String> _statuses;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final schema = p.customSchema ?? const CustomWorkspaceSchema();

    _nameController = TextEditingController(text: p.name);
    _itemLabelController = TextEditingController(text: schema.itemLabel);
    _groupLabelController = TextEditingController(text: schema.groupLabel);

    _enabledFields = Map<String, bool>.from(schema.enabledFields);
    _statuses = List<String>.from(schema.customStatuses);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemLabelController.dispose();
    _groupLabelController.dispose();
    super.dispose();
  }

  Future<void> _saveSchema() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedSchema = CustomWorkspaceSchema(
      itemLabel: _itemLabelController.text.trim().isEmpty ? 'Item' : _itemLabelController.text.trim(),
      groupLabel: _groupLabelController.text.trim().isEmpty ? 'Group' : _groupLabelController.text.trim(),
      enabledFields: _enabledFields,
      customStatuses: _statuses.isEmpty ? const ['backlog', 'inProgress', 'completed'] : _statuses,
    );

    final updatedProfile = widget.profile.copyWith(
      name: _nameController.text.trim().isEmpty ? widget.profile.name : _nameController.text.trim(),
      customSchema: updatedSchema,
    );

    await ProfileService.instance.updateProfile(updatedProfile);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${updatedProfile.name}" schema!'),
          backgroundColor: AppColors.caramelizedAmber,
        ),
      );
    }
  }

  Widget _buildFieldSwitch({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isEnabled = _enabledFields[key] ?? false;

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: isEnabled ? AppColors.caramelizedAmber : AppColors.deepCaramelMuted),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: isEnabled,
      activeTrackColor: AppColors.caramelizedAmber,
      onChanged: (val) {
        setState(() {
          _enabledFields[key] = val;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCard : theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workspace Schema',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customize terminology & toggle collection fields',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Settings Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workspace Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Workspace Name',
                        hintText: 'e.g. Vinyl Records, Retro Handhelds',
                        prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Terminology Section
                    Text(
                      'Terminology',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.caramelizedAmber,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Item Label',
                              hintText: 'e.g. Vinyl, Figure, Issue',
                              prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter item label' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _groupLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Group Label',
                              hintText: 'e.g. Artist, Brand, Publisher',
                              prefixIcon: Icon(Icons.folder_outlined, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Schema Field Toggles
                    Text(
                      'Enabled Data Fields',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.caramelizedAmber,
                      ),
                    ),
                    const SizedBox(height: 4),

                    _buildFieldSwitch(
                      key: 'coverUrl',
                      title: 'Cover Image Artwork',
                      subtitle: 'Store and display poster or photo art',
                      icon: Icons.image_outlined,
                    ),
                    _buildFieldSwitch(
                      key: 'price',
                      title: 'Price & Currency',
                      subtitle: 'Track acquisition cost and financial totals',
                      icon: Icons.payments_outlined,
                    ),
                    _buildFieldSwitch(
                      key: 'releaseDate',
                      title: 'Release Date',
                      subtitle: 'Track production year or launch dates',
                      icon: Icons.calendar_today_outlined,
                    ),
                    _buildFieldSwitch(
                      key: 'edition',
                      title: 'Edition & Subtype',
                      subtitle: 'Track variations, printings, or pressings',
                      icon: Icons.stars_outlined,
                    ),
                    _buildFieldSwitch(
                      key: 'platform',
                      title: 'Category / Format',
                      subtitle: 'e.g. 12" Vinyl, Box Set, Hardcover',
                      icon: Icons.category_outlined,
                    ),
                    _buildFieldSwitch(
                      key: 'rating',
                      title: 'Score & Rating',
                      subtitle: 'Record personal rating from 1 to 10',
                      icon: Icons.star_outline_rounded,
                    ),
                    _buildFieldSwitch(
                      key: 'notes',
                      title: 'Notes & Thoughts',
                      subtitle: 'Custom writeups, memories, and details',
                      icon: Icons.edit_note_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('save_schema_button'),
                onPressed: _saveSchema,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.caramelizedAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Schema Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
