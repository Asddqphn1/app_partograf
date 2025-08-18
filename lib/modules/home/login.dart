import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/home/home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // State untuk menampilkan/menyembunyikan password
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  /// Fungsi untuk login dengan email dan password
  Future<void> _signInWithEmailPassword() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // Cek apakah email sudah diverifikasi
      await _handleLogin(userCredential.user);

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Email atau password salah.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          String nameFromEmail = user.email!.split('@')[0];
          await _firestore.collection('user').doc(user.uid).set({
            'nama': user.displayName ?? nameFromEmail,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home(user: user.uid)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _handleLogin(User? user) async {
    try {
      // Reload user to get the latest email verification status
      await user?.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser?.emailVerified ?? false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home(user: refreshedUser!.uid)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email Anda belum diverifikasi. Silakan periksa email Anda.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // 2. Background diubah menjadi gradien
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8ABEB), Color(0xFFEDFADC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Bagian atas dengan gambar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.4,
              child: Container(
                color: Colors.transparent, // Dibuat transparan agar gradien terlihat
                child: Center(
                  // 1. Ukuran circle dan gambar diperkecil
                  child: Container(
                    width: 180,
                    height: 180,
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
                        height: 150, // Disesuaikan
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, size: 60, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bagian bawah dengan form login
            Positioned(
              top: size.height * 0.32, // Posisi disesuaikan
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Kartu form utama
                    Container(
                      margin: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.grey),
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
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.grey),
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
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signInWithEmailPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C2C6A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text('Login', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'atau',
                                style: TextStyle(color: Colors.black54, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                icon: Image.asset(
                                  'assets/images/google_icon.png',
                                  height: 22,
                                ),
                                label: const Text(
                                  'Sign In with Google',
                                  style: TextStyle(color: Colors.black87),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Kartu judul yang tumpang tindih
                    Container(
                      width: size.width * 0.7,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Login to your account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C6A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tombol kembali
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
      ),
    );
  }
}
