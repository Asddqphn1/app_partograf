import 'package:flutter/material.dart';
import 'package:partograf/modules/home/home.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kemajuan_persalinan.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kondisi_ibu.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kondisi_janin.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/obat_dan_cairan.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/pemantauan_kala_IV.dart ';

class DetailPasien extends StatelessWidget {
  const DetailPasien({super.key});

  @override
  Widget build(BuildContext context) {
    // Data untuk list menu, bisa juga diambil dari model atau API
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Kemajuan Persalinan',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      {
        'title': 'Kondisi Ibu',
        'icon': Icons.pregnant_woman,
        'color': Colors.pink,
      },
      {
        'title': 'Kondisi Janin',
        'icon': Icons.child_care,
        'color': Colors.green,
      },
      {
        'title': 'Obat dan Cairan',
        'icon': Icons.medical_services,
        'color': Colors.orange,
      },
      {
        'title': 'Pemantauan Kala IV',
        'icon': Icons.watch_later,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        title: const Text('Catatan Perkembangan'),
        backgroundColor: Color(0xFFE9E9E9),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF001BB7),
                Color(0xFF7B1FA2),
              ], // Biru Royal ke Ungu Tua
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildDetailCard(
            context: context,
            title: item['title'],
            icon: item['icon'],
            iconColor: item['color'],
            onTap: () {
              final String title = item['title'];

              Widget destinationPage;

              switch (title) {
                case 'Kemajuan Persalinan':
                  destinationPage = const KemajuanPersalinan();
                  break;
                case 'Kondisi Ibu':
                  destinationPage = const KondisiIbu();
                  break;
                case 'Kondisi Janin':
                  destinationPage = const KondisiJanin();
                  break;
                case 'Obat dan Cairan':
                  destinationPage = const ObatDanCairan();
                  break;
                case 'Pemantauan Kala IV':
                  destinationPage = const PemantauanKalaIv();
                  break;
                default:
                  destinationPage = const Home();
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destinationPage),
              );
            },
          );
        },
      ),
    );
  }

  /// Widget helper untuk membuat card menu yang seragam
  Widget _buildDetailCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
