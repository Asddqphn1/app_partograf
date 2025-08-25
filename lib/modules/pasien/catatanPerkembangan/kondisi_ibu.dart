import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'kondisiIbu/nadi.dart';
import 'kondisiIbu/suhu.dart';
import 'kondisiIbu/tekanan_darah.dart';
import 'kondisiIbu/urine.dart';


class KondisiIbu extends StatefulWidget {
  final String idUser;
  final String pasien;
  const KondisiIbu({super.key, required this.idUser, required this.pasien });

  @override
  State<KondisiIbu> createState() => _KondisiIbuState();
}

class _KondisiIbuState extends State<KondisiIbu> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // --- PERBAIKAN 1: Path ke Firestore diperbaiki ---
  // Menggunakan idUser dan pasien dengan benar.
  // Kita juga akan menggunakan satu dokumen saja per pasien untuk kondisi ibu agar lebih mudah dikelola.
  late final DocumentReference kondisiIbuDoc = FirebaseFirestore.instance
      .collection("user")
      .doc(widget.idUser) // <-- Menggunakan idUser
      .collection("pasien")
      .doc(widget.pasien) // <-- Menggunakan id pasien
      .collection("kondisi_ibu")
      .doc('data_kondisi'); // <-- Menggunakan ID yang konsisten

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.black87,
        elevation: 4,
        toolbarHeight: 80,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
        ),
        title: const Text(
          "Kondisi Ibu",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const [
            Tab(icon: FaIcon(FontAwesomeIcons.heartPulse), text: 'Nadi'),
            Tab(icon: FaIcon(FontAwesomeIcons.temperatureHalf), text: 'Suhu'),
            Tab(
              icon: FaIcon(FontAwesomeIcons.stethoscope),
              text: 'Tekanan Darah',
            ),
            Tab(icon: FaIcon(FontAwesomeIcons.flask), text: 'Urine'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: kondisiIbuDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- PERBAIKAN 2: Logika diubah agar UI tetap tampil walau dokumen belum ada ---
          List<dynamic>? nadiList;
          List<dynamic>? suhuList;
          List<dynamic>? tdList;
          List<dynamic>? urineList;

          // Cek apakah dokumen ada dan punya data. Jika ya, ambil datanya.
          // Jika tidak, list akan tetap null (kosong) dan UI akan menampilkan "Belum ada data".
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            nadiList = data['nadi'] as List<dynamic>?;
            suhuList = data['suhu'] as List<dynamic>?;
            tdList = data['tekanan_darah'] as List<dynamic>?;
            urineList = data['urine'] as List<dynamic>?;
          }

          // TabBarView sekarang akan selalu dibuat, sehingga tombol akan selalu terlihat.
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                items: nadiList,
                itemBuilder: _buildNadiCard,
                buttonLabel: "Tambahkan Data Nadi",
                onButtonPressed: () => _navigateToInputPage(0),
              ),
              _buildTabContent(
                items: suhuList,
                itemBuilder: _buildSuhuCard,
                buttonLabel: "Tambahkan Data Suhu",
                onButtonPressed: () => _navigateToInputPage(1),
              ),
              _buildTabContent(
                items: tdList,
                itemBuilder: _buildTekananDarahCard,
                buttonLabel: "Tambahkan Data Tekanan Darah",
                onButtonPressed: () => _navigateToInputPage(2),
              ),
              _buildTabContent(
                items: urineList,
                itemBuilder: _buildUrineCard,
                buttonLabel: "Tambahkan Data Urine",
                onButtonPressed: () => _navigateToInputPage(3),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToInputPage(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = InputNadi(docRef: kondisiIbuDoc);
        break;
      case 1:
        page = InputSuhu(docRef: kondisiIbuDoc);
        break;
      case 2:
        page = InputTd(docRef: kondisiIbuDoc);
        break;
      case 3:
        page = InputUrine(docRef: kondisiIbuDoc);
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildTabContent({
    required List<dynamic>? items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
      child: Column(
        children: [
          Expanded(
            child: items == null || items.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.folderOpen,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada data",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                // Mengurutkan data dari yang terbaru ke terlama
                final item = items.reversed.toList()[index] as Map<String, dynamic>;
                return itemBuilder(item);
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B), // Pink lebih gelap
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildNadiCard(Map<String, dynamic> item) {
    DateTime jamPemeriksaan = (item['jam-pemeriksaan'] as Timestamp).toDate();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          child: FaIcon(FontAwesomeIcons.heartPulse, size: 20),
        ),
        title: Text(
          '${item['hasilBPM'] ?? '-'} BPM',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Diperiksa: ${DateFormat('dd MMM yyyy, HH:mm').format(jamPemeriksaan)}',
        ),
      ),
    );
  }

  Widget _buildSuhuCard(Map<String, dynamic> item) {
    DateTime jamPemeriksaan = (item['jam_pemeriksaan'] as Timestamp).toDate();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
          child: FaIcon(FontAwesomeIcons.temperatureHalf, size: 20),
        ),
        title: Text(
          '${item['suhu'] ?? '-'} °C',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Diperiksa: ${DateFormat('dd MMM yyyy, HH:mm').format(jamPemeriksaan)}',
        ),
      ),
    );
  }

  Widget _buildTekananDarahCard(Map<String, dynamic> item) {
    DateTime jamPemeriksaan = (item['jam-pemeriksaan'] as Timestamp).toDate();
    final tekanan = item['tekanan'] as Map<String, dynamic>?;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          child: FaIcon(FontAwesomeIcons.stethoscope, size: 20),
        ),
        title: Text(
          '${tekanan?['sistolik'] ?? '-'}/${tekanan?['diastolik'] ?? '-'} mmHg',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Diperiksa: ${DateFormat('dd MMM yyyy, HH:mm').format(jamPemeriksaan)}',
        ),
      ),
    );
  }

  Widget _buildUrineCard(Map<String, dynamic> item) {
    DateTime jamPemeriksaan = (item['jam_pemeriksaan'] as Timestamp).toDate();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          child: FaIcon(FontAwesomeIcons.flask, size: 20),
        ),
        title: Text(
          'Volume: ${item['volume'] ?? '-'} ml',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Protein: ${item['protein'] ?? '-'} | Aseton: ${item['aseton'] ?? '-'}\nDiperiksa: ${DateFormat('dd MMM yyyy, HH:mm').format(jamPemeriksaan)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}