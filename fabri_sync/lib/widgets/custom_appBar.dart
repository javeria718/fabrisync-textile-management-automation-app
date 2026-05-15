import 'package:fabri_sync/main.dart';
import 'package:fabri_sync/utils/customcolors.dart';
import 'package:flutter/material.dart';

AppBar buildGradientAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
      onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
    ),
    actions: actions,
    title: const SizedBox.shrink(),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      alignment: Alignment.center,
      child: SafeArea(
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    ),
  );
}
