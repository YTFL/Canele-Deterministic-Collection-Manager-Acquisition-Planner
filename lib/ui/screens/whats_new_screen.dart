import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../services/update_service.dart';

class WhatsNewScreen extends StatefulWidget {
  const WhatsNewScreen({super.key});

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  late final Future<String> _releaseNotesFuture;

  @override
  void initState() {
    super.initState();
    _releaseNotesFuture = _loadReleaseNotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's New"),
      ),
      body: FutureBuilder<String>(
        future: _releaseNotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load release notes for this version.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Markdown(
            data: snapshot.data!,
            selectable: true,
            softLineBreak: true,
            padding: const EdgeInsets.all(16),
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
              ),
              h1: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
              ),
              h2: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
              ),
              h3: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
              ),
              listBullet: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                fontWeight: FontWeight.bold,
              ),
              code: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: isDark ? AppColors.darkPastryCardElevated : AppColors.warmPastryCrust,
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                    width: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadReleaseNotes() async {
    try {
      final markdown = await rootBundle.loadString('RELEASE_NOTES.md');
      return UpdateService.sanitizeReleaseNotes(markdown);
    } catch (e) {
      return '';
    }
  }
}
