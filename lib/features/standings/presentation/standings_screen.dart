import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Standings Screen
//  Location: lib/features/standings/presentation/standings_screen.dart
//
//  Shows Driver Championship + Constructor Championship
//  with animated bars, podium highlights and team colors.
// ─────────────────────────────────────────────────────────────────

const Color _kBg      = Color(0xFF030308);
const Color _kCyan    = Color(0xFF00E5FF);
const Color _kYellow  = Color(0xFFFFE600);
const Color _kWhite   = Colors.white;
const Color _kMagenta = Color(0xFFFF00FF);

// ── Driver standings data (2024 final) ───────────────────────────
class _DriverStanding {
  final int pos;
  final String name, flag, team, shortName;
  final Color teamColor;
  final int points, wins, podiums, poles;

  const _DriverStanding({
    required this.pos, required this.name, required this.flag,
    required this.team, required this.shortName,
    required this.teamColor, required this.points,
    required this.wins, required this.podiums, required this.poles,
  });
}

// ── Constructor standings data (2024 final) ──────────────────────
class _ConstructorStanding {
  final int pos;
  final String name, flag;
  final Color color;
  final int points, wins;
  final List<String> drivers;

  const _ConstructorStanding({
    required this.pos, required this.name, required this.flag,
    required this.color, required this.points,
    required this.wins, required this.drivers,
  });
}

const _drivers = [
  _DriverStanding(pos:1,  name:'Max Verstappen',   shortName:'VER', flag:'🇳🇱', team:'Red Bull Racing',  teamColor:Color(0xFF3671C6), points:437, wins:9,  podiums:21, poles:9),
  _DriverStanding(pos:2,  name:'Lando Norris',      shortName:'NOR', flag:'🇬🇧', team:'McLaren',          teamColor:Color(0xFFFF8000), points:374, wins:4,  podiums:13, poles:5),
  _DriverStanding(pos:3,  name:'Charles Leclerc',   shortName:'LEC', flag:'🇲🇨', team:'Ferrari',          teamColor:Color(0xFFE8002D), points:356, wins:3,  podiums:12, poles:6),
  _DriverStanding(pos:4,  name:'Oscar Piastri',     shortName:'PIA', flag:'🇦🇺', team:'McLaren',          teamColor:Color(0xFFFF8000), points:292, wins:2,  podiums:9,  poles:1),
  _DriverStanding(pos:5,  name:'Carlos Sainz',      shortName:'SAI', flag:'🇪🇸', team:'Ferrari',          teamColor:Color(0xFFE8002D), points:290, wins:2,  podiums:7,  poles:3),
  _DriverStanding(pos:6,  name:'George Russell',    shortName:'RUS', flag:'🇬🇧', team:'Mercedes',         teamColor:Color(0xFF27F4D2), points:245, wins:1,  podiums:7,  poles:1),
  _DriverStanding(pos:7,  name:'Lewis Hamilton',    shortName:'HAM', flag:'🇬🇧', team:'Mercedes',         teamColor:Color(0xFF27F4D2), points:223, wins:2,  podiums:7,  poles:1),
  _DriverStanding(pos:8,  name:'Sergio Pérez',      shortName:'PER', flag:'🇲🇽', team:'Red Bull Racing',  teamColor:Color(0xFF3671C6), points:152, wins:0,  podiums:2,  poles:0),
  _DriverStanding(pos:9,  name:'Fernando Alonso',   shortName:'ALO', flag:'🇪🇸', team:'Aston Martin',     teamColor:Color(0xFF358C75), points:70,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:10, name:'Lance Stroll',      shortName:'STR', flag:'🇨🇦', team:'Aston Martin',     teamColor:Color(0xFF358C75), points:24,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:11, name:'Yuki Tsunoda',      shortName:'TSU', flag:'🇯🇵', team:'RB',               teamColor:Color(0xFF6692FF), points:22,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:12, name:'Nico Hülkenberg',   shortName:'HUL', flag:'🇩🇪', team:'Haas',             teamColor:Color(0xFFB6BABD), points:31,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:13, name:'Pierre Gasly',      shortName:'GAS', flag:'🇫🇷', team:'Alpine',           teamColor:Color(0xFF0090FF), points:42,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:14, name:'Alex Albon',        shortName:'ALB', flag:'🇹🇭', team:'Williams',         teamColor:Color(0xFF64C4FF), points:12,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:15, name:'Daniel Ricciardo',  shortName:'RIC', flag:'🇦🇺', team:'RB',               teamColor:Color(0xFF6692FF), points:12,  wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:16, name:'Oliver Bearman',    shortName:'BEA', flag:'🇬🇧', team:'Haas',             teamColor:Color(0xFFB6BABD), points:7,   wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:17, name:'Esteban Ocon',      shortName:'OCO', flag:'🇫🇷', team:'Alpine',           teamColor:Color(0xFF0090FF), points:5,   wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:18, name:'Valtteri Bottas',   shortName:'BOT', flag:'🇫🇮', team:'Kick Sauber',      teamColor:Color(0xFF52E252), points:0,   wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:19, name:'Zhou Guanyu',       shortName:'ZHO', flag:'🇨🇳', team:'Kick Sauber',      teamColor:Color(0xFF52E252), points:0,   wins:0,  podiums:0,  poles:0),
  _DriverStanding(pos:20, name:'Logan Sargeant',    shortName:'SAR', flag:'🇺🇸', team:'Williams',         teamColor:Color(0xFF64C4FF), points:0,   wins:0,  podiums:0,  poles:0),
];

