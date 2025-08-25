import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/home/login.dart';
import 'package:partograf/modules/home/register.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Latar belakang gradien yang sesuai dengan gambar
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8ABEB), Color(0xFFEDFADC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Spacer untuk mendorong konten ke bawah dari status bar
              const Spacer(flex: 2),

              // Grup Judul dan Subjudul
              const Column(
                children: [
                  Text(
                    'Aplikasi Partograf',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF192A56),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aplikasi Pemantauan Tepat\nuntuk Persalinan Aman',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2C2C6A),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Container untuk gambar
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFADE),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD6B5D5),
                    width: 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/bidan.png',
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 80, color: Colors.grey);
                    },
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Grup Tombol dan Teks di bagian bawah
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    // Tombol Daftar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()),
                          );
                        },
                        child: const Text('Daftar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Teks "Sudah memiliki akun? Masuk"
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'Roboto',
                        ),
                        children: <TextSpan>[
                          const TextSpan(text: 'Sudah memiliki akun? '),
                          TextSpan(
                            text: 'Masuk',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C6A),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Masuk
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        child: const Text('Masuk', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
