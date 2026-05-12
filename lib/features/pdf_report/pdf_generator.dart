import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../core/database/database_service.dart';
import '../../../core/constants/salah_data.dart';

class PdfGenerator {
  static Future<Uint8List> generateMonthlyReport(
      DateTime month, List<DailyLog> logs) async {
    final pdf = pw.Document();

    final monthName = DateFormat('MMMM yyyy').format(month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Create a map of day -> DailyLog for easy lookup
    final logMap = {
      for (var log in logs) DateTime.parse(log.date).day: log,
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildHeader(monthName),
            pw.SizedBox(height: 20),
            _buildStatistics(logs),
            pw.SizedBox(height: 20),
            _buildDataTable(daysInMonth, logMap),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String monthName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Amal Tracker',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Monthly Report - $monthName',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          'Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildStatistics(List<DailyLog> logs) {
    if (logs.isEmpty) {
      return pw.Text('No data recorded for this month.');
    }

    final totalDays = logs.length;
    final totalFajr = logs.where((l) => l.fajr).length;
    final totalDhuhr = logs.where((l) => l.dhuhr).length;
    final totalAsr = logs.where((l) => l.asr).length;
    final totalMaghrib = logs.where((l) => l.maghrib).length;
    final totalIsha = logs.where((l) => l.isha).length;

    final avgCompletion = logs.fold(0.0, (sum, log) => sum + log.completionPercentage) / totalDays;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Active Days', '$totalDays'),
          _buildStatItem('Avg Completion', '${(avgCompletion * 100).round()}%'),
          _buildStatItem('Fajr Consistency', '${((totalFajr / totalDays) * 100).round()}%'),
          _buildStatItem('All 5 Prayers', '${(_calculateAllPrayers(logs) / totalDays * 100).round()}%'),
        ],
      ),
    );
  }

  static int _calculateAllPrayers(List<DailyLog> logs) {
    return logs.where((l) => l.fajr && l.dhuhr && l.asr && l.maghrib && l.isha).length;
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _buildDataTable(int daysInMonth, Map<int, DailyLog> logMap) {
    // Select key columns to keep table readable
    final columns = [
      'Day',
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
      'Dua',
      'Time',
      'Sleep',
    ];

    final headers = columns.map((c) => pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(c, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
    )).toList();

    final data = <List<pw.Widget>>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final log = logMap[day];
      
      data.add([
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('$day', style: const pw.TextStyle(fontSize: 10)),
        ),
        _buildCellMark(log?.fajr),
        _buildCellMark(log?.dhuhr),
        _buildCellMark(log?.asr),
        _buildCellMark(log?.maghrib),
        _buildCellMark(log?.isha),
        _buildCellMark(log?.fiveMinDua),
        _buildCellMark(log?.salahOnTime),
        _buildCellMark(log?.sleptBefore1030),
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers,
        ),
        ...data.map((row) => pw.TableRow(children: row)),
      ],
    );
  }

  static pw.Widget _buildCellMark(bool? isCompleted) {
    if (isCompleted == null) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: PdfColors.grey400)),
      );
    }
    
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        isCompleted ? 'Y' : 'N',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: isCompleted ? PdfColors.green700 : PdfColors.red700,
          fontWeight: isCompleted ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