const _constructors = [
  _ConstructorStanding(pos:1, name:'McLaren',         flag:'🇬🇧', color:Color(0xFFFF8000), points:666, wins:6,  drivers:['NOR','PIA']),
  _ConstructorStanding(pos:2, name:'Ferrari',         flag:'🇮🇹', color:Color(0xFFE8002D), points:652, wins:5,  drivers:['LEC','SAI']),
  _ConstructorStanding(pos:3, name:'Red Bull Racing', flag:'🇦🇹', color:Color(0xFF3671C6), points:589, wins:9,  drivers:['VER','PER']),
  _ConstructorStanding(pos:4, name:'Mercedes',        flag:'🇩🇪', color:Color(0xFF27F4D2), points:468, wins:3,  drivers:['HAM','RUS']),
  _ConstructorStanding(pos:5, name:'Aston Martin',    flag:'🇬🇧', color:Color(0xFF358C75), points:94,  wins:0,  drivers:['ALO','STR']),
  _ConstructorStanding(pos:6, name:'Alpine',          flag:'🇫🇷', color:Color(0xFF0090FF), points:65,  wins:0,  drivers:['GAS','OCO']),
  _ConstructorStanding(pos:7, name:'Haas',            flag:'🇺🇸', color:Color(0xFFB6BABD), points:58,  wins:0,  drivers:['HUL','MAG']),
  _ConstructorStanding(pos:8, name:'RB',              flag:'🇮🇹', color:Color(0xFF6692FF), points:46,  wins:0,  drivers:['TSU','RIC']),
  _ConstructorStanding(pos:9, name:'Williams',        flag:'🇬🇧', color:Color(0xFF64C4FF), points:17,  wins:0,  drivers:['ALB','SAR']),
  _ConstructorStanding(pos:10,name:'Kick Sauber',     flag:'🇨🇭', color:Color(0xFF52E252), points:4,   wins:0,  drivers:['BOT','ZHO']),
];

