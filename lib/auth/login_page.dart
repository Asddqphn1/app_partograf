import 'package:flutter/material.dart';
import 'package:partograf/auth/auth_service.dart'; // Pastikan path ini benar

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      body: Container(
        // Memberi background gradasi yang lembut
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spacer untuk memberi ruang di bagian atas
              const Spacer(),

              // Bagian Ilustrasi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Image.asset(
                  'assets/images/medical_illustration.png', // Ganti dengan gambar ilustrasi Anda
                  height: 250,
                ),
              ),
              const SizedBox(height: 30),

              // Bagian Teks Sambutan
              const Text(
                'Selamat Datang di Partograf',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Aplikasi pencatatan persalinan modern untuk bidan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const Spacer(), // Spacer untuk mendorong tombol ke bawah

              // Bagian Tombol Login
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: 24.0,
                  ),
                  label: const Text(
                    'Masuk dengan Google',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  onPressed: () async {
                    await authService.signInWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}