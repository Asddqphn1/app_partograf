import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:partograf/modules/home/welcome_screen.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kemajuan_persalinan.dart';
import 'package:partograf/modules/pasien/detail_pasien.dart';
import 'package:partograf/modules/pasien/input_pasien.dart';
import 'package:partograf/modules/pasien/partograft_pasien/grapic.dart';
import 'package:partograf/modules/pasien/partograft_pasien/kontraksi_graph.dart';

import '../pasien/partograft_pasien/kondisi_ibu_graph.dart';

class Home extends StatefulWidget {
  final String user;
  Home({super.key, required this.user});

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = widget.firestore.collection('user').doc(widget.user).get();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPartograf(String userId, String pasienId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PilihGrafikScreen(
          userId: userId,
          pasienId: pasienId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
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
          String userName = data['nama'] ?? 'Bidan';
          String userEmail = data['email'] ?? 'Tidak ada email';

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 220.0),
                  child: _buildPatientList(
                    onPatientTap: (userId, pasienId) {
                      if (_selectedIndex == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPasien(
                              pasienId: pasienId,
                              userId: userId,
                            ),
                          ),
                        );
                      } else {
                        _navigateToPartograf(userId, pasienId);
                      }
                    },
                  ),
                ),
                _buildHeader(userName, userEmail, context),
              ],
            ),
            bottomNavigationBar: BottomAppBar(
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _buildNavItem(
                        icon: Icons.home, label: 'Home', index: 0),
                    _buildAddPatientButton(),
                    _buildNavItem(
                        icon: Icons.graphic_eq, label: 'Partograf', index: 1),
                  ],
                ),
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: Text('User tidak ditemukan.')),
        );
      },
    );
  }

  Widget _buildAddPatientButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InputPasien(userId: widget.user),
          ),
        );
      },
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFF8ABEB),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: _selectedIndex == index ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _selectedIndex == index ? Colors.blue : Colors.grey,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList({
    required void Function(String userId, String pasienId) onPatientTap,
  }) {
    final Stream<QuerySnapshot> pasienStream = FirebaseFirestore.instance
        .collection('user')
        .doc(widget.user)
        .collection('pasien')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: pasienStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['nama']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return name.contains(query);
        }).toList();

        if (documents.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return const Center(child: Text("Pasien tidak ditemukan."));
          }
          return const Center(child: Text("Belum ada data pasien."));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 80),
          itemCount: documents.length,
          separatorBuilder: (context, index) => const Divider(
            color: Color.fromARGB(255, 224, 224, 224),
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            String userId = widget.user;
            String pasienId = doc.id;

            final tanggal = data['tanggal_pemeriksaan'] as Timestamp?;
            String registerDate = '-';
            if (tanggal != null) {
              registerDate = DateFormat('yyyy/MM/dd').format(tanggal.toDate());
            }

            return InkWell(
              onTap: () => onPatientTap(userId, pasienId),
              borderRadius: BorderRadius.circular(15),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 3,
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
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_outline_rounded,
                              size: 80,
                              color: Colors.grey,
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
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No. Register: $registerDate',
                                style: const TextStyle(color: Colors.black54),
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

  Widget _buildHeader(String bidanName, String email, BuildContext context) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        height: 240,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8ABEB), Color(0xFFEDFADC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (newContext) => Scaffold(
                            appBar: AppBar(
                              title: const Text('Profil'),
                              backgroundColor: const Color(0xFFF8ABEB),
                            ),
                            body: _buildProfilePage(bidanName, email, context),
                          ),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white54,
                      child: Icon(
                        Icons.person_outline,
                        size: 30,
                        color: Color(0xFF2C2C6A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                        Text(
                          'Bidan $bidanName!',
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    'assets/images/bidan.png',
                    height: 90,
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
              const SizedBox(height: 20),
              Transform.translate(
                offset: const Offset(0, -12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari Nama',
                      hintStyle: TextStyle(color: Color(0xFF999999)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 19) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  Widget _buildProfilePage(String name, String email, BuildContext context) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Spacer(flex: 2),
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFFF8C9F5).withOpacity(0.5),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C6A),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C2C6A)),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Spacer(flex: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: ListTile(
              onTap: () {
                _logout();
              },
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              tileColor: Colors.red.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red.withOpacity(0.2)),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class PilihGrafikScreen extends StatefulWidget {
  final String userId;
  final String pasienId;

  const PilihGrafikScreen({
    super.key,
    required this.userId,
    required this.pasienId,
  });

  @override
  State<PilihGrafikScreen> createState() => _PilihGrafikScreenState();
}

class _PilihGrafikScreenState extends State<PilihGrafikScreen> {

  Future<void> _navigateToGrafikServiks() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Mengambil data partograf..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .collection('pasien')
          .doc(widget.pasienId)
          .collection('kemajuan_persalinan')
          .limit(1)
          .get();

      if (mounted) Navigator.of(context).pop();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dokumen kemajuan persalinan tidak ditemukan."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final docSnapshot = querySnapshot.docs.first;
      final data = docSnapshot.data();

      if (data.containsKey('pembukaan_serviks') &&
          data['pembukaan_serviks'] is List) {
        final List<dynamic> listData = data['pembukaan_serviks'];

        if (listData.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Tidak ada data pemeriksaan untuk ditampilkan."),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final List<CatatanServiks> catatanList = listData
            .map((item) => CatatanServiks.fromMap(item as Map<String, dynamic>))
            .toList();

        catatanList.sort(
              (a, b) => a.jamPemeriksaan.compareTo(b.jamPemeriksaan),
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartografView(dataPemeriksaan: catatanList),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Field 'pembukaan_serviks' tidak ditemukan atau formatnya salah.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengambil data: $e"), backgroundColor: Colors.red,));
    }
  }

  void _navigateToGrafikKontraksi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KontraksiGraphScreen(
          userId: widget.userId,
          pasienId: widget.pasienId,
        ),
      ),
    );
  }

  // --- 2. BUAT FUNGSI NAVIGASI BARU ---
  void _navigateToGrafikKondisiIbu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KondisiIbuGraphScreen(
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
        title: const Text('Pilih Partograf', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Menggunakan Column agar bisa menampung 3 item
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionCard(
              icon: Icons.show_chart,
              title: 'Pembukaan Serviks',
              subtitle: 'Grafik kemajuan pembukaan dan penurunan serviks.',
              onTap: _navigateToGrafikServiks,
              color: Colors.pink,
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              icon: Icons.waves,
              title: 'Kontraksi Uterus',
              subtitle: 'Grafik frekuensi dan durasi kontraksi per 10 menit.',
              onTap: _navigateToGrafikKontraksi,
              color: Colors.teal,
            ),
            // --- 3. TAMBAHKAN KARTU OPSI BARU ---
            const SizedBox(height: 20),
            _buildOptionCard(
              icon: Icons.monitor_heart, // Icon yang relevan
              title: 'Kondisi Ibu',
              subtitle: 'Grafik nadi dan tekanan darah ibu.',
              onTap: _navigateToGrafikKondisiIbu, // Panggil fungsi baru
              color: Colors.blue, // Warna yang berbeda
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
