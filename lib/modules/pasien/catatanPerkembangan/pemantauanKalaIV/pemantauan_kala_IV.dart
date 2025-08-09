import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partograf/gradient_app_bar.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/pemantauanKalaIV/input_kala_IV.dart';

class PemantauanKalaIv extends StatelessWidget {
  const PemantauanKalaIv({super.key});

  @override
  Widget build(BuildContext context) {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection("user")
        .doc("QfAsyIkRTFuvNSy5YRaH")
        .collection("pasien")
        .doc('vJ0Wm7xmhr0OAPQ4ehNA')
        .collection("pemantauan_kala_IV")
        .doc('sQgI7A5AcbeL2OCf5wnM');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: const GradientAppBar(title: 'Pemantauan Kala IV'),
      ),
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: docRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi Kesalahan"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Data tidak ditemukan"));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                if (data['kala_IV'] == null ||
                    data['kala_IV'] is! List ||
                    (data['kala_IV'] as List).isEmpty) {
                  return const Center(
                    child: Text("Belum ada data pemantauan."),
                  );
                }

                final List<dynamic> listKalaIV = data['kala_IV'];

                return ListView.builder(
                  itemCount: listKalaIV.length,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemBuilder: (context, index) {
                    final kalaIVData =
                        listKalaIV[index] as Map<String, dynamic>;

                    String jamPemeriksaanFormatted = '-';
                    if (kalaIVData['jam_pemeriksaan'] != null &&
                        kalaIVData['jam_pemeriksaan'] is Timestamp) {
                      jamPemeriksaanFormatted =
                          DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(
                            (kalaIVData['jam_pemeriksaan'] as Timestamp)
                                .toDate(),
                          );
                    }

                    String tekananDarahFormatted = '-';
                    if (kalaIVData['tekanan_darah'] != null &&
                        kalaIVData['tekanan_darah'] is Map) {
                      final tekananMap =
                          kalaIVData['tekanan_darah'] as Map<String, dynamic>;
                      tekananDarahFormatted =
                          '${tekananMap['sistolik'] ?? '..'} / ${tekananMap['diastolik'] ?? '..'}';
                    }

                    final tinggiFundus =
                        kalaIVData['tinggi_fundus_uteri']?.toString() ?? '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInfoRow(
                              icon: Icons.access_time_filled_rounded,
                              color: Colors.blue.shade600,
                              title: 'Waktu Pemeriksaan',
                              value: jamPemeriksaanFormatted,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              icon: Icons.favorite_rounded,
                              color: Colors.red.shade500,
                              title: 'Tekanan Darah',
                              value: '$tekananDarahFormatted mmHg',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.straighten_rounded,
                              color: Colors.teal.shade500,
                              title: 'Tinggi Fundus Uteri',
                              value: '$tinggiFundus cm',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputKalaIv(docRef: docRef),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tambahkan Pemantauan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
