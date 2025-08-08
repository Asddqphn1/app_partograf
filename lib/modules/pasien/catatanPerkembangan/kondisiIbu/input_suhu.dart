import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partograf/gradient_app_bar.dart';

class InputSuhu extends StatefulWidget {
  final DocumentReference docRef;
  const InputSuhu({super.key, required this.docRef});

  @override
  State<InputSuhu> createState() => _InputSuhuState();
}

class _InputSuhuState extends State<InputSuhu> {
  final _formKey = GlobalKey<FormState>();
  final _suhuController = TextEditingController();
  final _jamPemeriksaanController = TextEditingController();

  DateTime? _selectedJamPemeriksaan;
  bool _isLoading = false;

  @override
  void dispose() {
    _suhuController.dispose();
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
      final newSuhuData = {
        'suhu': double.tryParse(_suhuController.text) ?? 0.0,
        'jam_pemeriksaan': Timestamp.fromDate(_selectedJamPemeriksaan!),
      };

      try {
        await widget.docRef.update({
          'suhu': FieldValue.arrayUnion([newSuhuData]),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Suhu berhasil disimpan!')),
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
      appBar: const GradientAppBar(title: 'Tambah Data Suhu'),
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
                controller: _suhuController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Suhu (°C)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.thermostat),
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
