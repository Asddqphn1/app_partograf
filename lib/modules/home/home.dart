import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partograf/modules/pasien/detail_pasien.dart';
import 'package:partograf/modules/pasien/input_pasien.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Menyimpan indeks item navbar yang dipilih

  // Fungsi untuk menangani pemilihan item navbar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menambahkan background warna abu-abu terang
      backgroundColor: Color(0xFFE9E9E9), // Latar belakang abu-abu terang
      // AppBar dengan gradient warna ungu dan biru
      appBar: AppBar(
        title: const Text('Daftar Pasien'),
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001BB7), Color(0xFF7B1FA2)], // Biru Royal ke Ungu Tua
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user')
              .doc('QfAsyIkRTFuvNSy5YRaH')
              .collection('pasien')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Terjadi kesalahan'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final documents = snapshot.data!.docs;

            if (documents.isEmpty) {
              return const Center(child: Text("Belum ada data pasien."));
            }

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final data = doc.data() as Map<String, dynamic>;
                final tanggal = data['tanggal_pemeriksaan'] as Timestamp;

                String formattedDate = '-';
                String registerDate = '-';
                if (tanggal != null) {
                  final date = tanggal.toDate();
                  formattedDate = DateFormat('dd-MM-yyyy').format(date);
                  registerDate = DateFormat('yyyy/MM/dd').format(date);
                }

                return Column(
                  children: [
                    // 💡 Bungkus Card dengan InkWell
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DetailPasien()),
                        );
                      },
                      // Atur borderRadius agar efek ripple sesuai dengan bentuk Card
                      borderRadius: BorderRadius.circular(15),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        elevation: 5,
                        // Penting: Set color Card menjadi transparent agar gradient dari Container terlihat
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF002B9E), Color(0xFF0046FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.account_circle,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['nama'],
                                          style: const TextStyle(fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white)),
                                      const SizedBox(height: 12),
                                      Text('Umur: ${data['umur'] ?? '-'} tahun',
                                          style: const TextStyle(color: Colors.white)),
                                      const SizedBox(height: 8),
                                      Text('No. Register: ${registerDate}',
                                          style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Garis pemisah setelah setiap card
                    const Divider(
                      color: Color(0xFFFF8040), // Warna garis
                      thickness: 1,         // Ketebalan garis
                      indent: 10,           // Jarak dari kiri
                      endIndent: 10,        // Jarak dari kanan
                    ),
                  ],
                );
              },
            );
          }),
      // Membuat BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // Menyembunyikan tombol '+' dari BottomNavigationBar
          BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq),
            label: 'Partograf',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // Warna background navbar
        selectedItemColor: Colors.blue, // Warna ikon yang dipilih
        unselectedItemColor: Colors.grey, // Warna ikon yang tidak dipilih
      ),
      // FloatingActionButton diletakkan di tengah
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputPasien()),
          );
        },
        backgroundColor: Color(0xFF0046FF),// Warna lingkaran tombol +
        child: const Icon(
          Icons.add,
          size: 30, // Ukuran ikon + lebih besar
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Menempatkan FAB di tengah
    );
  }
}
