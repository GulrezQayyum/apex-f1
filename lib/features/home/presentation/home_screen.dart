import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/onboarding/presentation/profile_setup_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  STATIC DATA
// ─────────────────────────────────────────────────────────────────

class NextRace {
  final String name;
  final String circuit;
  final String country;
  final String flag;
  final String date;
  final int daysLeft;
  const NextRace({
    required this.name, required this.circuit,
    required this.country, required this.flag,
    required this.date, required this.daysLeft,
  });
}

const kNextRace = NextRace(
  name: 'Australian Grand Prix',
  circuit: 'Albert Park Circuit',
  country: 'Australia',
  flag: '🇦🇺',
  date: '24 MAR',
  daysLeft: 9,
);

class _StandingRow {
  final int pos;
  final String driver;
  final String team;
  final int pts;
  final Color color;
  const _StandingRow(this.pos, this.driver, this.team, this.pts, this.color);
}

const _standings = [
  _StandingRow(1, 'Verstappen', 'Red Bull',  51, Color(0xFF3671C6)),
  _StandingRow(2, 'Pérez',      'Red Bull',  38, Color(0xFF3671C6)),
  _StandingRow(3, 'Norris',     'McLaren',   28, Color(0xFFFF8000)),
  _StandingRow(4, 'Sainz',      'Ferrari',   20, Color(0xFFE8002D)),
  _StandingRow(5, 'Piastri',    'McLaren',   14, Color(0xFFFF8000)),
];

