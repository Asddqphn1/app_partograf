import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/pasien/partograft_pasien/tekanan_graph.dart';
// Pastikan path import ini benar

class KondisiIbuGraphScreen extends StatelessWidget {
  final String userId;
  final String pasienId;

  const KondisiIbuGraphScreen({
    super.key,
    required this.userId,
    required this.pasienId,
  });

  @override
  Widget build(BuildContext context) {
    // Path ke koleksi 'kondisi_ibu' untuk pasien yang dipilih
    final kondisiIbuCollection = FirebaseFirestore.instance
        .collection("user")
        .doc(userId)
        .collection("pasien")
        .doc(pasienId)
        .collection("kondisi_ibu");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Kondisi Ibu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Kita ambil 1 dokumen saja dari koleksi, karena semua data ada di sana
        stream: kondisiIbuCollection.limit(1).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Data kondisi ibu belum diinput."));
          }

          // Ambil dokumen pertama
          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final nadiList = data['nadi'] as List<dynamic>?;
          final tdList = data['tekanan_darah'] as List<dynamic>?;

          // Kirim data ke widget WebView untuk digambar
          return GraphWebViewPage(
            nadiData: nadiList,
            tdData: tdList,
          );
        },
      ),
    );
  }
}
