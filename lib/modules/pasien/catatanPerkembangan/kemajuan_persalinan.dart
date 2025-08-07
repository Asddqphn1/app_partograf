import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatatanServiks {
  final DateTime jamPemeriksaan;
  final int besarPembukaan;
  final int besarPenurunan;

  CatatanServiks({
    required this.jamPemeriksaan,
    required this.besarPembukaan,
    required this.besarPenurunan,
  });

  Map<String, dynamic> toJson() {
    return {
      'jam_pemeriksaan': Timestamp.fromDate(jamPemeriksaan),
      'besar_pembukaan': besarPembukaan,
      'besar_penurunan': besarPenurunan,
    };
  }

  factory CatatanServiks.fromMap(Map<String, dynamic> map) {
    return CatatanServiks(
      jamPemeriksaan: (map['jam_pemeriksaan'] as Timestamp).toDate(),
      besarPembukaan: map['besar_pembukaan'] as int,
      besarPenurunan: map['besar_penurunan'] as int,
    );
  }
}

class KemajuanPersalinan extends StatefulWidget {
  String userId;
  String pasienId;

  KemajuanPersalinan({
    super.key,
    required this.userId,
    required this.pasienId,
  });

  @override
  State<KemajuanPersalinan> createState() => _KemajuanPersalinanScreenState();
}

class _KemajuanPersalinanScreenState extends State<KemajuanPersalinan> with SingleTickerProviderStateMixin {
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

  void _tambahCatatan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TambahCatatanScreen(pasienId: widget.pasienId)),
    );

    if (result != null && result is CatatanServiks) {
      // When a new record is added, the StreamBuilder will automatically update the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kemajuan Persalinan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEEF1DD),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white,
              indicator: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              tabs: const [
                Tab(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: Text(
                    'Pembukaan Serviks',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),),
                Tab(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: Text('Kontraksi Uterus'),
                ),),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPembukaanServiksTab(),
                const Center(child: Text('Fitur Kontraksi Uterus akan segera hadir!')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPembukaanServiksTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Catatan ini membantu memantau progres pembukaan serviks selama proses persalinan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user')
                  .doc(widget.userId)
                  .collection('pasien')
                  .doc(widget.pasienId)
                  .collection('kemajuan_persalinan')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildEmptyState();
                }

                final documents = snapshot.data!.docs;
                List<CatatanServiks> catatanList = [];
                for (var doc in documents) {
                  var data = doc.data() as Map<String, dynamic>;
                  var pembukaanServiksList = List.from(data['pembukaan_serviks'] ?? []);
                  for (var item in pembukaanServiksList) {
                    catatanList.add(CatatanServiks.fromMap(item));
                  }
                }

                return _buildDataList(catatanList);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, top: 10.0),
            child: ElevatedButton.icon(
              onPressed: _tambahCatatan,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambahkan Catatan', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8ABEB),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://i.ibb.co/9vqyht2/cute-ghost.png',
            height: 100,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.sentiment_dissatisfied, size: 100, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada catatan pembukaan serviks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap tombol di bawah untuk mulai mencatat progres persalinan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList(List<CatatanServiks> catatanList) {
    return ListView.builder(
      itemCount: catatanList.length,
      itemBuilder: (context, index) {
        final catatan = catatanList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            title: Text(
              'Pemeriksaan ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text('Waktu: ${DateFormat('d MMM yyyy, HH:mm').format(catatan.jamPemeriksaan)}'),
                Text('Pembukaan: ${catatan.besarPembukaan} cm'),
                Text('Penurunan: ${catatan.besarPenurunan}/5'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

// Layar untuk menambah catatan baru
class TambahCatatanScreen extends StatefulWidget {
  String pasienId;
  TambahCatatanScreen({super.key, required this.pasienId});

  @override
  State<TambahCatatanScreen> createState() => _TambahCatatanScreenState();
}

class _TambahCatatanScreenState extends State<TambahCatatanScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controller & State ---
  final _jamController = TextEditingController();
  final _pembuembukaanController = TextEditingController();
  final _penurunanController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedDateTimePemeriksaan;
  TimeOfDay? _selectedTime; // Declare selected time
  int? _selectedPembukaan; // Declare selected pembukaan
  int? _selectedPenurunan; // Declare selected penurunan

  @override
  void dispose() {
    _jamController.dispose();
    _pembuembukaanController.dispose();
    _penurunanController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pilihTanggalDanJam(BuildContext context, DateTime? initialDate) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Pilih Tanggal',
    );

    if (date == null) return null;
    if (!mounted) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      helpText: 'Pilih Jam',
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // --- Fungsi Simpan Data ---
  // --- Fungsi Simpan Data ---
  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final Map<String, dynamic> dataPasien = {
        'besar_pembukaan': _selectedPembukaan,
        'besar_penurunan': _selectedPenurunan,

        // Langsung gunakan state DateTime yang sudah lengkap untuk semua field
        'jam_pemeriksaan': _selectedDateTimePemeriksaan != null ? Timestamp.fromDate(_selectedDateTimePemeriksaan!) : null,
      };
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final pasiernRef = firestore.collection('user').doc('QfAsyIkRTFuvNSy5YRaH').collection('pasien').doc(widget.pasienId);

      try {
        final pasienDoc = await pasiernRef.get();
        String? kemajuan_id = pasienDoc.data()!['kemajuan_id'];

        if (kemajuan_id == null) {
          // Jika kemajuan_id tidak ada, buat koleksi baru dan dokumen untuk kemajuan_persalinan
          final newKemajuanRef = pasiernRef.collection('kemajuan_persalinan').doc();
          kemajuan_id = newKemajuanRef.id;
          await newKemajuanRef.set({
            'kemajuan_id': kemajuan_id,
            'pembukaan_serviks': [dataPasien] // Menyimpan data pembukaan serviks pertama
          });

          await pasiernRef.update({'kemajuan_id': kemajuan_id});
        } else {
          // Jika kemajuan_id sudah ada, update koleksi yang sudah ada
          final kemajuanRef = pasiernRef.collection('kemajuan_persalinan').doc(kemajuan_id);
          await kemajuanRef.update({
            'pembukaan_serviks': FieldValue.arrayUnion([dataPasien]) // Menambahkan data baru ke array pembukaan_serviks
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data pasien berhasil disimpan!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }


  // Time picker method
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null && time != _selectedTime) {
      setState(() {
        _selectedTime = time;
        _selectedDateTimePemeriksaan = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Menentukan tinggi AppBar
        child: AppBar(
          title: const Text(
            'Tambah Catatan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)], // Gradient warna sesuai permintaan
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pembukaan Serviks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  // Input Jam Periksa
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _selectedTime == null ? '' : DateFormat('HH:mm').format(DateTime(0, 0, 0, _selectedTime!.hour, _selectedTime!.minute)),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Jam Periksa',
                      hintText: 'Pilih waktu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    onTap: () => _selectTime(context),
                    validator: (value) => _selectedTime == null ? 'Waktu tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown Besar Pembukaan
                  DropdownButtonFormField<int>(
                    value: _selectedPembukaan,
                    decoration: InputDecoration(
                      labelText: 'Besar Pembukaan',
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
                      labelText: 'Besar Penurunan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: const Text('Pilih Penurunan'),
                    items: List.generate(5, (index) => index)
                        .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPenurunan = value),
                    validator: (value) => value == null ? 'Penurunan tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _simpanData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E44AD),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16)),
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
