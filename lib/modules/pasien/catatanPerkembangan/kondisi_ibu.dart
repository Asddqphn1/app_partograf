import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KondisiIbu extends StatelessWidget {
  const KondisiIbu({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentReference kondisiIbuDoc = FirebaseFirestore.instance
        .collection("user")
        .doc("QfAsyIkRTFuvNSy5YRaH")
        .collection("pasien")
        .doc('vJ0Wm7xmhr0OAPQ4ehNA')
        .collection("kondisi_ibu")
        .doc('ndPImv4ytlfvxxolbA4b');

    return Scaffold(
      appBar: AppBar(title: const Text("Kondisi Ibu")),
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

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (nadiList != null)
                ...nadiList.map((nadiItem) {
                  DateTime jamPemeriksaan = (nadiItem['jam-pemeriksaan'] as Timestamp).toDate();
                  String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(jamPemeriksaan);
                  DateTime jamSelesai = (nadiItem['jam-selesai'] as Timestamp).toDate();
                  String formattedEndTime = DateFormat('dd/MM/yyyy HH:mm').format(jamSelesai);
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: const Text('Nadi', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'BPM: ${nadiItem['hasilBPM'] ?? '-'} \n'
                        'Jam Pemeriksaan: $formattedTime \n'
                        'Jam Selesai: $formattedEndTime',
                      ),
                    ),
                  );
                }).toList(),

              if (suhuList != null)
                ...suhuList.map((suhuItem) {
                  DateTime jamPemeriksaan = (suhuItem['jam_pemeriksaan'] as Timestamp).toDate();
                  String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(jamPemeriksaan);
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: const Text('Suhu', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Suhu: ${suhuItem['suhu'] ?? '-'} °C \n'
                        'Jam Pemeriksaan: $formattedTime',
                      ),
                    ),
                  );
                }).toList(),

              if (tdList != null)
                ...tdList.map((tdItem) {
                  DateTime jamPemeriksaan = (tdItem['jam-pemeriksaan'] as Timestamp).toDate();
                  String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(jamPemeriksaan);
                  final tekananData = tdItem['tekanan'] as Map<String, dynamic>?;
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: const Text('Tekanan Darah', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Jam Pemeriksaan: $formattedTime \n'
                        'Diastolik: ${tekananData?['diastolik'] ?? '-'} mmHg \n'
                        'Sistolik: ${tekananData?['sistolik'] ?? '-'} mmHg',
                      ),
                    ),
                  );
                }).toList(),
              
              if (urineList != null)
                ...urineList.map((urineItem) {
                  // Perhatikan perbaikan nama field di sini
                  DateTime jamPemeriksaan = (urineItem['jam_pemeriksaan'] as Timestamp).toDate();
                  String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(jamPemeriksaan);
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: const Text(
                        'Urine',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Aseton: ${urineItem['aseton'] ?? '-'} \n'
                        'Jam Pemeriksaan: $formattedTime'
                        'Protein: ${urineItem['protein'] ?? '-'} \n'
                        'Volume: ${urineItem['volume'] ?? '-'} ml \n'
                      ),
                    ),
                  );
                }).toList(),
            ],
          );
        },
      ),
    );
  }
}