// ─────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  final void Function(String route) onNavigate;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  // ── Time ────────────────────────────────────
  late Timer _clock;
  DateTime _now = DateTime.now();

  // ── Animations ──────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  // ── Colors ──────────────────────────────────
  static const Color _bg    = Color(0xFF030308);
  static const Color _cyan  = Color(0xFF00E5FF);
  static const Color _white = Colors.white;

  Color get _accent => widget.profile.favTeam?.color ?? _cyan;

  @override
  void initState() {
    super.initState();

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Staggered entry
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  String get _timeStr =>
      '${_now.hour.toString().padLeft(2, '0')}:'
          '${_now.minute.toString().padLeft(2, '0')}:'
          '${_now.second.toString().padLeft(2, '0')}';

  String get _dateStr {
    const days   = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${days[_now.weekday - 1]}  ${_now.day}  ${months[_now.month - 1]}  ${_now.year}';
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Particle BG
          const _ParticleField(),

          // Scanlines
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),

          // Top accent line
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    _accent.withOpacity(_pulse.value),
                    const Color(0xFFFF00FF).withOpacity(_pulse.value * 0.7),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          // Scrollable content
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(_entryAnim),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 16),
                    _buildWelcomeCard(),
                    const SizedBox(height: 12),
                    _buildNextRaceCard(),
                    const SizedBox(height: 12),
                    _buildQuickNav(),
                    const SizedBox(height: 12),
                    _buildStandingsCard(),
                    const SizedBox(height: 12),
                    _buildLastResultCard(),
                    const SizedBox(height: 8),
                    _buildStatusBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'APEX',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _white,
                    shadows: [
                      Shadow(
                        color: _accent.withOpacity(0.5 * _pulse.value),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'F1',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _accent,
                    shadows: [
                      Shadow(color: _accent.withOpacity(_pulse.value), blurRadius: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Clock
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _timeStr,
              style: GoogleFonts.orbitron(
                fontSize: 16,
                color: _accent,
                letterSpacing: 1,
                shadows: [Shadow(color: _accent.withOpacity(0.5), blurRadius: 8)],
              ),
            ),
            Text(
              _dateStr,
              style: GoogleFonts.orbitron(
                fontSize: 9,
                color: _white.withOpacity(0.3),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Welcome card ────────────────────────────
  Widget _buildWelcomeCard() {
    final driver = widget.profile.favDriver;
    final team   = widget.profile.favTeam;

    return _NeonCard(
      accentColor: _accent,
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 1.5),
              color: _accent.withOpacity(0.1),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Center(
              child: Text(
                widget.profile.name.isNotEmpty
                    ? widget.profile.name[0].toUpperCase()
                    : '?',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME BACK',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: _white.withOpacity(0.35),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.profile.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (driver != null) ...[
                      Text(driver.flag, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        driver.name,
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: _white.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (driver != null && team != null)
                      Text(
                        '  ·  ',
                        style: TextStyle(color: _white.withOpacity(0.2), fontSize: 13),
                      ),
                    if (team != null)
                      Text(
                        team.name,
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: team.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (driver == null && team == null)
                      Text(
                        'No driver set',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: _white.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Season badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '2024',
              style: GoogleFonts.orbitron(
                fontSize: 10,
                color: _white.withOpacity(0.2),
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Next race card ──────────────────────────
  Widget _buildNextRaceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFE600).withOpacity(0.25)),
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFFFFE600).withOpacity(0.03),
      ),
      child: Row(
        children: [
          // Left accent
          Container(
            width: 3, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE600),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFFE600).withOpacity(0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '◆  NEXT RACE',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: const Color(0xFFFFE600).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(kNextRace.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kNextRace.name,
                            style: GoogleFonts.orbitron(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${kNextRace.circuit}  ·  ${kNextRace.date}',
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              color: _white.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Days left
          Column(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Text(
                  '${kNextRace.daysLeft}',
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFE600),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFE600).withOpacity(_pulse.value),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'DAYS',
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: const Color(0xFFFFE600).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick nav grid ──────────────────────────
  Widget _buildQuickNav() {
    final items = [
      _NavItem(label: 'CALENDAR',  sub: '24 Grand Prix',    icon: '🏁', color: _cyan,                   route: 'calendar'),
      _NavItem(label: 'STANDINGS', sub: 'Driver rankings',  icon: '🏆', color: const Color(0xFFFF00FF), route: 'standings'),
      _NavItem(label: 'DRIVERS',   sub: '20 drivers',       icon: '🧑‍✈️', color: const Color(0xFF39FF14), route: 'drivers'),
      _NavItem(label: 'RACE SIM',  sub: 'Start a race',     icon: '🎮', color: const Color(0xFFFFE600), route: 'sim'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: items.map(_buildNavCard).toList(),
    );
  }

  Widget _buildNavCard(_NavItem item) {
    return GestureDetector(
      onTap: () => widget.onNavigate(item.route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: item.color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(4),
          color: _white.withOpacity(0.025),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 20)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  item.sub,
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    color: _white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Standings card ──────────────────────────
  Widget _buildStandingsCard() {
    return _NeonCard(
      accentColor: _accent,
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP 5  DRIVERS',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _white,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate('standings'),
                child: Text(
                  'SEE ALL ›',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: _white.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rows
          ..._standings.map((s) => _buildStandingRow(s)),
        ],
      ),
    );
  }

  Widget _buildStandingRow(_StandingRow s) {
    final posColor = s.pos == 1
        ? const Color(0xFFFFE600)
        : s.pos == 2
        ? const Color(0xFFC0C0C0)
        : s.pos == 3
        ? const Color(0xFFCD7F32)
        : _white.withOpacity(0.25);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 24,
            child: Text(
              '${s.pos}',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: posColor,
                shadows: s.pos <= 3
                    ? [Shadow(color: posColor.withOpacity(0.6), blurRadius: 8)]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Team color dot
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.color,
              boxShadow: [BoxShadow(color: s.color.withOpacity(0.6), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 10),

          // Driver name
          Expanded(
            child: Text(
              s.driver,
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _white,
              ),
            ),
          ),

          // Team
          Text(
            s.team,
            style: GoogleFonts.rajdhani(
              fontSize: 12,
              color: _white.withOpacity(0.35),
            ),
          ),
          const SizedBox(width: 12),

          // Points
          Text(
            '${s.pts}',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _accent,
              shadows: [Shadow(color: _accent.withOpacity(0.4), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }

  // ── Last result card ────────────────────────
  Widget _buildLastResultCard() {
    // Placeholder — will be populated from races.json once Phase 2 is built
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _white.withOpacity(0.07)),
        borderRadius: BorderRadius.circular(4),
        color: _white.withOpacity(0.015),
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 48,
            decoration: BoxDecoration(
              color: _white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LAST RESULT',
                  style: GoogleFonts.orbitron(
                    fontSize: 9, letterSpacing: 3,
                    color: _white.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No races completed yet',
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    color: _white.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Start a race sim to see your result here',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: _white.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.onNavigate('sim'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _accent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(3),
                color: _accent.withOpacity(0.08),
              ),
              child: Text(
                'RACE\nNOW',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: _accent,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status bar ──────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'APEXF1  v1.0',
            style: GoogleFonts.orbitron(
              fontSize: 9, letterSpacing: 2,
              color: _white.withOpacity(0.15),
            ),
          ),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Row(
              children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF39FF14).withOpacity(_pulse.value),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF39FF14).withOpacity(0.5 * _pulse.value),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: GoogleFonts.orbitron(
                    fontSize: 9, letterSpacing: 2,
                    color: const Color(0xFF39FF14).withOpacity(_pulse.value),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '2024 SEASON',
            style: GoogleFonts.orbitron(
              fontSize: 9, letterSpacing: 2,
              color: _white.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  REUSABLE NEON CARD
// ─────────────────────────────────────────────────────────────────

class _NeonCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const _NeonCard({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white.withOpacity(0.025),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  NAV ITEM MODEL
// ─────────────────────────────────────────────────────────────────

class _NavItem {
  final String label, sub, icon, route;
  final Color color;
  const _NavItem({
    required this.label, required this.sub,
    required this.icon, required this.color,
    required this.route,
  });
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

  static final _rng = Random(77);
  static final _pts = List.generate(50, (i) => _P(
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    s: 0.03 + _rng.nextDouble() * 0.09,
    r: 0.4 + _rng.nextDouble() * 1.2,
    c: [
      const Color(0xFF00E5FF),
      const Color(0xFFFF00FF),
      const Color(0xFF39FF14),
      const Color(0xFFFFE600),
    ][i % 4].withOpacity(0.25 + _rng.nextDouble() * 0.2),
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
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
  final double x, y, s, r;
  final Color c;
  const _P({required this.x, required this.y, required this.s, required this.r, required this.c});
}

class _PPainter extends CustomPainter {
  final double prog;
  final List<_P> pts;
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