// ─────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with TickerProviderStateMixin {

  bool _showDrivers = true;

  late AnimationController _barCtrl;
  late Animation<double>   _barAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _barCtrl.forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool drivers) {
    setState(() => _showDrivers = drivers);
    _barCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: _showDrivers
                      ? _buildDriverList()
                      : _buildConstructorList(),
                ),
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
                Text('CHAMPIONSHIP', style: GoogleFonts.orbitron(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _kWhite,
                    shadows: [Shadow(color: _kCyan.withValues(alpha: 0.4), blurRadius: 12)])),
                Text('2024 FORMULA ONE WORLD CHAMPIONSHIP',
                    style: GoogleFonts.orbitron(fontSize: 8, letterSpacing: 2,
                        color: _kWhite.withValues(alpha: 0.3))),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: _kYellow.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
                color: _kYellow.withValues(alpha: 0.08 * _pulseAnim.value),
              ),
              child: Text('FINAL', style: GoogleFonts.orbitron(
                  fontSize: 9, fontWeight: FontWeight.w900,
                  color: _kYellow, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(child: _tab('DRIVERS', true)),
          const SizedBox(width: 10),
          Expanded(child: _tab('CONSTRUCTORS', false)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool forDrivers) {
    final active = _showDrivers == forDrivers;
    return GestureDetector(
      onTap: () => _switchTab(forDrivers),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? _kCyan : _kWhite.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: active ? _kCyan : _kWhite.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.orbitron(
              fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: active ? Colors.black : _kWhite.withValues(alpha: 0.4))),
        ),
      ),
    );
  }

  // ── Driver list ────────────────────────────
  Widget _buildDriverList() {
    final maxPts = _drivers.first.points.toDouble();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _drivers.length,
      itemBuilder: (_, i) {
        final d = _drivers[i];
        final isPodium = d.pos <= 3;
        final isChamp = d.pos == 1;

        return AnimatedBuilder(
          animation: _barAnim,
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isChamp
                      ? _kYellow.withValues(alpha: 0.5)
                      : isPodium
                      ? d.teamColor.withValues(alpha: 0.3)
                      : _kWhite.withValues(alpha: 0.06),
                  width: isChamp ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
                color: isChamp
                    ? _kYellow.withValues(alpha: 0.05)
                    : _kWhite.withValues(alpha: 0.02),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Position
                      SizedBox(
                        width: 32,
                        child: Text('${d.pos}',
                            style: GoogleFonts.orbitron(
                              fontSize: isChamp ? 20 : 15,
                              fontWeight: FontWeight.w900,
                              color: isChamp
                                  ? _kYellow
                                  : isPodium
                                  ? d.teamColor
                                  : _kWhite.withValues(alpha: 0.3),
                            )),
                      ),
                      // Flag
                      Text(d.flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name,
                                style: GoogleFonts.rajdhani(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: isChamp ? _kYellow : _kWhite)),
                            Text(d.team,
                                style: GoogleFonts.rajdhani(
                                    fontSize: 11, color: d.teamColor)),
                          ],
                        ),
                      ),
                      // Points
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${d.points}',
                              style: GoogleFonts.orbitron(
                                  fontSize: 18, fontWeight: FontWeight.w900,
                                  color: isChamp ? _kYellow : _kWhite)),
                          Text('PTS', style: GoogleFonts.orbitron(
                              fontSize: 8, color: _kWhite.withValues(alpha: 0.3),
                              letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Points bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 3,
                      child: Stack(children: [
                        Container(color: _kWhite.withValues(alpha: 0.06)),
                        FractionallySizedBox(
                          widthFactor: (d.points / maxPts) * _barAnim.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isChamp ? _kYellow : d.teamColor,
                              boxShadow: [BoxShadow(
                                  color: (isChamp ? _kYellow : d.teamColor).withValues(alpha: 0.5),
                                  blurRadius: 4)],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat('WINS', '${d.wins}', d.teamColor),
                      _miniStat('PODIUMS', '${d.podiums}', d.teamColor),
                      _miniStat('POLES', '${d.poles}', d.teamColor),
                      // Short name badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: d.teamColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: d.teamColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(d.shortName,
                            style: GoogleFonts.orbitron(
                                fontSize: 9, fontWeight: FontWeight.w900,
                                color: d.teamColor, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.orbitron(
            fontSize: 7, letterSpacing: 1,
            color: _kWhite.withValues(alpha: 0.25))),
      ],
    );
  }

  // ── Constructor list ────────────────────────
  Widget _buildConstructorList() {
    final maxPts = _constructors.first.points.toDouble();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _constructors.length,
      itemBuilder: (_, i) {
        final c = _constructors[i];
        final isTop = c.pos == 1;

        return AnimatedBuilder(
          animation: _barAnim,
          builder: (_, __) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isTop
                      ? c.color.withValues(alpha: 0.7)
                      : c.color.withValues(alpha: 0.2),
                  width: isTop ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
                color: c.color.withValues(alpha: 0.04),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Position
                      SizedBox(
                        width: 32,
                        child: Text('${c.pos}',
                            style: GoogleFonts.orbitron(
                                fontSize: 20, fontWeight: FontWeight.w900,
                                color: isTop ? c.color : _kWhite.withValues(alpha: 0.3))),
                      ),
                      // Flag + color bar
                      Container(
                        width: 4, height: 40,
                        decoration: BoxDecoration(
                          color: c.color,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.5), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(c.flag, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(c.name,
                                  style: GoogleFonts.rajdhani(
                                      fontSize: 16, fontWeight: FontWeight.w700,
                                      color: _kWhite)),
                            ]),
                            Text(c.drivers.join('  ·  '),
                                style: GoogleFonts.orbitron(
                                    fontSize: 9, color: c.color.withValues(alpha: 0.7),
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${c.points}',
                              style: GoogleFonts.orbitron(
                                  fontSize: 20, fontWeight: FontWeight.w900,
                                  color: isTop ? c.color : _kWhite)),
                          Text('PTS', style: GoogleFonts.orbitron(
                              fontSize: 8, color: _kWhite.withValues(alpha: 0.3),
                              letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Points bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 4,
                      child: Stack(children: [
                        Container(color: _kWhite.withValues(alpha: 0.06)),
                        FractionallySizedBox(
                          widthFactor: (c.points / maxPts) * _barAnim.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.color,
                              boxShadow: [BoxShadow(
                                  color: c.color.withValues(alpha: 0.6), blurRadius: 5)],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat('WINS', '${c.wins}', c.color),
                      _miniStat('DRIVERS', '${c.drivers.length}', c.color),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: c.color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                            isTop ? '🏆 CHAMPION' : 'P${c.pos}',
                            style: GoogleFonts.orbitron(
                                fontSize: 9, fontWeight: FontWeight.w900,
                                color: c.color, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.02);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), p);
    }
  }
  @override bool shouldRepaint(_ScanlinePainter _) => false;
}