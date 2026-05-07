import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Season Import Screen (Fixed)
//  Location: lib/features/races/presentation/season_import_screen.dart
// ─────────────────────────────────────────────────────────────────

const _kBg    = Color(0xFF030308);
const _kCyan  = Color(0xFF00E5FF);
const _kRed   = Color(0xFFFF073A);
const _kGreen = Color(0xFF39FF14);
const _kWhite = Colors.white;

extension _ColorX on Color {
  Color o(double opacity) => withValues(alpha: opacity);
}

class SeasonImportScreen extends StatefulWidget {
  final void Function(SeasonModel season)? onSeasonLoaded;
  final String? targetSeason;

  const SeasonImportScreen({super.key, this.onSeasonLoaded, this.targetSeason});

  @override
  State<SeasonImportScreen> createState() => _SeasonImportScreenState();
}

class _SeasonImportScreenState extends State<SeasonImportScreen>
    with SingleTickerProviderStateMixin {

  final _service = RaceServiceV2();
  final _jsonCtrl = TextEditingController();

  bool         _loading = false;
  String?      _error;
  SeasonModel? _preview;

  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;

  double _pad(BuildContext ctx) =>
      ResponsiveHelper.isMobile(ctx) ? 16 : 24;
  double _sp(BuildContext ctx, double base) =>
      ResponsiveHelper.isMobile(ctx) ? base : base + 4;
  double _fs(BuildContext ctx, double base) =>
      ResponsiveHelper.getResponsiveFontSize(ctx, mobileSize: base);
  double _radius(BuildContext ctx) =>
      ResponsiveHelper.getResponsiveBorderRadius(ctx);
  double _btnH(BuildContext ctx) =>
      ResponsiveHelper.isMobile(ctx) ? 50 : 56;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────

  void _onTextChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() { _preview = null; _error = null; });
      return;
    }
    try {
      final decoded = _validate(value.trim());
      final season  = (decoded['season'] ?? 'custom').toString();
      final races   = decoded['races'] as List<dynamic>;
      setState(() {
        _error   = null;
        _preview = SeasonModel(
          season:      int.tryParse(season) ?? 0,
          lastUpdated: DateTime.now().toIso8601String().split('T').first,
          races: races
              .map((r) => RaceModel.fromJson(r as Map<String, dynamic>))
              .toList(),
        );
      });
    } on FormatException {
      setState(() { _preview = null; _error = 'Invalid JSON — check your file.'; });
    } catch (e) {
      setState(() {
        _preview = null;
        _error   = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      setState(() => _error = 'Clipboard is empty.');
      return;
    }
    _jsonCtrl.text = text;
    _onTextChanged(text);
  }

  /// FIX: Use FilePicker.platform.pickFiles() — the correct API.
  /// The old code used FilePicker.pickFiles() (non-existent static method).
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );


      if (result == null || result.files.isEmpty) return; // user cancelled

      final file  = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        setState(() => _error = 'Could not read file — try pasting instead.');
        return;
      }

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        setState(() => _error = 'File too large (max 5 MB).');
        return;
      }

      final text = utf8.decode(bytes); // FIX: use utf8.decode, not fromCharCodes
      _jsonCtrl.text = text;
      _onTextChanged(text);
    } on PlatformException catch (e) {
      setState(() => _error = 'File picker error: ${e.message}');
    } catch (e) {
      setState(() => _error = 'File picker error: ${e.toString()}');
    }
  }

  Future<void> _loadSeason() async {
    final raw = _jsonCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Paste your races.json content first.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final decoded = _validate(raw);
      final season  = (decoded['season'] ?? 'custom').toString();

      if (widget.targetSeason != null && season != widget.targetSeason) {
        setState(() {
          _loading = false;
          _error = 'Wrong season — this JSON is for $season, '
              'but you selected ${widget.targetSeason}.';
        });
        return;
      }

      final model = await _service.saveAndSwitchCustom(season, raw);
      setState(() => _loading = false);

      if (widget.onSeasonLoaded != null) widget.onSeasonLoaded!(model);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF0A0A14),
          content: Text(
            '✅  Season ${model.season} loaded — ${model.races.length} races',
            style: GoogleFonts.orbitron(
                fontSize: 11, letterSpacing: 1.5, color: _kGreen),
          ),
          duration: const Duration(seconds: 3),
        ));
        if (widget.onSeasonLoaded == null) Navigator.of(context).pop();
      }
    } on FormatException {
      setState(() { _loading = false; _error = 'Invalid JSON — check your file.'; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Map<String, dynamic> _validate(String raw) {
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (!decoded.containsKey('races')) throw Exception("Missing 'races' key.");
    final races = decoded['races'] as List<dynamic>;
    if (races.isEmpty) throw Exception('No races found.');
    final first = races.first as Map<String, dynamic>;
    for (final f in ['round', 'name', 'flag', 'laps']) {
      if (!first.containsKey(f)) {
        throw Exception("Missing required field '$f' in first race.");
      }
    }
    return decoded;
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pad = _pad(context);
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 20, pad, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              SizedBox(height: _sp(context, 20)),
              _buildFormatHint(context),
              SizedBox(height: _sp(context, 12)),
              _buildTextField(context),
              if (_error != null) _buildError(context),
              if (_preview != null) _buildPreview(context),
              SizedBox(height: _sp(context, 16)),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            color: _kWhite.o(0.3), size: _sp(context, 18)),
      ),
      SizedBox(width: _sp(context, 12)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IMPORT SEASON', style: GoogleFonts.orbitron(
            fontSize: _fs(context, 18),
            fontWeight: FontWeight.w900, color: _kWhite)),
        Text(
            widget.targetSeason != null
                ? 'IMPORTING ${widget.targetSeason} SEASON'
                : 'PASTE OR PICK FROM PHONE',
            style: GoogleFonts.orbitron(
                fontSize: _fs(context, 10), letterSpacing: 2,
                color: _kWhite.o(0.3))),
      ]),
    ]);
  }

  Widget _buildFormatHint(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_sp(context, 14)),
      decoration: BoxDecoration(
        border: Border.all(color: _kCyan.o(0.2)),
        borderRadius: BorderRadius.circular(_radius(context)),
        color: _kCyan.o(0.04),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REQUIRED FORMAT', style: GoogleFonts.orbitron(
            fontSize: _fs(context, 10), letterSpacing: 2,
            color: _kCyan.o(0.7))),
        SizedBox(height: _sp(context, 8)),
        Text(
          '{ "season": 2025, "races": [\n'
              '  { "round": 1, "name": "...", "flag": "🏁",\n'
              '    "laps": 57, "circuit": "...", "country": "...",\n'
              '    "date": "2025-03-16", "status": "upcoming",\n'
              '    "distance_km": 308.2 }\n'
              ']}',
          style: GoogleFonts.robotoMono(
              fontSize: _fs(context, 10),
              color: _kWhite.o(0.4), height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(
            color: _error != null ? _kRed.o(0.5) : _kCyan.o(0.2)),
        borderRadius: BorderRadius.circular(_radius(context)),
        color: _kWhite.o(0.02),
      ),
      child: TextField(
        controller: _jsonCtrl,
        maxLines: null,
        expands: true,
        onChanged: _onTextChanged,
        style: GoogleFonts.robotoMono(
            fontSize: _fs(context, 11), color: _kWhite, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Paste your races.json here...',
          hintStyle: GoogleFonts.robotoMono(
              fontSize: _fs(context, 11), color: _kWhite.o(0.2)),
          contentPadding: EdgeInsets.all(_sp(context, 14)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: _sp(context, 10)),
      child: Container(
        padding: EdgeInsets.all(_sp(context, 12)),
        decoration: BoxDecoration(
          border: Border.all(color: _kRed.o(0.4)),
          borderRadius: BorderRadius.circular(_radius(context)),
          color: _kRed.o(0.06),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: _kRed, size: _sp(context, 18)),
          SizedBox(width: _sp(context, 8)),
          Expanded(child: Text(_error!,
              style: GoogleFonts.rajdhani(
                  fontSize: _fs(context, 13), color: _kRed))),
        ]),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final s     = _preview!;
    final first = s.races.isNotEmpty ? s.races.first.name : '—';
    final last  = s.races.isNotEmpty ? s.races.last.name  : '—';
    return Padding(
      padding: EdgeInsets.only(top: _sp(context, 10)),
      child: Container(
        padding: EdgeInsets.all(_sp(context, 14)),
        decoration: BoxDecoration(
          border: Border.all(color: _kGreen.o(0.35)),
          borderRadius: BorderRadius.circular(_radius(context)),
          color: _kGreen.o(0.05),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle_rounded,
                color: _kGreen, size: _sp(context, 16)),
            const SizedBox(width: 8),
            Text('Valid — ready to load', style: GoogleFonts.orbitron(
                fontSize: _fs(context, 11), color: _kGreen,
                fontWeight: FontWeight.w700)),
          ]),
          SizedBox(height: _sp(context, 10)),
          Row(children: [
            _PreviewStat(label: 'SEASON', value: '${s.season}',
                fs: _fs(context, 11)),
            const SizedBox(width: 12),
            _PreviewStat(label: 'RACES', value: '${s.races.length}',
                fs: _fs(context, 11)),
          ]),
          SizedBox(height: _sp(context, 8)),
          Text('OPENS   $first', style: GoogleFonts.rajdhani(
              fontSize: _fs(context, 12), color: _kWhite.o(0.5))),
          Text('FINALE  $last', style: GoogleFonts.rajdhani(
              fontSize: _fs(context, 12), color: _kWhite.o(0.5))),
        ]),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: _pickFile,
        child: Container(
          height: _btnH(context),
          decoration: BoxDecoration(
            border: Border.all(color: _kCyan.o(0.5)),
            borderRadius: BorderRadius.circular(_radius(context)),
            color: _kCyan.o(0.06),
          ),
          child: Center(child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file_rounded,
                  color: _kCyan, size: _sp(context, 20)),
              const SizedBox(width: 10),
              Text('PICK FILE FROM PHONE', style: GoogleFonts.orbitron(
                  fontSize: _fs(context, 11), letterSpacing: 1.5,
                  fontWeight: FontWeight.w700, color: _kCyan)),
            ],
          )),
        ),
      ),
      SizedBox(height: _sp(context, 8)),
      GestureDetector(
        onTap: _pasteFromClipboard,
        child: Container(
          height: _btnH(context),
          decoration: BoxDecoration(
            border: Border.all(color: _kWhite.o(0.12)),
            borderRadius: BorderRadius.circular(_radius(context)),
          ),
          child: Center(child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.content_paste_rounded,
                  color: _kWhite.o(0.5), size: _sp(context, 18)),
              const SizedBox(width: 8),
              Text('PASTE FROM CLIPBOARD', style: GoogleFonts.orbitron(
                  fontSize: _fs(context, 11), letterSpacing: 1.5,
                  color: _kWhite.o(0.4))),
            ],
          )),
        ),
      ),
      SizedBox(height: _sp(context, 10)),
      GestureDetector(
        onTap: (_loading || _preview == null) ? null : _loadSeason,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => AnimatedOpacity(
            opacity: _preview != null ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: _btnH(context),
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(_radius(context)),
                boxShadow: _preview != null
                    ? [BoxShadow(
                    color: _kRed.o(0.4 * _pulseAnim.value),
                    blurRadius: 20)]
                    : [],
              ),
              child: Center(child: _loading
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: _kWhite, strokeWidth: 2))
                  : Text('🏁  LOAD SEASON', style: GoogleFonts.orbitron(
                  fontSize: _fs(context, 12),
                  fontWeight: FontWeight.w900,
                  color: _kWhite, letterSpacing: 1.5))),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final double fs;
  const _PreviewStat({
    required this.label,
    required this.value,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.orbitron(
              fontSize: fs - 2, color: Colors.white38,
              letterSpacing: 1.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.orbitron(
              fontSize: fs + 6, color: Colors.white,
              fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}