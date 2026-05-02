import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Season Picker Screen
//  Location: lib/features/seasons/presentation/season_picker_screen.dart
//
//  Lets the user pick 2023 / 2024 / 2025 season or paste their
//  own custom races.json. Uses RaceServiceV2 + CustomRacesManager.
// ─────────────────────────────────────────────────────────────────

const _kBg     = Color(0xFF030308);
const _kCyan   = Color(0xFF00E5FF);
const _kYellow = Color(0xFFFFE600);
const _kGreen  = Color(0xFF39FF14);
const _kRed    = Color(0xFFFF073A);
const _kWhite  = Colors.white;

class _Option {
  final String season;
  final String title;
  final String subtitle;
  final Color  color;
  final String emoji;
  final bool   isCustomInput;

  const _Option({
    required this.season,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.emoji,
    this.isCustomInput = false,
  });
}

const _options = [
  _Option(season: '2024', title: '2024 SEASON',
      subtitle: '24 races · Verstappen champion',
      color: _kCyan,   emoji: '🏆'),
  _Option(season: '2025', title: '2025 SEASON',
      subtitle: '24 races · Current season',
      color: _kGreen,  emoji: '🔥'),
  _Option(season: '2023', title: '2023 SEASON',
      subtitle: '22 races · Verstappen champion',
      color: _kYellow, emoji: '⚡'),
  _Option(season: 'custom', title: 'CUSTOM SEASON',
      subtitle: 'Paste your own races.json content',
      color: _kRed,    emoji: '📂', isCustomInput: true),
];

// ─────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────

class SeasonPickerScreen extends StatefulWidget {
  final void Function(SeasonModel season) onSeasonSelected;

  const SeasonPickerScreen({super.key, required this.onSeasonSelected});

  @override
  State<SeasonPickerScreen> createState() => _SeasonPickerScreenState();
}

