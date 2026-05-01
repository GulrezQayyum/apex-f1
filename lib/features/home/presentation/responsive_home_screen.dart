import 'package:flutter/material.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';

/// Responsive Home Screen Layout
/// Adapts to mobile, tablet, and desktop screens
class ResponsiveHomeScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final Widget statusBar;
  final Widget clockCard;
  final Widget welcomeCard;
  final Widget nextRaceCard;
  final Widget quickMenuCard;
  final Widget standingsPreviewCard;
  final Widget lastRaceCard;

  const ResponsiveHomeScreen({
    super.key,
    required this.onNavigate,
    required this.statusBar,
    required this.clockCard,
    required this.welcomeCard,
    required this.nextRaceCard,
    required this.quickMenuCard,
    required this.standingsPreviewCard,
    required this.lastRaceCard,
  });

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  /// Mobile layout - single column, stacked vertically
  Widget _buildMobileLayout() {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.statusBar,
          SizedBox(height: spacing),
          // FIX: removed broken Expanded(child: SizedBox.shrink()) —
          // clockCard takes full width on mobile
          widget.clockCard,
          SizedBox(height: spacing),
          widget.welcomeCard,
          SizedBox(height: spacing),
          widget.nextRaceCard,
          SizedBox(height: spacing),
          widget.quickMenuCard,
          SizedBox(height: spacing),
          widget.standingsPreviewCard,
          SizedBox(height: spacing),
          widget.lastRaceCard,
        ],
      ),
    );
  }

  /// Tablet layout - 2 column grid
  Widget _buildTabletLayout() {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.statusBar,
          SizedBox(height: spacing),
          // FIX: replaced Row(spacing:) with explicit SizedBox
          Row(
            children: [
              Expanded(child: widget.clockCard),
              SizedBox(width: spacing),
              Expanded(child: widget.nextRaceCard),
            ],
          ),
          SizedBox(height: spacing),
          widget.welcomeCard,
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(child: widget.quickMenuCard),
              SizedBox(width: spacing),
              Expanded(child: widget.standingsPreviewCard),
            ],
          ),
          SizedBox(height: spacing),
          widget.lastRaceCard,
        ],
      ),
    );
  }

  /// Desktop layout - multi-column with optimal spacing
  Widget _buildDesktopLayout() {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.statusBar,
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(flex: 1, child: widget.clockCard),
              SizedBox(width: spacing),
              Expanded(flex: 2, child: widget.welcomeCard),
              SizedBox(width: spacing),
              Expanded(flex: 1, child: widget.nextRaceCard),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(flex: 1, child: widget.quickMenuCard),
              SizedBox(width: spacing),
              Expanded(flex: 1, child: widget.standingsPreviewCard),
              SizedBox(width: spacing),
              Expanded(flex: 1, child: widget.lastRaceCard),
            ],
          ),
        ],
      ),
    );
  }
}