import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — My Championship Screen
//  Location: lib/features/championship/presentation/championship_screen.dart
// ─────────────────────────────────────────────────────────────────

const Color _kBg     = Color(0xFF030308);
const Color _kCyan   = Color(0xFF00E5FF);
const Color _kYellow = Color(0xFFFFE600);
const Color _kGreen  = Color(0xFF39FF14);
const Color _kRed    = Color(0xFFFF073A);
const Color _kMagenta = Color(0xFFFF00FF);
const Color _kWhite  = Colors.white;

const _kPoints = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
int pointsForPosition(int pos) => (pos >= 1 && pos <= 20) ? _kPoints[pos - 1] : 0;

class _MyResult {
  final int round;
  final String raceName, flag;
  final int position, points;
  final String tyre;
  final bool hadFastestLap;

  const _MyResult({
    required this.round, required this.raceName, required this.flag,
    required this.position, required this.points,
    required this.tyre, required this.hadFastestLap,
  });

  Map<String, dynamic> toJson() => {
    'round': round, 'raceName': raceName, 'flag': flag,
    'position': position, 'points': points,
    'tyre': tyre, 'hadFastestLap': hadFastestLap,
  };

  factory _MyResult.fromJson(Map<String, dynamic> j) => _MyResult(
    round: j['round'] as int,
    raceName: j['raceName'] as String,
    flag: j['flag'] as String,
    position: j['position'] as int,
    points: j['points'] as int,
    tyre: j['tyre'] as String,
    hadFastestLap: j['hadFastestLap'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────

class ChampionshipScreen extends StatefulWidget {
  const ChampionshipScreen({super.key});

  @override
  State<ChampionshipScreen> createState() => _ChampionshipScreenState();

  static Future<void> recordResult({
    required int round,
    required String raceName,
    required String flag,
    required int position,
    required String tyre,
    required bool hadFastestLap,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('my_championship') ?? '[]';
    final list  = (jsonDecode(raw) as List<dynamic>)
        .map((j) => _MyResult.fromJson(j as Map<String, dynamic>)).toList();

    list.removeWhere((r) => r.round == round);

    int pts = pointsForPosition(position);
    if (hadFastestLap && position <= 10) pts++;

    list.add(_MyResult(
      round: round, raceName: raceName, flag: flag,
      position: position, points: pts,
      tyre: tyre, hadFastestLap: hadFastestLap,
    ));
    list.sort((a, b) => a.round.compareTo(b.round));

    await prefs.setString('my_championship',
        jsonEncode(list.map((r) => r.toJson()).toList()));
  }
}

class _ChampionshipScreenState extends State<ChampionshipScreen>
    with SingleTickerProviderStateMixin {

  List<_MyResult> _results = [];
  bool _loading = true;
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _loadResults();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('my_championship') ?? '[]';
    final list = jsonDecode(raw) as List<dynamic>;
    setState(() {
      _results = list
          .map((j) => _MyResult.fromJson(j as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
    _barCtrl.forward();
  }

  // FIX: removed unused _saveResults method (was causing warning)
  // Results are saved directly in ChampionshipScreen.recordResult()

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A18),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            // FIX: .withValues(alpha: ) → .withValues(alpha:)
            side: BorderSide(color: _kRed.withValues(alpha: 0.4))),
        title: Text('RESET SEASON', style: GoogleFonts.orbitron(
            color: _kRed, fontSize: 14, fontWeight: FontWeight.w900)),
        content: Text('This will delete all your race results.\nAre you sure?',
            style: GoogleFonts.rajdhani(
                color: _kWhite.withValues(alpha: 0.7), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.orbitron(
                color: _kCyan, fontSize: 10)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('RESET', style: GoogleFonts.orbitron(
                color: _kRed, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('my_championship');
      setState(() => _results = []);
    }
  }

  int get _totalPoints   => _results.fold(0, (s, r) => s + r.points);
  int get _racesCompleted => _results.length;
  int get _wins           => _results.where((r) => r.position == 1).length;
  int get _podiums        => _results.where((r) => r.position <= 3).length;
  int get _bestPos        => _results.isEmpty
      ? 0
      : _results.map((r) => r.position).reduce((a, b) => a < b ? a : b);
  double get _avgPos => _results.isEmpty
      ? 0
      : _results.map((r) => r.position).reduce((a, b) => a + b) /
      _results.length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kCyan)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _results.isEmpty ? _buildEmpty() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: _kWhite.withValues(alpha: 0.3), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY SEASON', style: GoogleFonts.orbitron(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _kWhite,
                    shadows: [Shadow(
                        color: _kCyan.withValues(alpha: 0.4), blurRadius: 12)])),
                Text('PERSONAL CHAMPIONSHIP TRACKER',
                    style: GoogleFonts.orbitron(fontSize: 8, letterSpacing: 2,
                        color: _kWhite.withValues(alpha: 0.3))),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: _kRed.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(4),
                  color: _kRed.withValues(alpha: 0.06),
                ),
                child: Text('RESET', style: GoogleFonts.orbitron(
                    fontSize: 8, fontWeight: FontWeight.w900,
                    color: _kRed, letterSpacing: 2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // FIX: added const
          const Text('🏁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text('NO RACES YET', style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w900,
              color: _kWhite.withValues(alpha: 0.4), letterSpacing: 3)),
          const SizedBox(height: 10),
          Text('Complete a race simulation\nto track your championship.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(fontSize: 14,
                  color: _kWhite.withValues(alpha: 0.25), height: 1.6)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _kCyan.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(4),
              color: _kCyan.withValues(alpha: 0.08),
            ),
            // FIX: added const
            child: const Text('GO TO CALENDAR → RACE SIM',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _kCyan,
                    letterSpacing: 2,
                    fontFamily: 'Orbitron')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        _buildTotalPoints(),
        const SizedBox(height: 14),
        _buildStatsRow(),
        const SizedBox(height: 14),
        _buildProgressChart(),
        const SizedBox(height: 14),
        _buildResultsList(),
      ],
    );
  }

