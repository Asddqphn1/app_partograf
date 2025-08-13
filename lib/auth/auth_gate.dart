import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partograf/auth/auth_service.dart';
import 'package:partograf/auth/login_page.dart';
import 'package:partograf/modules/home/home.dart'; // Sesuaikan path

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Mendengarkan perubahan status dari AuthService
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Jika sedang loading, tampilkan progress indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Jika user sudah login (data tidak null)
        if (snapshot.hasData) {
          return Home(); // Tampilkan halaman utama
        }

        // Jika user belum login
        return const LoginPage(); // Tampilkan halaman login
      },
    );
  }
}
