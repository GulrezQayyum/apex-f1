import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Calendar Screen (Fixed — handles overflow)
//  Location: lib/features/races/presentation/calendar_screen.dart
// ─────────────────────────────────────────────────────────────────

const Color _kBg    = Color(0xFF030308);
const Color _kCyan  = Color(0xFF00E5FF);
const Color _kWhite = Colors.white;

enum _Filter { all, upcoming, completed }

const List<String> kAvailableSeasons = ['2023', '2024', '2025'];

class CalendarScreen extends StatefulWidget {
  final void Function(RaceModel race) onRaceTapped;

  const CalendarScreen({super.key, required this.onRaceTapped});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {

  final _service = RaceServiceV2();

  List<RaceModel> _allRaces = [];
  bool _loading = true;
  String? _error;
  _Filter _filter = _Filter.all;

  String _currentSeason = kAvailableSeasons.last;

  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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
    setState(() { _loading = true; _error = null; });
    try {
      final seasonModel = await _service.getSeasonRaces(_currentSeason);
      if (mounted) {
        setState(() { _allRaces = seasonModel.races; _loading = false; });
        _entryCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  void _showSeasonPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeasonPickerSheet(
        currentSeason: _currentSeason,
        availableSeasons: kAvailableSeasons,
        onSeasonSelected: (season) {
          Navigator.pop(context);
          if (season != _currentSeason) {
            setState(() => _currentSeason = season);
            _service.switchSeason(season);
            _loadRaces();
          }
        },
      ),
    );
  }

  List<RaceModel> get _filtered => switch (_filter) {
    _Filter.all       => _allRaces,
    _Filter.upcoming  => _allRaces.where((r) => r.status.isUpcoming).toList(),
    _Filter.completed => _allRaces.where((r) => r.status.isCompleted).toList(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const _ParticleField(),
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    _kCyan.withOpacity(_pulseAnim.value),
                    const Color(0xFFFF00FF).withOpacity(_pulseAnim.value * 0.6),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kWhite.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('‹  BACK', style: GoogleFonts.orbitron(
                    fontSize: 9, letterSpacing: 2,
                    color: _kWhite.withOpacity(0.4),
                  )),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showSeasonPicker,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kCyan.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(2),
                      color: _kCyan.withOpacity(0.08),
                      boxShadow: [
                        BoxShadow(
                          color: _kCyan.withOpacity(0.15 * _pulseAnim.value),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_currentSeason SEASON',
                          style: GoogleFonts.orbitron(
                            fontSize: 9, letterSpacing: 2,
                            color: _kCyan, fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _kCyan, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('RACE', style: GoogleFonts.orbitron(
            fontSize: 32, fontWeight: FontWeight.w900,
            color: _kWhite, letterSpacing: 2, height: 1,
          )),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Text('CALENDAR', style: GoogleFonts.orbitron(
              fontSize: 32, fontWeight: FontWeight.w900,
              letterSpacing: 2, height: 1, color: _kCyan,
              shadows: [Shadow(
                color: _kCyan.withOpacity(0.5 * _pulseAnim.value),
                blurRadius: 16,
              )],
            )),
          ),
          const SizedBox(height: 12),
          if (!_loading && _error == null)
            Row(
              children: [
                _buildStatChip(
                  '${_allRaces.where((r) => r.status.isCompleted).length}',
                  'COMPLETED', const Color(0xFF39FF14),
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  '${_allRaces.where((r) => r.status.isUpcoming).length}',
                  'UPCOMING', _kCyan,
                ),
                const SizedBox(width: 8),
                _buildStatChip('${_allRaces.length}', 'TOTAL',
                    _kWhite.withOpacity(0.4)),
              ],
            ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _kCyan.withOpacity(0.4),
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
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(2),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Text(value, style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.w900, color: color,
            shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 6)],
          )),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.orbitron(
            fontSize: 8, letterSpacing: 1.5,
            color: color.withOpacity(0.6),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: _Filter.values.map((f) {
          final active = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _kCyan : Colors.transparent,
                border: Border.all(
                  color: active ? _kCyan : _kWhite.withOpacity(0.15),
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [BoxShadow(color: _kCyan.withOpacity(0.3), blurRadius: 10)]
                    : null,
              ),
              child: Text(
                f.name.toUpperCase(),
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
          const SizedBox(width: 32, height: 32,
              child: CircularProgressIndicator(color: _kCyan, strokeWidth: 1.5)),
          const SizedBox(height: 16),
          Text('LOADING $_currentSeason SEASON...', style: GoogleFonts.orbitron(
            fontSize: 10, letterSpacing: 3,
            color: _kWhite.withOpacity(0.3),
          )),
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
            Text('⚠', style: TextStyle(
              fontSize: 32,
              color: const Color(0xFFFF073A).withOpacity(0.8),
            )),
            const SizedBox(height: 12),
            Text('FAILED TO LOAD', style: GoogleFonts.orbitron(
              fontSize: 12, letterSpacing: 3,
              color: const Color(0xFFFF073A),
            )),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', style: GoogleFonts.rajdhani(
              fontSize: 13, color: _kWhite.withOpacity(0.3),
            ), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadRaces,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _kCyan.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('RETRY', style: GoogleFonts.orbitron(
                  fontSize: 10, letterSpacing: 3, color: _kCyan,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text('NO RACES FOUND', style: GoogleFonts.orbitron(
        fontSize: 12, letterSpacing: 3,
        color: _kWhite.withOpacity(0.2),
      )),
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
            child: _RaceCard(race: race, onTap: () => widget.onRaceTapped(race)),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SEASON PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────

class _SeasonPickerSheet extends StatelessWidget {
  final String currentSeason;
  final List<String> availableSeasons;
  final void Function(String season) onSeasonSelected;

  const _SeasonPickerSheet({
    required this.currentSeason,
    required this.availableSeasons,
    required this.onSeasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFF00E5FF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text('SELECT SEASON', style: GoogleFonts.orbitron(
            fontSize: 14, fontWeight: FontWeight.w900,
            color: Colors.white, letterSpacing: 2,
          )),
          const SizedBox(height: 6),
          Text('TAP TO SWITCH SEASON', style: GoogleFonts.orbitron(
            fontSize: 9, letterSpacing: 2,
            color: Colors.white.withOpacity(0.3),
          )),
          const SizedBox(height: 24),
          ...availableSeasons.reversed.map((season) {
            final isActive = season == currentSeason;
            final isLatest = season == availableSeasons.last;
            return GestureDetector(
              onTap: () => onSeasonSelected(season),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF00E5FF)
                        : Colors.white.withOpacity(0.1),
                    width: isActive ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? const Color(0xFF00E5FF).withOpacity(0.1)
                      : Colors.white.withOpacity(0.02),
                ),
                child: Row(
                  children: [
                    Text(season, style: GoogleFonts.orbitron(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: isActive ? const Color(0xFF00E5FF) : Colors.white,
                    )),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FORMULA ONE SEASON', style: GoogleFonts.orbitron(
                          fontSize: 9, letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.4),
                        )),
                        if (isLatest)
                          Text('LATEST', style: GoogleFonts.orbitron(
                            fontSize: 8, letterSpacing: 2,
                            color: const Color(0xFF39FF14),
                          )),
                        if (isActive && !isLatest)
                          Text('CURRENT', style: GoogleFonts.orbitron(
                            fontSize: 8, letterSpacing: 2,
                            color: const Color(0xFF00E5FF),
                          )),
                      ],
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.6),
                            blurRadius: 6,
                          )],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  RACE CARD (STRICT LAYOUT — FINAL FIX)
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
        padding: const EdgeInsets.all(12), // Slightly reduced padding
        decoration: BoxDecoration(
          border: Border.all(
            color: _hovered
                ? _roundColor.withOpacity(0.7)
                : Colors.white.withOpacity(0.08),
          ),
          borderRadius: BorderRadius.circular(4),
          color: _hovered
              ? _roundColor.withOpacity(0.06)
              : Colors.white.withOpacity(0.02),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. ROUND NUMBER (Fixed Width)
            SizedBox(
              width: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('R', style: GoogleFonts.orbitron(
                    fontSize: 7, color: Colors.white.withOpacity(0.2),
                  )),
                  Text('${race.round}', style: GoogleFonts.orbitron(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: completed ? _roundColor : Colors.white.withOpacity(0.25),
                  )),
                ],
              ),
            ),

            // 2. VERTICAL DIVIDER
            Container(
              width: 1, height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: _roundColor.withOpacity(0.2),
            ),

            // 3. MAIN CONTENT (Flexible & Expanded)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(race.flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded( // Force text to wrap/truncate inside this row
                        child: Text(
                          race.name.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${race.circuit} · ${race.city}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 10, color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (completed && race.winner != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 9)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            race.winner!.driver,
                            style: GoogleFonts.rajdhani(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFE600).withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 4. DATE & STATUS (Fixed Alignment)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(race.shortDate, style: GoogleFonts.orbitron(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: _roundColor,
                )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: completed
                        ? const Color(0xFF39FF14).withOpacity(0.1)
                        : _kCyan.withOpacity(0.1),
                    border: Border.all(
                      color: completed
                          ? const Color(0xFF39FF14).withOpacity(0.3)
                          : _kCyan.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    completed ? 'DONE' : 'UPCOMING',
                    style: GoogleFonts.orbitron(
                      fontSize: 7, fontWeight: FontWeight.w700,
                      color: completed ? const Color(0xFF39FF14) : _kCyan,
                    ),
                  ),
                ),
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
    ][i % 4].withOpacity(0.2 + _rng.nextDouble() * 0.15),
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