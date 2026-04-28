import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/simulation/presentation/race_sim_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Qualifying Screen
//  Location: lib/features/simulation/presentation/qualifying_screen.dart
//
//  Full Q1 → Q2 → Q3 qualifying session.
//  Player sets lap time by tapping at the right moment.
//  Rivals have personality-based lap times.
//  Earns a grid slot that seeds starting position in the race sim.
// ─────────────────────────────────────────────────────────────────

const _kBg     = Color(0xFF030308);
const _kCyan   = Color(0xFF00E5FF);
const _kYellow = Color(0xFFFFE600);
const _kRed    = Color(0xFFFF073A);
const _kGreen  = Color(0xFF39FF14);
const _kWhite  = Colors.white;
const _kPurple = Color(0xFFFF00FF);

// ── Rival with personality ────────────────────────────────────────
class _QualDriver {
  final String id, shortName, flag, team;
  final Color teamColor;
  final double baseTime;   // seconds, lower = faster
  final double consistency; // 0-1, higher = more consistent

  String? lapTime;
  int? position;

  _QualDriver({
    required this.id, required this.shortName, required this.flag,
    required this.team, required this.teamColor,
    required this.baseTime, required this.consistency,
  });

  String get lapDisplay => lapTime ?? '--:--.---';
}

final _allRivals = [
  _QualDriver(id:'ver', shortName:'VER', flag:'🇳🇱', team:'Red Bull',  teamColor:const Color(0xFF3671C6), baseTime:88.2, consistency:0.96),
  _QualDriver(id:'nor', shortName:'NOR', flag:'🇬🇧', team:'McLaren',   teamColor:const Color(0xFFFF8000), baseTime:88.4, consistency:0.94),
  _QualDriver(id:'lec', shortName:'LEC', flag:'🇲🇨', team:'Ferrari',   teamColor:const Color(0xFFE8002D), baseTime:88.5, consistency:0.93),
  _QualDriver(id:'ham', shortName:'HAM', flag:'🇬🇧', team:'Mercedes',  teamColor:const Color(0xFF27F4D2), baseTime:88.6, consistency:0.95),
  _QualDriver(id:'sai', shortName:'SAI', flag:'🇪🇸', team:'Ferrari',   teamColor:const Color(0xFFE8002D), baseTime:88.7, consistency:0.92),
  _QualDriver(id:'rus', shortName:'RUS', flag:'🇬🇧', team:'Mercedes',  teamColor:const Color(0xFF27F4D2), baseTime:88.8, consistency:0.91),
  _QualDriver(id:'pia', shortName:'PIA', flag:'🇦🇺', team:'McLaren',   teamColor:const Color(0xFFFF8000), baseTime:88.9, consistency:0.90),
  _QualDriver(id:'per', shortName:'PER', flag:'🇲🇽', team:'Red Bull',  teamColor:const Color(0xFF3671C6), baseTime:89.1, consistency:0.88),
  _QualDriver(id:'alo', shortName:'ALO', flag:'🇪🇸', team:'Aston M.',  teamColor:const Color(0xFF358C75), baseTime:89.4, consistency:0.92),
  _QualDriver(id:'str', shortName:'STR', flag:'🇨🇦', team:'Aston M.',  teamColor:const Color(0xFF358C75), baseTime:90.0, consistency:0.80),
  _QualDriver(id:'gas', shortName:'GAS', flag:'🇫🇷', team:'Alpine',    teamColor:const Color(0xFF0090FF), baseTime:89.7, consistency:0.85),
  _QualDriver(id:'oco', shortName:'OCO', flag:'🇫🇷', team:'Alpine',    teamColor:const Color(0xFF0090FF), baseTime:89.8, consistency:0.84),
  _QualDriver(id:'tsu', shortName:'TSU', flag:'🇯🇵', team:'RB',        teamColor:const Color(0xFF6692FF), baseTime:89.9, consistency:0.83),
  _QualDriver(id:'hul', shortName:'HUL', flag:'🇩🇪', team:'Haas',      teamColor:const Color(0xFFB6BABD), baseTime:90.1, consistency:0.82),
  _QualDriver(id:'mag', shortName:'MAG', flag:'🇩🇰', team:'Haas',      teamColor:const Color(0xFFB6BABD), baseTime:90.2, consistency:0.79),
  _QualDriver(id:'alb', shortName:'ALB', flag:'🇹🇭', team:'Williams',  teamColor:const Color(0xFF64C4FF), baseTime:90.4, consistency:0.81),
  _QualDriver(id:'ric', shortName:'RIC', flag:'🇦🇺', team:'RB',        teamColor:const Color(0xFF6692FF), baseTime:90.5, consistency:0.78),
  _QualDriver(id:'bot', shortName:'BOT', flag:'🇫🇮', team:'Sauber',    teamColor:const Color(0xFF52E252), baseTime:90.7, consistency:0.77),
  _QualDriver(id:'zho', shortName:'ZHO', flag:'🇨🇳', team:'Sauber',    teamColor:const Color(0xFF52E252), baseTime:90.9, consistency:0.76),
];

