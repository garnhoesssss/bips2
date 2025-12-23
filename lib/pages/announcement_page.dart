import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/announcement_model.dart';

/// ============================================
/// ANNOUNCEMENT PAGE - REALTIME FEED
/// ============================================

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengumuman',
            style: AppTextStyles.heading2,
          ),
          Text(
            'Informasi terbaru dari admin',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isRefreshing = true;
            });
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _isRefreshing = false;
                });
              }
            });
          },
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: AppColors.textMedium),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getAnnouncementsStream(),
      builder: (context, snapshot) {
        // Show loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // Handle errors
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final data = snapshot.data ?? [];

        // Show empty state if no announcements
        if (data.isEmpty) {
          return _buildEmptyState();
        }

        // Parse announcements
        final announcements = data
            .map((json) => Announcement.fromJson(json))
            .toList();

        return _buildAnnouncementList(announcements);
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getAnnouncementsStream() {
    try {
      return Supabase.instance.client
          .from('app_info')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(20);
    } catch (e) {
      // Return dummy data stream if Supabase not configured
      return Stream.value(
        Announcement.getDummyAnnouncements()
            .map((a) => a.toJson())
            .toList(),
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat pengumuman...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.statusDelayed,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada pengumuman',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'Semua informasi penting dari admin\nakan muncul di sini.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
                ),
              ),
              child: Text(
                'Refresh Feed',
                style: AppTextStyles.labelBold.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementList(List<Announcement> announcements) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildUpdatingHeader();
          }
          return _buildAnnouncementCard(announcements[index - 1]);
        },
      ),
    );
  }

  Widget _buildUpdatingHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.statusOnline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'UPDATING FEED...',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    Color categoryColor;
    switch (announcement.category?.toUpperCase()) {
      case 'URGENT':
        categoryColor = AppColors.morningRoute;
        break;
      case 'MAINTENANCE':
        categoryColor = AppColors.primary;
        break;
      default:
        categoryColor = AppColors.afternoonRoute;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAnnouncementDetail(announcement),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        announcement.categoryLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(announcement.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  announcement.title,
                  style: AppTextStyles.labelBold.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Content preview
                Text(
                  announcement.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  void _showAnnouncementDetail(Announcement announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy • HH:mm').format(announcement.createdAt),
                      style: AppTextStyles.bodySmall,
                    ),
                    const Divider(height: 32),
                    Text(
                      announcement.content,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
