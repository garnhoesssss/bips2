import 'package:flutter/material.dart';
import '../core/constants.dart';

/// ============================================
/// ROUTE INFO PAGE - SCROLLABLE IMAGE LAYOUT
/// ============================================

class RouteInfoPage extends StatelessWidget {
  const RouteInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rute Bis Politeknik',
          style: AppTextStyles.heading3,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Route legend header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF1E2E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Pagi', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 24),
                  Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF159BB3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Sore', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Full-width scrollable route image
            Image.asset(
              'assets/images/rute_visual.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            ),

            // Bottom padding for safe area + navbar height
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Fallback placeholder if image not found
  Widget _buildPlaceholder() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Route image not found',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Place rute_visual.png in\nassets/images/',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
