import 'package:flutter/material.dart';

class AppSnackBar {
  /// Shows a SnackBar after clearing any active/queued snackbars,
  /// ensuring the newest notification displays immediately and restarts its timer.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    SnackBar snackBar,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    return messenger.showSnackBar(snackBar);
  }
}

extension AppSnackBarExtension on BuildContext {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
    SnackBar snackBar,
  ) {
    return AppSnackBar.show(this, snackBar);
  }
}
