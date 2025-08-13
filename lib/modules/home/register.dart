import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/home/login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk input field
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController(); // Controller untuk nama

  // Instance dari Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State untuk menampilkan/menyembunyikan password
  bool _isPasswordVisible = false;

  // Fungsi untuk proses registrasi
  void _handleRegister() async {
    // Menampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Membuat user baru dengan email dan password di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Mengirim email verifikasi
      await userCredential.user!.sendEmailVerification();

      // Menutup loading indicator
      Navigator.of(context).pop();

      // Menampilkan pesan bahwa email verifikasi telah dikirim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verifikasi telah dikirim! Cek email Anda untuk mengaktifkan akun.'),
          backgroundColor: Colors.green,
        ),
      );

      await _saveUserDataToFirestore(userCredential.user!);

      // Mengarahkan pengguna untuk memeriksa email mereka
      // Tidak menyimpan data ke Firestore sampai email diverifikasi
    } on FirebaseAuthException catch (e) {
      // Menutup loading indicator
      Navigator.of(context).pop();

      // Menampilkan pesan error yang lebih jelas
      String errorMessage = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        errorMessage = 'Password yang dimasukkan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveUserDataToFirestore(User user) async {
    try {
      // Menyimpan data user ke Firestore setelah email diverifikasi
      final docRef = FirebaseFirestore.instance.collection('user').doc(user.uid);

      // Cek apakah user sudah ada di Firestore
      final doc = await docRef.get();
      if (!doc.exists) {
        // Jika data belum ada, simpan data baru
        await docRef.set({
          'email': user.email,
          'nama': nameController.text.trim(),
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menyimpan data ke Firestore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  String _generateVerificationCode() {
    // Membuat 4 digit angka acak
    return (1000 + Random().nextInt(9000)).toString();
  }

  Future<void> _sendVerificationEmail(User user, String verificationCode) async {
    try {
      // Kirim email verifikasi Firebase untuk akun
      await user.sendEmailVerification();

      // Simpan kode verifikasi di Firestore
      await _firestore.collection('user').doc(user.uid).update({
        'verificationCode': verificationCode,
      });

      // Anda bisa menambahkan pengiriman kode verifikasi lainnya (misalnya lewat sistem email lain).
    } catch (e) {
      // Menangani error jika ada masalah saat mengirim verifikasi email
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengirim email verifikasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              color: const Color(0xFFF8C9F5),
              child: Center(
                child: Container(
                  width: size.width * 0.45,
                  height: size.width * 0.45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAFADE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD6B5D5),
                      width: 5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/bidan.png',
                      height: size.width * 0.25,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 60, color: Colors.grey);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.38,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3E3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Create New Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C6A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text('Nama Bidan:', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Email:', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Password:', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Daftar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2C2C6A)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}


class VerificationDialog extends StatefulWidget {
  final UserCredential userCredential;
  final String verificationCode;

  const VerificationDialog({
    required this.userCredential,
    required this.verificationCode,
    super.key,
  });

  @override
  _VerificationDialogState createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  final TextEditingController codeController = TextEditingController();

  // Fungsi untuk memverifikasi kode
  void _verifyCode() async {
    if (codeController.text.trim() == widget.verificationCode) {
      // Jika kode benar, arahkan ke halaman login
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode verifikasi berhasil!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } else {
      // Jika kode salah, tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode verifikasi salah!'), backgroundColor: Colors.red),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Masukkan Kode Verifikasi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kode Verifikasi',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verifyCode,
          child: const Text('Verifikasi'),
        ),
      ],
    );
  }
}
