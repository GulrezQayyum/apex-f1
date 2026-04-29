import 'package:flutter/material.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';

/// Responsive Race Calendar Screen
class ResponsiveRaceCalendarScreen extends StatefulWidget {
  final List<Widget> raceCards;
  final String season;
  final int completedCount;
  final int upcomingCount;
  final Function(int index, dynamic race) onRaceSelected;

  const ResponsiveRaceCalendarScreen({
    super.key,
    required this.raceCards,
    required this.season,
    required this.completedCount,
    required this.upcomingCount,
    required this.onRaceSelected,
  });

  @override
  State<ResponsiveRaceCalendarScreen> createState() =>
      _ResponsiveRaceCalendarScreenState();
}

class _ResponsiveRaceCalendarScreenState
    extends State<ResponsiveRaceCalendarScreen> {
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

  /// Mobile: 1 column
  Widget _buildMobileLayout() {
    return _buildGridLayout(crossAxisCount: 1);
  }

  /// Tablet: 2 columns
  Widget _buildTabletLayout() {
    return _buildGridLayout(crossAxisCount: 2);
  }

  /// Desktop: 3-4 columns depending on screen width
  Widget _buildDesktopLayout() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1400 ? 4 : 3;
    return _buildGridLayout(crossAxisCount: crossAxisCount);
  }

  Widget _buildGridLayout({required int crossAxisCount}) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(spacing),
          SizedBox(height: spacing * 2),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: _getChildAspectRatio(crossAxisCount),
            children: widget.raceCards,
          ),
        ],
      ),
    );
  }

  double _getChildAspectRatio(int columns) {
    if (columns == 1) return 1.2;
    if (columns == 2) return 1.0;
    if (columns == 3) return 0.9;
    return 0.85;
  }

  Widget _buildHeader(double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEASON ${widget.season}',
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Rajdhani',
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            _buildStatChip(
              label: 'COMPLETED',
              value: widget.completedCount,
              color: const Color(0xFF00E5FF),
            ),
            SizedBox(width: spacing),
            _buildStatChip(
              label: 'UPCOMING',
              value: widget.upcomingCount,
              color: const Color(0xFFFF00FF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'Rajdhani',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
