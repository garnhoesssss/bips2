import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/bus_model.dart';

/// ============================================
/// BUS DETAIL PANEL - FLEET COMMAND DESIGN
/// ============================================

class BusDetailPanel extends StatefulWidget {
  final BusModel bus;
  final VoidCallback? onClose;
  final ScrollController? scrollController;

  const BusDetailPanel({
    super.key,
    required this.bus,
    this.onClose,
    this.scrollController,
  });

  @override
  State<BusDetailPanel> createState() => _BusDetailPanelState();
}

class _BusDetailPanelState extends State<BusDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse animation if smoke detected
    if (widget.bus.hasGasSensor && !widget.bus.isAirQualitySafe) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BusDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bus.hasGasSensor && !widget.bus.isAirQualitySafe) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.elevatedShadow,
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle bar - visual indicator for draggable sheet
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingLarge,
                0,
                AppDimensions.paddingLarge,
                AppDimensions.paddingLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Bus ID + Status Badge + Favorite Icon
                  _buildHeader(),

                  const SizedBox(height: 8),

                  // Sub-header: Route name
                  _buildSubHeader(),

                  const SizedBox(height: 20),

                  // Stats Row: Speed, ETA, Status
                  _buildStatsRow(),

                  const SizedBox(height: 20),

                  // Timeline Widget: Next Stop & Following
                  _buildTimeline(),

                  // Air Quality Widget (only for BUS-01)
                  if (widget.bus.hasGasSensor) ...[
                    const SizedBox(height: 16),
                    _buildAirQualityWidget(),
                  ],

                  // Extra padding at bottom for safety
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Bus ID
        Text(
          widget.bus.busId,
          style: AppTextStyles.heading1,
        ),

        const SizedBox(width: 12),

        // Status Badge
        _buildStatusBadge(),

        const Spacer(),

        // Favorite Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.favorite_border_rounded,
            color: AppColors.textLight,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;

    switch (widget.bus.status) {
      case BusStatus.onRoute:
        badgeColor = AppColors.statusOnline;
        statusText = 'In Transit';
        break;
      case BusStatus.atStop:
        badgeColor = AppColors.statusAtStop;
        statusText = 'At Stop';
        break;
      case BusStatus.delayed:
        badgeColor = AppColors.statusDelayed;
        statusText = 'Delayed';
        break;
      case BusStatus.offline:
        badgeColor = AppColors.statusOffline;
        statusText = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: AppTextStyles.bodySmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Row(
      children: [
        Icon(
          Icons.route_rounded,
          size: 16,
          color: AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.bus.routeName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.speed_rounded,
          value: '${widget.bus.speed.toInt()}',
          label: 'km/h',
          iconColor: AppColors.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.access_time_rounded,
          value: '${widget.bus.etaMinutes ?? 0}m',
          label: 'ETA Next',
          iconColor: AppColors.afternoonRoute,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: widget.bus.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          value: widget.bus.isOnline ? 'Online' : 'Offline',
          label: 'IoT Status',
          iconColor: widget.bus.isOnline ? AppColors.statusOnline : AppColors.statusOffline,
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.labelBold.copyWith(fontSize: 16),
          ),
          Text(
            label,
            style: AppTextStyles.statLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // Timeline visual
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.morningRoute,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppColors.divider,
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider, width: 2),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Stop details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT STOP',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.bus.nextStop ?? 'Unknown',
                  style: AppTextStyles.labelBold.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 16),
                Text(
                  'FOLLOWING',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.bus.followingStop ?? 'Unknown',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityWidget() {
    final isSafe = widget.bus.isAirQualitySafe;
    final bgColor = isSafe ? AppColors.airSafe : AppColors.airDanger;
    final textColor = isSafe ? AppColors.airSafeText : AppColors.airDangerText;
    final statusText = isSafe ? 'Safe' : 'SMOKE DETECTED';
    final icon = isSafe ? Icons.check_circle_rounded : Icons.warning_rounded;

    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: textColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cabin Air Quality',
                  style: AppTextStyles.labelBold.copyWith(color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  isSafe
                      ? 'CO2 levels are normal (${widget.bus.gasLevel}ppm). Air Conditioning is active.'
                      : 'WARNING: Elevated gas levels detected (${widget.bus.gasLevel}ppm)!',
                  style: AppTextStyles.bodySmall.copyWith(color: textColor.withAlpha(180)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // Apply pulse animation for danger state
    if (!isSafe) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }
}

/// ============================================
/// FLEET SELECTOR CARD WIDGET
/// ============================================

class FleetSelectorCard extends StatelessWidget {
  final BusModel bus;
  final bool isSelected;
  final VoidCallback onTap;

  const FleetSelectorCard({
    super.key,
    required this.bus,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (bus.status) {
      case BusStatus.onRoute:
        statusColor = AppColors.statusOnline;
        statusIcon = Icons.directions_bus_rounded;
        statusText = 'On Route';
        break;
      case BusStatus.atStop:
        statusColor = AppColors.statusAtStop;
        statusIcon = Icons.location_on_rounded;
        statusText = 'At Stop';
        break;
      case BusStatus.delayed:
        statusColor = AppColors.statusDelayed;
        statusIcon = Icons.warning_rounded;
        statusText = 'Delayed';
        break;
      case BusStatus.offline:
        statusColor = AppColors.statusOffline;
        statusIcon = Icons.wifi_off_rounded;
        statusText = 'Offline';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          boxShadow: isSelected ? AppShadows.cardShadow : AppShadows.softShadow,
          border: isSelected
              ? Border.all(color: statusColor, width: 2)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bus.busId,
                  style: AppTextStyles.labelBold.copyWith(
                    fontSize: 13,
                    color: isSelected ? AppColors.textDark : AppColors.textMedium,
                  ),
                ),
                Text(
                  statusText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
