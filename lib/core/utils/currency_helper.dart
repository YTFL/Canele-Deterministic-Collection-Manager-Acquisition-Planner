import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../../services/exchange_rate_service.dart';

class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final int decimalDigits;
  final double symbolScale;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
    this.symbolScale = 1.0,
  });

  /// Returns the optimal font size for this currency's symbol given a base font size.
  /// Automatically scales multi-character symbols (e.g. CA$) so they fit containers seamlessly.
  double fontSizeFor(double baseFontSize) {
    if (symbolScale != 1.0) return baseFontSize * symbolScale;
    if (symbol.length >= 3) return baseFontSize * 0.70;
    if (symbol.length == 2) return baseFontSize * 0.85;
    return baseFontSize;
  }
}

class CurrencyHelper {
  /// Standard default volume price across Canele
  static const double defaultVolumePrice = 14.99;

  /// Standard default volume currency (USD)
  static const String defaultVolumeCurrency = 'USD';

  static const List<CurrencyOption> supportedCurrencies = [
    CurrencyOption(
      code: 'CAD',
      symbol: r'CA$',
      name: 'Canadian Dollar (CAD)',
      decimalDigits: 2,
      symbolScale: 0.70,
    ),
    CurrencyOption(
      code: 'USD',
      symbol: r'$',
      name: 'US Dollar (USD)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound (GBP)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee (INR)',
      decimalDigits: 2,
      symbolScale: 1.0,
    ),
    CurrencyOption(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen (JPY)',
      decimalDigits: 0,
      symbolScale: 1.0,
    ),
  ];

  static CurrencyOption getOption(String? code) {
    if (code == null || code.isEmpty) {
      return supportedCurrencies.firstWhere((c) => c.code == 'USD');
    }
    final upper = code.toUpperCase().trim();
    return supportedCurrencies.firstWhere(
      (c) => c.code == upper || (upper == 'YEN' && c.code == 'JPY') || (upper == 'POUND' && c.code == 'GBP'),
      orElse: () => supportedCurrencies.firstWhere((c) => c.code == 'USD'),
    );
  }

  static String getSymbol(String? code) {
    return getOption(code).symbol;
  }

  static double getSymbolFontSize(String? code, double baseSize) {
    return getOption(code).fontSizeFor(baseSize);
  }

  static String format(double amount, {String? currencyCode}) {
    final option = getOption(currencyCode);

    if (option.code == 'INR') {
      // Indian numbering format (e.g. ₹1,23,456.00 or ₹499.00)
      final format = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
      );
      return format.format(amount);
    } else if (option.code == 'JPY') {
      // Japanese Yen has no fractional subunit
      final format = NumberFormat.currency(
        locale: 'ja_JP',
        symbol: '¥',
        decimalDigits: 0,
      );
      return format.format(amount.roundToDouble());
    } else if (option.code == 'GBP') {
      final format = NumberFormat.currency(
        locale: 'en_GB',
        symbol: '£',
        decimalDigits: 2,
      );
      return format.format(amount);
    } else if (option.code == 'CAD') {
      final format = NumberFormat.currency(
        locale: 'en_CA',
        symbol: r'CA$',
        decimalDigits: 2,
      );
      return format.format(amount);
    } else {
      // Default USD
      final format = NumberFormat.currency(
        locale: 'en_US',
        symbol: r'$',
        decimalDigits: 2,
      );
      return format.format(amount);
    }
  }

  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    ExchangeRates? rates,
  }) {
    final activeRates = rates ?? ExchangeRateService.loadFromStorage();
    return activeRates.convert(amount: amount, from: fromCurrency, to: toCurrency);
  }

  static String? detectCurrency(dynamic input) {
    if (input == null) return null;
    final str = input.toString().trim();
    if (str.contains('CA\$') || str.contains('CAD')) return 'CAD';
    if (str.contains('£') || str.contains('GBP')) return 'GBP';
    if (str.contains('₹') || str.contains('INR') || str.contains('Rs')) return 'INR';
    if (str.contains('¥') || str.contains('JPY') || str.contains('YEN')) return 'JPY';
    if (str.contains(r'$') || str.contains('USD')) return 'USD';
    return null;
  }

  static double parsePrice(dynamic input) {
    if (input == null) return 0.0;
    if (input is num) return input.toDouble();

    String str = input.toString().trim();
    if (str.isEmpty) return 0.0;

    // Remove known currency symbols and labels
    str = str
        .replaceAll(r'CA$', '')
        .replaceAll(r'CAD', '')
        .replaceAll(r'USD', '')
        .replaceAll(r'GBP', '')
        .replaceAll(r'INR', '')
        .replaceAll(r'JPY', '')
        .replaceAll(r'YEN', '')
        .replaceAll(r'$', '')
        .replaceAll('£', '')
        .replaceAll('₹', '')
        .replaceAll('¥', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .trim();

    // Remove any commas
    str = str.replaceAll(',', '').trim();

    return double.tryParse(str) ?? 0.0;
  }
}

/// A standardized reusable avatar/badge for displaying currency symbols throughout the app
class CurrencySymbolBox extends StatelessWidget {
  final String currencyCode;
  final double size;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;
  final double? baseFontSize;
  final BorderRadius? borderRadius;

  const CurrencySymbolBox({
    super.key,
    required this.currencyCode,
    this.size = 40,
    this.isSelected = false,
    this.backgroundColor,
    this.textColor,
    this.baseFontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final option = CurrencyHelper.getOption(currencyCode);
    final effectiveBaseFontSize = baseFontSize ?? (size * 0.44);
    final scaledFontSize = option.fontSizeFor(effectiveBaseFontSize);

    final defaultBg = isSelected
        ? AppColors.caramelizedAmber
        : (isDark ? AppColors.darkPastryBorder : AppColors.warmPastryCrust);
    final defaultTextColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.08),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.2),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          option.symbol,
          style: TextStyle(
            fontSize: scaledFontSize,
            fontWeight: FontWeight.w800,
            color: textColor ?? defaultTextColor,
          ),
        ),
      ),
    );
  }
}

/// A standardized text widget for currency symbols (used in input prefixes, inline badges, etc.)
class CurrencySymbolText extends StatelessWidget {
  final String currencyCode;
  final double baseFontSize;
  final FontWeight fontWeight;
  final Color? color;

  const CurrencySymbolText({
    super.key,
    required this.currencyCode,
    this.baseFontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final option = CurrencyHelper.getOption(currencyCode);
    final effectiveFontSize = option.fontSizeFor(baseFontSize);

    return Text(
      option.symbol,
      style: TextStyle(
        fontSize: effectiveFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

/// A standardized DropdownFormField for currency selection that matches InputDecoration height and styling
class CurrencyDropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const CurrencyDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.caramelizedAmber),
      items: CurrencyHelper.supportedCurrencies.map((c) {
        return DropdownMenuItem<String>(
          value: c.code,
          child: Text(
            '${c.code} (${c.symbol})',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