class _SeasonPickerScreenState extends State<SeasonPickerScreen>
    with SingleTickerProviderStateMixin {

  final _service = RaceServiceV2();
  final _manager = CustomRacesManager();
  final _jsonCtrl = TextEditingController();

  String  _activeSeason = '2024';
  bool    _loading      = false;
  bool    _showPaste    = false;
  String? _error;
  Map<String, String?> _customPreviews = {};

  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _init();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final active = await _manager.getActiveSeason();
    final previews = <String, String?>{};
    for (final s in ['2023', '2024', '2025', 'custom']) {
      final has = await _manager.hasCustomRaces(s);
      previews[s] = has ? '✓ Custom data loaded' : null;
    }
    if (mounted) {
      setState(() {
        _activeSeason = active;
        _customPreviews = previews;
      });
    }
  }

  // ── Select built-in season ─────────────────────────────────────
  Future<void> _pickSeason(String season) async {
    setState(() { _loading = true; _error = null; });
    try {
      final model = await _service.switchSeason(season);
      if (model.races.isEmpty) {
        throw Exception(
          'No races found for $season.\n'
              'Add assets/data/races_$season.json to your project\n'
              'or paste a custom races.json below.',
        );
      }
      setState(() { _activeSeason = season; _loading = false; });
      widget.onSeasonSelected(model);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Save and load custom JSON ──────────────────────────────────
  Future<void> _loadCustom() async {
    final raw = _jsonCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Please paste your races.json content first.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final decoded = _validate(raw);
      final races   = decoded['races'] as List<dynamic>;
      final season  = (decoded['season'] ?? 'custom').toString();

      final model = await _service.saveAndSwitchCustom(season, raw);

      setState(() {
        _loading      = false;
        _activeSeason = season;
        _showPaste    = false;
        _customPreviews[season] = '${races.length} races · Season $season';
        _jsonCtrl.clear();
      });

      widget.onSeasonSelected(model);

    } on FormatException {
      setState(() { _loading = false; _error = 'Invalid JSON. Check your file.'; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Map<String, dynamic> _validate(String raw) {
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (!decoded.containsKey('races')) {
      throw Exception("Missing 'races' key.");
    }
    final races = decoded['races'] as List<dynamic>;
    if (races.isEmpty) throw Exception('No races found.');
    final first = races.first as Map<String, dynamic>;
    for (final f in ['round', 'name', 'flag', 'laps']) {
      if (!first.containsKey(f)) throw Exception("Missing '$f' in first race.");
    }
    return decoded;
  }

  // ─────────────────────────────────────────────────────────────
  //  RESPONSIVE HELPERS  (wraps your ResponsiveHelper statics)
  // ─────────────────────────────────────────────────────────────

  double _pagePad(BuildContext ctx) =>
      ResponsiveHelper.isMobile(ctx) ? 16 : 24;

  /// Scales a base value up slightly on larger screens
  double _sp(BuildContext ctx, double base) =>
      ResponsiveHelper.isMobile(ctx) ? base : base + 4;

  double _fs(BuildContext ctx, double base) =>
      ResponsiveHelper.getResponsiveFontSize(ctx, mobileSize: base);

  double _radius(BuildContext ctx) =>
      ResponsiveHelper.getResponsiveBorderRadius(ctx);

  double _btnHeight(BuildContext ctx) =>
      ResponsiveHelper.isMobile(ctx) ? 50 : 56;

  // Named font-size shortcuts
  double _headingMd(BuildContext ctx) => _fs(ctx, 18);
  double _headingSm(BuildContext ctx) => _fs(ctx, 15);
  double _headingXs(BuildContext ctx) => _fs(ctx, 11);
  double _bodyMd(BuildContext ctx)    => _fs(ctx, 13);
  double _bodySm(BuildContext ctx)    => _fs(ctx, 11);
  double _iconSm(BuildContext ctx)    => _sp(ctx, 18);
  double _iconMd(BuildContext ctx)    => _sp(ctx, 20);
  double _iconLg(BuildContext ctx)    => _sp(ctx, 24);

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _showPaste ? _buildPasteView(context) : _buildPickerView(context),
      ),
    );
  }

  // ── Picker list ────────────────────────────────────────────────
  Widget _buildPickerView(BuildContext context) {
    final pad = _pagePad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 20),
      child: Column(children: [
        _buildHeader(context, 'SELECT SEASON', 'CHOOSE YOUR F1 CALENDAR'),
        SizedBox(height: _sp(context, 28)),

        Expanded(child: ListView.separated(
          itemCount: _options.length,
          separatorBuilder: (_, __) => SizedBox(height: _sp(context, 12)),
          itemBuilder: (ctx, i) => _buildOptionCard(ctx, _options[i]),
        )),

        if (_error != null) _buildError(context),
        if (_loading) Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: const CircularProgressIndicator(color: _kCyan, strokeWidth: 2),
        ),
      ]),
    );
  }

  Widget _buildOptionCard(BuildContext context, _Option opt) {
    final isActive  = _activeSeason == opt.season;
    final hasCustom = _customPreviews[opt.season] != null;
    final preview   = _customPreviews[opt.season];
    final color     = opt.color;

    return GestureDetector(
      onTap: _loading ? null : () {
        if (opt.isCustomInput) {
          setState(() { _showPaste = true; _error = null; });
        } else {
          _pickSeason(opt.season);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(_sp(context, 18)),
        decoration: BoxDecoration(
          border: Border.all(
              color: isActive ? color : color.withOpacity(0.22),
              width: isActive ? 2 : 1),
          borderRadius: BorderRadius.circular(_radius(context)),
          color: isActive ? color.withOpacity(0.08) : _kWhite.withOpacity(0.02),
        ),
        child: Row(children: [
          Text(opt.emoji, style: TextStyle(fontSize: _fs(context, 30))),
          SizedBox(width: _sp(context, 16)),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(opt.title, style: GoogleFonts.orbitron(
                  fontSize: _headingSm(context),
                  fontWeight: FontWeight.w900,
                  color: isActive ? color : _kWhite)),
              SizedBox(height: _sp(context, 3)),
              Text(
                hasCustom && preview != null ? preview : opt.subtitle,
                style: GoogleFonts.rajdhani(
                    fontSize: _bodyMd(context),
                    color: isActive
                        ? color.withOpacity(0.8)
                        : _kWhite.withOpacity(0.4)),
              ),
            ],
          )),
          if (isActive)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                padding: EdgeInsets.symmetric(
                    horizontal: _sp(context, 10),
                    vertical: _sp(context, 5)),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(_radius(context)),
                  color: color.withOpacity(0.12),
                ),
                child: Text('ACTIVE', style: GoogleFonts.orbitron(
                    fontSize: _bodySm(context),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: color.withOpacity(_pulseAnim.value))),
              ),
            )
          else
            Icon(
              opt.isCustomInput
                  ? Icons.upload_file_rounded
                  : Icons.chevron_right_rounded,
              color: color.withOpacity(0.5),
              size: _iconLg(context),
            ),
        ]),
      ),
    );
  }

  // ── Paste view ─────────────────────────────────────────────────
  Widget _buildPasteView(BuildContext context) {
    final pad = _pagePad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 20),
      child: Column(children: [
        _buildHeader(context, 'CUSTOM SEASON', 'PASTE YOUR RACES.JSON CONTENT',
            onBack: () => setState(() { _showPaste = false; _error = null; })),
        SizedBox(height: _sp(context, 16)),

        // Instructions box
        Container(
          padding: EdgeInsets.all(_sp(context, 14)),
          decoration: BoxDecoration(
            border: Border.all(color: _kCyan.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(_radius(context)),
            color: _kCyan.withOpacity(0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REQUIRED FORMAT', style: GoogleFonts.orbitron(
                  fontSize: _headingXs(context), letterSpacing: 2,
                  color: _kCyan.withOpacity(0.7))),
              SizedBox(height: _sp(context, 10)),
              Text(
                '{ "season": 2025, "races": [\n'
                    '  { "round": 1, "name": "...", "flag": "🏁",\n'
                    '    "laps": 57, "circuit": "...", "country": "...",\n'
                    '    "date": "2025-03-16", "status": "upcoming",\n'
                    '    "distance_km": 308.2 }\n'
                    ']}',
                style: GoogleFonts.robotoMono(
                    fontSize: _bodySm(context) - 1,
                    color: _kWhite.withOpacity(0.45), height: 1.5),
              ),
            ],
          ),
        ),

        SizedBox(height: _sp(context, 12)),

        // Text field
        Expanded(child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: _error != null
                    ? _kRed.withOpacity(0.5)
                    : _kCyan.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(_radius(context)),
            color: _kWhite.withOpacity(0.02),
          ),
          child: TextField(
            controller: _jsonCtrl,
            maxLines: null, expands: true,
            style: GoogleFonts.robotoMono(
                fontSize: _bodySm(context), color: _kWhite, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Paste your races.json here...',
              hintStyle: GoogleFonts.robotoMono(
                  fontSize: _bodySm(context),
                  color: _kWhite.withOpacity(0.2)),
              contentPadding: EdgeInsets.all(_sp(context, 14)),
              border: InputBorder.none,
            ),
          ),
        )),

        if (_error != null) _buildError(context),

        SizedBox(height: _sp(context, 14)),

        Row(children: [
          // Cancel
          Expanded(child: GestureDetector(
            onTap: () => setState(() { _showPaste = false; _error = null; }),
            child: Container(
              height: _btnHeight(context),
              decoration: BoxDecoration(
                border: Border.all(color: _kWhite.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(_radius(context)),
              ),
              child: Center(child: Text('CANCEL',
                  style: GoogleFonts.orbitron(
                      fontSize: _headingXs(context),
                      letterSpacing: 2,
                      color: _kWhite.withOpacity(0.4)))),
            ),
          )),
          SizedBox(width: _sp(context, 12)),
          // Load
          Expanded(flex: 2, child: GestureDetector(
            onTap: _loading ? null : _loadCustom,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                height: _btnHeight(context),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(_radius(context)),
                  boxShadow: [BoxShadow(
                      color: _kRed.withOpacity(0.4 * _pulseAnim.value),
                      blurRadius: 16)],
                ),
                child: Center(child: _loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: _kWhite, strokeWidth: 2))
                    : Text('📂  LOAD SEASON',
                    style: GoogleFonts.orbitron(
                        fontSize: _headingXs(context),
                        fontWeight: FontWeight.w900,
                        color: _kWhite, letterSpacing: 1))),
              ),
            ),
          )),
        ]),
      ]),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String title, String sub,
      {VoidCallback? onBack}) {
    return Row(children: [
      GestureDetector(
        onTap: onBack ?? () => Navigator.pop(context),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            color: _kWhite.withOpacity(0.3), size: _iconSm(context)),
      ),
      SizedBox(width: _sp(context, 12)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.orbitron(
            fontSize: _headingMd(context),
            fontWeight: FontWeight.w900, color: _kWhite)),
        Text(sub, style: GoogleFonts.orbitron(
            fontSize: _bodySm(context), letterSpacing: 2,
            color: _kWhite.withOpacity(0.3))),
      ]),
    ]);
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _sp(context, 10)),
      child: Container(
        padding: EdgeInsets.all(_sp(context, 12)),
        decoration: BoxDecoration(
          border: Border.all(color: _kRed.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(_radius(context)),
          color: _kRed.withOpacity(0.06),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: _kRed, size: _iconMd(context)),
          SizedBox(width: _sp(context, 10)),
          Expanded(child: Text(_error!,
              style: GoogleFonts.rajdhani(
                  fontSize: _bodyMd(context), color: _kRed))),
        ]),
      ),
    );
  }
}