import 'package:flutter/material.dart';
import 'package:partograf/modules/home/home.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kemajuan_persalinan.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kondisi_janin.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/obatDanCairan/obat_dan_cairan.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/pemantauanKalaIV/pemantauan_kala_IV.dart';

class DetailPasien extends StatelessWidget {
  String pasienId;
  String userId;
  DetailPasien({super.key, required this.pasienId, required this.userId});

  @override
  Widget build(BuildContext context) {
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
      // Mengubah warna background agar sesuai dengan gambar referensi
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catatan Perkembangan'),
        backgroundColor: Colors.transparent, // Membuat AppBar transparan
        elevation: 0, // Menghilangkan bayangan
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E44AD),
                Color(0xFFF8ABEB),
              ], // Gradient ungu ke pink
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // Mengganti ListView dengan GridView
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        // Konfigurasi grid
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 kolom
          crossAxisSpacing: 16, // Jarak horizontal antar item
          mainAxisSpacing: 16, // Jarak vertikal antar item
          childAspectRatio: 1, // Membuat item menjadi persegi
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          // Menggunakan widget baru untuk item grid
          return _buildMenuGridItem(
            context: context,
            title: item['title'],
            icon: item['icon'],
            iconColor: item['color'],
            onTap: () {
              // Logika navigasi tetap sama
              final String title = item['title'];
              Widget destinationPage;

              switch (title) {
                case 'Kemajuan Persalinan':
                  destinationPage = KemajuanPersalinan(
                    userId: userId,
                    pasienId: pasienId,
                  );
                  break;
                case 'Kondisi Janin':
                  destinationPage = const KondisiJanin();
                  break;
                case 'Obat dan Cairan':
                  destinationPage =  ObatDanCairan(
                    userId: userId,
                    pasienId: pasienId,
                  );
                  break;
                case 'Pemantauan Kala IV':
                  destinationPage = PemantauanKalaIv(
                    userId: userId,
                    pasienId: pasienId,
                  );
                  break;
                default:
                  destinationPage = Home(user: userId);
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

  /// Widget helper BARU untuk membuat item grid yang kotak
  Widget _buildMenuGridItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      // Warna kartu pink seperti pada gambar
      color: const Color(0xFFFDECF4),
      shadowColor: Colors.pink.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // Menambahkan border seperti pada gambar
        side: BorderSide(color: Colors.pink.shade100, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lingkaran putih untuk ikon
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 12),
              // Judul item
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