String _fmtTime(double seconds) {
  final m = (seconds ~/ 60);
  final s = seconds % 60;
  final ms = ((s - s.truncate()) * 1000).round();
  return '${m}:${s.truncate().toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
}

// ─────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────

class QualifyingScreen extends StatefulWidget {
  final RaceModel race;
  final String playerDriverId;
  final String playerDriverName;
  final String playerTeamName;
  final String playerFlag;

  const QualifyingScreen({
    super.key,
    required this.race,
    required this.playerDriverId,
    required this.playerDriverName,
    required this.playerTeamName,
    required this.playerFlag,
  });

  @override
  State<QualifyingScreen> createState() => _QualifyingScreenState();
}

class _QualifyingScreenState extends State<QualifyingScreen>
    with TickerProviderStateMixin {

  final _rng = Random();

  // Session state
  int _session = 1;         // 1=Q1, 2=Q2, 3=Q3
  bool _onLap = false;      // is player currently on flying lap
  bool _lapDone = false;    // player has set a time this session
  bool _sessionDone = false;
  bool _eliminated = false;
  bool _qualDone = false;   // all 3 sessions complete
  int _gridPosition = 20;

  // Player time this session
  double? _playerTime;
  double? _playerBestTime;

  // Rival times per session
  List<_QualDriver> _sessionDrivers = [];
  List<_QualDriver> _fullGrid = [];

  // Timing bar animation
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  // Lap timer
  Timer? _lapTimer;
  double _lapProgress = 0.0; // 0..1 over ~90 seconds of sim lap
  double _timingBarPos = 0.0; // 0..1 oscillating for player to tap
  Timer? _timingTimer;
  bool _showTimingBar = false;

  // Sector display
  String _sector1 = '--:--.---';
  String _sector2 = '--:--.---';
  String _sector3 = '--:--.---';
  Color _s1Color = _kWhite;
  Color _s2Color = _kWhite;
  Color _s3Color = _kWhite;

  // Pulse for tap button
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _startSession();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _pulseCtrl.dispose();
    _lapTimer?.cancel();
    _timingTimer?.cancel();
    super.dispose();
  }

  // ── Session setup ───────────────────────────────────────────────

  void _startSession() {
    _sessionDone = false;
    _lapDone = false;
    _onLap = false;
    _playerTime = null;
    _sector1 = '--:--.---';
    _sector2 = '--:--.---';
    _sector3 = '--:--.---';
    _s1Color = _kWhite;
    _s2Color = _kWhite;
    _s3Color = _kWhite;

    // Pick rivals for this session
    if (_session == 1) {
      _sessionDrivers = List.from(_allRivals);
    } else if (_session == 2) {
      // Top 15 from Q1
      _sessionDrivers = _allRivals.where((d) =>
      _fullGrid.indexWhere((g) => g.id == d.id) < 15).toList();
    } else {
      // Top 10 from Q2
      _sessionDrivers = _allRivals.where((d) =>
      _fullGrid.indexWhere((g) => g.id == d.id) < 10).toList();
    }

    setState(() {});
  }

  // ── Timing bar (oscillates while on lap) ───────────────────────

  void _startTimingBar() {
    _showTimingBar = true;
    double direction = 1.0;
    _timingBarPos = 0.0;
    _timingTimer?.cancel();
    _timingTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _timingBarPos += direction * 0.012;
        if (_timingBarPos >= 1.0) { _timingBarPos = 1.0; direction = -1.0; }
        if (_timingBarPos <= 0.0) { _timingBarPos = 0.0; direction = 1.0; }
      });
    });
  }

  void _stopTimingBar() {
    _timingTimer?.cancel();
    setState(() => _showTimingBar = false);
  }

  // ── Start flying lap ───────────────────────────────────────────

  void _startLap() {
    if (_onLap || _lapDone) return;
    setState(() {
      _onLap = true;
      _lapProgress = 0.0;
    });

    // Sector 1 timing bar (tap for S1)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _startTimingBar();
    });
  }

  // ── Player taps to set sector time ─────────────────────────────

  void _onTap() {
    if (!_onLap || !_showTimingBar) return;
    _stopTimingBar();

    // Calculate sector quality: centre of bar = purple, edges = yellow, very edge = green
    final distFromCentre = ((_timingBarPos - 0.5) * 2).abs(); // 0=perfect, 1=edge
    final sectorQuality = 1.0 - distFromCentre; // 1=perfect, 0=terrible

    // Get player base time
    final playerBase = _playerBestTime != null
        ? _playerBestTime! * 0.98  // improves on best
        : 89.5;

    if (_sector1 == '--:--.---') {
      // Setting S1
      final s1 = playerBase * 0.33 * (1 - sectorQuality * 0.015 + _rng.nextDouble() * 0.004);
      setState(() {
        _sector1 = _fmtTime(s1);
        _s1Color = _sectorColor(sectorQuality);
      });
      // Start S2 bar
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || !_onLap) return;
        _startTimingBar();
      });

    } else if (_sector2 == '--:--.---') {
      // Setting S2
      final s1val = _parseSectorTime(_sector1);
      final s2 = playerBase * 0.34 * (1 - sectorQuality * 0.015 + _rng.nextDouble() * 0.004);
      setState(() {
        _sector2 = _fmtTime(s2);
        _s2Color = _sectorColor(sectorQuality);
      });
      // Start S3 bar
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || !_onLap) return;
        _startTimingBar();
      });

    } else {
      // Setting S3 — complete the lap
      final s1val = _parseSectorTime(_sector1);
      final s2val = _parseSectorTime(_sector2);
      final s3 = playerBase * 0.33 * (1 - sectorQuality * 0.015 + _rng.nextDouble() * 0.004);
      setState(() {
        _sector3 = _fmtTime(s3);
        _s3Color = _sectorColor(sectorQuality);
      });

      final totalTime = s1val + s2val + s3;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _completeLap(totalTime);
      });
    }
  }

  double _parseSectorTime(String s) {
    // Format is M:SS.mmm
    try {
      final parts = s.split(':');
      final mins = double.parse(parts[0]);
      final secs = double.parse(parts[1]);
      return mins * 60 + secs;
    } catch (_) { return 30.0; }
  }

  Color _sectorColor(double quality) {
    if (quality > 0.8) return _kPurple;  // purple = personal best zone
    if (quality > 0.5) return _kGreen;   // green = good
    if (quality > 0.2) return _kYellow;  // yellow = ok
    return _kWhite.withOpacity(0.5);      // white = poor
  }

  // ── Complete lap ───────────────────────────────────────────────

  void _completeLap(double time) {
    final isImprovement = _playerBestTime == null || time < _playerBestTime!;
    if (isImprovement) _playerBestTime = time;

    setState(() {
      _playerTime = time;
      _onLap = false;
      _lapDone = true;
    });

    // Simulate rival times
    _simulateRivalTimes();
  }

  void _simulateRivalTimes() {
    for (final d in _sessionDrivers) {
      final spread = (1 - d.consistency) * 1.5;
      final t = d.baseTime + (_rng.nextDouble() - 0.5) * spread;
      d.lapTime = _fmtTime(t);
    }

    // Sort all including player
    _computePositions();
    setState(() => _sessionDone = true);
    _barCtrl.forward(from: 0);
  }

  void _computePositions() {
    final all = <Map<String, dynamic>>[];

    // Player
    if (_playerBestTime != null) {
      all.add({'id': widget.playerDriverId, 'time': _playerBestTime!, 'isPlayer': true});
    }

    // Rivals
    for (final d in _sessionDrivers) {
      final spread = (1 - d.consistency) * 1.5;
      final t = d.baseTime + (_rng.nextDouble() - 0.3) * spread;
      all.add({'id': d.id, 'time': t, 'isPlayer': false});
    }

    all.sort((a, b) => (a['time'] as double).compareTo(b['time'] as double));

    _gridPosition = all.indexWhere((x) => x['isPlayer'] == true) + 1;

    // Update full grid for next session
    _fullGrid = [];
    for (final entry in all) {
      final rival = _allRivals.firstWhere(
            (r) => r.id == entry['id'],
        orElse: () => _QualDriver(
          id: widget.playerDriverId, shortName: 'YOU',
          flag: widget.playerFlag, team: widget.playerTeamName,
          teamColor: _kCyan, baseTime: 89.5, consistency: 0.9,
        ),
      );
      _fullGrid.add(rival);
    }
  }

  // ── Advance to next session / finish ──────────────────────────

  void _nextSession() {
    // Check if player is eliminated
    if (_session == 1 && _gridPosition > 15) {
      setState(() => _eliminated = true);
      return;
    }
    if (_session == 2 && _gridPosition > 10) {
      setState(() => _eliminated = true);
      return;
    }
    if (_session == 3) {
      setState(() => _qualDone = true);
      return;
    }

    setState(() {
      _session++;
      _barCtrl.reset();
    });
    _startSession();
  }

  void _skipToRace() {
    setState(() => _qualDone = true);
  }

  void _goToRaceSim() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => RaceSimScreen(
        race:             widget.race,
        playerDriverId:   widget.playerDriverId,
        playerDriverName: widget.playerDriverName,
        playerTeamName:   widget.playerTeamName,
        playerFlag:       widget.playerFlag,
        qualifyingPos:    _gridPosition,
      ),
    ));
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_qualDone || _eliminated) return _buildFinalResult();
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSessionTabs(),
            _buildSectors(),
            const SizedBox(height: 8),
            if (!_sessionDone) ...[
              _buildTimingSection(),
            ] else ...[
              Expanded(child: _buildResultsList()),
              _buildNextButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: _kWhite.withOpacity(0.3), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.race.name.toUpperCase(), style: GoogleFonts.orbitron(
                fontSize: 13, fontWeight: FontWeight.w900, color: _kWhite)),
            Text('QUALIFYING SESSION', style: GoogleFonts.orbitron(
                fontSize: 8, letterSpacing: 2, color: _kWhite.withOpacity(0.3))),
          ],
        )),
        GestureDetector(
          onTap: _skipToRace,
          child: Text('SKIP →', style: GoogleFonts.orbitron(
              fontSize: 9, color: _kWhite.withOpacity(0.3), letterSpacing: 1)),
        ),
      ]),
    );
  }

  // ── Q1 / Q2 / Q3 tabs ──────────────────────────────────────────
  Widget _buildSessionTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [1, 2, 3].map((q) {
        final active = q == _session;
        final done   = q < _session;
        return Expanded(child: Container(
          margin: EdgeInsets.only(right: q < 3 ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _kYellow : done ? _kGreen.withOpacity(0.15) : _kWhite.withOpacity(0.03),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: active ? _kYellow : done ? _kGreen.withOpacity(0.4) : _kWhite.withOpacity(0.08)),
          ),
          child: Center(child: Text('Q$q', style: GoogleFonts.orbitron(
              fontSize: 12, fontWeight: FontWeight.w900,
              color: active ? Colors.black : done ? _kGreen : _kWhite.withOpacity(0.3)))),
        ));
      }).toList()),
    );
  }

  // ── Sector times display ────────────────────────────────────────
  Widget _buildSectors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: _kCyan.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(6),
          color: _kCyan.withOpacity(0.03),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('SECTOR TIMES', style: GoogleFonts.orbitron(
                fontSize: 9, letterSpacing: 3, color: _kWhite.withOpacity(0.3))),
            if (_playerBestTime != null)
              Text(_fmtTime(_playerBestTime!), style: GoogleFonts.orbitron(
                  fontSize: 14, fontWeight: FontWeight.w900, color: _kCyan,
                  shadows: [Shadow(color: _kCyan.withOpacity(0.5), blurRadius: 8)])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _sectorBox('S1', _sector1, _s1Color)),
            const SizedBox(width: 8),
            Expanded(child: _sectorBox('S2', _sector2, _s2Color)),
            const SizedBox(width: 8),
            Expanded(child: _sectorBox('S3', _sector3, _s3Color)),
          ]),
        ]),
      ),
    );
  }

  Widget _sectorBox(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(label, style: GoogleFonts.orbitron(
            fontSize: 8, letterSpacing: 2, color: color.withOpacity(0.6))),
        const SizedBox(height: 4),
        Text(time, style: GoogleFonts.orbitron(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ── Timing section (main gameplay) ─────────────────────────────
  Widget _buildTimingSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_onLap) ...[
              // Pre-lap
              Text('${widget.playerFlag}  ${widget.playerDriverName.split(' ').last.toUpperCase()}',
                  style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: _kWhite)),
              const SizedBox(height: 6),
              Text('Q$_session · ${_session == 1 ? "20" : _session == 2 ? "15" : "10"} cars',
                  style: GoogleFonts.orbitron(fontSize: 9, letterSpacing: 2, color: _kWhite.withOpacity(0.3))),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => GestureDetector(
                  onTap: _startLap,
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kYellow,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(
                          color: _kYellow.withOpacity(0.5 * _pulseAnim.value),
                          blurRadius: 24)],
                    ),
                    child: Center(child: Text(
                        _lapDone ? '🔄  IMPROVE LAP' : '🏎  START FLYING LAP',
                        style: GoogleFonts.orbitron(
                            fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tap the sectors at the right moment for a fast lap',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rajdhani(fontSize: 13, color: _kWhite.withOpacity(0.3))),
            ] else ...[
              // On lap — timing bar
              Text('ON FLYING LAP', style: GoogleFonts.orbitron(
                  fontSize: 11, letterSpacing: 4, color: _kYellow,
                  shadows: [Shadow(color: _kYellow.withOpacity(0.5), blurRadius: 10)])),
              const SizedBox(height: 6),
              Text(_sector1 == '--:--.---' ? 'TAP FOR SECTOR 1'
                  : _sector2 == '--:--.---' ? 'TAP FOR SECTOR 2'
                  : 'TAP FOR SECTOR 3',
                  style: GoogleFonts.orbitron(
                      fontSize: 9, letterSpacing: 3, color: _kWhite.withOpacity(0.4))),
              const SizedBox(height: 32),
              // Timing bar
              if (_showTimingBar) ...[
                _buildTimingBar(),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _onTap,
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _kPurple.withOpacity(0.6), width: 1.5),
                    ),
                    child: Center(child: Text('⚡  TAP!',
                        style: GoogleFonts.orbitron(
                            fontSize: 16, fontWeight: FontWeight.w900, color: _kPurple))),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 80),
                Text('GET READY...', style: GoogleFonts.orbitron(
                    fontSize: 14, letterSpacing: 4, color: _kWhite.withOpacity(0.2))),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimingBar() {
    // Sweet spot zones: purple (centre), green (middle), yellow (outer)
    return SizedBox(
      height: 32,
      child: Stack(alignment: Alignment.centerLeft, children: [
        // Background
        Container(decoration: BoxDecoration(
          color: _kWhite.withOpacity(0.04),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _kWhite.withOpacity(0.1)),
        )),
        // Yellow zone (ok)
        Positioned(left: 0, right: 0, child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: _kYellow.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        )),
        // Green zone (good) — middle 50%
        Positioned(
          left: MediaQuery.of(context).size.width * 0.25 - 32,
          right: MediaQuery.of(context).size.width * 0.25 - 32,
          child: Container(height: 32, color: _kGreen.withOpacity(0.15)),
        ),
        // Purple zone (perfect) — centre 20%
        Positioned(
          left: MediaQuery.of(context).size.width * 0.4 - 32,
          right: MediaQuery.of(context).size.width * 0.4 - 32,
          child: Container(height: 32, color: _kPurple.withOpacity(0.2)),
        ),
        // Moving indicator
        Positioned(
          left: _timingBarPos * (MediaQuery.of(context).size.width - 64) - 10,
          child: Container(
            width: 20, height: 32,
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: _kWhite.withOpacity(0.8), blurRadius: 8)],
            ),
          ),
        ),
        // Zone labels
        Positioned(
          left: 8, top: 0, bottom: 0,
          child: Center(child: Text('POOR', style: GoogleFonts.orbitron(
              fontSize: 7, color: _kYellow.withOpacity(0.6)))),
        ),
        Positioned(
          right: 8, top: 0, bottom: 0,
          child: Center(child: Text('POOR', style: GoogleFonts.orbitron(
              fontSize: 7, color: _kYellow.withOpacity(0.6)))),
        ),
        Positioned.fill(
          child: Center(child: Text('PERFECT', style: GoogleFonts.orbitron(
              fontSize: 7, fontWeight: FontWeight.w900, color: _kPurple.withOpacity(0.7)))),
        ),
      ]),
    );
  }

  // ── Results list after session ──────────────────────────────────
  Widget _buildResultsList() {
    // Build sorted list
    final all = <Map<String, dynamic>>[];
    if (_playerBestTime != null) {
      all.add({
        'name': widget.playerDriverName.split(' ').last.toUpperCase(),
        'flag': widget.playerFlag,
        'team': widget.playerTeamName,
        'color': _kCyan,
        'time': _playerBestTime!,
        'isPlayer': true,
      });
    }
    for (final d in _sessionDrivers) {
      if (d.lapTime != null) {
        final spread = (1 - d.consistency) * 0.5;
        all.add({
          'name': d.shortName,
          'flag': d.flag,
          'team': d.team,
          'color': d.teamColor,
          'time': d.baseTime + (_rng.nextDouble() - 0.3) * spread,
          'isPlayer': false,
        });
      }
    }
    all.sort((a, b) => (a['time'] as double).compareTo(b['time'] as double));
    final playerIdx = all.indexWhere((x) => x['isPlayer'] == true);

    return AnimatedBuilder(
      animation: _barAnim,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final entry = all[i];
          final isPlayer = entry['isPlayer'] as bool;
          final isEliminated = (_session == 1 && i >= 15) ||
              (_session == 2 && i >= 10);
          final pos = i + 1;
          final color = entry['color'] as Color;
          final gap = i == 0
              ? 'POLE'
              : '+${((entry['time'] as double) - (all[0]['time'] as double)).toStringAsFixed(3)}';

          return AnimatedOpacity(
            opacity: _barAnim.value,
            duration: Duration(milliseconds: 200 + i * 30),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isPlayer
                      ? _kCyan.withOpacity(0.5)
                      : isEliminated
                      ? _kRed.withOpacity(0.15)
                      : _kWhite.withOpacity(0.06),
                  width: isPlayer ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(5),
                color: isPlayer
                    ? _kCyan.withOpacity(0.06)
                    : isEliminated
                    ? _kRed.withOpacity(0.03)
                    : _kWhite.withOpacity(0.02),
              ),
              child: Row(children: [
                SizedBox(width: 28, child: Text('$pos',
                    style: GoogleFonts.orbitron(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: pos <= 3
                            ? [_kYellow, _kWhite, _kWhite.withOpacity(0.7)][pos-1]
                            : isEliminated
                            ? _kRed.withOpacity(0.5)
                            : _kWhite.withOpacity(0.3)))),
                Text(entry['flag'] as String, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry['name'] as String, style: GoogleFonts.rajdhani(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isPlayer ? _kCyan : _kWhite)),
                  Text(entry['team'] as String, style: GoogleFonts.rajdhani(
                      fontSize: 10, color: color)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmtTime(entry['time'] as double), style: GoogleFonts.orbitron(
                      fontSize: 11, fontWeight: FontWeight.w700, color: _kWhite)),
                  Text(gap, style: GoogleFonts.orbitron(
                      fontSize: 9, color: isPlayer
                      ? _kCyan.withOpacity(0.7)
                      : _kWhite.withOpacity(0.3))),
                ]),
                if (isEliminated)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('OUT', style: GoogleFonts.orbitron(
                        fontSize: 8, fontWeight: FontWeight.w900,
                        color: _kRed, letterSpacing: 1)),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton() {
    final isEliminated = (_session == 1 && _gridPosition > 15) ||
        (_session == 2 && _gridPosition > 10);
    final label = _session == 3 || isEliminated
        ? 'START RACE  🏁'
        : 'ADVANCE TO Q${_session + 1}  →';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: GestureDetector(
        onTap: _nextSession,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            color: _session == 3 || isEliminated ? _kCyan : _kYellow,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(child: Text(label, style: GoogleFonts.orbitron(
              fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black))),
        ),
      ),
    );
  }

  // ── Final qualifying result ────────────────────────────────────
  Widget _buildFinalResult() {
    final posColor = _gridPosition == 1
        ? _kYellow
        : _gridPosition <= 3
        ? _kCyan
        : _gridPosition <= 10
        ? _kGreen
        : _kWhite;
    final label = _gridPosition == 1 ? 'POLE POSITION!'
        : _gridPosition <= 3 ? 'FRONT ROW!'
        : _gridPosition <= 10 ? 'Q3 QUALIFIED!'
        : _eliminated && _session == 2 ? 'Q2 ELIMINATED'
        : 'Q1 ELIMINATED';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('QUALIFYING COMPLETE', style: GoogleFonts.orbitron(
                  fontSize: 10, letterSpacing: 4, color: _kWhite.withOpacity(0.4))),
              const SizedBox(height: 24),
              Text(widget.raceFlag, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text('P${_gridPosition.toString().padLeft(2, '0')}',
                  style: GoogleFonts.orbitron(
                      fontSize: 80, fontWeight: FontWeight.w900, color: posColor,
                      height: 0.9,
                      shadows: [Shadow(color: posColor.withOpacity(0.5), blurRadius: 30)])),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.orbitron(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: posColor, letterSpacing: 3)),
              const SizedBox(height: 8),
              if (_playerBestTime != null)
                Text(_fmtTime(_playerBestTime!), style: GoogleFonts.orbitron(
                    fontSize: 18, color: _kWhite.withOpacity(0.6))),
              const SizedBox(height: 48),
              Text('YOU WILL START THE RACE FROM', style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 2, color: _kWhite.withOpacity(0.3))),
              Text('GRID POSITION $_gridPosition', style: GoogleFonts.orbitron(
                  fontSize: 16, fontWeight: FontWeight.w900, color: _kWhite)),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _goToRaceSim,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    width: double.infinity, height: 60,
                    decoration: BoxDecoration(
                      color: _kCyan,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(
                          color: _kCyan.withOpacity(0.4 * _pulseAnim.value),
                          blurRadius: 20)],
                    ),
                    child: Center(child: Text('🏁  LIGHTS OUT — START RACE',
                        style: GoogleFonts.orbitron(
                            fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get raceFlag => widget.race.flag;
}

extension on QualifyingScreen {
  String get raceFlag => race.flag;
}