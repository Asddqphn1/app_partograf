import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:partograf/gradient_app_bar.dart';

class InputKalaIv extends StatefulWidget {
  final DocumentReference docRef;
  const InputKalaIv({super.key, required this.docRef});

  @override
  State<InputKalaIv> createState() => _InputKalaIvState();
}

class _InputKalaIvState extends State<InputKalaIv> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime? _selectedJamPemeriksaan;

  final _jamPemeriksaanController = TextEditingController();
  final _sistolikController = TextEditingController();
  final _diastolikController = TextEditingController();
  final _tinggiFundusController = TextEditingController();
  final _kontraksiController = TextEditingController();
  final _nadiController = TextEditingController();
  final _suhuController = TextEditingController();
  final _darahKeluarController = TextEditingController();
  final _urineController = TextEditingController();

  @override
  void dispose() {
    _jamPemeriksaanController.dispose();
    _sistolikController.dispose();
    _diastolikController.dispose();
    _tinggiFundusController.dispose();
    _kontraksiController.dispose();
    _nadiController.dispose();
    _suhuController.dispose();
    _darahKeluarController.dispose();
    _urineController.dispose();
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
        'id_ID',
      ).format(_selectedJamPemeriksaan!);
    });
  }

  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newKalaIVEntry = {
        'jam_pemeriksaan': Timestamp.fromDate(_selectedJamPemeriksaan!),
        'tekanan_darah': {
          'sistolik': int.tryParse(_sistolikController.text) ?? 0,
          'diastolik': int.tryParse(_diastolikController.text) ?? 0,
        },
        'tinggi_fundus_uteri': int.tryParse(_tinggiFundusController.text) ?? 0,
        'kontraksi_uterus': int.tryParse(_kontraksiController.text) ?? 0,
        'nadi': int.tryParse(_nadiController.text) ?? 0,
        'suhu': double.tryParse(_suhuController.text) ?? 0.0,
        'jumlah_darah_keluar': int.tryParse(_darahKeluarController.text) ?? 0,
        'jumlah_urin': int.tryParse(_urineController.text) ?? 0,
      };

      try {
        await widget.docRef.set({
          'kala_IV': FieldValue.arrayUnion([newKalaIVEntry]),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan!')),
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
      appBar: const GradientAppBar(title: 'Input Pemantauan Kala IV'),
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
                hint: 'Pilih waktu',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () => _pilihWaktu(context),
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'Tekanan Darah (mmHg)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC2185B),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _sistolikController,
                          label: 'Sistolik',
                          hint: 'cth: 120',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _diastolikController,
                          label: 'Diastolik',
                          hint: 'cth: 80',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nadiController,
                label: 'Nadi',
                hint: 'kali/menit',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _suhuController,
                label: 'Suhu',
                hint: '°C',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _tinggiFundusController,
                label: 'Tinggi Fundus Uteri',
                hint: 'cm',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _kontraksiController,
                label: 'Kontraksi Uterus',
                hint: 'jumlah dalam 10 menit',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _darahKeluarController,
                label: 'Pendarahan',
                hint: 'cc',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _urineController,
                label: 'Jumlah Urine',
                hint: 'cc',
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
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
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
