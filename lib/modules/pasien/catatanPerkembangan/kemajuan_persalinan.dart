import 'dart:async'; // Diperlukan untuk Timer
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===== MODEL DATA BARU UNTUK KONTRAKSI =====
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
}

// Data Model untuk satu catatan serviks
class CatatanServiks {
  final DateTime jamPemeriksaan;
  final int besarPembukaan;
  final int besarPenurunan;

  CatatanServiks({
    required this.jamPemeriksaan,
    required this.besarPembukaan,
    required this.besarPenurunan,
  });

  factory CatatanServiks.fromMap(Map<String, dynamic> map) {
    return CatatanServiks(
      jamPemeriksaan: (map['jam_pemeriksaan'] as Timestamp).toDate(),
      besarPembukaan: map['besar_pembukaan'] as int,
      besarPenurunan: map['besar_penurunan'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Menggunakan format ISO 8601 agar mudah dibaca oleh JavaScript
      'jam_pemeriksaan': jamPemeriksaan.toIso8601String(),
      'besar_pembukaan': besarPembukaan,
      'besar_penurunan': besarPenurunan,
    };
  }
}

// Layar utama untuk menampilkan kemajuan persalinan
class KemajuanPersalinan extends StatefulWidget {
  final String userId;
  final String pasienId;

  const KemajuanPersalinan({
    super.key,
    required this.userId,
    required this.pasienId,
  });

