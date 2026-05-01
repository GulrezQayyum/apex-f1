import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/simulation/domain/race_sim_engine.dart';
import 'package:apex_f1/features/championship/presentation/championship_screen.dart';
import 'package:apex_f1/features/simulation/presentation/debrief_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Result Screen
//  Location: lib/features/simulation/presentation/result_screen.dart
// ─────────────────────────────────────────────────────────────────

const Color _kBg    = Color(0xFF030308);
const Color _kCyan  = Color(0xFF00E5FF);
const Color _kWhite = Colors.white;

class ResultScreen extends StatefulWidget {
  final RaceSimResult result;
  final String raceName;
  final String raceFlag;
  final int round;

  const ResultScreen({
    super.key,
    required this.result,
    required this.raceName,
    required this.raceFlag,
    required this.round,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {

  // ── Reveal animation sequence ───────────────
  late AnimationController _revealCtrl;
  late Animation<double>   _revealAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _countCtrl;
  late Animation<double>   _countAnim;

  bool _showPosition  = false;
  bool _showDetails   = false;
  bool _showStats     = false;
  bool _showButtons   = false;

  Color get _resultColor => switch (widget.result.finalPosition) {
    1 => const Color(0xFFFFE600),
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFCD7F32),
    _ when widget.result.isPoints => _kCyan,
    _ => _kWhite.withValues(alpha: 0.4),
  };

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _revealCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.elasticOut);

    _countCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _countAnim = CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut);