  Widget _buildTotalPoints() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: _kYellow.withValues(alpha: 0.4), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: _kYellow.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAMPIONSHIP POINTS',
                    style: GoogleFonts.orbitron(fontSize: 9, letterSpacing: 3,
                        color: _kYellow.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Text('$_totalPoints', style: GoogleFonts.orbitron(
                    fontSize: 52, fontWeight: FontWeight.w900, color: _kYellow,
                    height: 0.9,
                    shadows: [Shadow(
                        color: _kYellow.withValues(alpha: 0.5), blurRadius: 20)])),
                const SizedBox(height: 4),
                Text('$_racesCompleted of 24 races completed',
                    style: GoogleFonts.rajdhani(fontSize: 12,
                        color: _kWhite.withValues(alpha: 0.4))),
              ],
            ),
          ),
          _buildProgressRing(),
        ],
      ),
    );
  }

  Widget _buildProgressRing() {
    final progress = _racesCompleted / 24;
    return SizedBox(
      width: 72, height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => CircularProgressIndicator(
              value: progress * _barAnim.value,
              strokeWidth: 5,
              backgroundColor: _kWhite.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_kYellow),
            ),
          ),
          Text('${(_racesCompleted / 24 * 100).toInt()}%',
              style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w900, color: _kYellow)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('WINS', '$_wins', _kCyan)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('PODIUMS', '$_podiums', _kGreen)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('BEST', _bestPos > 0 ? 'P$_bestPos' : '—', _kYellow)),
        const SizedBox(width: 8),
        Expanded(child: _statCard(
          'AVG POS',
          _results.isEmpty ? '—' : 'P${_avgPos.toStringAsFixed(1)}',
          _kWhite.withValues(alpha: 0.6),
        )),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.04),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.orbitron(
            fontSize: 18, fontWeight: FontWeight.w900, color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8)])),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.orbitron(
            fontSize: 7, letterSpacing: 1,
            color: _kWhite.withValues(alpha: 0.3))),
      ]),
    );
  }

  Widget _buildProgressChart() {
    if (_results.length < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: _kWhite.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(6),
        color: _kWhite.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POINTS PROGRESSION', style: GoogleFonts.orbitron(
              fontSize: 10, letterSpacing: 3,
              color: _kWhite.withValues(alpha: 0.4))),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) => CustomPaint(
                painter: _ChartPainter(_results, _barAnim.value),
                size: const Size(double.infinity, 80),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RACE RESULTS', style: GoogleFonts.orbitron(
            fontSize: 10, letterSpacing: 3,
            color: _kWhite.withValues(alpha: 0.4))),
        const SizedBox(height: 10),
        ..._results.reversed.map((r) => _resultRow(r)),
      ],
    );
  }

  Widget _resultRow(_MyResult r) {
    final isWin    = r.position == 1;
    final isPodium = r.position <= 3;
    final isPoints = r.position <= 10;
    final posColor = isWin
        ? _kYellow
        : isPodium
        ? _kCyan
        : isPoints
        ? _kGreen
        : _kWhite.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
            color: isWin
                ? _kYellow.withValues(alpha: 0.4)
                : _kWhite.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(6),
        color: isWin
            ? _kYellow.withValues(alpha: 0.05)
            : _kWhite.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _kWhite.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _kWhite.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Text('R${r.round}', style: GoogleFonts.orbitron(
                  fontSize: 8, fontWeight: FontWeight.w900,
                  color: _kWhite.withValues(alpha: 0.4))),
            ),
          ),
          const SizedBox(width: 12),
          Text(r.flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.raceName, style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _kWhite)),
                Row(children: [
                  Text(r.tyre, style: GoogleFonts.orbitron(
                      fontSize: 8, color: _kWhite.withValues(alpha: 0.3))),
                  if (r.hadFastestLap) ...[
                    const SizedBox(width: 6),
                    Text('⚡ FL', style: GoogleFonts.orbitron(
                        fontSize: 8, color: _kMagenta)),
                  ],
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('P${r.position}', style: GoogleFonts.orbitron(
                  fontSize: 18, fontWeight: FontWeight.w900, color: posColor,
                  shadows: [Shadow(
                      color: posColor.withValues(alpha: 0.5), blurRadius: 8)])),
              Text('+${r.points} PTS', style: GoogleFonts.orbitron(
                  fontSize: 9, color: posColor.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Points chart painter ──────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final List<_MyResult> results;
  final double anim;

  const _ChartPainter(this.results, this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    final cumulative = <int>[];
    int running = 0;
    for (final r in results) {
      running += r.points;
      cumulative.add(running);
    }
    final maxPts = cumulative.last.toDouble();
    if (maxPts == 0) return;

    final n = cumulative.length;
    final stepX = size.width / (n > 1 ? n - 1 : 1);

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < n; i++) {
      final x = i * stepX;
      final y = size.height - (cumulative[i] / maxPts) * size.height * anim;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((n - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = _kCyan.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = _kCyan
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (int i = 0; i < n; i++) {
      final x = i * stepX;
      final y = size.height - (cumulative[i] / maxPts) * size.height * anim;
      final isWin = results[i].position == 1;
      canvas.drawCircle(
        Offset(x, y),
        isWin ? 5 : 3,
        Paint()..color = isWin ? _kYellow : _kCyan,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.anim != anim || old.results.length != results.length;
}