import 'dart:async';
import 'dart:math';
import 'package:apex_f1/features/simulation/presentation/widgets/%20multi_car_circuit_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/simulation/domain/race_sim_engine.dart';
import 'package:apex_f1/features/simulation/presentation/result_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Simulation Screen (VISUAL REBUILD)
//  Location: lib/features/simulation/presentation/race_sim_screen.dart
// ─────────────────────────────────────────────────────────────────

const Color _kBg      = Color(0xFF030308);
const Color _kCyan    = Color(0xFF00E5FF);
const Color _kMagenta = Color(0xFFFF00FF);
const Color _kGreen   = Color(0xFF39FF14);
const Color _kYellow  = Color(0xFFFFE600);
const Color _kRed     = Color(0xFFFF073A);
const Color _kOrange  = Color(0xFFFF8000);
const Color _kWhite   = Colors.white;

// ─────────────────────────────────────────────────────────────────
//  CIRCUIT PATH POINTS
//  Normalised 0..1 coordinates tracing each circuit outline
// ─────────────────────────────────────────────────────────────────

class RaceSimScreen extends StatefulWidget {
  final RaceModel race;
  final String playerDriverId;
  final String playerDriverName;
  final String playerTeamName;
  final String playerFlag;
  final int qualifyingPos;

  const RaceSimScreen({
    super.key,
    required this.race,
    required this.playerDriverId,
    required this.playerDriverName,
    required this.playerTeamName,
    required this.playerFlag,
    this.qualifyingPos = 10,
  });

  @override
  State<RaceSimScreen> createState() => _RaceSimScreenState();
}

