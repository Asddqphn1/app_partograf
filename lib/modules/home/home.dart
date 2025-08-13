import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partograf/modules/pasien/detail_pasien.dart';
import 'package:partograf/modules/pasien/input_pasien.dart';

class Home extends StatefulWidget {
  Home({super.key});

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final String userId = 'QfAsyIkRTFuvNSy5YRaH';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference userDoc = widget.firestore
        .collection('user')
        .doc(widget.userId);

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc.get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        // --- State Handling ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Gagal memuat data.')),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          String userName = data['nama'] ?? 'Bidan'; // Ambil nama user

          // --- UI UTAMA DIBANGUN DI SINI ---
          return Scaffold(
            backgroundColor: Color(0xFFF4F6F9), // Warna background body
            body: Stack(
              children: [
                _buildHeader(userName),

                Padding(
                  // Beri padding atas agar konten tidak tertutup header & search bar
                  padding: const EdgeInsets.only(top: 220.0),
                  child:
                      _buildPatientList(), // Ganti dengan daftar pasien Anda nanti
                ),

                // Search Bar diposisikan di atas tumpukan
                _buildSearchBar(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),

                BottomNavigationBarItem(
                  icon: Icon(Icons.graphic_eq),
                  label: 'Partograf',
                ),
              ],
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),

            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InputPasien()),
                );
              },
              backgroundColor: Color(0xFFF8ABEB),
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          );
        }

        return const Scaffold(
          body: Center(child: Text('User tidak ditemukan.')),
        );
      },
    );
  }

  // WIDGET UNTUK MEMBANGUN HEADER
  Widget _buildHeader(String bidanName) {
    return ClipPath(
      clipper: HeaderClipper(), // Clipper untuk membuat bentuk melengkung
      child: Container(
        height: 240, // Tinggi header
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Pagi',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bidan $bidanName!',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Gambar bidan di pojok kanan atas
            Image.asset(
              'assets/images/bidan.png',
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white24,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET UNTUK SEARCH BAR
  Widget _buildSearchBar() {
    return Positioned(
      // Atur posisi search bar agar berada di area lengkungan
      top: 165,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Cari Nama',
            icon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // Placeholder untuk daftar pasien
  Widget _buildPatientList() {
    // Path ke koleksi pasien, dibuat dinamis menggunakan userId dari bidan yang login
    final Stream<QuerySnapshot> pasienStream = FirebaseFirestore.instance
        .collection('user')
        .doc('QfAsyIkRTFuvNSy5YRaH')
        .collection('pasien')
        .snapshots();

    // Gunakan StreamBuilder untuk "mendengarkan" data dari Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: pasienStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // 1. Tangani jika ada error saat mengambil data
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan.'));
        }

        // 2. Tampilkan loading indicator saat data sedang diambil
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 3. Jika data sudah datang, ambil daftar dokumennya
        final documents = snapshot.data!.docs;

        // 4. Tangani jika tidak ada satupun dokumen (data pasien kosong)
        if (documents.isEmpty) {
          return const Center(child: Text("Belum ada data pasien."));
        }

        // 5. Jika semua aman dan data ada, bangun ListView.separated
        // ListView.separated lebih efisien untuk daftar dengan pemisah
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
          itemCount: documents.length,
          // separatorBuilder membangun pemisah antar item
          separatorBuilder: (context, index) => const Divider(
            color: Color(0xFFFF8040),
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          // itemBuilder membangun setiap card pasien
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            String userId = 'QfAsyIkRTFuvNSy5YRaH';
            String pasienId = doc.id;

            // Logika untuk memformat tanggal
            final tanggal = data['tanggal_pemeriksaan'] as Timestamp?;
            String registerDate = '-';
            if (tanggal != null) {
              registerDate = DateFormat('yyyy/MM/dd').format(tanggal.toDate());
            }

            // Return widget Card Anda di sini
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailPasien(pasienId: pasienId, userId: userId),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 4,
                ), // Margin vertikal lebih kecil
                elevation: 5,
                color: Colors.transparent, // Biarkan container yang menghias
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/pasien.png',
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white24,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['nama'] ?? 'Tanpa Nama',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Umur: ${data['umur'] ?? '-'} tahun',
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No. Register: $registerDate',
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// CLASS UNTUK MEMBUAT BENTUK LENGKUNG PADA HEADER
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50); // Mulai dari kiri bawah (dengan offset)
    path.quadraticBezierTo(
      size.width / 2, // Titik kontrol tengah
      size.height, // Puncak lengkungan
      size.width, // Titik akhir di kanan bawah
      size.height - 50,
    );
    path.lineTo(size.width, 0); // Garis ke kanan atas
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
