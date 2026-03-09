import 'package:flutter/material.dart';
import 'package:fabri_sync/utils/customcolors.dart';

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

  /// ✅ NEW (optional): frosted glass style for login/signup
  /// When true:
  /// - Unfocused: translucent field on gradient
  /// - Focused: field turns white like reference image
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
    this.frostedStyle = false, // ✅ default safe
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
    // ✅ Modern radius
    final radius = BorderRadius.circular(14);

    // ✅ Frosted style colors (like image)
    final fillColor = widget.frostedStyle
        ? (isFocused
              ? Colors.white.withOpacity(0.92) // focus => white
              : Colors.white.withOpacity(0.10)) // unfocus => translucent
        : Colors.grey[100];

    final textColor = widget.frostedStyle
        ? (isFocused ? Colors.black87 : Colors.white.withOpacity(0.92))
        : Colors.black87;

    final iconColor = widget.frostedStyle
        ? (isFocused ? Colors.black54 : Colors.white.withOpacity(0.75))
        : Colors.grey;

    final borderColor = widget.frostedStyle
        ? (isFocused
              ? Colors.white.withOpacity(0.35)
              : Colors.white.withOpacity(0.18))
        : Colors.grey;

    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText ? _obscureText : false,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: widget.frostedStyle
          ? (isFocused ? Colors.black87 : Colors.white)
          : Colors.black87,
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

        // ✅ IMPORTANT: labelText + floating styles (label will NOT disappear)
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,

        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: widget.frostedStyle
              ? Colors.white.withOpacity(0.75)
              : Colors.grey,
        ),

        floatingLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: widget.frostedStyle
              ? (isFocused ? Colors.black87 : Colors.white.withOpacity(0.85))
              : Colors.black87,
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
// ------------------------

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

    // ✅ MATCH CustomTextFormField behavior
    final fillColor = hasFocus
        ? Colors.white.withOpacity(0.92) // focus => white
        : Colors.white.withOpacity(0.10); // unfocus => translucent

    final valueTextColor = hasFocus
        ? Colors.black87
        : Colors.white.withOpacity(0.92);
    final hintColor = hasFocus
        ? Colors.black45
        : Colors.white.withOpacity(0.60);

    final iconColor = hasFocus
        ? Colors.black54
        : Colors.white.withOpacity(0.75);

    final borderColor = hasFocus
        ? Colors.white.withOpacity(0.35)
        : Colors.white.withOpacity(0.18);

    return DropdownButtonFormField<String>(
      focusNode: _focusNode,
      value: widget.value,
      isExpanded: true,

      // ✅ IMPORTANT: Force selected text rendering (fixes ".."/blank)
      // And now it matches TextField: focus=>black, unfocus=>white
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
              style: TextStyle(
                color: valueTextColor,
                fontWeight: FontWeight.w600, // same as TextField
                fontSize: 14,
              ),
            ),
          );
        }).toList();
      },

      // field text style (fallback)
      style: TextStyle(
        color: valueTextColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),

      // ✅ menu background opaque to avoid blur
      dropdownColor: const Color(0xFF0B1220),

      iconEnabledColor: iconColor,

      hint: Text(
        widget.hintText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hintColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),

      items: widget.items.map((item) {
        return DropdownMenuItem<String>(
          value: item.value,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white, // menu items always crisp white
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

        // ✅ same label rules as CustomTextFormField
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: hasFocus ? Colors.black54 : Colors.white,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hasFocus ? Colors.black87 : Colors.white,
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
