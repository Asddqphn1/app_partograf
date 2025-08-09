import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partograf/gradient_app_bar.dart';

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
  final _jamSelesaiController = TextEditingController();

  DateTime? _selectedJamPemeriksaan;
  DateTime? _selectedJamSelesai;
  bool _isLoading = false;

  @override
  void dispose() {
    _bpmController.dispose();
    _jamPemeriksaanController.dispose();
    _jamSelesaiController.dispose();
    super.dispose();
  }

  Future<void> _pilihWaktu(
    BuildContext context, {
    required bool isPemeriksaan,
  }) async {
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

      if (isPemeriksaan) {
        _selectedJamPemeriksaan = selectedDateTime;
        _jamPemeriksaanController.text = formattedDateTime;
      } else {
        _selectedJamSelesai = selectedDateTime;
        _jamSelesaiController.text = formattedDateTime;
      }
    });
  }

  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newNadiData = {
        'hasilBPM': int.tryParse(_bpmController.text) ?? 0,
        'jam-pemeriksaan': Timestamp.fromDate(_selectedJamPemeriksaan!),
        'jam-selesai': Timestamp.fromDate(_selectedJamSelesai!),
      };

      try {
        await widget.docRef.update({
          'nadi': FieldValue.arrayUnion([newNadiData]),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Nadi berhasil disimpan!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Tambah Data Nadi'),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _jamPemeriksaanController,
                label: 'Jam Pemeriksaan',
                hint: 'Pilih waktu mulai',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _pilihWaktu(context, isPemeriksaan: true),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _jamSelesaiController,
                label: 'Jam Selesai',
                hint: 'Pilih waktu selesai',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _pilihWaktu(context, isPemeriksaan: false),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bpmController,
                label: 'Hasil Nadi (BPM)',
                hint: 'cth: 80',
                icon: Icons.monitor_heart_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2185B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Simpan Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey.shade600)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 12.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFC2185B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label wajib diisi';
        }
        return null;
      },
    );
  }
}
