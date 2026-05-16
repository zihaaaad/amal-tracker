import 'package:supabase_flutter/supabase_flutter.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'] ?? 'general',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AnnouncementService {
  static final instance = AnnouncementService._();
  AnnouncementService._();

  final _supabase = Supabase.instance.client;

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      
      return (response as List).map((e) => Announcement.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> postAnnouncement(String title, String content) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('announcements').insert({
      'title': title,
      'content': content,
      'created_by': user.id,
    });
  }
}
