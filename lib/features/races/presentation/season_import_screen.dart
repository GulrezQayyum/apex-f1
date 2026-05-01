import 'package:flutter/material.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';
import 'dart:convert';
// FIX: removed unused 'dart:io' import — this file doesn't use File directly

class SeasonImportScreen extends StatefulWidget {
  const SeasonImportScreen({super.key});

  @override
  State<SeasonImportScreen> createState() => _SeasonImportScreenState();
}

class _SeasonImportScreenState extends State<SeasonImportScreen> {
  final List<String> _seasons = ['2023', '2024', '2025'];
  late Map<String, bool> _hasCustom;
  String? _selectedSeason;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hasCustom = {for (var season in _seasons) season: false};
    _checkCustomRaces();
  }

  Future<void> _checkCustomRaces() async {
    for (var season in _seasons) {
      final has = await CustomRacesManager().hasCustomRaces(season);
      if (mounted) {
        setState(() => _hasCustom[season] = has);
      }
    }
  }

  // FIX: removed `Future.delayed(Duration.zero, _showJsonInput)` anti-pattern.
  // setState is now done before calling _showJsonInput directly.
  void _selectSeasonAndShowInput(String season) {
    setState(() => _selectedSeason = season);
    _showJsonInput();
  }

  void _showJsonInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF0A0A14),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Import Races for $_selectedSeason',
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rajdhani',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 15,
                  minLines: 10,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Paste your races.json content here...',
                    hintStyle: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00E5FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00E5FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF00FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a1a2e),
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF00E5FF)),
                      ),
                    ),
                    ElevatedButton(
                      // FIX: pass dialogContext so Navigator.pop targets
                      // the dialog, not the whole route stack
                      onPressed: () =>
                          _importRaces(controller.text, dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                      ),
                      child: const Text(
                        'Import',
                        style: TextStyle(color: Color(0xFF030308)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importRaces(String jsonContent, BuildContext dialogContext) async {
    if (jsonContent.isEmpty) {
      setState(() => _errorMessage = 'Please paste JSON content');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final parsed = jsonDecode(jsonContent);

      if (!CustomRacesManager.validateRacesStructure(parsed)) {
        setState(() => _errorMessage = 'Invalid races.json structure');
        if (dialogContext.mounted) Navigator.pop(dialogContext);
        setState(() => _isLoading = false);
        return;
      }

      await CustomRacesManager().saveCustomRaces(_selectedSeason!, jsonContent);

      if (mounted) {
        setState(() {
          _hasCustom[_selectedSeason!] = true;
          _errorMessage = null;
        });

        if (dialogContext.mounted) Navigator.pop(dialogContext);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('✓ Races for $_selectedSeason imported successfully'),
            backgroundColor: const Color(0xFF00E5FF),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
      if (dialogContext.mounted) Navigator.pop(dialogContext);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomRaces(String season) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A14),
        title: const Text(
          'Delete Custom Races?',
          style: TextStyle(color: Color(0xFF00E5FF)),
        ),
        content: Text(
          'This will delete custom races for $season',
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF00E5FF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF00FF))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CustomRacesManager().deleteCustomRaces(season);
        if (mounted) {
          setState(() => _hasCustom[season] = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Deleted custom races for $season'),
              backgroundColor: const Color(0xFF00E5FF),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        title: const Text(
          'SEASON IMPORT',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontFamily: 'Rajdhani',
            letterSpacing: 2,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      )
          : SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(spacing),
            SizedBox(height: spacing * 2),
            _buildSeasonGrid(spacing, isMobile),
            if (_errorMessage != null) ...[
              SizedBox(height: spacing),
              _buildErrorMessage(),
            ],
            SizedBox(height: spacing),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import Custom Races',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Rajdhani',
          ),
        ),
        SizedBox(height: spacing),
        const Text(
          'Add your own races.json files for 2023, 2024, or 2025 seasons',
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 14,
            fontFamily: 'Rajdhani',
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonGrid(double spacing, bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: isMobile ? 1.2 : 0.9,
      children: _seasons
          .map((season) => _buildSeasonCard(season, spacing))
          .toList(),
    );
  }

  Widget _buildSeasonCard(String season, double spacing) {
    final hasCustom = _hasCustom[season] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00E5FF)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF0A0A14),
      ),
      padding: EdgeInsets.all(spacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            season,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          if (hasCustom)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 20),
                SizedBox(width: 4),
                Text(
                  'Custom Loaded',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 12,
                    fontFamily: 'Rajdhani',
                  ),
                ),
              ],
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                // FIX: use the new combined method instead of the
                // setState + Future.delayed hack
                onPressed: () => _selectSeasonAndShowInput(season),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  hasCustom ? 'Update' : 'Import',
                  style: const TextStyle(
                    color: Color(0xFF030308),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasCustom) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _deleteCustomRaces(season),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFFFF00FF)),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFFFF00FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF00FF)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1a0a0f),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Color(0xFFFF00FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 12,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context)),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00E5FF), width: 0.5),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF0A0A14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'JSON Format Requirements:',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Must contain "races" array\n'
                '• Each race needs: round, name, circuit, country, date\n'
                '• Optional: status, results, lapRecord\n'
                '• Max file size: 5MB',
            style: TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 12,
              fontFamily: 'Courier',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}