import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool frostedStyle;

  const CustomTextFormField({
    super.key,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.obscureText = false,
    this.controller,
    this.focusNode,
    this.validator,
    this.suffix,
    this.onChanged,
    this.frostedStyle = false,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool isFocused = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscureText = widget.obscureText;
  }

  void _handleFocusChange() {
    setState(() {
      isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(covariant CustomTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
      isFocused = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final fillColor = widget.frostedStyle
        ? (isFocused ? AppColors.surface : AppColors.surfaceMuted)
        : AppColors.surface;
    final iconColor = isFocused
        ? AppColors.primaryAccent
        : AppColors.secondaryText;
    final borderColor = isFocused
        ? AppColors.primaryAccent
        : AppColors.border;

    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText ? _obscureText : false,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: const TextStyle(
        color: AppColors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: AppColors.primaryAccent,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        prefixIcon: Icon(widget.icon, color: iconColor),
        suffixIcon:
            widget.suffix ??
            (widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  )
                : null),
        filled: true,
        fillColor: fillColor,
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryAccent,
        ),
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: AppColors.customRedColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: AppColors.customRedColor,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class FrostedDropdown extends StatefulWidget {
  final String? value;
  final String label;
  final String hintText;
  final IconData icon;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const FrostedDropdown({
    required this.value,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.onChanged,
    super.key,
  });

  @override
  State<FrostedDropdown> createState() => _FrostedDropdownState();
}

class _FrostedDropdownState extends State<FrostedDropdown> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final fillColor = hasFocus ? AppColors.surface : AppColors.surfaceMuted;
    final iconColor = hasFocus
        ? AppColors.primaryAccent
        : AppColors.secondaryText;
    final borderColor = hasFocus
        ? AppColors.primaryAccent
        : AppColors.border;

    return DropdownButtonFormField<String>(
      focusNode: _focusNode,
      value: widget.value,
      isExpanded: true,
      selectedItemBuilder: (context) {
        return widget.items.map((item) {
          final text = (item.child is Text)
              ? (item.child as Text).data ?? ''
              : (item.value ?? '');
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        }).toList();
      },
      style: const TextStyle(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      dropdownColor: AppColors.surface,
      iconEnabledColor: iconColor,
      hint: Text(
        widget.hintText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      items: widget.items.map((item) {
        return DropdownMenuItem<String>(
          value: item.value,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            child: item.child,
          ),
        );
      }).toList(),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        prefixIcon: Icon(widget.icon, color: iconColor),
        filled: true,
        fillColor: fillColor,
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryText,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryAccent,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
      ),
    );
  }
}
