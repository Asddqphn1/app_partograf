import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/home/login.dart';
import 'package:partograf/modules/home/register.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil ukuran layar untuk penyesuaian responsif
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Menggunakan Column untuk membagi layar menjadi 2 bagian
      body: Column(
        children: [
          // Bagian Atas (Ungu)
          Expanded(
            flex: 3, // Memberi porsi 3 dari 5 untuk bagian atas
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF7C8F4), // Warna ungu muda sesuai gambar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Judul Aplikasi
                  const Text(
                    'Aplikasi Partograf',
                    style: TextStyle(
                      color: Color(0xFF2C2C6A),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Deskripsi Aplikasi
                  const Text(
                    'Aplikasi Pemantauan Tepat\nuntuk Persalinan Aman',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2C2C6A),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(flex: 1),
                  // Container untuk gambar dengan border dan shadow
                  Container(
                    width: size.width * 0.55,
                    height: size.width * 0.55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFADE), // Warna background hijau muda
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
                      // Gambar di dalam lingkaran
                      child: Image.asset(
                        'assets/images/bidan.png',
                        height: size.width * 0.35,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, size: 80, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          // Bagian Bawah (Krem)
          Expanded(
            flex: 2, // Memberi porsi 2 dari 5 untuk bagian bawah
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF3F3E3), // Warna krem sesuai gambar
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Tombol Daftar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C6A), // Warna biru tua
                        foregroundColor: Colors.white, // Warna teks putih
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
                        fontFamily: 'Roboto', // Pastikan font sama
                      ),
                      children: <TextSpan>[
                        const TextSpan(text: 'Sudah memiliki akun? '),
                        TextSpan(
                          text: 'Masuk',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C6A),
                          ),
                          // Membuat teks "Masuk" dapat diklik
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
                        backgroundColor: const Color(0xFF2C2C6A), // Warna biru tua
                        foregroundColor: Colors.white, // Warna teks putih
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
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}