  @override
  State<KemajuanPersalinan> createState() => _KemajuanPersalinanState();
}

class _KemajuanPersalinanState extends State<KemajuanPersalinan> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Navigasi ke layar tambah catatan serviks
  void _tambahCatatanServiks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahCatatanScreen(
          userId: widget.userId,
          pasienId: widget.pasienId,
        ),
      ),
    );
  }

  // ===== FUNGSI BARU: Navigasi ke layar tambah kontraksi =====
  void _tambahCatatanKontraksi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahKontraksiScreen(
          userId: widget.userId,
          pasienId: widget.pasienId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kemajuan Persalinan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEEF1DD),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              tabs: const [
                Tab(child: Text('Pembukaan Serviks')),
                Tab(child: Text('Kontraksi Uterus')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPembukaanServiksTab(),
                // ===== PERUBAHAN: Memanggil widget untuk tab kontraksi =====
                _buildKontraksiUterusTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== WIDGET BARU: Untuk membangun tab "Kontraksi Uterus" =====
  Widget _buildKontraksiUterusTab() {
    return StreamBuilder<DocumentSnapshot>(
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
          return _buildContentWithButton(
            content: _buildEmptyState(
              pesan: 'Belum ada catatan kontraksi',
              deskripsi: 'Tekan tombol di bawah untuk menambah\ncatatan kontraksi pertama.',
            ),
            onPressed: _tambahCatatanKontraksi,
            labelTombol: 'Catat Kontraksi',
          );
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
            if (!kemajuanSnapshot.hasData || !kemajuanSnapshot.data!.exists) {
              return _buildContentWithButton(
                content: _buildEmptyState(
                  pesan: 'Belum ada catatan kontraksi',
                  deskripsi: 'Tekan tombol di bawah untuk menambah\ncatatan kontraksi pertama.',
                ),
                onPressed: _tambahCatatanKontraksi,
                labelTombol: 'Catat Kontraksi',
              );
            }

            final kemajuanData = kemajuanSnapshot.data!.data() as Map<String, dynamic>;
            final List<dynamic> listData = kemajuanData['kontraksi_uterus'] ?? [];

            if (listData.isEmpty) {
              return _buildContentWithButton(
                content: _buildEmptyState(
                  pesan: 'Belum ada catatan kontraksi',
                  deskripsi: 'Tekan tombol di bawah untuk menambah\ncatatan kontraksi pertama.',
                ),
                onPressed: _tambahCatatanKontraksi,
                labelTombol: 'Catat Kontraksi',
              );
            }

            List<CatatanKontraksi> catatanList = listData
                .map((item) => CatatanKontraksi.fromMap(item as Map<String, dynamic>))
                .toList();

            catatanList.sort((a, b) => b.jamMulai.compareTo(a.jamMulai));

            return _buildContentWithButton(
              content: _buildKontraksiList(catatanList),
              onPressed: _tambahCatatanKontraksi,
              labelTombol: 'Catat Kontraksi',
            );
          },
        );
      },
    );
  }

  Widget _buildPembukaanServiksTab() {

    print("Mencoba membangun tab dengan User ID: ${widget.userId}");
    print("Mencoba membangun tab dengan Pasien ID: ${widget.pasienId}");
    return StreamBuilder<DocumentSnapshot>(
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
          return _buildContentWithButton(
            content: _buildEmptyState(),
            onPressed: _tambahCatatanServiks,
            labelTombol: 'Tambahkan Catatan',
          );
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
            if (!kemajuanSnapshot.hasData || !kemajuanSnapshot.data!.exists) {
              return _buildContentWithButton(
                content: _buildEmptyState(),
                onPressed: _tambahCatatanServiks,
                labelTombol: 'Tambahkan Catatan',
              );
            }

            final kemajuanData = kemajuanSnapshot.data!.data() as Map<String, dynamic>;
            final List<dynamic> listData = kemajuanData['pembukaan_serviks'] ?? [];

            if (listData.isEmpty) {
              return _buildContentWithButton(
                content: _buildEmptyState(),
                onPressed: _tambahCatatanServiks,
                labelTombol: 'Tambahkan Catatan',
              );
            }

            List<CatatanServiks> catatanList = listData
                .map((item) => CatatanServiks.fromMap(item as Map<String, dynamic>))
                .toList();

            catatanList.sort((a, b) => b.jamPemeriksaan.compareTo(a.jamPemeriksaan));

            return _buildContentWithButton(
              content: _buildServiksList(catatanList),
              onPressed: _tambahCatatanServiks,
              labelTombol: 'Tambahkan Catatan',
            );
          },
        );
      },
    );
  }

  // ===== PERUBAHAN: Padding bawah ditambah agar tombol tidak tertutup navbar sistem =====
  Widget _buildContentWithButton({
    required Widget content,
    required VoidCallback onPressed,
    required String labelTombol,
  }) {
    return Column(
      children: [
        Expanded(child: content),
        Padding(
          // Padding bawah ditambah dari 24.0 menjadi 48.0
          padding: const EdgeInsets.only(bottom: 48.0, top: 10.0, left: 20.0, right: 20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(labelTombol, style: const TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8ABEB),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ===== PERUBAHAN: Empty state dibuat lebih umum =====
  Widget _buildEmptyState({
    String pesan = 'Belum ada catatan',
    String deskripsi = 'Tekan tombol di bawah untuk menambah\ncatatan kemajuan persalinan pertama.',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(pesan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(deskripsi, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Menampilkan daftar catatan serviks
  Widget _buildServiksList(List<CatatanServiks> catatanList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: catatanList.length,
      itemBuilder: (context, index) {
        final catatan = catatanList[index];
        return _buildServiksCard(catatan, catatanList.length - index);
      },
    );
  }

  // ===== WIDGET BARU: Menampilkan daftar catatan kontraksi =====
  Widget _buildKontraksiList(List<CatatanKontraksi> catatanList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: catatanList.length,
      itemBuilder: (context, index) {
        final catatan = catatanList[index];
        return _buildKontraksiCard(catatan, catatanList.length - index);
      },
    );
  }

  // Kartu untuk menampilkan satu data catatan serviks
  Widget _buildServiksCard(CatatanServiks catatan, int nomorPemeriksaan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.pink.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pemeriksaan Ke-$nomorPemeriksaan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C2C6A))),
            const Divider(height: 20),
            _buildInfoRow(icon: Icons.access_time_filled, label: 'Jam Pemeriksaan', value: DateFormat('d MMM yyyy, HH:mm').format(catatan.jamPemeriksaan), iconColor: Colors.orange),
            const SizedBox(height: 12),
            _buildInfoRow(icon: Icons.open_in_full, label: 'Pembukaan Serviks', value: '${catatan.besarPembukaan} cm', iconColor: Colors.pink),
            const SizedBox(height: 12),
            _buildInfoRow(icon: Icons.arrow_downward, label: 'Penurunan Serviks', value: '${catatan.besarPenurunan}/5', iconColor: Colors.purple),
          ],
        ),
      ),
    );
  }

  // ===== WIDGET BARU: Kartu untuk menampilkan satu data kontraksi =====
  Widget _buildKontraksiCard(CatatanKontraksi catatan, int nomorKontraksi) {
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
      return "$twoDigitMinutes menit $twoDigitSeconds detik";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.teal.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kontraksi Ke-$nomorKontraksi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF004D40))),
            const Divider(height: 20),
            _buildInfoRow(
              icon: Icons.play_circle_outline,
              label: 'Jam Mulai',
              value: DateFormat('d MMM yyyy, HH:mm:ss').format(catatan.jamMulai),
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.timer_outlined,
              label: 'Lama Kontraksi',
              value: formatDuration(catatan.durasi),
              iconColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan untuk membuat baris info yang konsisten
  Widget _buildInfoRow({required IconData icon, required String label, required String value, required Color iconColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}


class TambahKontraksiScreen extends StatefulWidget {
  final String userId;
  final String pasienId;
  const TambahKontraksiScreen({super.key, required this.userId, required this.pasienId});

  @override
  State<TambahKontraksiScreen> createState() => _TambahKontraksiScreenState();
}

class _TambahKontraksiScreenState extends State<TambahKontraksiScreen> {
  bool _isLoading = false;
  bool _isRunning = false;

  DateTime? _jamMulai;
  DateTime? _jamSelesai;

  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dibatalkan saat layar ditutup
    super.dispose();
  }

  void _toggleStopwatch() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        // Mulai Stopwatch
        _jamMulai = DateTime.now();
        _jamSelesai = null;
        _secondsElapsed = 0;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _secondsElapsed++;
          });
        });
      } else {
        // Hentikan Stopwatch
        _timer?.cancel();
        _jamSelesai = DateTime.now();
      }
    });
  }

  void _reset() {
    setState(() {
      _timer?.cancel();
      _isRunning = false;
      _jamMulai = null;
      _jamSelesai = null;
      _secondsElapsed = 0;
    });
  }

  Future<void> _simpanData() async {
    if (_jamMulai == null || _jamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selesaikan pencatatan waktu terlebih dahulu!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() { _isLoading = true; });

    final Map<String, dynamic> dataKontraksiBaru = {
      'jam_mulai': Timestamp.fromDate(_jamMulai!),
      'jam_selesai': Timestamp.fromDate(_jamSelesai!),
    };

    final pasienRef = FirebaseFirestore.instance
        .collection('user')
        .doc(widget.userId) // Ganti dengan ID user yang sesuai
        .collection('pasien')
        .doc(widget.pasienId);

    try {
      final pasienDoc = await pasienRef.get();
      final pasienData = pasienDoc.data() as Map<String, dynamic>?;
      String? kemajuanId = pasienData?['kemajuan_id'];

      if (kemajuanId == null) {
        // Jika kemajuan_id tidak ada, buat dokumen baru
        final newKemajuanRef = pasienRef.collection('kemajuan_persalinan').doc();
        kemajuanId = newKemajuanRef.id;

        await newKemajuanRef.set({
          'kemajuan_id': kemajuanId,
          'kontraksi_uterus': [dataKontraksiBaru]
        });

        await pasienRef.update({'kemajuan_id': kemajuanId});
      } else {
        // Jika kemajuan_id sudah ada, update array yang ada
        final kemajuanRef = pasienRef.collection('kemajuan_persalinan').doc(kemajuanId);
        final kemajuanDoc = await kemajuanRef.get();

        if (kemajuanDoc.exists) {
          await kemajuanRef.update({
            'kontraksi_uterus': FieldValue.arrayUnion([dataKontraksiBaru])
          });
        } else {
          // Kasus jika kemajuan_id ada di pasien tapi doc nya terhapus
          await kemajuanRef.set({
            'kemajuan_id': kemajuanId,
            'kontraksi_uterus': [dataKontraksiBaru]
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kontraksi berhasil dicatat!'), backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  String get _timerText {
    final int minutes = _secondsElapsed ~/ 60;
    final int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Kontraksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lama Kontraksi',
                style: TextStyle(fontSize: 24, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Text(
                _timerText,
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 200,
                child: ElevatedButton(
                  onPressed: _toggleStopwatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.redAccent : Colors.green,
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _isRunning ? Icons.stop : Icons.play_arrow,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (!_isRunning && _jamMulai != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      onPressed: _isLoading ? null : _reset,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Menyimpan...' : 'Simpan'),
                      onPressed: _isLoading ? null : _simpanData,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E44AD)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TambahCatatanScreen extends StatefulWidget {
  final String userId;
  final String pasienId;
  const TambahCatatanScreen({super.key, required this.pasienId, required this.userId});

  @override
  State<TambahCatatanScreen> createState() => _TambahCatatanScreenState();
}

class _TambahCatatanScreenState extends State<TambahCatatanScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- State untuk form ---
  DateTime? _selectedDateTime;
  int? _selectedPembukaan;
  int? _selectedPenurunan;
  bool _isLoading = false;

  // --- Fungsi untuk memilih tanggal dan waktu ---
  Future<void> _pilihTanggalDanJam(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (date == null || !mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // --- Fungsi untuk menyimpan data ke Firestore ---
  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final Map<String, dynamic> dataCatatanBaru = {
        'jam_pemeriksaan': Timestamp.fromDate(_selectedDateTime!),
        'besar_pembukaan': _selectedPembukaan,
        'besar_penurunan': _selectedPenurunan,
      };

      final pasienRef = FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId) // Ganti dengan ID user yang sesuai
          .collection('pasien')
          .doc(widget.pasienId);

      try {
        final pasienDoc = await pasienRef.get();
        final pasienData = pasienDoc.data() as Map<String, dynamic>?;
        String? kemajuanId = pasienData?['kemajuan_id'];

        if (kemajuanId == null) {
          // Jika kemajuan_id tidak ada, buat dokumen baru di 'kemajuan_persalinan'
          final newKemajuanRef = pasienRef.collection('kemajuan_persalinan').doc();
          kemajuanId = newKemajuanRef.id;

          // Set data pertama di dokumen baru tersebut
          await newKemajuanRef.set({
            'kemajuan_id': kemajuanId,
            'pembukaan_serviks': [dataCatatanBaru] // Simpan sebagai array dengan 1 item
          });

          // Update dokumen pasien dengan kemajuan_id yang baru
          await pasienRef.update({'kemajuan_id': kemajuanId});
        } else {
          // Jika kemajuan_id sudah ada, update array yang ada
          final kemajuanRef = pasienRef.collection('kemajuan_persalinan').doc(kemajuanId);
          await kemajuanRef.update({
            'pembukaan_serviks': FieldValue.arrayUnion([dataCatatanBaru])
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan berhasil disimpan!'), backgroundColor: Colors.green));
        Navigator.pop(context);

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Catatan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 4,
            shadowColor: Colors.pink.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Pemeriksaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C2C6A))),
                  const SizedBox(height: 24),
                  // Input Jam Periksa
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _selectedDateTime == null ? '' : DateFormat('d MMM yyyy, HH:mm').format(_selectedDateTime!),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Jam Pemeriksaan',
                      hintText: 'Pilih tanggal & waktu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () => _pilihTanggalDanJam(context),
                    validator: (value) => _selectedDateTime == null ? 'Waktu tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown Besar Pembukaan
                  DropdownButtonFormField<int>(
                    value: _selectedPembukaan,
                    decoration: InputDecoration(
                      labelText: 'Besar Pembukaan (cm)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: const Text('Pilih Pembukaan'),
                    items: List.generate(10, (index) => index + 1)
                        .map((cm) => DropdownMenuItem(value: cm, child: Text('$cm cm')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPembukaan = value),
                    validator: (value) => value == null ? 'Pembukaan tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown Besar Penurunan
                  DropdownButtonFormField<int>(
                    value: _selectedPenurunan,
                    decoration: InputDecoration(
                      labelText: 'Besar Penurunan (per 5)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: const Text('Pilih Penurunan'),
                    items: List.generate(6, (index) => index)
                        .map((val) => DropdownMenuItem(value: val, child: Text('$val/5')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPenurunan = value),
                    validator: (value) => value == null ? 'Penurunan tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E44AD),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

