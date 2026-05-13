import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../tracker/providers/daily_log_provider.dart';
import '../../../../core/database/database_service.dart';
import '../../../pdf_report/pdf_generator.dart';
import '../../../tracker/providers/tasks_provider.dart';
import '../../../tracker/data/models/amal_task.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final monthLogs = ref.watch(monthLogsProvider);
    final streak = ref.watch(streakProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: tasksAsync.when(
        data: (tasks) => _buildBody(context, monthLogs, streak, tasks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Error loading: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DailyLog> monthLogs,
    int streak,
    List<AmalTask> tasks,
  ) {
    final now = DateTime.now();
    final pastLogs = monthLogs.where((l) {
      final day = DateTime.parse(l.date).day;
      return day <= now.day;
    }).toList();

    final avgCompletion = pastLogs.isEmpty
        ? 0.0
        : pastLogs.fold(0.0, (s, l) => s + l.calculateCompletion(tasks)) /
            pastLogs.length;

    final daysTracked = pastLogs.where((l) => l.calculateCompletion(tasks) > 0).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat Cards Row ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.warmAmber,
                  value: '$streak',
                  label: 'Day Streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF6B9BD2),
                  value: '$daysTracked',
                  label: 'Days Tracked',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.sageGreen,
                  value: '${(avgCompletion * 100).round()}%',
                  label: 'Avg. Done',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Monthly Chart ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Consistency',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: context.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildLineChart(context, monthLogs, tasks),

          const SizedBox(height: 28),

          // ── Best & Worst Days ───────────────────────────────────
          _buildDayBreakdown(context, pastLogs, tasks),

          const SizedBox(height: 28),

          // ── Export Button ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF...')),
                );
                try {
                  final month = DateTime.now();
                  final bytes = await PdfGenerator.generateMonthlyReport(
                      month, monthLogs, tasks);
                  if (!context.mounted) return;
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename: 'amal_${month.month}_${month.year}.pdf',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('Export Monthly Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    BuildContext context,
    List<DailyLog> logs,
    List<AmalTask> tasks,
  ) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final spots = <FlSpot>[];
    for (int i = 0; i < daysInMonth; i++) {
      if (i < logs.length) {
        spots.add(FlSpot(i.toDouble(), logs[i].calculateCompletion(tasks) * 100));
      } else {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorder),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.surfaceOverlay,
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        'Day ${s.x.toInt() + 1}\n${s.y.round()}%',
                        TextStyle(
                          color: AppColors.sageGreenLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.glassBorder,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 5,
                getTitlesWidget: (value, _) {
                  if (value > daysInMonth - 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${value.toInt() + 1}',
                      style: TextStyle(color: context.textMuted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 38,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: TextStyle(color: context.textMuted, fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (daysInMonth - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.sageGreenLight,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sageGreen.withValues(alpha: 0.25),
                    AppColors.sageGreen.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBreakdown(
    BuildContext context,
    List<DailyLog> logs,
    List<AmalTask> tasks,
  ) {
    if (logs.isEmpty) return const SizedBox.shrink();

    DailyLog? best;
    DailyLog? worst;
    double bestScore = -1;
    double worstScore = 2;

    for (final log in logs) {
      final score = log.calculateCompletion(tasks);
      if (score > bestScore) {
        bestScore = score;
        best = log;
      }
      if (score < worstScore && score > 0) {
        worstScore = score;
        worst = log;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (best != null)
              Expanded(
                child: _DayHighlightCard(
                  label: 'Best Day',
                  date: best.date,
                  score: bestScore,
                  color: AppColors.sageGreen,
                  icon: Icons.star_rounded,
                ),
              ),
            if (best != null && worst != null) const SizedBox(width: 12),
            if (worst != null)
              Expanded(
                child: _DayHighlightCard(
                  label: 'Needs Work',
                  date: worst.date,
                  score: worstScore,
                  color: AppColors.softCoral,
                  icon: Icons.trending_down_rounded,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Day Highlight Card ────────────────────────────────────────────────────

class _DayHighlightCard extends StatelessWidget {
  final String label;
  final String date;
  final double score;
  final Color color;
  final IconData icon;

  const _DayHighlightCard({
    required this.label,
    required this.date,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);
    final dateStr = parsed != null ? DateFormat('MMM d').format(parsed) : date;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            context.surfaceCard,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(score * 100).round()}% complete',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
