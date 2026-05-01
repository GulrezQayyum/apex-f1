import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/race_service.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Calendar Screen
//  Location: lib/features/races/presentation/calendar_screen.dart
// ─────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────
//  SHARED COLORS — accessible by all classes in this file
// ─────────────────────────────────────────────────────────────────
const Color _kBg    = Color(0xFF030308);
const Color _kCyan  = Color(0xFF00E5FF);
const Color _kWhite = Colors.white;

// Filter tabs
enum _Filter { all, upcoming, completed }

class CalendarScreen extends StatefulWidget {
  final void Function(RaceModel race) onRaceTapped;

  const CalendarScreen({super.key, required this.onRaceTapped});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────
  final _service = RaceService();
  List<RaceModel> _allRaces = [];
  bool _loading = true;
  String? _error;
  _Filter _filter = _Filter.all;

  // ── Animation ──────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Colors ─────────────────────────────────

  // ─────────────────────────────────────────────────────────────
  //  INIT
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadRaces();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRaces() async {
    try {
      final races = await _service.getAllRaces();
      if (mounted) {
        setState(() { _allRaces = races; _loading = false; });
        _entryCtrl.forward();
      }
    } on RaceServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  // ── Filtered list ──────────────────────────
  List<RaceModel> get _filtered => switch (_filter) {
    _Filter.all       => _allRaces,
    _Filter.upcoming  => _allRaces.where((r) => r.status.isUpcoming).toList(),
    _Filter.completed => _allRaces.where((r) => r.status.isCompleted).toList(),
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
                    _kCyan.withValues(alpha: _pulseAnim.value),
                    const Color(0xFFFF00FF).withValues(alpha: _pulseAnim.value * 0.6),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildFilterTabs(),
                const SizedBox(height: 4),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kWhite.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '‹  BACK',
                    style: GoogleFonts.orbitron(
                      fontSize: 9, letterSpacing: 2,
                      color: _kWhite.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Season badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(2),
                  color: _kCyan.withValues(alpha: 0.05),
                ),
                child: Text(
                  '2024 SEASON',
                  style: GoogleFonts.orbitron(
                    fontSize: 9, letterSpacing: 2,
                    color: _kCyan.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'RACE',
            style: GoogleFonts.orbitron(
              fontSize: 32, fontWeight: FontWeight.w900,
              color: _kWhite, letterSpacing: 2, height: 1,
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Text(
              'CALENDAR',
              style: GoogleFonts.orbitron(
                fontSize: 32, fontWeight: FontWeight.w900,
                letterSpacing: 2, height: 1,
                color: _kCyan,
                shadows: [
                  Shadow(
                    color: _kCyan.withValues(alpha: 0.5 * _pulseAnim.value),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          if (!_loading && _error == null)
            Row(
              children: [
                _buildStatChip(
                  '${_allRaces.where((r) => r.status.isCompleted).length}',
                  'COMPLETED',
                  const Color(0xFF39FF14),
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  '${_allRaces.where((r) => r.status.isUpcoming).length}',
                  'UPCOMING',
                  _kCyan,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  '${_allRaces.length}',
                  'TOTAL',
                  _kWhite.withValues(alpha: 0.4),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Neon divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _kCyan.withValues(alpha: 0.4),
                Colors.transparent,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(2),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 13, fontWeight: FontWeight.w900,
              color: color,
              shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 8, letterSpacing: 1.5,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter tabs ────────────────────────────
  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: _Filter.values.map((f) {
          final active = _filter == f;
          final label = f.name.toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _kCyan : Colors.transparent,
                border: Border.all(
                  color: active ? _kCyan : _kWhite.withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [BoxShadow(color: _kCyan.withValues(alpha: 0.3), blurRadius: 10)]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700,
                  color: active ? Colors.black : _kWhite.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Body ───────────────────────────────────
  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();
    return _buildRaceList();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              color: _kCyan, strokeWidth: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING RACES...',
            style: GoogleFonts.orbitron(
              fontSize: 10, letterSpacing: 3,
              color: _kWhite.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚠',
              style: TextStyle(
                fontSize: 32, color: const Color(0xFFFF073A).withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'FAILED TO LOAD',
              style: GoogleFonts.orbitron(
                fontSize: 12, letterSpacing: 3,
                color: const Color(0xFFFF073A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.rajdhani(
                fontSize: 13, color: _kWhite.withValues(alpha: 0.3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () { setState(() { _loading = true; _error = null; }); _loadRaces(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _kCyan.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.orbitron(
                    fontSize: 10, letterSpacing: 3, color: _kCyan,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'NO RACES FOUND',
        style: GoogleFonts.orbitron(
          fontSize: 12, letterSpacing: 3,
          color: _kWhite.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildRaceList() {
    return FadeTransition(
      opacity: _entryAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final race = _filtered[i];
          // Staggered animation delay per card
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 50),
            curve: Curves.easeOut,
            builder: (_, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - val)),
                child: child,
              ),
            ),
            child: _RaceCard(
              race: race,
              onTap: () => widget.onRaceTapped(race),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  RACE CARD
// ─────────────────────────────────────────────────────────────────

class _RaceCard extends StatefulWidget {
  final RaceModel race;
  final VoidCallback onTap;

  const _RaceCard({required this.race, required this.onTap});

  @override
  State<_RaceCard> createState() => _RaceCardState();
}

class _RaceCardState extends State<_RaceCard> {
  bool _hovered = false;

  // Team-like color per race based on round
  Color get _roundColor {
    const colors = [
      Color(0xFF00E5FF), Color(0xFFFF00FF), Color(0xFF39FF14),
      Color(0xFFFFE600), Color(0xFFFF3E3E), Color(0xFFFF8000),
      Color(0xFF3671C6), Color(0xFFE8002D), Color(0xFF27F4D2),
      Color(0xFF358C75),
    ];
    return colors[(widget.race.round - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final race = widget.race;
    final completed = race.status.isCompleted;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: _hovered
                ? _roundColor.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(4),
          color: _hovered
              ? _roundColor.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.02),
          boxShadow: _hovered
              ? [BoxShadow(color: _roundColor.withValues(alpha: 0.15), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            // Round number
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Text(
                    'R',
                    style: GoogleFonts.orbitron(
                      fontSize: 8, letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  Text(
                    '${race.round}',
                    style: GoogleFonts.orbitron(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: completed
                          ? _roundColor
                          : Colors.white.withValues(alpha: 0.25),
                      shadows: completed
                          ? [Shadow(color: _roundColor.withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Left divider line
            Container(
              width: 1, height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _roundColor.withValues(alpha: completed ? 0.4 : 0.15),
            ),

            // Flag + race info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(race.flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          race.name,
                          style: GoogleFonts.orbitron(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${race.circuit}  ·  ${race.city}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Winner row if completed
                  if (completed && race.winner != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '🏆',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          race.winner!.driver,
                          style: GoogleFonts.rajdhani(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFE600).withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          race.winner!.team,
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Right side — date + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  race.shortDate,
                  style: GoogleFonts.orbitron(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: _roundColor,
                    shadows: [Shadow(color: _roundColor.withValues(alpha: 0.4), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: completed
                        ? const Color(0xFF39FF14).withValues(alpha: 0.1)
                        : _kCyan.withValues(alpha: 0.1),
                    border: Border.all(
                      color: completed
                          ? const Color(0xFF39FF14).withValues(alpha: 0.3)
                          : _kCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    completed ? 'DONE' : 'UPCOMING',
                    style: GoogleFonts.orbitron(
                      fontSize: 7, letterSpacing: 1,
                      color: completed
                          ? const Color(0xFF39FF14)
                          : _kCyan,
                    ),
                  ),
                ),
                // Days left for upcoming
                if (!completed) ...[
                  const SizedBox(height: 4),
                  Text(
                    race.daysUntil > 0
                        ? '${race.daysUntil}d away'
                        : 'TODAY',
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
  static final _rng = Random(55);
  static final _pts = List.generate(45, (i) => _P(
    x: _rng.nextDouble(), y: _rng.nextDouble(),
    s: 0.03 + _rng.nextDouble() * 0.08, r: 0.4 + _rng.nextDouble() * 1.1,
    c: [
      const Color(0xFF00E5FF), const Color(0xFFFF00FF),
      const Color(0xFF39FF14), const Color(0xFFFFE600),
    ][i % 4].withValues(alpha: 0.2 + _rng.nextDouble() * 0.15),
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
    final p = Paint()..color = Colors.black.withValues(alpha: 0.022);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), p);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}