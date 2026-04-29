// EXAMPLE IMPLEMENTATION - How to integrate responsive design into existing screens
// Copy and adapt these examples for your project

import 'package:flutter/material.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';
import 'package:apex_f1/features/races/presentation/season_import_screen.dart';

// ============================================================================
// EXAMPLE 1: Responsive Home Screen with Season Import Button
// ============================================================================

class ExampleResponsiveHomeScreen extends StatefulWidget {
  const ExampleResponsiveHomeScreen({super.key});

  @override
  State<ExampleResponsiveHomeScreen> createState() =>
      _ExampleResponsiveHomeScreenState();
}

class _ExampleResponsiveHomeScreenState
    extends State<ExampleResponsiveHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: [
            // Status bar
            Container(
              height: 2,
              color: const Color(0xFF00E5FF),
            ),
            SizedBox(height: spacing),
            
            // Add season import button
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SeasonImportScreen(),
                ),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Custom Races'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF030308),
              ),
            ),
            SizedBox(height: spacing),

            // Responsive layout
            if (isMobile) _buildMobileLayout(spacing) else _buildDesktopLayout(spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(double spacing) {
    return Column(spacing: spacing, children: [
      _buildClockCard(),
      _buildWelcomeCard(),
      _buildNextRaceCard(),
      _buildStandingsCard(),
    ]);
  }

  Widget _buildDesktopLayout(double spacing) {
    return Column(spacing: spacing, children: [
      Row(spacing: spacing, children: [
        Expanded(child: _buildClockCard()),
        Expanded(child: _buildWelcomeCard()),
        Expanded(child: _buildNextRaceCard()),
      ]),
      Row(spacing: spacing, children: [
        Expanded(child: _buildStandingsCard()),
        Expanded(child: Container()),
      ]),
    ]);
  }

  Widget _buildClockCard() =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E5FF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Clock Card',
          style: TextStyle(color: Color(0xFF00E5FF)),
        ),
      );

  Widget _buildWelcomeCard() =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E5FF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Welcome Card',
          style: TextStyle(color: Color(0xFF00E5FF)),
        ),
      );

  Widget _buildNextRaceCard() =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E5FF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Next Race Card',
          style: TextStyle(color: Color(0xFF00E5FF)),
        ),
      );

  Widget _buildStandingsCard() =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00E5FF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Standings Card',
          style: TextStyle(color: Color(0xFF00E5FF)),
        ),
      );
}

// ============================================================================
// EXAMPLE 2: Responsive Race Calendar with Custom Races
// ============================================================================

class ExampleResponsiveRaceCalendarScreen extends StatefulWidget {
  final Function(dynamic) onRaceSelected;

  const ExampleResponsiveRaceCalendarScreen({
    super.key,
    required this.onRaceSelected,
  });

  @override
  State<ExampleResponsiveRaceCalendarScreen> createState() =>
      _ExampleResponsiveRaceCalendarScreenState();
}

class _ExampleResponsiveRaceCalendarScreenState
    extends State<ExampleResponsiveRaceCalendarScreen> {
  late RaceServiceV2 _raceService;
  String _selectedSeason = '2024';
  List<dynamic> _races = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _raceService = RaceServiceV2();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    try {
      setState(() => _isLoading = true);
      // Automatically loads custom if available, else default
      final seasonModel = await _raceService.getSeasonRaces(_selectedSeason);
      setState(() {
        _races = seasonModel.races;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading races: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final columns = ResponsiveHelper.getGridColumns(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        title: const Text('RACES'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (season) {
              setState(() => _selectedSeason = season);
              _loadRaces();
            },
            itemBuilder: (context) => ['2023', '2024', '2025']
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  _selectedSeason,
                  style: const TextStyle(color: Color(0xFF00E5FF)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: padding,
              child: GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: columns == 1 ? 1.2 : 0.9,
                children: _races.map((race) {
                  return GestureDetector(
                    onTap: () => widget.onRaceSelected(race),
                    child: Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00E5FF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            race.toString(),
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Responsive Grid/List Toggle
// ============================================================================

class ExampleResponsiveListScreen extends StatefulWidget {
  final List<String> items;

  const ExampleResponsiveListScreen({
    super.key,
    required this.items,
  });

  @override
  State<ExampleResponsiveListScreen> createState() =>
      _ExampleResponsiveListScreenState();
}

class _ExampleResponsiveListScreenState
    extends State<ExampleResponsiveListScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: isMobile ? _buildListView(spacing) : _buildGridView(spacing),
    );
  }

  /// Mobile: Single column list
  Widget _buildListView(double spacing) {
    return ListView.separated(
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (context, index) => _buildItemCard(widget.items[index]),
    );
  }

  /// Tablet/Desktop: Multi-column grid
  Widget _buildGridView(double spacing) {
    final columns = ResponsiveHelper.getGridColumns(context);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      children: widget.items.map(_buildItemCard).toList(),
    );
  }

  Widget _buildItemCard(String item) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF00E5FF)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      item,
      style: const TextStyle(color: Color(0xFF00E5FF)),
    ),
  );
}

// ============================================================================
// EXAMPLE 4: Responsive Font Sizes & Spacing
// ============================================================================

class ExampleResponsiveText extends StatelessWidget {
  const ExampleResponsiveText({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: Center(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: ResponsiveHelper.getResponsiveSpacing(context),
            children: [
              // Responsive heading
              Text(
                'Responsive Text',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobileSize: 24,
                    tabletSize: 32,
                    desktopSize: 40,
                  ),
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Responsive body text
              Text(
                'This text adapts to screen size',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobileSize: 14,
                    tabletSize: 16,
                    desktopSize: 18,
                  ),
                  color: const Color(0xFFAAAAAA),
                ),
              ),

              // Responsive button
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context) * 4,
                    vertical: ResponsiveHelper.getResponsiveSpacing(context) * 2,
                  ),
                ),
                child: Text(
                  'Responsive Button',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobileSize: 14,
                      tabletSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Using Custom Races in Navigation
// ============================================================================

class ExampleMainNavigation extends StatelessWidget {
  const ExampleMainNavigation({super.key});

  void _handleNavigation(BuildContext context, String route) {
    switch (route) {
      case 'home':
        Navigator.of(context).pushReplacementNamed('/home');
        break;

      case 'races':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExampleResponsiveRaceCalendarScreen(
              onRaceSelected: (race) {
                // Handle race selection
              },
            ),
          ),
        );
        break;

      case 'season-import':
        // Navigate to custom races import
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SeasonImportScreen(),
          ),
        );
        break;

      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            ElevatedButton(
              onPressed: () => _handleNavigation(context, 'home'),
              child: const Text('Home'),
            ),
            ElevatedButton(
              onPressed: () => _handleNavigation(context, 'races'),
              child: const Text('Races'),
            ),
            ElevatedButton(
              onPressed: () => _handleNavigation(context, 'season-import'),
              child: const Text('Import Races'),
            ),
            ElevatedButton(
              onPressed: () => _handleNavigation(context, 'settings'),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
