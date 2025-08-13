import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Instance untuk layanan Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mendapatkan stream perubahan status autentikasi (login/logout).
  /// Ini sangat berguna untuk mengarahkan pengguna secara otomatis.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mendapatkan informasi user yang sedang login saat ini.
  User? get currentUser => _auth.currentUser;

  /// Fungsi untuk memulai proses Sign In dengan Google.
  /// Fungsi ini juga akan membuat dokumen user di Firestore jika user tersebut baru.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Memulai proses login interaktif dengan Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Jika pengguna membatalkan dialog login, proses berhenti.
      if (googleUser == null) {
        return null;
      }

      // 2. Mendapatkan kredensial (token) dari akun Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Menggunakan kredensial untuk login ke Firebase Authentication
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // 4. [PENTING] Cek jika ini adalah user baru, lalu buat dokumen di Firestore
      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          // Jika user baru, buat dokumen baru di koleksi 'user'
          // dengan ID yang sama dengan UID dari Authentication.
          await _firestore.collection('user').doc(user.uid).set({
            'nama': user.displayName,
            'email': user.email,
            'uid': user.uid,
            'photoUrl': user.photoURL, // Simpan URL foto profil
            'createdAt': Timestamp.now(), // Simpan waktu pendaftaran
          });
        }
      }

      return userCredential;

    } on FirebaseAuthException catch (e) {
      // Menangani error spesifik dari Firebase Auth
      print('Firebase Auth Exception: ${e.message}');
      return null;
    } catch (e) {
      // Menangani error umum lainnya
      print('An unknown error occurred: $e');
      return null;
    }
  }

  /// Fungsi untuk Sign Out dari Firebase dan Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}