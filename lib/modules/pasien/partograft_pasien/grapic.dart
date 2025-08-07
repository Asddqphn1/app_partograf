import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:partograf/modules/pasien/catatanPerkembangan/kemajuan_persalinan.dart';

class PartografScreen extends StatelessWidget {
  final List<CatatanServiks> catatanServiks;

  PartografScreen({required this.catatanServiks});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> pembukaanSpots = [];
    List<FlSpot> penurunanSpots = [];

    // Mengubah data pembukaan dan penurunan ke format yang dapat digunakan oleh fl_chart
    for (int i = 0; i < catatanServiks.length; i++) {
      final catatan = catatanServiks[i];
      pembukaanSpots.add(
        FlSpot(i.toDouble(), catatan.besarPembukaan.toDouble()),
      );
      penurunanSpots.add(
        FlSpot(i.toDouble(), catatan.besarPenurunan.toDouble()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partograf Pembukaan dan Penurunan Serviks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              // Bar data for Pembukaan with custom symbol
              LineChartBarData(
                spots: pembukaanSpots,
                isCurved: true,
                color: Colors.blue,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
              // Bar data for Penurunan with custom symbol
              LineChartBarData(
                spots: penurunanSpots,
                isCurved: true,
                color: Colors.red,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6, // Circle symbol
                      color: Colors.red,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameSize: 16,
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
              bottomTitles: AxisTitles(
                axisNameSize: 16,
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
