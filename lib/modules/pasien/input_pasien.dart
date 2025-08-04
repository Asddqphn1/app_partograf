import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InputPasien extends StatefulWidget {
  const InputPasien({super.key});

  @override
  State<InputPasien> createState() => _InputPasienState();
}

class _InputPasienState extends State<InputPasien> {
  final _formKey = GlobalKey<FormState>();

  // --- Controller & State ---
  final _namaController = TextEditingController();
  final _umurController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noPuskesmasController = TextEditingController();
  final _noRegisterController = TextEditingController();
  final _tanggalPemeriksaanController = TextEditingController();
  final _jamKetubanPecahController = TextEditingController();
  final _jamMulesController = TextEditingController();

  bool? _isKetubanPecah;
  // PERUBAHAN: Semua state tanggal sekarang adalah DateTime lengkap
  DateTime? _selectedDateTimePemeriksaan;
  DateTime? _selectedDateTimeKetubanPecah;
  DateTime? _selectedDateTimeMules;

  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _umurController.dispose();
    _alamatController.dispose();
    _noPuskesmasController.dispose();
    _noRegisterController.dispose();
    _tanggalPemeriksaanController.dispose();
    _jamKetubanPecahController.dispose();
    _jamMulesController.dispose();
    super.dispose();
  }

  // --- Fungsi untuk memilih Tanggal DAN Jam ---
  // Fungsi ini sekarang akan digunakan oleh semua field tanggal/jam
  Future<DateTime?> _pilihTanggalDanJam(BuildContext context, DateTime? initialDate) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Pilih Tanggal',
    );

    if (date == null) return null;
    if (!mounted) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      helpText: 'Pilih Jam',
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // --- Fungsi Simpan Data ---
  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final dataPasien = {
        'nama': _namaController.text,
        'umur': int.tryParse(_umurController.text) ?? 0,
        'alamat': _alamatController.text,
        'no_puskesmas': _noPuskesmasController.text,
        'no_register': _noRegisterController.text,
        'is_ketuban_pecah': _isKetubanPecah ?? false,

        // Langsung gunakan state DateTime yang sudah lengkap untuk semua field
        'tanggal_pemeriksaan': _selectedDateTimePemeriksaan != null ? Timestamp.fromDate(_selectedDateTimePemeriksaan!) : null,
        'jam_ketuban_pecah': _selectedDateTimeKetubanPecah != null ? Timestamp.fromDate(_selectedDateTimeKetubanPecah!) : null,
        'jam_mules': _selectedDateTimeMules != null ? Timestamp.fromDate(_selectedDateTimeMules!) : null,
      };

      try {
        await FirebaseFirestore.instance.collection('user').doc('QfAsyIkRTFuvNSy5YRaH').collection('pasien').add(dataPasien);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data pasien berhasil disimpan!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      appBar: AppBar(
        title: const Text('Input Data Pasien'),
        backgroundColor: Color(0xFFE9E9E9),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [

            TextFormField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Pasien', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _umurController, decoration: const InputDecoration(labelText: 'Umur', border: OutlineInputBorder(), prefixIcon: Icon(Icons.cake)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Umur tidak boleh kosong' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _alamatController, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)), maxLines: 3, validator: (v) => v!.isEmpty ? 'Alamat tidak boleh kosong' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _noPuskesmasController, decoration: const InputDecoration(labelText: 'No. Puskesmas', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_hospital)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'No. Puskesmas tidak boleh kosong' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _noRegisterController, decoration: const InputDecoration(labelText: 'No. Register', border: OutlineInputBorder(), prefixIcon: Icon(Icons.app_registration)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'No. Register tidak boleh kosong' : null),
            const SizedBox(height: 16),

            // PERUBAHAN: Field Tanggal Pemeriksaan
            TextFormField(
              controller: _tanggalPemeriksaanController,
              decoration: const InputDecoration(
                labelText: 'Tanggal & Jam Pemeriksaan', // Label diubah
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                // Menggunakan fungsi yang sama
                final pickedDateTime = await _pilihTanggalDanJam(context, _selectedDateTimePemeriksaan);
                if (pickedDateTime != null) {
                  setState(() {
                    _selectedDateTimePemeriksaan = pickedDateTime;
                    _tanggalPemeriksaanController.text = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(pickedDateTime);
                  });
                }
              },
              validator: (v) => v!.isEmpty ? 'Tanggal & Jam pemeriksaan tidak boleh kosong' : null,
            ),
            const SizedBox(height: 24),

            // Opsi Ya/Tidak (tetap sama)
            FormField<bool>(
              initialValue: _isKetubanPecah,
              validator: (value) => value == null ? 'Anda harus memilih salah satu' : null,
              builder: (FormFieldState<bool> state) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Apakah Ketuban Pecah?', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () { setState(() { _isKetubanPecah = true; }); state.didChange(true);}, style: OutlinedButton.styleFrom(backgroundColor: state.value == true ? Colors.purple.withOpacity(0.1) : null, side: BorderSide(color: state.value == true ? Colors.purple : Colors.grey)), child: const Text('Ya'))),
                    const SizedBox(width: 16),
                    Expanded(child: OutlinedButton(onPressed: () { setState(() { _isKetubanPecah = false; _selectedDateTimeKetubanPecah = null; _jamKetubanPecahController.clear(); }); state.didChange(false);}, style: OutlinedButton.styleFrom(backgroundColor: state.value == false ? Colors.purple.withOpacity(0.1) : null, side: BorderSide(color: state.value == false ? Colors.purple : Colors.grey)), child: const Text('Tidak'))),
                  ]),
                  if (state.hasError) Padding(padding: const EdgeInsets.only(top: 8.0, left: 12.0), child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
                ]);
              },
            ),
            const SizedBox(height: 16),

            // Tampilkan field ini jika "Ya"
            if (_isKetubanPecah == true)
              Column(children: [
                TextFormField(
                  controller: _jamKetubanPecahController,
                  decoration: const InputDecoration(labelText: 'Tanggal & Jam Ketuban Pecah', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                  readOnly: true,
                  onTap: () async {
                    final pickedDateTime = await _pilihTanggalDanJam(context, _selectedDateTimeKetubanPecah);
                    if (pickedDateTime != null) {
                      setState(() {
                        _selectedDateTimeKetubanPecah = pickedDateTime;
                        _jamKetubanPecahController.text = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(pickedDateTime);
                      });
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Tanggal & Jam harus diisi' : null,
                ),
                const SizedBox(height: 16),
              ]),

            TextFormField(
              controller: _jamMulesController,
              decoration: const InputDecoration(labelText: 'Tanggal & Jam Mulai Mules', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer)),
              readOnly: true,
              onTap: () async {
                final pickedDateTime = await _pilihTanggalDanJam(context, _selectedDateTimeMules);
                if (pickedDateTime != null) {
                  setState(() {
                    _selectedDateTimeMules = pickedDateTime;
                    _jamMulesController.text = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(pickedDateTime);
                  });
                }
              },
              validator: (v) => v!.isEmpty ? 'Tanggal & Jam mules tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _simpanData,
              style: ElevatedButton.styleFrom(backgroundColor:Color(0xFF0046FF), padding: const EdgeInsets.symmetric(vertical: 16.0), textStyle: const TextStyle(fontSize: 18)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Data', style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }
}