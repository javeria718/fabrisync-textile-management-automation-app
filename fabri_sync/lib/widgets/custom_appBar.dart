import 'package:fabri_sync/main.dart';
import 'package:flutter/material.dart';

AppBar buildGradientAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.transparent, // Transparent to show gradient
    elevation: 0, // Remove shadow
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back,
        color: Colors.white,
      ), // White back button
      onPressed: () =>
          Navigator.of(navigatorKey.currentContext!).pop(), // or context.pop()
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white, // White text
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A), // slate blue
            Color(0xFF111827), // charcoal blue
          ],
        ),
      ),
    ),
  );
}
