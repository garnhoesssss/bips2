// ============================================
// ANNOUNCEMENT DATA MODEL (app_info table)
// ============================================

class Announcement {
  final String id;  // UUID from app_info
  final String title;
  final String content;
  final bool isActive;
  final String? category;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.isActive = true,
    this.category,
    required this.createdAt,
  });

  /// Factory constructor to parse data from Supabase app_info table
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      category: json['category'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_active': isActive,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get the category label for display
  String get categoryLabel {
    switch (category?.toUpperCase()) {
      case 'URGENT':
        return 'URGENT';
      case 'INFO':
        return 'INFO';
      case 'MAINTENANCE':
        return 'MAINTENANCE';
      default:
        return 'INFO';
    }
  }

  /// Create dummy data for testing
  static List<Announcement> getDummyAnnouncements() {
    return [
      Announcement(
        id: '1',
        title: 'Perubahan Rute Bus 2',
        content: 'Dikarenakan perbaikan jalan di sektor utara, Bus 2 akan dialihkan melewati Jalan Merdeka...',
        isActive: true,
        category: 'URGENT',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Announcement(
        id: '2',
        title: 'Jadwal Libur Semester',
        content: 'Bus tidak akan beroperasi pada tanggal merah dan hari libur nasional. Operasional...',
        isActive: true,
        category: 'INFO',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: '3',
        title: 'Aplikasi sedang maintenance',
        content: 'Fitur live tracking akan dinonaktifkan sementara untuk pemeliharaan server pada...',
        isActive: true,
        category: 'MAINTENANCE',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
