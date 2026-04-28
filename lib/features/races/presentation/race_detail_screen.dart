import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Detail Screen
//  Location: lib/features/races/presentation/race_detail_screen.dart
// ─────────────────────────────────────────────────────────────────

// ── Shared colors ─────────────────────────────────────────────────
const Color _kBg    = Color(0xFF030308);
const Color _kCyan  = Color(0xFF00E5FF);
const Color _kWhite = Colors.white;

class RaceDetailScreen extends StatefulWidget {
  final RaceModel race;
  final void Function()? onStartSim;
  final void Function()? onStartQualifying;

  const RaceDetailScreen({
    super.key,
    required this.race,
    this.onStartSim,
    this.onStartQualifying,
  });

  @override
  State<RaceDetailScreen> createState() => _RaceDetailScreenState();
}

class _RaceDetailScreenState extends State<RaceDetailScreen>
    with TickerProviderStateMixin {

  // ── Tab index — 0: Overview  1: Results ──
  int _tab = 0;

  // ── Animations ──────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryAnim;

  // ── Round accent color ──────────────────────
  Color get _accent {
    const colors = [
      Color(0xFF00E5FF), Color(0xFFFF00FF), Color(0xFF39FF14),
      Color(0xFFFFE600), Color(0xFFFF3E3E), Color(0xFFFF8000),
      Color(0xFF3671C6), Color(0xFFE8002D), Color(0xFF27F4D2),
      Color(0xFF358C75),
    ];
    return colors[(widget.race.round - 1) % colors.length];
  }

  bool get _isCompleted => widget.race.status.isCompleted;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    Future.delayed(
      const Duration(milliseconds: 80),
          () { if (mounted) _entryCtrl.forward(); },
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Particles
          const _ParticleField(),

          // Scanlines
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),

          // Top accent line
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    _accent.withOpacity(_pulseAnim.value),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(_entryAnim),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildHeroCard(),
                    _buildTabBar(),
                    Expanded(
                      child: _tab == 0
                          ? _buildOverviewTab()
                          : _buildResultsTab(),
                    ),
                    if (!_isCompleted) _buildSimButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: _kWhite.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '‹  BACK',
                style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 2,
                  color: _kWhite.withOpacity(0.4),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Round badge
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: _accent.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(2),
                color: _accent.withOpacity(0.08),
              ),
              child: Text(
                'ROUND  ${widget.race.round}',
                style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 2,
                  color: _accent.withOpacity(0.9),
                  shadows: [Shadow(color: _accent.withOpacity(_pulseAnim.value * 0.5), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero card ──────────────────────────────
  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _accent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
          color: _accent.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flag + name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.race.flag, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.race.name.toUpperCase(),
                        style: GoogleFonts.orbitron(
                          fontSize: 14, fontWeight: FontWeight.w900,
                          color: _kWhite, letterSpacing: 0.5, height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.race.circuit,
                        style: GoogleFonts.rajdhani(
                          fontSize: 13, color: _kWhite.withOpacity(0.45),
                        ),
                      ),
                      Text(
                        '${widget.race.city}  ·  ${widget.race.country}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12, color: _kWhite.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Stats row
            Row(
              children: [
                _buildMiniStat('DATE',     widget.race.fullDate),
                _buildMiniStat('LAPS',     '${widget.race.laps}'),
                _buildMiniStat('DISTANCE', '${widget.race.distanceKm} km'),
              ],
            ),

            // Status bar
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  _accent.withOpacity(0.3),
                  Colors.transparent,
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _isCompleted
                        ? const Color(0xFF39FF14).withOpacity(0.1)
                        : _kCyan.withOpacity(0.1),
                    border: Border.all(
                      color: _isCompleted
                          ? const Color(0xFF39FF14).withOpacity(0.4)
                          : _kCyan.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _isCompleted ? '✓  COMPLETED' : '◉  UPCOMING',
                    style: GoogleFonts.orbitron(
                      fontSize: 8, letterSpacing: 1.5,
                      color: _isCompleted
                          ? const Color(0xFF39FF14)
                          : _kCyan,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.race.circuitTypeLabel.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 8, letterSpacing: 1.5,
                    color: _kWhite.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 7, letterSpacing: 2,
              color: _kWhite.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: _kWhite.withOpacity(0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────
  Widget _buildTabBar() {
    final tabs = _isCompleted
        ? ['OVERVIEW', 'RESULTS']
        : ['OVERVIEW'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final active = _tab == e.key;
          return GestureDetector(
            onTap: () => setState(() => _tab = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _accent : Colors.transparent,
                border: Border.all(
                  color: active ? _accent : _kWhite.withOpacity(0.12),
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 10)]
                    : null,
              ),
              child: Text(
                e.value,
                style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700,
                  color: active ? Colors.black : _kWhite.withOpacity(0.4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  OVERVIEW TAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        // Lap record
        _buildSectionTitle('LAP RECORD'),
        const SizedBox(height: 8),
        _buildLapRecordCard(),

        const SizedBox(height: 14),

        // Circuit info
        _buildSectionTitle('CIRCUIT INFO'),
        const SizedBox(height: 8),
        _buildCircuitInfoCard(),

        // Podium if completed
        if (_isCompleted && widget.race.podium.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildSectionTitle('PODIUM'),
          const SizedBox(height: 8),
          _buildPodiumCard(),
        ],

        // Days away if upcoming
        if (!_isCompleted) ...[
          const SizedBox(height: 14),
          _buildCountdownCard(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.orbitron(
        fontSize: 9, letterSpacing: 3,
        color: _accent.withOpacity(0.7),
      ),
    );
  }

  Widget _buildLapRecordCard() {
    final lr = widget.race.lapRecord;
    return _InfoCard(
      accentColor: _accent,
      child: Row(
        children: [
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lr.time,
                style: GoogleFonts.orbitron(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: _accent,
                  shadows: [Shadow(color: _accent.withOpacity(0.5), blurRadius: 12)],
                ),
              ),
              Text(
                'FASTEST LAP',
                style: GoogleFonts.orbitron(
                  fontSize: 8, letterSpacing: 2,
                  color: _kWhite.withOpacity(0.25),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lr.driver,
                style: GoogleFonts.rajdhani(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: _kWhite,
                ),
              ),
              Text(
                '${lr.year}',
                style: GoogleFonts.orbitron(
                  fontSize: 10, color: _kWhite.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitInfoCard() {
    final ci = widget.race.circuitInfo;
    return _InfoCard(
      accentColor: _accent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircuitStat('LENGTH',    '${ci.lengthKm} km'),
          _buildCircuitDivider(),
          _buildCircuitStat('CORNERS',   '${ci.corners}'),
          _buildCircuitDivider(),
          _buildCircuitStat('DRS ZONES', '${ci.drsZones}'),
          _buildCircuitDivider(),
          _buildCircuitStat('TYPE',      ci.type == CircuitType.street ? 'STREET' : 'PERM.'),
        ],
      ),
    );
  }

  Widget _buildCircuitStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.w900,
            color: _kWhite,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 7, letterSpacing: 1.5,
            color: _kWhite.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCircuitDivider() => Container(
    width: 1, height: 32,
    color: _kWhite.withOpacity(0.08),
  );

  Widget _buildPodiumCard() {
    final podium = widget.race.podium;
    const podiumColors = [
      Color(0xFFFFE600),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
    ];
    const medals = ['🥇', '🥈', '🥉'];

    return _InfoCard(
      accentColor: _accent,
      child: Column(
        children: podium.map((r) {
          final color = podiumColors[r.pos - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(medals[r.pos - 1], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.driver,
                        style: GoogleFonts.rajdhani(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _kWhite,
                        ),
                      ),
                      Text(
                        r.team,
                        style: GoogleFonts.rajdhani(
                          fontSize: 11, color: _kWhite.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      r.time,
                      style: GoogleFonts.orbitron(
                        fontSize: 10, color: _kWhite.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '+${r.points} PTS',
                      style: GoogleFonts.orbitron(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: color,
                        shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 6)],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountdownCard() {
    final days = widget.race.daysUntil;
    return _InfoCard(
      accentColor: _accent,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RACE STARTS IN',
                style: GoogleFonts.orbitron(
                  fontSize: 8, letterSpacing: 2,
                  color: _kWhite.withOpacity(0.25),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '$days',
                      style: GoogleFonts.orbitron(
                        fontSize: 36, fontWeight: FontWeight.w900,
                        color: _accent,
                        shadows: [Shadow(color: _accent.withOpacity(_pulseAnim.value), blurRadius: 20)],
                      ),
                    ),
                    TextSpan(
                      text: '  DAYS',
                      style: GoogleFonts.orbitron(
                        fontSize: 14, color: _kWhite.withOpacity(0.3),
                        letterSpacing: 2,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.race.shortDate,
                style: GoogleFonts.orbitron(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: _kWhite,
                ),
              ),
              Text(
                '${widget.race.city.toUpperCase()}',
                style: GoogleFonts.rajdhani(
                  fontSize: 13, color: _kWhite.withOpacity(0.35),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  RESULTS TAB
  // ─────────────────────────────────────────────────────────────

  Widget _buildResultsTab() {
    final results = widget.race.results;
    if (results.isEmpty) {
      return Center(
        child: Text(
          'NO RESULTS YET',
          style: GoogleFonts.orbitron(
            fontSize: 11, letterSpacing: 3,
            color: _kWhite.withOpacity(0.2),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final r = results[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + i * 40),
          curve: Curves.easeOut,
          builder: (_, val, child) => Opacity(
            opacity: val,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - val)),
              child: child,
            ),
          ),
          child: _buildResultRow(r),
        );
      },
    );
  }

  Widget _buildResultRow(RaceResult r) {
    final posColors = {
      1: const Color(0xFFFFE600),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    final posColor = posColors[r.pos] ?? _kWhite.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border.all(
          color: r.pos <= 3
              ? posColor.withOpacity(0.3)
              : _kWhite.withOpacity(0.06),
        ),
        borderRadius: BorderRadius.circular(4),
        color: r.pos == 1
            ? const Color(0xFFFFE600).withOpacity(0.04)
            : _kWhite.withOpacity(0.015),
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 28,
            child: Text(
              '${r.pos}',
              style: GoogleFonts.orbitron(
                fontSize: 16, fontWeight: FontWeight.w900,
                color: posColor,
                shadows: r.pos <= 3
                    ? [Shadow(color: posColor.withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Driver + team
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.driver,
                  style: GoogleFonts.rajdhani(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: _kWhite,
                  ),
                ),
                Text(
                  r.team,
                  style: GoogleFonts.rajdhani(
                    fontSize: 11, color: _kWhite.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r.time,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: _kWhite.withOpacity(r.pos == 1 ? 0.8 : 0.45),
                ),
              ),
              // Points
              Text(
                '+${r.points} PTS',
                style: GoogleFonts.orbitron(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: r.isPointsFinish
                      ? _accent.withOpacity(0.8)
                      : _kWhite.withOpacity(0.15),
                ),
              ),
            ],
          ),

          // Fastest lap indicator
          if (r.fastestLap) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF00FF).withOpacity(0.15),
                border: Border.all(color: const Color(0xFFFF00FF).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'FL',
                style: GoogleFonts.orbitron(
                  fontSize: 7, color: const Color(0xFFFF00FF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Sim button (only for upcoming races) ───
  Widget _buildSimButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(children: [
        // Qualifying button
        GestureDetector(
          onTap: widget.onStartQualifying,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE600),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(
                  color: const Color(0xFFFFE600).withOpacity(0.3),
                  blurRadius: 16)],
            ),
            child: Center(child: Text('🏎  QUALIFYING SESSION  →  RACE',
                style: GoogleFonts.orbitron(
                    fontSize: 12, fontWeight: FontWeight.w900,
                    letterSpacing: 1, color: Colors.black))),
          ),
        ),
        const SizedBox(height: 10),
        // Skip to race button
        GestureDetector(
          onTap: widget.onStartSim,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: _accent.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(3),
                color: _accent.withOpacity(0.08),
              ),
              child: Center(child: Text(
                  '🏁  SKIP QUALIFYING — START RACE',
                  style: GoogleFonts.orbitron(
                      fontSize: 11, fontWeight: FontWeight.w900,
                      letterSpacing: 1, color: _accent))),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  REUSABLE INFO CARD
// ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const _InfoCard({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white.withOpacity(0.02),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  PARTICLE FIELD
// ─────────────────────────────────────────────────────────────────

class _ParticleField extends StatefulWidget {
  const _ParticleField();
  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  static final _rng = Random(33);
  static final _pts = List.generate(40, (i) => _P(
    x: _rng.nextDouble(), y: _rng.nextDouble(),
    s: 0.03 + _rng.nextDouble() * 0.07, r: 0.3 + _rng.nextDouble() * 1.0,
    c: [
      const Color(0xFF00E5FF), const Color(0xFFFF00FF),
      const Color(0xFF39FF14), const Color(0xFFFFE600),
    ][i % 4].withOpacity(0.18 + _rng.nextDouble() * 0.12),
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
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

// ─────────────────────────────────────────────────────────────────
//  SCANLINE PAINTER
// ─────────────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.022);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), p);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}