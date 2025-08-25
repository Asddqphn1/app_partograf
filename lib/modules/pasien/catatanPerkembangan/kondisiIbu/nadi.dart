import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class InputNadi extends StatefulWidget {
  final DocumentReference docRef;
  const InputNadi({super.key, required this.docRef});

  @override
  State<InputNadi> createState() => _InputNadiState();
}

class _InputNadiState extends State<InputNadi> {
  final _formKey = GlobalKey<FormState>();
  final _bpmController = TextEditingController();
  final _jamPemeriksaanController = TextEditingController();

  DateTime? _selectedJamPemeriksaan;
  bool _isLoading = false;

  @override
  void dispose() {
    _bpmController.dispose();
    _jamPemeriksaanController.dispose();
    super.dispose();
  }

  // --- FUNGSI DIPERBARUI: Disederhanakan untuk satu input waktu ---
  Future<void> _pilihWaktu(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (pickedTime == null) return;

    setState(() {
      final selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      final formattedDateTime = DateFormat(
        'dd MMM yyyy, HH:mm',
      ).format(selectedDateTime);

      _selectedJamPemeriksaan = selectedDateTime;
      _jamPemeriksaanController.text = formattedDateTime;
    });
  }

  // --- FUNGSI DIPERBARUI: Hanya menyimpan data yang relevan ---
  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Data yang disimpan kini lebih sederhana
      final newNadiData = {
        'hasilBPM': int.tryParse(_bpmController.text) ?? 0,
        'jam-pemeriksaan': Timestamp.fromDate(_selectedJamPemeriksaan!),
      };

      try {
        // Menggunakan set dengan merge:true agar dokumen dibuat jika belum ada
        await widget.docRef.set({
          'nadi': FieldValue.arrayUnion([newNadiData]),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Nadi berhasil disimpan!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah data nadi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8ABEB), Color(0xFFEEF1DD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _jamPemeriksaanController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Jam Pemeriksaan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _pilihWaktu(context),
                validator: (value) => value == null || value.isEmpty
                    ? 'Pilih waktu pemeriksaan'
                    : null,
              ),
              const SizedBox(height: 16),
              // --- WIDGET DIHAPUS: Input Jam Selesai sudah tidak ada ---
              TextFormField(
                controller: _bpmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hasil BPM',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B), // Pink lebih gelap
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
