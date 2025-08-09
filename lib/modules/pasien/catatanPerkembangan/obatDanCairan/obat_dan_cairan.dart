import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'input_obat.dart';
import 'input_cairan.dart';

class ObatDanCairan extends StatefulWidget {
  const ObatDanCairan({super.key});

  @override
  State<ObatDanCairan> createState() => _ObatDanCairanState();
}

class _ObatDanCairanState extends State<ObatDanCairan>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final DocumentReference obatDanCairanDoc = FirebaseFirestore.instance
      .collection("user")
      .doc("QfAsyIkRTFuvNSy5YRaH")
      .collection("pasien")
      .doc('vJ0Wm7xmhr0OAPQ4ehNA')
      .collection("obat-cairan")
      .doc('z2vMj0CivJ1sgG9j85XT');

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

  void _navigateToInputPage() {
    Widget page;

    if (_tabController.index == 0) {
      page = InputObat(docRef: obatDanCairanDoc);
    } else {
      page = InputCairan(docRef: obatDanCairanDoc);
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
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
          "Obat & Cairan",
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
          tabs: const [
            Tab(icon: FaIcon(FontAwesomeIcons.pills), text: 'Obat'),
            Tab(icon: FaIcon(FontAwesomeIcons.syringe), text: 'Cairan Infus'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: obatDanCairanDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Data obat & cairan tidak ditemukan."),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final obatList = data['obat'] as List<dynamic>?;
          final cairanList = data['cairan'] as List<dynamic>?;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                items: obatList,
                itemBuilder: _buildObatCard,
                emptyDataIcon: FontAwesomeIcons.pills,
                emptyDataText: "Belum ada data obat",
              ),
              _buildTabContent(
                items: cairanList,
                itemBuilder: _buildCairanCard,
                emptyDataIcon: FontAwesomeIcons.syringe,
                emptyDataText: "Belum ada data cairan",
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToInputPage,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _tabController.index == 0 ? "Tambah Obat" : "Tambah Cairan",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent({
    required List<dynamic>? items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
    required IconData emptyDataIcon,
    required String emptyDataText,
  }) {
    if (items == null || items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(emptyDataIcon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyDataText,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return itemBuilder(item);
      },
    );
  }

  Widget _buildObatCard(Map<String, dynamic> item) {
    final String nama = item['nama'] ?? 'Nama tidak diketahui';
    final int dosis = item['dosis'] ?? 0;
    final Timestamp? timestamp = item['jam-pemberian'] as Timestamp?;

    final String waktuFormatted = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Waktu tidak tersedia';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          child: FaIcon(FontAwesomeIcons.pills, size: 20),
        ),
        title: Text(
          nama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text('Dosis: $dosis mg\nDiberikan: $waktuFormatted'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCairanCard(Map<String, dynamic> item) {
    final String nama = item['nama'] ?? 'Nama tidak diketahui';
    final int totalTetes = item['total-tetes'] ?? 0;
    final Timestamp? timestamp = item['jam-pemberian'] as Timestamp?;

    final String waktuFormatted = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Waktu tidak tersedia';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
          child: FaIcon(FontAwesomeIcons.syringe, size: 20),
        ),
        title: Text(
          nama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          'Tetesan: $totalTetes tetes/menit\nDiberikan: $waktuFormatted',
        ),
        isThreeLine: true,
      ),
    );
  }
}
