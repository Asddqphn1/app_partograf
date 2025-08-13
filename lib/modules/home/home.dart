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

class Home extends StatefulWidget {
  final String user;
  Home({super.key, required this.user});

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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

  Future<void> _navigateToPartograf(String userId, String pasienId) async {
    // Tampilkan dialog loading
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
      // Ambil data dari sub-collection 'catatan_serviks'
      final snapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.user)
          .collection('pasien')
          .doc(pasienId)
          .collection(
            'catatan_serviks',
          ) // Pastikan nama sub-collection ini benar
          .orderBy('jam_pemeriksaan')
          .get();

      // Ubah setiap dokumen menjadi objek CatatanServiks
      final List<CatatanServiks> catatanList = snapshot.docs
          .map((doc) => CatatanServiks.fromMap(doc.data()))
          .toList();

      if (mounted) Navigator.of(context).pop(); // Tutup dialog loading

      // Navigasi ke halaman grafik dengan membawa data yang sudah diambil
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartografView(dataPemeriksaan: catatanList),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Tutup dialog loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengambil data: $e")));
    }
  }
  @override
  Widget build(BuildContext context) {
    DocumentReference userDoc = widget.firestore
        .collection('user')
        .doc(widget.user);

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc.get(),
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

              final List<Widget> _pages = <Widget>[
                // Page 0: Home Screen (navigates to DetailPasien)
                Stack(
                  children: [
                    _buildHeader(userName, userEmail, context),
                    Padding(
                      padding: const EdgeInsets.only(top: 220.0),
                      child: _buildPatientList(
                        onPatientTap: (userId, pasienId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPasien(
                                pasienId: pasienId,
                                userId: userId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSearchBar(),
                  ],
                ),

                // Page 1: Partograf Screen
                Scaffold(
                  appBar: AppBar(
                    title: const Text('Pilih Pasien untuk Partograf'),
                    backgroundColor: const Color(0xFFF8ABEB),
                    automaticallyImplyLeading: false,
                  ),
                  body: _buildPatientList(
                    // PERUBAHAN DI SINI: Memanggil fungsi _navigateToPartograf
                    onPatientTap: (userId, pasienId) {
                      _navigateToPartograf(widget.user, pasienId);
                    },
                  ),
                ),
              ];

              return Scaffold(
                backgroundColor: const Color(0xFFF4F6F9),
                body: _pages[_selectedIndex],
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
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
                floatingActionButton: _selectedIndex == 0
                    ? FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InputPasien(userId: widget.user,),
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFFF8ABEB),
                        child: const Icon(
                          Icons.add,
                          size: 30,
                          color: Colors.white,
                        ),
                      )
                    : null,
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

  Widget _buildPatientList({
    required void Function(String userId, String pasienId) onPatientTap,
  }) {
    final Stream<QuerySnapshot> pasienStream = FirebaseFirestore.instance
        .collection('user')
        .doc(widget.user) // Ganti dengan ID user yang sesuai
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
        final documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return const Center(child: Text("Belum ada data pasien."));
        }

        return ListView.separated(
          padding: _selectedIndex == 0
              ? const EdgeInsets.fromLTRB(10, 20, 10, 20)
              : const EdgeInsets.all(8.0),
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
                              Icons.person_outline,
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
        padding: const EdgeInsets.fromLTRB(20, 40, 5, 0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8ABEB), Color(0xFFEDFADC)],
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
                  const SizedBox(height: 10),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
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
            IconButton(
              icon: const Icon(
                Icons.account_circle,
                size: 40,
                color: Colors.white,
              ),
              onPressed: () {
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
            ),
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

  Widget _buildSearchBar() {
    return Positioned(
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

  Widget _buildProfilePage(String name, String email, BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
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
