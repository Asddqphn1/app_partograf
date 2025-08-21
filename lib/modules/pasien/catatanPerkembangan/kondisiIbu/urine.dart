import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InputUrine extends StatefulWidget {
  final DocumentReference docRef;
  const InputUrine({super.key, required this.docRef});

  @override
  State<InputUrine> createState() => _InputUrineState();
}

class _InputUrineState extends State<InputUrine> {
  final _formKey = GlobalKey<FormState>();
  final _asetonController = TextEditingController();
  final _proteinController = TextEditingController();
  final _volumeController = TextEditingController();
  final _jamPemeriksaanController = TextEditingController();

  DateTime? _selectedJamPemeriksaan;
  bool _isLoading = false;

  @override
  void dispose() {
    _asetonController.dispose();
    _proteinController.dispose();
    _volumeController.dispose();
    _jamPemeriksaanController.dispose();
    super.dispose();
  }

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
      _selectedJamPemeriksaan = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _jamPemeriksaanController.text = DateFormat(
        'dd MMM yyyy, HH:mm',
      ).format(_selectedJamPemeriksaan!);
    });
  }

  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final newUrineData = {
        'jam_pemeriksaan': Timestamp.fromDate(_selectedJamPemeriksaan!),
        'aseton': int.tryParse(_asetonController.text) ?? 0,
        'protein': int.tryParse(_proteinController.text) ?? 0,
        'volume': int.tryParse(_volumeController.text) ?? 0,
      };

      try {
        await widget.docRef.update({
          'urine': FieldValue.arrayUnion([newUrineData]),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Urine berhasil disimpan!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah data urine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              // PERUBAIKAN: Urutan diubah, jam di atas
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
              TextFormField(
                controller: _asetonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aseton',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protein',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _volumeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Volume (ml)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
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