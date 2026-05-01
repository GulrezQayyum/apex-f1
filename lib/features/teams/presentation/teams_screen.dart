import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Teams Screen
//  Location: lib/features/teams/presentation/teams_screen.dart
//
//  10 constructor profiles with drivers, championship position,
//  car stats, livery accent, season summary.
// ─────────────────────────────────────────────────────────────────

const Color _kBg    = Color(0xFF030308);
const Color _kCyan  = Color(0xFF00E5FF);
const Color _kWhite = Colors.white;

// ── Team data model ───────────────────────────────────────────────
class _TeamData {
  final String name, base, chassis, engine, principal;
  final String flag, driver1, driver2, d1Flag, d2Flag;
  final Color color;
  final int champPos, points, wins, podiums, poles, fastestLaps;
  final double power, aero, reliability, tyre;

  const _TeamData({
    required this.name, required this.base, required this.chassis,
    required this.engine, required this.principal,
    required this.flag, required this.driver1, required this.driver2,
    required this.d1Flag, required this.d2Flag,
    required this.color, required this.champPos, required this.points,
    required this.wins, required this.podiums, required this.poles,
    required this.fastestLaps,
    required this.power, required this.aero,
    required this.reliability, required this.tyre,
  });
}

const _teams = [
  _TeamData(
    name:'McLaren', base:'Woking, UK', chassis:'MCL38',
    engine:'Mercedes', principal:'Andrea Stella',
    flag:'🇬🇧', driver1:'Lando Norris', driver2:'Oscar Piastri',
    d1Flag:'🇬🇧', d2Flag:'🇦🇺',
    color:Color(0xFFFF8000), champPos:1, points:666, wins:6,
    podiums:22, poles:6, fastestLaps:3,
    power:9.2, aero:9.8, reliability:9.0, tyre:9.5,
  ),
  _TeamData(
    name:'Ferrari', base:'Maranello, Italy', chassis:'SF-24',
    engine:'Ferrari', principal:'Frédéric Vasseur',
    flag:'🇮🇹', driver1:'Charles Leclerc', driver2:'Carlos Sainz',
    d1Flag:'🇲🇨', d2Flag:'🇪🇸',
    color:Color(0xFFE8002D), champPos:2, points:652, wins:5,
    podiums:19, poles:9, fastestLaps:4,
    power:9.4, aero:9.2, reliability:8.7, tyre:9.0,
  ),
  _TeamData(
    name:'Red Bull Racing', base:'Milton Keynes, UK', chassis:'RB20',
    engine:'Honda RBPT', principal:'Christian Horner',
    flag:'🇦🇹', driver1:'Max Verstappen', driver2:'Sergio Pérez',
    d1Flag:'🇳🇱', d2Flag:'🇲🇽',
    color:Color(0xFF3671C6), champPos:3, points:589, wins:9,
    podiums:23, poles:9, fastestLaps:5,
    power:9.6, aero:9.0, reliability:8.9, tyre:8.8,
  ),
  _TeamData(
    name:'Mercedes', base:'Brackley, UK', chassis:'W15',
    engine:'Mercedes', principal:'Toto Wolff',
    flag:'🇩🇪', driver1:'Lewis Hamilton', driver2:'George Russell',
    d1Flag:'🇬🇧', d2Flag:'🇬🇧',
    color:Color(0xFF27F4D2), champPos:4, points:468, wins:3,
    podiums:14, poles:2, fastestLaps:2,
    power:9.3, aero:8.8, reliability:9.1, tyre:8.9,
  ),
  _TeamData(
    name:'Aston Martin', base:'Silverstone, UK', chassis:'AMR24',
    engine:'Mercedes', principal:'Mike Krack',
    flag:'🇬🇧', driver1:'Fernando Alonso', driver2:'Lance Stroll',
    d1Flag:'🇪🇸', d2Flag:'🇨🇦',
    color:Color(0xFF358C75), champPos:5, points:94, wins:0,
    podiums:0, poles:0, fastestLaps:0,
    power:8.5, aero:8.3, reliability:8.6, tyre:8.4,
  ),
  _TeamData(
    name:'Alpine', base:'Enstone, UK', chassis:'A524',
    engine:'Renault', principal:'Bruno Famin',
    flag:'🇫🇷', driver1:'Pierre Gasly', driver2:'Esteban Ocon',
    d1Flag:'🇫🇷', d2Flag:'🇫🇷',
    color:Color(0xFF0090FF), champPos:6, points:65, wins:0,
    podiums:0, poles:0, fastestLaps:1,
    power:7.8, aero:8.0, reliability:7.9, tyre:8.1,
  ),
  _TeamData(
    name:'Haas', base:'Kannapolis, USA', chassis:'VF-24',
    engine:'Ferrari', principal:'Ayao Komatsu',
    flag:'🇺🇸', driver1:'Nico Hülkenberg', driver2:'Kevin Magnussen',
    d1Flag:'🇩🇪', d2Flag:'🇩🇰',
    color:Color(0xFFB6BABD), champPos:7, points:58, wins:0,
    podiums:0, poles:0, fastestLaps:0,
    power:8.0, aero:7.7, reliability:7.8, tyre:7.9,
  ),
  _TeamData(
    name:'RB', base:'Faenza, Italy', chassis:'VCARB 01',
    engine:'Honda RBPT', principal:'Laurent Mekies',
    flag:'🇮🇹', driver1:'Yuki Tsunoda', driver2:'Daniel Ricciardo',
    d1Flag:'🇯🇵', d2Flag:'🇦🇺',
    color:Color(0xFF6692FF), champPos:8, points:46, wins:0,
    podiums:0, poles:0, fastestLaps:0,
    power:8.3, aero:7.9, reliability:8.0, tyre:8.0,
  ),
  _TeamData(
    name:'Williams', base:'Grove, UK', chassis:'FW46',
    engine:'Mercedes', principal:'James Vowles',
    flag:'🇬🇧', driver1:'Alex Albon', driver2:'Logan Sargeant',
    d1Flag:'🇹🇭', d2Flag:'🇺🇸',
    color:Color(0xFF64C4FF), champPos:9, points:17, wins:0,
    podiums:0, poles:0, fastestLaps:0,
    power:7.5, aero:7.6, reliability:7.8, tyre:7.7,
  ),
  _TeamData(
    name:'Kick Sauber', base:'Hinwil, Switzerland', chassis:'C44',
    engine:'Ferrari', principal:'Alessandro Alunni Bravi',
    flag:'🇨🇭', driver1:'Valtteri Bottas', driver2:'Zhou Guanyu',
    d1Flag:'🇫🇮', d2Flag:'🇨🇳',
    color:Color(0xFF52E252), champPos:10, points:4, wins:0,
    podiums:0, poles:0, fastestLaps:0,
    power:7.4, aero:7.3, reliability:7.5, tyre:7.6,
  ),
];