class _RaceSimScreenState extends State<RaceSimScreen>
    with TickerProviderStateMixin {

  late RaceSimEngine _engine;
  late SimState      _state;

  Timer? _lapTimer;
  bool   _running     = false;
  bool   _showPitMenu = false;

  // Drama overlay
  String? _dramaTitle;
  String? _dramaSubtitle;
  Color   _dramaColor = _kYellow;
  bool    _showDrama  = false;

  // Radio
  String? _radioMessage;
  bool    _showRadio = false;
  Timer?  _radioTimer;

  // Car progress around circuit 0..1

  // Animations
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _dramaCtrl;
  late Animation<double>   _dramaAnim;
  late AnimationController _carCtrl;
  late AnimationController _posCtrl;
  late Animation<double>   _posAnim;
  late AnimationController _radioCtrl;
  late Animation<double>   _radioAnim;


  @override
  void initState() {
    super.initState();


    _engine = RaceSimEngine(
      raceName:         widget.race.name,
      totalLaps:        widget.race.laps,
      playerDriverId:   widget.playerDriverId,
      playerDriverName: widget.playerDriverName,
      playerTeamName:   widget.playerTeamName,
      playerFlag:       widget.playerFlag,
      qualifyingPos:    widget.qualifyingPos,
    );
    _engine.initialize();
    _state = _engine.currentState;

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _dramaCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _dramaAnim = CurvedAnimation(parent: _dramaCtrl, curve: Curves.easeOut);

    _carCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    _posCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _posAnim = CurvedAnimation(parent: _posCtrl, curve: Curves.elasticOut);

    _radioCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _radioAnim = CurvedAnimation(parent: _radioCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _lapTimer?.cancel();
    _radioTimer?.cancel();
    _pulseCtrl.dispose();
    _dramaCtrl.dispose();
    _carCtrl.dispose();
    _posCtrl.dispose();
    _radioCtrl.dispose();
    super.dispose();
  }

  // ── Sim flow ───────────────────────────────

  void _startSim() {
    setState(() => _running = true);
    _carCtrl.repeat();
    _lapTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!_running || _state.raceFinished) {
        _lapTimer?.cancel();
        _carCtrl.stop();
        if (_state.raceFinished) _goToResult();
        return;
      }
      _advanceLap();
    });
  }

  void _pauseSim() {
    setState(() => _running = false);
    _lapTimer?.cancel();
    _carCtrl.stop();
  }

  void _advanceLap() {
    final prevPos  = _state.playerPosition;
    final newState = _engine.advanceLap();

    for (final e in newState.latestEvents) {
      _handleEvent(e, newState);
    }

    if (newState.playerPosition != prevPos) _posCtrl.forward(from: 0);
    setState(() => _state = newState);

    if (newState.raceFinished) {
      _pauseSim();
      Future.delayed(const Duration(milliseconds: 700), _goToResult);
    }
  }

  void _handleEvent(RaceEvent event, SimState state) {
    switch (event.type) {
      case RaceEventType.safetyCar:
        _drama('🟡  SAFETY CAR', 'DEPLOYED — MAINTAIN DELTA', _kYellow, 3);
      case RaceEventType.weatherChange:
        _drama('${state.weather.emoji}  WEATHER CHANGE',
            state.weather.label, const Color(0xFF64C4FF), 3);
      case RaceEventType.rivalBattle:
        _drama('⚔️  BATTLE!',
            event.message.replaceAll('⚔️ BATTLE — ', ''), _kRed, 2);
      case RaceEventType.pitWindowOpen:
        if (!_showPitMenu) {
          _drama('🔧  PIT WINDOW OPEN', 'BOX THIS LAP?', _kOrange, 2);
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) { _pauseSim(); setState(() => _showPitMenu = true); }
          });
        }
      default: break;
    }
    if (event.radioMessage != null) _triggerRadio(event.radioMessage!);
  }

  void _drama(String title, String subtitle, Color color, int secs) {
    if (!mounted) return;
    setState(() {
      _dramaTitle    = title;
      _dramaSubtitle = subtitle;
      _dramaColor    = color;
      _showDrama     = true;
    });
    _dramaCtrl.forward(from: 0);
    Future.delayed(Duration(seconds: secs), () {
      if (!mounted) return;
      _dramaCtrl.reverse().then((_) {
        if (mounted) setState(() => _showDrama = false);
      });
    });
  }

  void _triggerRadio(String msg) {
    if (!mounted) return;
    setState(() { _radioMessage = msg; _showRadio = true; });
    _radioCtrl.forward(from: 0);
    _radioTimer?.cancel();
    _radioTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _radioCtrl.reverse().then((_) {
        if (mounted) setState(() => _showRadio = false);
      });
    });
  }

  void _pitStop(TyreCompound tyre) {
    final ns = _engine.playerPitStop(tyre);
    setState(() { _state = ns; _showPitMenu = false; });
    _triggerRadio('Good stop. ${tyre.label} tyres fitted. Now PUSH!');
    _startSim();
  }

  void _skipPit() {
    setState(() => _showPitMenu = false);
    _startSim();
  }

  void _goToResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        result:   _engine.buildResult(),
        raceName: widget.race.name,
        raceFlag: widget.race.flag,
        round:    widget.race.round,
      ),
    ));
  }

  Color _tyreColor(TyreCompound t) => switch (t) {
    TyreCompound.soft         => _kRed,
    TyreCompound.medium       => _kYellow,
    TyreCompound.hard         => _kWhite,
    TyreCompound.intermediate => _kGreen,
    TyreCompound.wet          => const Color(0xFF3671C6),
  };

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const _ParticleField(),
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildCircuitAndStatus(),
                _buildTowerHeader(),
                Expanded(child: _buildTower()),
                _buildProgressAndControls(),
              ],
            ),
          ),

          if (_showDrama) _buildDramaOverlay(),
          if (_showRadio) _buildRadioOverlay(),
          if (_showPitMenu) _buildPitMenu(),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kCyan.withOpacity(0.12))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { _pauseSim(); Navigator.of(context).pop(); },
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: _kWhite.withOpacity(0.3), size: 16),
          ),
          const SizedBox(width: 8),
          Text(widget.race.flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.race.name.toUpperCase(),
              style: GoogleFonts.orbitron(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: _kWhite, letterSpacing: 0.5,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: _kCyan.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(2),
                color: _kCyan.withOpacity(0.07),
              ),
              child: Text(
                'LAP ${_state.currentLap} / ${_state.totalLaps}',
                style: GoogleFonts.orbitron(
                  fontSize: 10, fontWeight: FontWeight.w900,
                  color: _kCyan.withOpacity(_pulseAnim.value), letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(_state.weather.emoji, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  // ── Circuit map + player status ─────────────

  Widget _buildCircuitAndStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        children: [
          // ── BIG Circuit Map ──────────────────────────────
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: _kCyan.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: MultiCarCircuit(
                drivers:    _state.drivers,
                totalLaps:  _state.totalLaps,
                currentLap: _state.currentLap,
                safetyCar:  _state.safetyCar || _state.virtualSafetyCar,
                running:    _running,
                round:      widget.race.round,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Compact Player Status Row ────────────────────
          _buildCompactStatus(),
        ],
      ),
    );
  }

  Widget _buildCompactStatus() {
    final p = _state.player;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _kCyan.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(6),
        color: _kCyan.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Position
          Text('P${p.position}',
              style: GoogleFonts.orbitron(
                fontSize: 28, fontWeight: FontWeight.w900, color: _kCyan,
                shadows: [Shadow(color: _kCyan.withOpacity(0.6), blurRadius: 14)],
              )),
          const SizedBox(width: 12),

          // Driver
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.flag}  ${p.name}',
                    style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w700, color: _kWhite)),
                Text(p.teamName,
                    style: GoogleFonts.rajdhani(fontSize: 11, color: _kWhite.withOpacity(0.35))),
              ],
            ),
          ),

          // Tyre
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Container(width: 9, height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tyreColor(p.tyre),
                      boxShadow: [BoxShadow(color: _tyreColor(p.tyre).withOpacity(0.6), blurRadius: 5)],
                    )),
                const SizedBox(width: 5),
                Text(p.tyre.label,
                    style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.w700, color: _tyreColor(p.tyre))),
              ]),
              const SizedBox(height: 4),
              // Tyre health bar
              SizedBox(
                width: 65, height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(children: [
                    Container(color: _kWhite.withOpacity(0.08)),
                    FractionallySizedBox(
                      widthFactor: p.tyreHealth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.tyreCritical ? _kRed : _tyreColor(p.tyre),
                          boxShadow: [BoxShadow(color: (p.tyreCritical ? _kRed : _tyreColor(p.tyre)).withOpacity(0.5), blurRadius: 3)],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Text(p.tyreCritical ? '⚠ CRITICAL' : '${(p.tyreHealth*100).toInt()}%',
                  style: GoogleFonts.orbitron(fontSize: 7, color: p.tyreCritical ? _kRed : _kWhite.withOpacity(0.35))),
            ],
          ),

          const SizedBox(width: 10),

          // Gap + SC
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(p.gapDisplay,
                  style: GoogleFonts.orbitron(fontSize: 9, color: _kWhite.withOpacity(0.4), letterSpacing: 1)),
              if (_state.safetyCar || _state.virtualSafetyCar)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_state.safetyCar ? '🟡 SC' : '🟡 VSC',
                      style: GoogleFonts.orbitron(fontSize: 8, fontWeight: FontWeight.w900, color: _kYellow)),
                ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTowerHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Text('LIVE TOWER',
              style: GoogleFonts.orbitron(fontSize: 8, letterSpacing: 3, color: _kCyan.withOpacity(0.5))),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: _kCyan.withOpacity(0.1))),
          const SizedBox(width: 8),
          Text('TYRE',
              style: GoogleFonts.orbitron(fontSize: 8, letterSpacing: 2, color: _kWhite.withOpacity(0.2))),
          const SizedBox(width: 20),
          Text('GAP',
              style: GoogleFonts.orbitron(fontSize: 8, letterSpacing: 2, color: _kWhite.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _buildTower() {
    final drivers = _state.drivers.take(10).toList();
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: drivers.length,
      itemBuilder: (_, i) {
        final d = drivers[i];
        final isP = d.isPlayer;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(
              color: isP ? _kCyan.withOpacity(0.6) : _kWhite.withOpacity(0.05),
              width: isP ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(3),
            color: isP ? _kCyan.withOpacity(0.07) : _kWhite.withOpacity(0.015),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text('${d.position}',
                    style: GoogleFonts.orbitron(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: isP ? _kCyan : d.position <= 3 ? _kYellow : _kWhite.withOpacity(0.28),
                    )),
              ),
              Text(d.flag, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isP ? '★ ${d.name}' : d.name,
                  style: GoogleFonts.rajdhani(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isP ? _kWhite : _kWhite.withOpacity(0.6),
                  ),
                ),
              ),
              // Tyre
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _tyreColor(d.tyre),
                  boxShadow: isP ? [BoxShadow(color: _tyreColor(d.tyre).withOpacity(0.6), blurRadius: 4)] : null,
                ),
              ),
              const SizedBox(width: 3),
              SizedBox(
                width: 16,
                child: Text(d.tyre.shortLabel,
                    style: GoogleFonts.orbitron(fontSize: 8, color: _tyreColor(d.tyre).withOpacity(0.7))),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 60,
                child: Text(d.gapDisplay,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      color: d.position == 1 ? _kYellow : _kWhite.withOpacity(0.28),
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Progress bar + controls ─────────────────

  Widget _buildProgressAndControls() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 3,
              child: Stack(
                children: [
                  Container(color: _kWhite.withOpacity(0.05)),
                  FractionallySizedBox(
                    widthFactor: _state.raceProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kCyan, _kMagenta]),
                        boxShadow: [BoxShadow(color: _kCyan.withOpacity(0.4), blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Row(
            children: [
              // Pit button
              GestureDetector(
                onTap: () { _pauseSim(); setState(() => _showPitMenu = true); },
                child: Container(
                  height: 48, width: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: _kOrange.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(3),
                    color: _kOrange.withOpacity(0.08),
                  ),
                  child: const Center(child: Text('🔧', style: TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(width: 10),

              // Play / Pause
              Expanded(
                child: GestureDetector(
                  onTap: _running ? _pauseSim : _startSim,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _running ? _kRed : _kCyan,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(
                          color: (_running ? _kRed : _kCyan).withOpacity(0.35 * _pulseAnim.value),
                          blurRadius: 14,
                        )],
                      ),
                      child: Center(
                        child: Text(
                          _running ? '⏸  PAUSE'
                              : _state.currentLap == 0 ? '▶  START RACE' : '▶  RESUME',
                          style: GoogleFonts.orbitron(
                            fontSize: 12, fontWeight: FontWeight.w900,
                            letterSpacing: 2, color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Skip to finish
              GestureDetector(
                onTap: () {
                  _pauseSim();
                  while (!_state.raceFinished) { _state = _engine.advanceLap(); }
                  setState(() {});
                  _goToResult();
                },
                child: Container(
                  height: 48, width: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: _kWhite.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text('⏭', style: TextStyle(fontSize: 20, color: _kWhite.withOpacity(0.3))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Drama overlay ───────────────────────────

  Widget _buildDramaOverlay() {
    return Positioned(
      top: 72, left: 14, right: 14,
      child: FadeTransition(
        opacity: _dramaAnim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
              .animate(_dramaAnim),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: _dramaColor.withOpacity(0.8), width: 1.5),
                borderRadius: BorderRadius.circular(6),
                color: _dramaColor.withOpacity(0.12),
                boxShadow: [BoxShadow(
                  color: _dramaColor.withOpacity(0.28 * _pulseAnim.value), blurRadius: 22,
                )],
              ),
              child: Column(
                children: [
                  Text(_dramaTitle ?? '',
                      style: GoogleFonts.orbitron(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: _dramaColor, letterSpacing: 2,
                      ), textAlign: TextAlign.center),
                  if (_dramaSubtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(_dramaSubtitle!,
                        style: GoogleFonts.rajdhani(
                          fontSize: 13, color: _kWhite.withOpacity(0.7), letterSpacing: 1,
                        ), textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Radio overlay ───────────────────────────

  Widget _buildRadioOverlay() {
    return Positioned(
      bottom: 85, left: 14, right: 14,
      child: FadeTransition(
        opacity: _radioAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _kGreen.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(4),
            color: _kBg.withOpacity(0.96),
            boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.1), blurRadius: 12)],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGreen.withOpacity(0.12 * _pulseAnim.value),
                    border: Border.all(color: _kGreen.withOpacity(0.45)),
                  ),
                  child: const Center(child: Text('📻', style: TextStyle(fontSize: 13))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENGINEER',
                        style: GoogleFonts.orbitron(
                          fontSize: 8, letterSpacing: 2, color: _kGreen.withOpacity(0.7),
                        )),
                    Text(_radioMessage ?? '',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _kWhite.withOpacity(0.85),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pit menu ────────────────────────────────

  Widget _buildPitMenu() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: _kOrange.withOpacity(0.55)),
              borderRadius: BorderRadius.circular(8),
              color: _kBg,
              boxShadow: [BoxShadow(color: _kOrange.withOpacity(0.2), blurRadius: 32)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔧  PIT STOP',
                    style: GoogleFonts.orbitron(
                      fontSize: 20, fontWeight: FontWeight.w900, color: _kOrange,
                      shadows: [Shadow(color: _kOrange.withOpacity(0.5), blurRadius: 12)],
                    )),
                const SizedBox(height: 4),
                Text('LAP ${_state.currentLap}  —  CHOOSE YOUR TYRE',
                    style: GoogleFonts.orbitron(
                      fontSize: 9, letterSpacing: 2, color: _kWhite.withOpacity(0.3),
                    )),
                const SizedBox(height: 20),
                ...[TyreCompound.soft, TyreCompound.medium, TyreCompound.hard,
                  TyreCompound.intermediate, TyreCompound.wet]
                    .map(_buildTyreOption),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _skipPit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kWhite.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text('STAY OUT',
                          style: GoogleFonts.orbitron(
                            fontSize: 11, letterSpacing: 3, color: _kWhite.withOpacity(0.3),
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTyreOption(TyreCompound tyre) {
    final c = _tyreColor(tyre);
    final isWet   = _state.weather.needsWets;
    final isInter = _state.weather.needsInters;
    final rec = (tyre == TyreCompound.wet && isWet) ||
        (tyre == TyreCompound.intermediate && isInter) ||
        (tyre == TyreCompound.medium && !isWet && !isInter);
    return GestureDetector(
      onTap: () => _pitStop(tyre),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: rec ? c : c.withOpacity(0.22), width: rec ? 1.5 : 1),
          borderRadius: BorderRadius.circular(3),
          color: rec ? c.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: c,
                boxShadow: [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tyre.label,
                  style: GoogleFonts.orbitron(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: rec ? _kWhite : _kWhite.withOpacity(0.4),
                  )),
            ),
            if (rec)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.withOpacity(0.18), borderRadius: BorderRadius.circular(2),
                ),
                child: Text('RECOMMENDED',
                    style: GoogleFonts.orbitron(fontSize: 7, letterSpacing: 1, color: c)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CIRCUIT MAP CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────


class _ParticleField extends StatefulWidget {
  const _ParticleField();
  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  static final _r = Random(11);
  static final _pts = List.generate(28, (i) => _P(
    x: _r.nextDouble(), y: _r.nextDouble(),
    s: 0.02 + _r.nextDouble() * 0.05, r: 0.3 + _r.nextDouble() * 0.8,
    c: [_kCyan, _kMagenta, _kGreen, _kYellow][i % 4]
        .withOpacity(0.10 + _r.nextDouble() * 0.08),
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      painter: _PPainter(_ctrl.value, _pts),
      size: MediaQuery.of(context).size,
    ),
  );
}

class _P {
  final double x, y, s, r; final Color c;
  const _P({required this.x, required this.y, required this.s, required this.r, required this.c});
}

class _PPainter extends CustomPainter {
  final double prog; final List<_P> pts;
  _PPainter(this.prog, this.pts);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pts) {
      final y = ((p.y - prog * p.s) % 1.0) * size.height;
      canvas.drawCircle(Offset(p.x * size.width, y), p.r, Paint()..color = p.c);
    }
  }
  @override
  bool shouldRepaint(_PPainter o) => o.prog != prog;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.02);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), p);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}