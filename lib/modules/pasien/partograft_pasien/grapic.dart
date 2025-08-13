import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kemajuan_persalinan.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PartografView extends StatefulWidget {
  final List<CatatanServiks> dataPemeriksaan;

  const PartografView({super.key, required this.dataPemeriksaan});

  @override
  State<PartografView> createState() => _PartografViewState();
}

class _PartografViewState extends State<PartografView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Setelah halaman HTML selesai dimuat, kirim data ke JavaScript
            _updateChartData();
          },
        ),
      );

    _loadHtmlFromAssets();
  }

  // Memuat file HTML dari assets
  void _loadHtmlFromAssets() async {
    String fileText = await rootBundle.loadString(
      'assets/partograf_chart.html',
    );
    _controller.loadHtmlString(fileText);
  }

  // Mengirim data ke JavaScript di dalam WebView
  void _updateChartData() {
    if (widget.dataPemeriksaan.isEmpty) {
      // Jangan lakukan apa-apa jika data kosong
      return;
    }

    // 1. Ubah list Dart menjadi JSON String
    final List<Map<String, dynamic>> pembukaanDataJson = widget.dataPemeriksaan
        .map((e) => e.toJson())
        .toList();
    final String pembukaanDataString = jsonEncode(pembukaanDataJson);

    // Data penurunan juga diambil dari list yang sama
    final String penurunanDataString = pembukaanDataString;

    // 2. Buat label untuk sumbu X (jam pemeriksaan)
    final List<Map<String, String>> labels = widget.dataPemeriksaan.map((
      catatan,
    ) {
      return {
        'jam': catatan.jamPemeriksaan.toIso8601String(),
        'label': DateFormat('HH:mm').format(catatan.jamPemeriksaan),
      };
    }).toList();
    final String labelsString = jsonEncode(labels);

    // 3. Panggil fungsi JavaScript `updateChart` dengan data JSON
    _controller.runJavaScript(
      'updateChart($pembukaanDataString, $penurunanDataString, $labelsString);',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partograf')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
