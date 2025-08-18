import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Model data kontraksi
class CatatanKontraksi {
  final DateTime jamMulai;
  final DateTime jamSelesai;

  CatatanKontraksi({
    required this.jamMulai,
    required this.jamSelesai,
  });

  Duration get durasi => jamSelesai.difference(jamMulai);

  factory CatatanKontraksi.fromMap(Map<String, dynamic> map) {
    return CatatanKontraksi(
      jamMulai: (map['jam_mulai'] as Timestamp).toDate(),
      jamSelesai: (map['jam_selesai'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jamMulai': jamMulai.toIso8601String(),
      'jamSelesai': jamSelesai.toIso8601String(),
    };
  }
}

class KontraksiGraphScreen extends StatefulWidget {
  final String userId;
  final String pasienId;

  const KontraksiGraphScreen({
    super.key,
    required this.userId,
    required this.pasienId,
  });

  @override
  State<KontraksiGraphScreen> createState() => _KontraksiGraphScreenState();
}

class _KontraksiGraphScreenState extends State<KontraksiGraphScreen> {
  late final WebViewController _controller;
  List<CatatanKontraksi> _dataKontraksi = [];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Setelah WebView siap, kirim data jika sudah ada
            if (_dataKontraksi.isNotEmpty) {
              _sendDataToWebView();
            }
          },
        ),
      );

    _loadHtmlFromAssets();
  }

  // Memuat file HTML dari assets
  void _loadHtmlFromAssets() async {
    String fileText = await rootBundle.loadString('assets/kontraksi_chart.html');
    _controller.loadHtmlString(fileText);
  }

  void _sendDataToWebView() {
    if (_dataKontraksi.isNotEmpty) {
      // Ubah list of objects menjadi JSON string
      final List<Map<String, dynamic>> jsonData =
      _dataKontraksi.map((c) => c.toJson()).toList();
      final String jsonString = jsonEncode(jsonData);

      // Panggil fungsi JavaScript di WebView dengan data JSON
      _controller.runJavaScript('renderPartograph($jsonString)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Kontraksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .collection('pasien')
            .doc(widget.pasienId)
            .snapshots(),
        builder: (context, pasienSnapshot) {
          if (pasienSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!pasienSnapshot.hasData || !pasienSnapshot.data!.exists) {
            return const Center(child: Text('Data pasien tidak ditemukan.'));
          }

          final pasienData = pasienSnapshot.data!.data() as Map<String, dynamic>?;
          final String? kemajuanId = pasienData?['kemajuan_id'];

          if (kemajuanId == null) {
            return const Center(child: Text('Belum ada data kemajuan persalinan.'));
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .doc(widget.userId)
                .collection('pasien')
                .doc(widget.pasienId)
                .collection('kemajuan_persalinan')
                .doc(kemajuanId)
                .snapshots(),
            builder: (context, kemajuanSnapshot) {
              if (kemajuanSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (kemajuanSnapshot.hasError) {
                return Center(child: Text('Error: ${kemajuanSnapshot.error}'));
              }

              List<CatatanKontraksi> latestData = [];
              if (kemajuanSnapshot.hasData && kemajuanSnapshot.data!.exists) {
                final kemajuanData = kemajuanSnapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> listData = kemajuanData['kontraksi_uterus'] ?? [];

                latestData = listData
                    .map((item) => CatatanKontraksi.fromMap(item as Map<String, dynamic>))
                    .toList();
              }

              // Cek apakah ada perubahan data sebelum mengirim ulang
              if (jsonEncode(_dataKontraksi) != jsonEncode(latestData)) {
                _dataKontraksi = latestData;
                _sendDataToWebView();
              }

              if (_dataKontraksi.isEmpty && kemajuanSnapshot.connectionState == ConnectionState.active) {
                // Jika data kosong, panggil JS untuk menampilkan pesan
                _controller.runJavaScript('renderPartograph([])');
              }

              return WebViewWidget(controller: _controller);
            },
          );
        },
      ),
    );
  }
}
