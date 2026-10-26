import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class ExternalLinkHelper {
  static const _channel = MethodChannel('com.ytfl.canale/update');

  /// Direct URL to GitHub bug report issue template
  static const String bugReportUrl =
      'https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues/new?template=bug_report.yml';

  /// Direct URL to GitHub feature request issue template
  static const String featureRequestUrl =
      'https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues/new?template=feature_request.yml';

  /// Direct URL to GitHub documentation issue template
  static const String documentationUrl =
      'https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues/new?template=documentation.yml';

  /// Direct URL to GitHub repository issues board
  static const String githubIssuesUrl =
      'https://github.com/YTFL/Canele-Deterministic-Collection-Manager-Acquisition-Planner/issues';

  /// Opens [url] in the default web browser via native Android Intent.
  /// Falls back to copying the link to clipboard if opening fails or on non-Android platforms.
  static Future<bool> openUrl(BuildContext context, String url) async {
    bool opened = false;
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('openUrl', {'url': url});
        opened = result == true;
      }
    } catch (e) {
      debugPrint('[ExternalLinkHelper] Error opening URL: $e');
    }

    if (!opened && context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not open browser. Link copied to clipboard:\n$url'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
    }
    return opened;
  }

  /// Copies [url] to the clipboard and shows feedback.
  static Future<void> copyUrl(BuildContext context, String url, {String? label}) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${label ?? "Link"} copied to clipboard!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Displays a modal bottom sheet presenting direct links, descriptions, and action buttons.
  static Future<void> showFeedbackOptionsSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPastryCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback & Issue Reporting',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Direct links to GitHub issue templates',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTemplateCard(
                        context: ctx,
                        theme: theme,
                        icon: Icons.bug_report_outlined,
                        title: 'Report a Bug',
                        description:
                            'Report unexpected behavior, crashes, or visual glitches. Includes fields for Android version and reproduction steps.',
                        url: bugReportUrl,
                        tag: 'bug_report.yml',
                        color: AppColors.statusDanger,
                      ),
                      const SizedBox(height: 12),
                      _buildTemplateCard(
                        context: ctx,
                        theme: theme,
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Request a Feature',
                        description:
                            'Propose new features, rule studio conditions, workspace options, or general workflow improvements.',
                        url: featureRequestUrl,
                        tag: 'feature_request.yml',
                        color: AppColors.caramelizedAmber,
                      ),
                      const SizedBox(height: 12),
                      _buildTemplateCard(
                        context: ctx,
                        theme: theme,
                        icon: Icons.description_outlined,
                        title: 'Documentation & Guides',
                        description:
                            'Suggest documentation updates, architecture guides, or report inaccuracies in README and technical docs.',
                        url: documentationUrl,
                        tag: 'documentation.yml',
                        color: AppColors.statusInfo,
                      ),
                      const SizedBox(height: 12),
                      _buildTemplateCard(
                        context: ctx,
                        theme: theme,
                        icon: Icons.view_list_rounded,
                        title: 'All GitHub Issues',
                        description: 'Browse all open issues, roadmaps, and community discussions.',
                        url: githubIssuesUrl,
                        tag: 'issues',
                        color: isDark ? AppColors.darkTextMuted : AppColors.pastryCrustBorder,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildTemplateCard({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required String url,
    required String tag,
    required Color color,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCardElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          // Direct Link display box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              url,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => copyUrl(context, url, label: title),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Copy Link'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => openUrl(context, url),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Open'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
