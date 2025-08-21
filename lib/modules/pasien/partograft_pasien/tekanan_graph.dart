import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:collection/collection.dart'; // Tambahkan ini di pubspec.yaml

class GraphWebViewPage extends StatefulWidget {
  final List<dynamic>? nadiData;
  final List<dynamic>? tdData;

  const GraphWebViewPage({
    super.key,
    required this.nadiData,
    required this.tdData,
  });

  @override
  State<GraphWebViewPage> createState() => _GraphWebViewPageState();
}

class _GraphWebViewPageState extends State<GraphWebViewPage> {
  late final WebViewController _controller;
  bool _isPageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Tandai bahwa halaman sudah selesai dimuat
            setState(() {
              _isPageLoaded = true;
            });
            // Kirim data setelah halaman siap
            _prepareAndSendData();
          },
        ),
      )
      ..loadFlutterAsset('assets/tekanan_darah.html');
  }

  // Fungsi ini akan dipanggil setiap kali data di halaman induk berubah
  @override
  void didUpdateWidget(covariant GraphWebViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika halaman sudah siap dan data berubah, kirim ulang data
    if (_isPageLoaded) {
      _prepareAndSendData();
    }
  }

  void _prepareAndSendData() {
    // 1. Gabungkan dan proses data
    final combinedData = _combineAndSortData();

    // 2. Ubah menjadi JSON
    final jsonString = jsonEncode(combinedData);

    // 3. Kirim ke JavaScript di WebView
    // Kita perlu "escape" string JSON agar aman dikirim
    _controller.runJavaScript('renderAllData(\'$jsonString\')');
  }

  List<Map<String, dynamic>> _combineAndSortData() {
    final Map<String, Map<String, dynamic>> dataByHour = {};
    final formatter = DateFormat('dd/MM HH:00'); // Kelompokkan per jam

    // Proses data Nadi
    (widget.nadiData ?? []).forEach((item) {
      final timestamp = item['jam-pemeriksaan'].toDate();
      final key = formatter.format(timestamp);
      dataByHour.putIfAbsent(key, () => {'timestamp': timestamp});
      dataByHour[key]!['nadi'] = item['hasilBPM'];
    });

    // Proses data Tekanan Darah
    (widget.tdData ?? []).forEach((item) {
      final timestamp = item['jam-pemeriksaan'].toDate();
      final key = formatter.format(timestamp);
      final tekanan = item['tekanan'];
      dataByHour.putIfAbsent(key, () => {'timestamp': timestamp});
      dataByHour[key]!['sistolik'] = tekanan['sistolik'];
      dataByHour[key]!['diastolik'] = tekanan['diastolik'];
    });

    // Urutkan berdasarkan waktu
    final sortedKeys = dataByHour.keys.sorted((a, b) {
      final dateA = dataByHour[a]!['timestamp'] as DateTime;
      final dateB = dataByHour[b]!['timestamp'] as DateTime;
      return dateA.compareTo(dateB);
    });

    // Buat format akhir yang akan dikirim ke JS
    return sortedKeys.map((key) {
      final entry = dataByHour[key]!;
      return {
        'label': DateFormat('HH:mm').format(entry['timestamp']),
        'nadi': entry['nadi'],
        'sistolik': entry['sistolik'],
        'diastolik': entry['diastolik'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}