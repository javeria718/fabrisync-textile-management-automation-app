import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:fabri_sync/Model/orderModel.dart';

class NewOrderGlassCard extends StatelessWidget {
  const NewOrderGlassCard({super.key, required this.child, this.minHeight});

  final Widget child;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight ?? 0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            // ignore: deprecated_member_use
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 30,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66FFFFFF), Color(0x33E0EFFF)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.analytics, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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

class DepartmentEstimateList extends StatelessWidget {
  const DepartmentEstimateList({super.key, required this.estimatedDeptHours});

  final Map<String, double> estimatedDeptHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Department-wise Estimated Time",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...estimatedDeptHours.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${(e.value / 8).ceil()} days (${e.value.round()} hrs)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
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
              color: Colors.white,
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
      color: Colors.white.withOpacity(0.7),
      fontSize: fontSize,
    );

    final defaultValueStyle = TextStyle(
      color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x66FFFFFF), Color(0x33E0EFFF)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white70, fontSize: titleFont),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
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
