import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:fabri_sync/Model/orderModel.dart';
import 'package:fabri_sync/utils/customcolors.dart';

class NewOrderGlassCard extends StatelessWidget {
  const NewOrderGlassCard({super.key, required this.child, this.minHeight});

  final Widget child;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.surface(radius: 24),
      child: child,
    );
  }
}

class OrderInputCard extends StatelessWidget {
  const OrderInputCard({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.softPanel(),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: AppColors.primaryText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.secondaryText),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: AppDecorations.accentFill(AppColors.accentBlue),
            child: Icon(icon, color: AppColors.accentBlue),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class EstimateCard extends StatelessWidget {
  const EstimateCard({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
    required this.isCardTapped,
    this.subtitle,
    this.height,
    this.minHeight,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isCardTapped;
  final String? subtitle;
  final double? height;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final accent = title.toLowerCase().contains('cost')
        ? AppColors.accentOrange
        : AppColors.primaryAccent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: height != null ? (isCardTapped ? 120 : height) : null,
        constraints: minHeight != null
            ? BoxConstraints(minHeight: isCardTapped ? 120 : minHeight!)
            : null,
        padding: const EdgeInsets.all(18),
        decoration: AppDecorations.surface(radius: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: accent.withOpacity(0.14),
              child: Icon(Icons.analytics, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderSummaryDetails extends StatelessWidget {
  const OrderSummaryDetails({
    super.key,
    required this.order,
    required this.rowFont,
  });

  final OrderModel order;
  final double rowFont;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          OrderSummaryRow(
            label: "Order ID",
            value: order.orderId,
            fontSize: rowFont,
          ),
          OrderSummaryRow(
            label: "Department",
            value: order.currentDepartment,
            fontSize: rowFont,
          ),
          OrderSummaryRow(
            label: "Quantity",
            value: order.quantity.toString(),
            fontSize: rowFont,
          ),
          OrderSummaryRow(
            label: "Date",
            value: DateFormat("dd MMM yyyy").format(order.createdAt),
            fontSize: rowFont,
          ),
          OrderSummaryRow(
            label: "Time",
            value: DateFormat("hh:mm a").format(order.createdAt),
            fontSize: rowFont,
          ),
          OrderSummaryRow(
            label: "Status",
            value: order.status,
            fontSize: rowFont,
            valueStyle: const TextStyle(
              color: AppColors.primaryAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderSummaryRow extends StatelessWidget {
  const OrderSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.fontSize = 13,
    this.valueStyle,
  });

  final String label;
  final String value;
  final double fontSize;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: AppColors.secondaryText,
      fontSize: fontSize,
    );

    final defaultValueStyle = TextStyle(
      color: AppColors.primaryText,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: labelStyle, softWrap: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: valueStyle ?? defaultValueStyle,
                textAlign: TextAlign.right,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FrostedGradientCard extends StatelessWidget {
  const FrostedGradientCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.titleFont,
    required this.valueFont,
    required this.avatarRadius,
    required this.iconSize,
  });

  final String title;
  final String value;
  final IconData icon;
  final double titleFont;
  final double valueFont;
  final double avatarRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final accent = title.toLowerCase().contains('cost')
        ? AppColors.accentOrange
        : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: accent.withOpacity(0.14),
            child: Icon(icon, color: accent, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: titleFont,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: valueFont,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStepCard extends StatelessWidget {
  const OrderStepCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.surface(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: AppDecorations.accentFill(AppColors.primaryAccent),
                child: Icon(icon, color: AppColors.primaryAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class OrderFieldWrap extends StatelessWidget {
  const OrderFieldWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 720;
        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class OrderTextInputField extends StatelessWidget {
  const OrderTextInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.primaryText),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.secondaryText),
      ),
    );
  }
}

class OrderDropdownField extends StatelessWidget {
  const OrderDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.primaryText),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class OrderPickerField extends StatelessWidget {
  const OrderPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.secondaryText),
        ),
        child: Text(
          value,
          style: const TextStyle(color: AppColors.primaryText),
        ),
      ),
    );
  }
}

class OrderSwitchField extends StatelessWidget {
  const OrderSwitchField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: AppDecorations.softPanel(radius: 14),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.softPanel(radius: 14),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.secondaryText),
      ),
    );
  }
}

class OrderWizardShell extends StatelessWidget {
  const OrderWizardShell({
    super.key,
    required this.stepLabel,
    required this.children,
  });

  final String stepLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : 14,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      stepLabel,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderActionBar extends StatelessWidget {
  const OrderActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surface(radius: 18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.end,
        children: children,
      ),
    );
  }
}
