import 'package:flutter/material.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';

/// Responsive Drivers Screen
class ResponsiveDriversScreen extends StatefulWidget {
  final List<Widget> driverCards;
  final List<String> sortOptions;
  final Function(String) onSortChanged;
  final String currentSort;

  const ResponsiveDriversScreen({
    super.key,
    required this.driverCards,
    required this.sortOptions,
    required this.onSortChanged,
    required this.currentSort,
  });

  @override
  State<ResponsiveDriversScreen> createState() =>
      _ResponsiveDriversScreenState();
}

class _ResponsiveDriversScreenState extends State<ResponsiveDriversScreen> {
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

  Widget _buildMobileLayout() {
    return _buildLayout(crossAxisCount: 1, isListView: true);
  }

  Widget _buildTabletLayout() {
    return _buildLayout(crossAxisCount: 2, isListView: false);
  }

  Widget _buildDesktopLayout() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1400 ? 4 : 3;
    return _buildLayout(crossAxisCount: crossAxisCount, isListView: false);
  }

  Widget _buildLayout({
    required int crossAxisCount,
    required bool isListView,
  }) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(spacing),
          SizedBox(height: spacing * 2),
          _buildSortOptions(spacing),
          SizedBox(height: spacing),
          if (isListView)
            Column(
              // FIX: replaced Column(spacing:) with explicit SizedBox children
              children: widget.driverCards.expand((card) => [
                card,
                SizedBox(height: spacing),
              ]).toList(),
            )
          else
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.8,
              children: widget.driverCards,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DRIVERS',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Rajdhani',
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          '${widget.driverCards.length} drivers in championship',
          style: const TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 14,
            fontFamily: 'Rajdhani',
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions(double spacing) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // FIX: replaced Row(spacing:) with explicit SizedBox between children
        children: widget.sortOptions.expand((option) {
          final isActive = widget.currentSort == option;
          return [
            FilterChip(
              label: Text(option),
              selected: isActive,
              onSelected: (_) => widget.onSortChanged(option),
              // FIX: replaced .withValues(alpha: ) with .withAlpha() (non-deprecated)
              backgroundColor: isActive
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF0A0A14),
              selectedColor: const Color(0xFF00E5FF),
              labelStyle: TextStyle(
                color: isActive
                    ? const Color(0xFF030308)
                    : const Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontFamily: 'Rajdhani',
              ),
              side: BorderSide(
                color: isActive
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF444444),
              ),
            ),
            SizedBox(width: spacing),
          ];
        }).toList(),
      ),
    );
  }
}

/// Responsive Standings Screen
class ResponsiveStandingsScreen extends StatefulWidget {
  final List<Widget> driverCards;
  final List<Widget> constructorCards;
  final bool showDrivers;
  final Function(bool) onTabChanged;

  const ResponsiveStandingsScreen({
    super.key,
    required this.driverCards,
    required this.constructorCards,
    required this.showDrivers,
    required this.onTabChanged,
  });

  @override
  State<ResponsiveStandingsScreen> createState() =>
      _ResponsiveStandingsScreenState();
}

class _ResponsiveStandingsScreenState
    extends State<ResponsiveStandingsScreen> {
  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final cards = widget.showDrivers
        ? widget.driverCards
        : widget.constructorCards;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STANDINGS',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: spacing * 2),
          _buildTabButtons(spacing),
          SizedBox(height: spacing * 2),
          // FIX: replaced Column(spacing:) with explicit SizedBox
          Column(
            children: cards.expand((card) => [
              card,
              SizedBox(height: spacing),
            ]).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons(double spacing) {
    return Row(
      // FIX: replaced Row(spacing:) with explicit SizedBox
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => widget.onTabChanged(true),
            child: Container(
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.showDrivers
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF444444),
                ),
                borderRadius: BorderRadius.circular(4),
                // FIX: .withValues(alpha: 0.1) → Color.withAlpha(26)
                color: widget.showDrivers
                    ? const Color(0xFF00E5FF).withAlpha(26)
                    : const Color(0xFF0A0A14),
              ),
              child: Text(
                'DRIVERS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.showDrivers
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFAAAAAA),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: GestureDetector(
            onTap: () => widget.onTabChanged(false),
            child: Container(
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                border: Border.all(
                  color: !widget.showDrivers
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF444444),
                ),
                borderRadius: BorderRadius.circular(4),
                // FIX: .withValues(alpha: 0.1) → Color.withAlpha(26)
                color: !widget.showDrivers
                    ? const Color(0xFF00E5FF).withAlpha(26)
                    : const Color(0xFF0A0A14),
              ),
              child: Text(
                'CONSTRUCTORS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !widget.showDrivers
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFAAAAAA),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}