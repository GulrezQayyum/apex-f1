import 'package:flutter/material.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';

/// Responsive Teams Screen
class ResponsiveTeamsScreen extends StatefulWidget {
  final List<String> teamNames;
  final String selectedTeam;
  final Function(String) onTeamSelected;
  final Widget teamDetails;

  const ResponsiveTeamsScreen({
    super.key,
    required this.teamNames,
    required this.selectedTeam,
    required this.onTeamSelected,
    required this.teamDetails,
  });

  @override
  State<ResponsiveTeamsScreen> createState() => _ResponsiveTeamsScreenState();
}

class _ResponsiveTeamsScreenState extends State<ResponsiveTeamsScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    if (isMobile) {
      return SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TEAMS',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rajdhani',
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: spacing * 2),
            _buildTeamSelector(spacing),
            SizedBox(height: spacing * 2),
            widget.teamDetails,
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TEAMS',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rajdhani',
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: spacing * 2),
                  _buildTeamSelector(spacing),
                ],
              ),
            ),
            SizedBox(width: spacing * 2),
            Expanded(
              flex: 3,
              child: widget.teamDetails,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTeamSelector(double spacing) {
    // FIX: replaced Column(spacing:) with explicit SizedBox between items
    return Column(
      children: widget.teamNames.expand((team) {
        final isSelected = widget.selectedTeam == team;
        return [
          GestureDetector(
            onTap: () => widget.onTeamSelected(team),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacing),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF444444),
                ),
                borderRadius: BorderRadius.circular(4),
                // FIX: .withValues(alpha: 0.1) → .withAlpha(26)
                color: isSelected
                    ? const Color(0xFF00E5FF).withAlpha(26)
                    : Colors.transparent,
              ),
              child: Text(
                team,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFAAAAAA),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing),
        ];
      }).toList(),
    );
  }
}

/// Responsive Championship Screen
class ResponsiveChampionshipScreen extends StatefulWidget {
  final Widget header;
  final List<Widget> raceResultCards;
  final Widget pointsChart;

  const ResponsiveChampionshipScreen({
    super.key,
    required this.header,
    required this.raceResultCards,
    required this.pointsChart,
  });

  @override
  State<ResponsiveChampionshipScreen> createState() =>
      _ResponsiveChampionshipScreenState();
}

class _ResponsiveChampionshipScreenState
    extends State<ResponsiveChampionshipScreen> {
  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.header,
          SizedBox(height: spacing * 2),
          // FIX: ShaderMask had a broken gradient (transparent→black instead of
          // opaque→transparent). Replaced with a simple ClipRect + fade overlay
          // that actually works as intended.
          if (isTablet)
            widget.pointsChart
          else
            Stack(
              children: [
                widget.pointsChart,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 32,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          // FIX: .withValues(alpha: ) → .withAlpha()
                          Colors.black.withAlpha(77),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: spacing * 2),
          const Text(
            'RACE HISTORY',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: spacing),
          if (isTablet)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.2,
              children: widget.raceResultCards,
            )
          else
          // FIX: replaced Column(spacing:) with explicit SizedBox
            Column(
              children: widget.raceResultCards.expand((card) => [
                card,
                SizedBox(height: spacing),
              ]).toList(),
            ),
        ],
      ),
    );
  }
}