import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_update_model.dart';

class UpdateFullScreen extends StatelessWidget {
  final AppUpdate update;
  final String currentVersion;
  final VoidCallback onInstallNow;
  final VoidCallback onRemindLater;
  final bool isDownloading;
  final double downloadProgress;

  const UpdateFullScreen({
    super.key,
    required this.update,
    required this.currentVersion,
    required this.onInstallNow,
    required this.onRemindLater,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('App Update Available'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _UpdateContent(update: update, currentVersion: currentVersion),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isDownloading
                ? _buildProgressBar(context, downloadProgress)
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRemindLater,
                          child: const Text('Remind Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onInstallNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Install Now'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    final percent = (progress * 100).clamp(0, 100).toInt();
    final textString = progress > 0 ? 'Downloading... $percent%' : 'Downloading...';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.darkPastryCardElevated
        : AppColors.pastryCrustLight;
    final progressColor = isDark
        ? AppColors.caramelizedAmberLight
        : AppColors.caramelizedAmber;
    final textOnBackground = isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel;
    final textOnProgress = isDark ? AppColors.deepCaramelBlack : Colors.white;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final filledWidth = totalWidth * progress.clamp(0.0, 1.0);

          return Stack(
            children: [
              // Background Layer Text
              SizedBox(
                width: totalWidth,
                height: 48,
                child: Center(
                  child: Text(
                    textString,
                    style: TextStyle(
                      color: textOnBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Progress fill layer with clipped text
              if (filledWidth > 0)
                ClipRect(
                  clipper: _ProgressClipper(filledWidth),
                  child: Container(
                    width: totalWidth,
                    height: 48,
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        textString,
                        style: TextStyle(
                          color: textOnProgress,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressClipper extends CustomClipper<Rect> {
  final double width;
  _ProgressClipper(this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(_ProgressClipper oldClipper) {
    return oldClipper.width != width;
  }
}

class _UpdateContent extends StatelessWidget {
  final AppUpdate update;
  final String currentVersion;

  const _UpdateContent({required this.update, required this.currentVersion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version is available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPastryCard : AppColors.warmPastryCrust.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Version',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentVersion,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                  size: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'New Version',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      update.version,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.statusSuccessDark : AppColors.caramelizedAmber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Divider(
            color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
            thickness: 1,
          ),
          const SizedBox(height: 14),
          Text(
            "What's New",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPastryCard : AppColors.pastryCrustLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                width: 1,
              ),
            ),
            child: MarkdownBody(
              data: update.changelog.isNotEmpty ? update.changelog : 'No release notes provided for this version.',
              selectable: true,
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                ),
                h1: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                ),
                h2: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                ),
                h3: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                ),
                listBullet: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                ),
                code: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: isDark ? AppColors.darkPastryCardElevated : AppColors.warmPastryCrust,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
