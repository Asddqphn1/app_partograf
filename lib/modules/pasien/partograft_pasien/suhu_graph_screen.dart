import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SuhuGraphScreen extends StatefulWidget {
  final String userId;
  final String pasienId;

  const SuhuGraphScreen({
    super.key,
    required this.userId,
    required this.pasienId,
  });

  @override
  State<SuhuGraphScreen> createState() => _SuhuGraphScreenState();
}

class _SuhuGraphScreenState extends State<SuhuGraphScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      // 1. Ambil data dari Firestore
      final docRef = FirebaseFirestore.instance
          .collection("user")
          .doc(widget.userId)
          .collection("pasien")
          .doc(widget.pasienId)
          .collection("kondisi_ibu")
          .doc('data_kondisi');

      final docSnapshot = await docRef.get();

      List<Map<String, dynamic>> suhuDataForChart = [];

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('suhu') && data['suhu'] is List) {
          final suhuList = data['suhu'] as List<dynamic>;

          // 2. Olah data agar sesuai format yang dibutuhkan JavaScript
          suhuDataForChart = suhuList.map((item) {
            final record = item as Map<String, dynamic>;
            final timestamp = record['jam_pemeriksaan'] as Timestamp;
            final suhuValue = record['suhu'];

            // Konversi suhuValue ke double, jika perlu
            final double suhuDouble = (suhuValue is int)
                ? suhuValue.toDouble()
                : (suhuValue as double);

            return {
              // Kirim sebagai milidetik agar JavaScript mudah memprosesnya
              'jam_pemeriksaan': timestamp.millisecondsSinceEpoch,
              'suhu': suhuDouble,
            };
          }).toList();
        }
      }

      // 3. Load file template HTML dari assets
      final htmlTemplate = await rootBundle.loadString('assets/partograf_suhu.html');

      // 4. Ubah data Dart menjadi string JSON
      final jsonData = jsonEncode(suhuDataForChart);

      // 5. Injeksi data JSON ke dalam template HTML
      final finalHtml = htmlTemplate.replaceFirst('__DATA_PLACEHOLDER__', jsonData);

      // 6. Inisialisasi WebView Controller
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadHtmlString(finalHtml);

    } catch (e) {
      // Tangani jika ada error
      setState(() {
        _error = "Gagal memuat data grafik: $e";
      });
    } finally {
      // Selesaikan loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Suhu Ibu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      ))
          : WebViewWidget(controller: _controller),
    );
  }
}