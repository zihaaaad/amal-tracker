import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/database_service.dart';
import '../tracker/data/models/amal_task.dart';

class PdfGenerator {
  static Future<Uint8List> generateMonthlyReport(
      DateTime month, List<DailyLog> logs, List<AmalTask> tasks) async {
    final pdf = pw.Document(
      title: 'Amal Monthly Report',
      author: 'Amal Tracker',
    );

    final monthName = DateFormat('MMMM yyyy').format(month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final logMap = {
      for (var log in logs) DateTime.parse(log.date).day: log,
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) {
          return [
            _buildHeader(monthName),
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.SizedBox(height: 20),
            _buildStatistics(logs, tasks),
            pw.SizedBox(height: 30),
            _buildInsights(logs, tasks),
            pw.SizedBox(height: 30),
            _buildSectionTitle('DAILY LOG'),
            pw.SizedBox(height: 10),
            _buildDataTable(daysInMonth, logMap, tasks),
            pw.SizedBox(height: 30),
            _buildFooter(),
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
              'AMAL TRACKER',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#4A6741'), // Sage Green
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Monthly Progress Report | $monthName',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey600,
        letterSpacing: 1.5,
      ),
    );
  }

  static pw.Widget _buildStatistics(List<DailyLog> logs, List<AmalTask> tasks) {
    if (logs.isEmpty || tasks.isEmpty) {
      return pw.Text('No data recorded for this month.');
    }

    final totalDays = logs.length;
    final avgCompletion =
        logs.fold(0.0, (sum, log) => sum + log.calculateCompletion(tasks)) /
            totalDays;

    return pw.Row(
      children: [
        _buildStatBox('Days Tracked', '$totalDays', PdfColors.blue100),
        pw.SizedBox(width: 15),
        _buildStatBox('Avg Completion', '${(avgCompletion * 100).round()}%', PdfColors.green100),
        pw.SizedBox(width: 15),
        _buildStatBox('Best Streak', 'Active', PdfColors.amber100),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        ),
        child: pw.Column(
          children: [
            pw.Text(value,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildInsights(List<DailyLog> logs, List<AmalTask> tasks) {
    // Basic logic for PDF insights
    String text = 'You have shown consistent commitment this month. Your spiritual journey is reflected in the steady discipline across your daily tasks.';
    
    final fajrTask = tasks.where((t) => t.title.toLowerCase().contains('fajr')).firstOrNull;
    if (fajrTask != null) {
      final fajrRatio = logs.where((l) => l.getBool(fajrTask.id)).length / logs.length;
      if (fajrRatio > 0.8) {
        text = 'Exceptional Fajr consistency. This morning discipline is the hallmark of elite spiritual growth and will continue to bring Barakah into your days.';
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('SPIRITUAL INSIGHT'),
          pw.SizedBox(height: 8),
          pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800, lineSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDataTable(
      int daysInMonth, Map<int, DailyLog> logMap, List<AmalTask> tasks) {
    final checkboxTasks =
        tasks.where((t) => t.inputType == TaskInputType.checkbox).take(7).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        for (int i = 1; i <= checkboxTasks.length; i++) i: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Day', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
            ),
            ...checkboxTasks.map((t) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(t.title,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
                      textAlign: pw.TextAlign.center),
                )),
          ],
        ),
        for (int day = 1; day <= daysInMonth; day++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('$day', style: const pw.TextStyle(fontSize: 7)),
              ),
              ...checkboxTasks.map((t) => _buildCellMark(logMap[day]?.getBool(t.id))),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildCellMark(bool? isCompleted) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Center(
        child: pw.Text(
          isCompleted == null ? '-' : (isCompleted ? 'v' : 'x'),
          style: pw.TextStyle(
            fontSize: 8,
            color: isCompleted == true ? PdfColors.green700 : PdfColors.grey400,
            fontWeight: isCompleted == true ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Steady Progress, Spiritual Excellence.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }
}
