import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../tracker/data/models/amal_task.dart';
import '../../../core/database/database_service.dart';

class PdfGenerator {
  static Future<Uint8List> generateMonthlyReport(
      DateTime month, List<DailyLog> logs, List<AmalTask> tasks) async {
    final pdf = pw.Document();

    final monthName = DateFormat('MMMM yyyy').format(month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

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
            _buildStatistics(logs, tasks),
            pw.SizedBox(height: 20),
            _buildDataTable(daysInMonth, logMap, tasks),
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

  static pw.Widget _buildStatistics(List<DailyLog> logs, List<AmalTask> tasks) {
    if (logs.isEmpty || tasks.isEmpty) {
      return pw.Text('No data recorded for this month.');
    }

    final totalDays = logs.length;
    final avgCompletion = logs.fold(0.0, (sum, log) => sum + log.calculateCompletion(tasks)) / totalDays;

    // Find "Fajr" task for specific stat if it exists
    final fajrTask = tasks.where((t) => t.title.toLowerCase().contains('fajr')).firstOrNull;
    final fajrConsistency = fajrTask != null 
        ? logs.where((l) => l.getBool(fajrTask.id)).length / totalDays
        : 0.0;

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
          if (fajrTask != null)
            _buildStatItem('Fajr Consistency', '${(fajrConsistency * 100).round()}%'),
        ],
      ),
    );
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

  static pw.Widget _buildDataTable(int daysInMonth, Map<int, DailyLog> logMap, List<AmalTask> tasks) {
    // Select the first 8 checkbox tasks to keep table readable
    final displayTasks = tasks
        .where((t) => t.inputType == TaskInputType.checkbox)
        .take(8)
        .toList();

    final headers = [
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Day', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
      ...displayTasks.map((t) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(t.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
      )),
    ];

    final dataRows = <pw.TableRow>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final log = logMap[day];
      
      dataRows.add(pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$day', style: const pw.TextStyle(fontSize: 8))),
          ...displayTasks.map((t) => _buildCellMark(log?.getBool(t.id))),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers,
        ),
        ...dataRows,
      ],
    );
  }

  static pw.Widget _buildCellMark(bool? isCompleted) {
    if (isCompleted == null) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('-', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8)),
      );
    }
    
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        isCompleted ? 'Y' : 'N',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          color: isCompleted ? PdfColors.green700 : PdfColors.red700,
          fontWeight: isCompleted ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
