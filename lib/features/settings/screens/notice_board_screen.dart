import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/theme/theme_extension.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text('Foundation Notices', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await HapticFeedback.mediumImpact();
          setState(() => _refreshKey = UniqueKey());
        },
        backgroundColor: context.surfaceCard,
        color: context.timeTint,
        child: FutureBuilder<List<Announcement>>(
          key: _refreshKey,
          future: AnnouncementService.instance.getAnnouncements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notices = snapshot.data ?? [];
            if (notices.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.surfaceSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_none_rounded, size: 48, color: context.textMuted),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 16),
                        Text('No official notices yet.', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Pull down to refresh', style: TextStyle(color: context.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.timeTint.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notice.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: context.timeTint,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM').format(notice.createdAt),
                            style: TextStyle(fontSize: 11, color: context.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        notice.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }
}
