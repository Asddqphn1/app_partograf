import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const GradientAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.black87,
      elevation: 4,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
            colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  @override
  // Baris ini wajib ada untuk custom AppBar.
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