// ─────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen>
    with SingleTickerProviderStateMixin {

  int _selectedIdx = 0;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _selectTeam(int idx) {
    setState(() => _selectedIdx = idx);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final team = _teams[_selectedIdx];
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTeamTabs(),
            Expanded(child: _buildTeamDetail(team)),
          ],
        ),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CONSTRUCTORS', style: GoogleFonts.orbitron(
                fontSize: 18, fontWeight: FontWeight.w900, color: _kWhite)),
            Text('2024 TEAMS & TECHNICAL SPECS',
                style: GoogleFonts.orbitron(fontSize: 8, letterSpacing: 2,
                    color: _kWhite.withValues(alpha: 0.3))),
          ]),
        ],
      ),
    );
  }

  // ── Horizontal team picker ──────────────────
  Widget _buildTeamTabs() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: _teams.length,
        itemBuilder: (_, i) {
          final t = _teams[i];
          final sel = i == _selectedIdx;
          return GestureDetector(
            onTap: () => _selectTeam(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? t.color.withValues(alpha: 0.15) : _kWhite.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: sel ? t.color : _kWhite.withValues(alpha: 0.08),
                    width: sel ? 1.5 : 1),
              ),
              child: Text(t.name,
                  style: GoogleFonts.orbitron(
                      fontSize: 9, fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: sel ? t.color : _kWhite.withValues(alpha: 0.35))),
            ),
          );
        },
      ),
    );
  }

  // ── Team detail ─────────────────────────────
  Widget _buildTeamDetail(_TeamData t) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _anim.value)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamBanner(t),
                const SizedBox(height: 14),
                _buildDriverCards(t),
                const SizedBox(height: 14),
                _buildSeasonStats(t),
                const SizedBox(height: 14),
                _buildCarStats(t),
                const SizedBox(height: 14),
                _buildTechInfo(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Team banner ────────────────────────────
  Widget _buildTeamBanner(_TeamData t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: t.color.withValues(alpha: 0.4), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: t.color.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          // Color bar
          Container(
            width: 5, height: 64,
            decoration: BoxDecoration(
              color: t.color,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: t.color.withValues(alpha: 0.6), blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(t.name, style: GoogleFonts.orbitron(
                    fontSize: 17, fontWeight: FontWeight.w900,
                    color: _kWhite,
                    shadows: [Shadow(color: t.color.withValues(alpha: 0.5), blurRadius: 10)])),
              ]),
              const SizedBox(height: 4),
              Text('P${t.champPos}  CONSTRUCTORS', style: GoogleFonts.orbitron(
                  fontSize: 9, color: t.color, letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(t.base, style: GoogleFonts.rajdhani(
                  fontSize: 12, color: _kWhite.withValues(alpha: 0.4))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${t.points}', style: GoogleFonts.orbitron(
                fontSize: 28, fontWeight: FontWeight.w900, color: t.color,
                shadows: [Shadow(color: t.color.withValues(alpha: 0.5), blurRadius: 12)])),
            Text('POINTS', style: GoogleFonts.orbitron(
                fontSize: 7, letterSpacing: 2, color: _kWhite.withValues(alpha: 0.3))),
          ]),
        ],
      ),
    );
  }

  // ── Driver cards side by side ───────────────
  Widget _buildDriverCards(_TeamData t) {
    return Row(
      children: [
        Expanded(child: _driverCard(t.driver1, t.d1Flag, t.color)),
        const SizedBox(width: 10),
        Expanded(child: _driverCard(t.driver2, t.d2Flag, t.color)),
      ],
    );
  }

  Widget _driverCard(String name, String flag, Color color) {
    final parts = name.split(' ');
    final surname = parts.length > 1 ? parts.last : name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.04),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 6),
        Text(surname.toUpperCase(), style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.w900, color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 6)])),
        Text(parts.length > 1 ? parts.first : '',
            style: GoogleFonts.rajdhani(
                fontSize: 11, color: _kWhite.withValues(alpha: 0.4))),
      ]),
    );
  }

  // ── Season stats ────────────────────────────
  Widget _buildSeasonStats(_TeamData t) {
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
          Text('2024 SEASON', style: GoogleFonts.orbitron(
              fontSize: 10, letterSpacing: 3,
              color: _kWhite.withValues(alpha: 0.4))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBlock('${t.wins}', 'WINS', t.color),
              _vDivider(),
              _statBlock('${t.podiums}', 'PODIUMS', t.color),
              _vDivider(),
              _statBlock('${t.poles}', 'POLES', t.color),
              _vDivider(),
              _statBlock('${t.fastestLaps}', 'FASTEST', t.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 36, color: _kWhite.withValues(alpha: 0.06));

  Widget _statBlock(String val, String label, Color color) {
    return Column(children: [
      Text(val, style: GoogleFonts.orbitron(
          fontSize: 22, fontWeight: FontWeight.w900, color: color,
          shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8)])),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.orbitron(
          fontSize: 7, letterSpacing: 1, color: _kWhite.withValues(alpha: 0.3))),
    ]);
  }

  // ── Car performance radar bars ──────────────
  Widget _buildCarStats(_TeamData t) {
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
          Text('CAR PERFORMANCE', style: GoogleFonts.orbitron(
              fontSize: 10, letterSpacing: 3, color: _kWhite.withValues(alpha: 0.4))),
          const SizedBox(height: 14),
          _carBar('POWER',       t.power,       t.color),
          _carBar('AERODYNAMICS',t.aero,        t.color),
          _carBar('RELIABILITY', t.reliability, t.color),
          _carBar('TYRE MGMT',   t.tyre,        t.color),
        ],
      ),
    );
  }

  Widget _carBar(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.orbitron(
                  fontSize: 9, letterSpacing: 1,
                  color: _kWhite.withValues(alpha: 0.5))),
              Text(val.toStringAsFixed(1), style: GoogleFonts.orbitron(
                  fontSize: 9, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 5),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: Stack(children: [
                  Container(color: _kWhite.withValues(alpha: 0.06)),
                  FractionallySizedBox(
                    widthFactor: (val / 10) * _anim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: [BoxShadow(
                            color: color.withValues(alpha: 0.6), blurRadius: 5)],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Technical info ──────────────────────────
  Widget _buildTechInfo(_TeamData t) {
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
          Text('TECHNICAL', style: GoogleFonts.orbitron(
              fontSize: 10, letterSpacing: 3, color: _kWhite.withValues(alpha: 0.4))),
          const SizedBox(height: 12),
          _techRow('CHASSIS',    t.chassis),
          _techRow('POWER UNIT', t.engine),
          _techRow('BASE',       t.base),
          _techRow('PRINCIPAL',  t.principal),
        ],
      ),
    );
  }

  Widget _techRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.orbitron(
                fontSize: 9, letterSpacing: 1,
                color: _kWhite.withValues(alpha: 0.3))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.rajdhani(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kWhite)),
          ),
        ],
      ),
    );
  }
}