import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:partograf/modules/pasien/catatanPerkembangan/kondisiIbu/input_td.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kondisiibu/input_nadi.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kondisiibu/input_suhu.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kondisiibu/input_urine.dart';

class KondisiIbu extends StatefulWidget {
  const KondisiIbu({super.key});

  @override
  State<KondisiIbu> createState() => _KondisiIbuState();
}

class _KondisiIbuState extends State<KondisiIbu>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DocumentReference kondisiIbuDoc = FirebaseFirestore.instance
      .collection("user")
      .doc("QfAsyIkRTFuvNSy5YRaH")
      .collection("pasien")
      .doc('vJ0Wm7xmhr0OAPQ4ehNA')
      .collection("kondisi_ibu")
      .doc('ndPImv4ytlfvxxolbA4b');

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
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nadiList = data['nadi'] as List<dynamic>?;
          final suhuList = data['suhu'] as List<dynamic>?;
          final tdList = data['tekanan_darah'] as List<dynamic>?;
          final urineList = data['urine'] as List<dynamic>?;

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
      padding: const EdgeInsets.all(16.0),
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
                      final item = items[index] as Map<String, dynamic>;
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
                backgroundColor: const Color(0xFFC2185B),
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
