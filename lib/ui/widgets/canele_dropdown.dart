import 'package:flutter/material.dart';

/// A themed dropdown that matches the Canel\u00e9 app input style.
/// Wraps [DropdownButtonFormField] with [menuMaxHeight] for scrollability.
class CaneleDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final Widget? prefixIcon;
  final String? label;
  final String? Function(T?)? validator;

  const CaneleDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.prefixIcon,
    this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      menuMaxHeight: 300,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
      ),
      hint: hint != null ? Text(hint!) : null,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