    _startRevealSequence();
    _recordToChampionship();
  }

  Future<void> _recordToChampionship() async {
    try {
      await ChampionshipScreen.recordResult(
        round:         widget.round,
        raceName:      widget.raceName,
        flag:          widget.raceFlag,
        position:      widget.result.finalPosition,
        tyre:          widget.result.finalTyre.label,
        hadFastestLap: false,
      );
    } catch (_) {}
  }

  Future<void> _startRevealSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _showPosition = true);
    _revealCtrl.forward();
    _countCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _showDetails = true);

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showStats = true);

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showButtons = true);
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _pulseCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Particles
          const _ParticleField(),
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),

          // Result glow background
          if (_showPosition)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        _resultColor.withValues(alpha: 0.08 * _pulseAnim.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_showPosition) _buildPositionReveal(),
                  const SizedBox(height: 20),
                  if (_showDetails) _buildDetailsCard(),
                  const SizedBox(height: 14),
                  if (_showStats) _buildStatsGrid(),
                  const SizedBox(height: 14),
                  if (_showStats && widget.result.allEvents.isNotEmpty)
                    _buildRaceHighlights(),
                  const SizedBox(height: 24),
                  if (_showButtons) _buildButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          '🏁  CHEQUERED FLAG',
          style: GoogleFonts.orbitron(
            fontSize: 11, letterSpacing: 4,
            color: _kWhite.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.raceFlag}  ${widget.raceName.toUpperCase()}',
          style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: _kWhite, letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Position reveal ────────────────────────
  Widget _buildPositionReveal() {
    return ScaleTransition(
      scale: _revealAnim,
      child: FadeTransition(
        opacity: _revealAnim,
        child: Column(
          children: [
            Text(
              widget.result.resultEmoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Text(
                widget.result.positionLabel,
                style: GoogleFonts.orbitron(
                  fontSize: 72, fontWeight: FontWeight.w900,
                  color: _resultColor, height: 1,
                  shadows: [
                    Shadow(
                      color: _resultColor.withValues(alpha: 0.8 * _pulseAnim.value),
                      blurRadius: 30,
                    ),
                    Shadow(
                      color: _resultColor.withValues(alpha: 0.4 * _pulseAnim.value),
                      blurRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.result.isPodium
                  ? 'PODIUM FINISH!'
                  : widget.result.isPoints
                  ? 'POINTS FINISH!'
                  : 'RACE COMPLETE',
              style: GoogleFonts.orbitron(
                fontSize: 13, letterSpacing: 4,
                color: _resultColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Details card ───────────────────────────
  Widget _buildDetailsCard() {
    return AnimatedOpacity(
      opacity: _showDetails ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _resultColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
          color: _resultColor.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Text(
              widget.result.driverName.toUpperCase(),
              style: GoogleFonts.orbitron(
                fontSize: 20, fontWeight: FontWeight.w900,
                color: _kWhite, letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.result.teamName,
              style: GoogleFonts.rajdhani(
                fontSize: 14, color: _kWhite.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  _resultColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Points earned
            AnimatedBuilder(
              animation: _countAnim,
              builder: (_, __) {
                final pts = (widget.result.pointsEarned * _countAnim.value).round();
                return RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '+$pts',
                      style: GoogleFonts.orbitron(
                        fontSize: 36, fontWeight: FontWeight.w900,
                        color: _resultColor,
                        shadows: [Shadow(color: _resultColor.withValues(alpha: 0.5), blurRadius: 12)],
                      ),
                    ),
                    TextSpan(
                      text: '  POINTS',
                      style: GoogleFonts.orbitron(
                        fontSize: 14, color: _kWhite.withValues(alpha: 0.3),
                        letterSpacing: 2,
                      ),
                    ),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats grid ─────────────────────────────
  Widget _buildStatsGrid() {
    final stats = [
      ('LAPS',       '${widget.result.totalLaps}'),
      ('PIT STOPS',  '${widget.result.pitStops}'),
      ('FINAL TYRE', widget.result.finalTyre.label),
      ('WEATHER',    widget.result.peakWeather.label),
      ('SAFETY CAR', widget.result.surviredSafetyCar ? 'YES' : 'NO'),
      ('EVENTS',     '${widget.result.allEvents.length}'),
    ];

    return AnimatedOpacity(
      opacity: _showStats ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: stats.map((s) => Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kWhite.withValues(alpha: 0.07)),
            borderRadius: BorderRadius.circular(4),
            color: _kWhite.withValues(alpha: 0.02),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                s.$2,
                style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w900,
                  color: _kCyan,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                s.$1,
                style: GoogleFonts.orbitron(
                  fontSize: 7, letterSpacing: 1.5,
                  color: _kWhite.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── Race highlights ─────────────────────────
  Widget _buildRaceHighlights() {
    final keyEvents = widget.result.allEvents
        .where((e) => e.type != RaceEventType.radioMessage)
        .take(5)
        .toList();

    if (keyEvents.isEmpty) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _showStats ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RACE HIGHLIGHTS',
            style: GoogleFonts.orbitron(
              fontSize: 9, letterSpacing: 3,
              color: _kCyan.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          ...keyEvents.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  'LAP ${e.lap}',
                  style: GoogleFonts.orbitron(
                    fontSize: 9, color: _kCyan.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.message,
                    style: GoogleFonts.rajdhani(
                      fontSize: 12, color: _kWhite.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Buttons ────────────────────────────────
  Widget _buildButtons(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showButtons ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          // Back to home
          GestureDetector(
            onTap: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _resultColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: _resultColor.withValues(alpha: 0.4 * _pulseAnim.value),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🏠  BACK TO HOME',
                    style: GoogleFonts.orbitron(
                      fontSize: 12, fontWeight: FontWeight.w900,
                      letterSpacing: 2, color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Race again
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: _kWhite.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Text(
                  '↺  RACE AGAIN',
                  style: GoogleFonts.orbitron(
                    fontSize: 11, letterSpacing: 2,
                    color: _kWhite.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // View debrief
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DebriefScreen(
                  result:    widget.result,
                  raceName:  widget.raceName,
                  raceFlag:  widget.raceFlag,
                  round:     widget.round,
                ),
              ));
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF00FF).withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(3),
                color: const Color(0xFFFF00FF).withValues(alpha: 0.06),
              ),
              child: Center(
                child: Text(
                  '📊  RACE DEBRIEF & STATS',
                  style: GoogleFonts.orbitron(
                    fontSize: 11, letterSpacing: 2,
                    color: const Color(0xFFFF00FF),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // View championship
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              // Small delay then push championship
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ChampionshipScreen(),
                ));
              });
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6692FF).withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(3),
                color: const Color(0xFF6692FF).withValues(alpha: 0.06),
              ),
              child: Center(
                child: Text(
                  '📊  VIEW MY SEASON',
                  style: GoogleFonts.orbitron(
                    fontSize: 11, letterSpacing: 2,
                    color: const Color(0xFF6692FF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PARTICLE FIELD + SCANLINES
// ─────────────────────────────────────────────────────────────────

class _ParticleField extends StatefulWidget {
  const _ParticleField();
  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  static final _rng = Random(22);
  static final _pts = List.generate(60, (i) => _P(
    x: _rng.nextDouble(), y: _rng.nextDouble(),
    s: 0.02 + _rng.nextDouble() * 0.08, r: 0.4 + _rng.nextDouble() * 1.4,
    c: [
      const Color(0xFF00E5FF), const Color(0xFFFF00FF),
      const Color(0xFF39FF14), const Color(0xFFFFE600),
      const Color(0xFFFF073A),
    ][i % 5].withValues(alpha: 0.2 + _rng.nextDouble() * 0.2),
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
    final p = Paint()..color = Colors.black.withValues(alpha: 0.022);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), p);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}