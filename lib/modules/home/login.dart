import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/home/home.dart';
// NEW: Import required packages for Google Sign-In and Firestore
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
  // NEW: Add Firestore instance
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

  // NEW: Function to handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Handle case where user cancels the sign-in
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Check if user is new, if so, save data to Firestore
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // Extract name from email as requested (e.g., 'example' from 'example@gmail.com')
          String nameFromEmail = user.email!.split('@')[0];

          await _firestore.collection('user').doc(user.uid).set({
            'nama': user.displayName ?? nameFromEmail, // Use display name if available, otherwise use extracted name
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(), // Set creation timestamp
          });
        }
        // 6. Navigate to Home Screen
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
      // Cek apakah email sudah diverifikasi
      if (user?.emailVerified ?? false) {
        // Jika email sudah diverifikasi, lanjutkan ke halaman Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home(user: user!.uid)),
        );
      } else {
        // Jika email belum diverifikasi, beri tahu pengguna untuk memeriksa email mereka
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
      body: Stack(
        children: [
          // Bagian atas dengan warna ungu dan gambar
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
          // Bagian bawah dengan form login
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
                    // Judul Form
                    const Center(
                      child: Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C6A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Label dan Input Email
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

                    // Label dan Input Password
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
                    const SizedBox(height: 30),

                    // Tombol Login
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

                    // Pemisah "or"
                    const Center(
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // MODIFIED: Tombol Sign In with Google is now active
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle, // Call the new function
                        icon: Image.asset(
                          'assets/images/google_icon.png', // Pastikan Anda punya logo Google di assets
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
          ),
          // Tombol kembali (opsional, jika diperlukan)
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
