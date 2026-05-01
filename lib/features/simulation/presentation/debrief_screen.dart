import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apex_f1/features/simulation/domain/race_sim_engine.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Post-Race Debrief Screen
//  Location: lib/features/simulation/presentation/debrief_screen.dart
//
//  Shows lap time chart, tyre history, overtakes, race highlights,
//  and a shareable race card summary.
// ─────────────────────────────────────────────────────────────────

const _kBg     = Color(0xFF030308);
const _kCyan   = Color(0xFF00E5FF);
const _kYellow = Color(0xFFFFE600);
const _kGreen  = Color(0xFF39FF14);
const _kRed    = Color(0xFFFF073A);
const _kPurple = Color(0xFFFF00FF);
const _kWhite  = Colors.white;

class DebriefScreen extends StatefulWidget {
  final RaceSimResult result;
  final String raceName;
  final String raceFlag;
  final int round;

  const DebriefScreen({
    super.key,
    required this.result,
    required this.raceName,
    required this.raceFlag,
    required this.round,
  });

  @override
  State<DebriefScreen> createState() => _DebriefScreenState();
}

class _DebriefScreenState extends State<DebriefScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _anim;
  int _tab = 0; // 0=pace, 1=tyres, 2=race story

  // Simulated lap time data (generated from result)
  late List<double> _lapTimes;
  late List<_TyreStint> _stints;
  late List<_RaceEvent> _events;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
    _generateData();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _generateData() {
    final total = widget.result.totalLaps;
    final base = 90.0 + _rng.nextDouble() * 3;

    // Lap times — simulate degradation, SC periods, best lap
    _lapTimes = List.generate(total, (i) {
      double t = base;
      // Degradation rises over stint
      t += i * 0.04;
      // SC lap = much slower
      if (i > 0 && _rng.nextInt(20) == 0) t += 15 + _rng.nextDouble() * 5;
      // Random small variance
      t += (_rng.nextDouble() - 0.5) * 0.8;
      // Outlap after pit = slow
      if (i == total ~/ 2 && widget.result.pitStops > 0) t += 8;
      return t;
    });

    // Tyre stints
    _stints = [];
    if (widget.result.pitStops == 0) {
      _stints.add(_TyreStint(
        compound: widget.result.finalTyre,
        startLap: 1, endLap: total,
      ));
    } else {
      final pitLap = total ~/ (widget.result.pitStops + 1);
      _stints.add(_TyreStint(
        compound: TyreCompound.soft,
        startLap: 1, endLap: pitLap,
      ));
      if (widget.result.pitStops >= 2) {
        final pit2 = pitLap + (total - pitLap) ~/ 2;
        _stints.add(_TyreStint(
          compound: TyreCompound.medium,
          startLap: pitLap + 1, endLap: pit2,
        ));
        _stints.add(_TyreStint(
          compound: widget.result.finalTyre,
          startLap: pit2 + 1, endLap: total,
        ));
      } else {
        _stints.add(_TyreStint(
          compound: widget.result.finalTyre,
          startLap: pitLap + 1, endLap: total,
        ));
      }
    }

    // Race events from actual sim events
    _events = widget.result.allEvents.map((e) => _RaceEvent(
      lap: e.lap,
      message: e.message,
      type: e.type,
    )).toList();

    // Add start event
    _events.insert(0, _RaceEvent(
      lap: 0,
      message: '🚦 LIGHTS OUT — RACE START',
      type: RaceEventType.lapUpdate,
    ));

    // Add finish event
    _events.add(_RaceEvent(
      lap: total,
      message: '🏁 CHEQUERED FLAG — P${widget.result.finalPosition}',
      type: RaceEventType.lapUpdate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildResultBanner(),
            _buildTabs(),
            Expanded(child: _buildTabContent()),
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
              color: _kWhite.withValues(alpha: 0.3), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POST-RACE DEBRIEF', style: GoogleFonts.orbitron(
                fontSize: 16, fontWeight: FontWeight.w900, color: _kWhite)),
            Text('${widget.raceFlag}  ${widget.raceName.toUpperCase()}',
                style: GoogleFonts.orbitron(
                    fontSize: 8, letterSpacing: 2,
                    color: _kWhite.withValues(alpha: 0.3))),
          ],
        )),
      ]),
    );
  }

  // ── Result banner ───────────────────────────────────────────────
  Widget _buildResultBanner() {
    final pos     = widget.result.finalPosition;
    final color   = pos == 1
        ? _kYellow
        : pos <= 3
        ? _kCyan
        : pos <= 10 ? _kGreen : _kWhite.withValues(alpha: 0.4);
    final best    = _lapTimes.reduce(min);
    final bestIdx = _lapTimes.indexOf(best);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FINISH', style: GoogleFonts.orbitron(
                fontSize: 8, letterSpacing: 2, color: color.withValues(alpha: 0.6))),
            Text('P$pos', style: GoogleFonts.orbitron(
                fontSize: 40, fontWeight: FontWeight.w900, color: color,
                height: 0.9,
                shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 16)])),
          ]),
          const SizedBox(width: 20),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine('POINTS EARNED', '+${widget.result.pointsEarned}', color),
              _statLine('PIT STOPS',     '${widget.result.pitStops}',      _kWhite.withValues(alpha: 0.6)),
              _statLine('FASTEST LAP',   'L${bestIdx+1} — ${_fmtLap(best)}', _kPurple),
              _statLine('WEATHER',       widget.result.peakWeather.label,   _kCyan.withValues(alpha: 0.7)),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _statLine(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text('$label  ', style: GoogleFonts.orbitron(
            fontSize: 8, letterSpacing: 1, color: _kWhite.withValues(alpha: 0.3))),
        Text(value, style: GoogleFonts.orbitron(
            fontSize: 9, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────
  Widget _buildTabs() {
    const tabs = ['PACE', 'TYRES', 'STORY'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _tab;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? _kCyan : _kWhite.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: active ? _kCyan : _kWhite.withValues(alpha: 0.08)),
              ),
              child: Center(child: Text(tabs[i], style: GoogleFonts.orbitron(
                  fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1,
                  color: active ? Colors.black : _kWhite.withValues(alpha: 0.4)))),
            ),
          ));
        }),
      ),
    );
  }

  // ── Tab content ─────────────────────────────────────────────────
  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: switch (_tab) {
        0 => _buildPaceChart(),
        1 => _buildTyreStints(),
        _ => _buildRaceStory(),
      },
    );
  }

  // ── Pace chart ──────────────────────────────────────────────────
  Widget _buildPaceChart() {
    final best    = _lapTimes.reduce(min);
    final worst   = _lapTimes.reduce(max);
    final bestIdx = _lapTimes.indexOf(best);
    final avgTime = _lapTimes.reduce((a, b) => a + b) / _lapTimes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LAP TIME CHART', style: GoogleFonts.orbitron(
            fontSize: 9, letterSpacing: 3, color: _kWhite.withValues(alpha: 0.3))),
        const SizedBox(height: 6),
        Row(children: [
          _miniChip('BEST', _fmtLap(best), _kPurple),
          const SizedBox(width: 8),
          _miniChip('AVG', _fmtLap(avgTime), _kCyan),
          const SizedBox(width: 8),
          _miniChip('LAPS', '${_lapTimes.length}', _kWhite.withValues(alpha: 0.5)),
        ]),
        const SizedBox(height: 14),
        Expanded(child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => CustomPaint(
            painter: _LapChartPainter(
              lapTimes: _lapTimes,
              bestIdx: bestIdx,
              animValue: _anim.value,
              pitLaps: _stints.map((s) => s.endLap).toList(),
            ),
            size: Size.infinite,
          ),
        )),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legendDot(_kPurple), Text('  FASTEST LAP', style: GoogleFonts.orbitron(
              fontSize: 8, color: _kWhite.withValues(alpha: 0.4))),
          const SizedBox(width: 16),
          _legendDot(_kCyan), Text('  YOUR PACE', style: GoogleFonts.orbitron(
              fontSize: 8, color: _kWhite.withValues(alpha: 0.4))),
          const SizedBox(width: 16),
          _legendDot(_kYellow.withValues(alpha: 0.5)),
          Text('  PIT LAP', style: GoogleFonts.orbitron(
              fontSize: 8, color: _kWhite.withValues(alpha: 0.4))),
        ]),
      ],
    );
  }

  Widget _miniChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.06),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.orbitron(
            fontSize: 11, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.orbitron(
            fontSize: 7, letterSpacing: 1, color: color.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _legendDot(Color c) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  // ── Tyre stints ─────────────────────────────────────────────────
  Widget _buildTyreStints() {
    final total = widget.result.totalLaps.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TYRE STRATEGY', style: GoogleFonts.orbitron(
            fontSize: 9, letterSpacing: 3, color: _kWhite.withValues(alpha: 0.3))),
        const SizedBox(height: 16),
        // Timeline bar
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: _stints.map((stint) {
                      final width = (stint.laps / total) * _anim.value;
                      final color = _tyreColor(stint.compound);
                      return Expanded(
                        flex: stint.laps,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: color.withValues(alpha: 0.5)),
                            boxShadow: [BoxShadow(
                                color: color.withValues(alpha: 0.3), blurRadius: 6)],
                          ),
                          child: Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(stint.compound.shortLabel, style: GoogleFonts.orbitron(
                                  fontSize: 11, fontWeight: FontWeight.w900,
                                  color: color)),
                              Text('${stint.laps}L', style: GoogleFonts.orbitron(
                                  fontSize: 8, color: color.withValues(alpha: 0.7))),
                            ],
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Text('L1', style: GoogleFonts.orbitron(
                      fontSize: 7, color: _kWhite.withValues(alpha: 0.2))),
                  const Spacer(),
                  Text('L${widget.result.totalLaps}', style: GoogleFonts.orbitron(
                      fontSize: 7, color: _kWhite.withValues(alpha: 0.2))),
                ]),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Stint details
        ..._stints.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final color = _tyreColor(s.compound);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(6),
              color: color.withValues(alpha: 0.04),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(s.compound.shortLabel, style: GoogleFonts.orbitron(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.compound.label, style: GoogleFonts.rajdhani(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kWhite)),
                  Text('Laps ${s.startLap}–${s.endLap}  ·  ${s.laps} laps',
                      style: GoogleFonts.orbitron(
                          fontSize: 8, color: _kWhite.withValues(alpha: 0.3))),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('STINT ${i + 1}', style: GoogleFonts.orbitron(
                    fontSize: 8, letterSpacing: 2, color: color.withValues(alpha: 0.5))),
                if (i < _stints.length - 1)
                  Text('→ PIT L${s.endLap}', style: GoogleFonts.orbitron(
                      fontSize: 8, color: _kYellow.withValues(alpha: 0.5))),
              ]),
            ]),
          );
        }),
      ],
    );
  }

  Color _tyreColor(TyreCompound t) => switch (t) {
    TyreCompound.soft         => _kRed,
    TyreCompound.medium       => _kYellow,
    TyreCompound.hard         => _kWhite.withValues(alpha: 0.8),
    TyreCompound.intermediate => _kGreen,
    TyreCompound.wet          => const Color(0xFF4488FF),
  };

  // ── Race story ──────────────────────────────────────────────────
  Widget _buildRaceStory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RACE STORY', style: GoogleFonts.orbitron(
            fontSize: 9, letterSpacing: 3, color: _kWhite.withValues(alpha: 0.3))),
        const SizedBox(height: 12),
        Expanded(child: ListView.builder(
          itemCount: _events.length,
          itemBuilder: (_, i) {
            final e = _events[i];
            final color = _eventColor(e.type);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Center(child: Text(
                        e.lap == 0 ? 'GO' : 'L${e.lap}',
                        style: GoogleFonts.orbitron(
                            fontSize: 8, fontWeight: FontWeight.w900, color: color))),
                  ),
                  if (i < _events.length - 1)
                    Container(width: 1, height: 24, color: _kWhite.withValues(alpha: 0.06)),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                  child: Text(e.message, style: GoogleFonts.rajdhani(
                      fontSize: 14, color: _kWhite.withValues(alpha: 0.8), height: 1.4)),
                )),
              ],
            );
          },
        )),
      ],
    );
  }

  Color _eventColor(RaceEventType t) => switch (t) {
    RaceEventType.safetyCar       => _kYellow,
    RaceEventType.virtualSafetyCar=> _kYellow.withValues(alpha: 0.7),
    RaceEventType.weatherChange   => const Color(0xFF4488FF),
    RaceEventType.rivalBattle     => _kRed,
    RaceEventType.pitWindowOpen   => _kCyan,
    RaceEventType.engineerCall    => _kGreen,
    _                             => _kWhite.withValues(alpha: 0.4),
  };
}

// ── Data models ─────────────────────────────────────────────────────

class _TyreStint {
  final TyreCompound compound;
  final int startLap, endLap;
  int get laps => endLap - startLap + 1;
  _TyreStint({required this.compound, required this.startLap, required this.endLap});
}

class _RaceEvent {
  final int lap;
  final String message;
  final RaceEventType type;
  _RaceEvent({required this.lap, required this.message, required this.type});
}

String _fmtLap(double seconds) {
  final m = (seconds ~/ 60);
  final s = seconds % 60;
  final ms = ((s - s.truncate()) * 1000).round();
  return '${m}:${s.truncate().toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
}

// ── Lap chart painter ────────────────────────────────────────────────

class _LapChartPainter extends CustomPainter {
  final List<double> lapTimes;
  final int bestIdx;
  final double animValue;
  final List<int> pitLaps;

  _LapChartPainter({
    required this.lapTimes,
    required this.bestIdx,
    required this.animValue,
    required this.pitLaps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lapTimes.isEmpty) return;

    final minT = lapTimes.reduce(min);
    final maxT = lapTimes.reduce(max);
    final range = maxT - minT;
    if (range == 0) return;

    final n      = lapTimes.length;
    final stepX  = size.width / (n - 1);
    const padY   = 20.0;

    // Helper: y from lap time
    double yFor(double t) {
      return size.height - padY - ((t - minT) / range) * (size.height - 2 * padY);
    }
    double xFor(int i) => i * stepX;

    // Pit lap vertical lines
    for (final lap in pitLaps) {
      if (lap > 0 && lap < n) {
        canvas.drawLine(
          Offset(xFor(lap), 0), Offset(xFor(lap), size.height),
          Paint()
            ..color = const Color(0xFFFFE600).withValues(alpha: 0.2)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // Grid lines
    for (int i = 0; i < 5; i++) {
      final y = padY + i * (size.height - 2 * padY) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..strokeWidth = 0.5);
    }

    // Fill under line
    final fillPath = Path();
    final drawCount = (n * animValue).round().clamp(2, n);
    fillPath.moveTo(xFor(0), size.height);
    fillPath.lineTo(xFor(0), yFor(lapTimes[0]));
    for (int i = 1; i < drawCount; i++) {
      fillPath.lineTo(xFor(i), yFor(lapTimes[i]));
    }
    fillPath.lineTo(xFor(drawCount - 1), size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill);

    // Main line
    final path = Path();
    path.moveTo(xFor(0), yFor(lapTimes[0]));
    for (int i = 1; i < drawCount; i++) {
      path.lineTo(xFor(i), yFor(lapTimes[i]));
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Dot per lap
    for (int i = 0; i < drawCount; i++) {
      final isBest = i == bestIdx;
      final x = xFor(i);
      final y = yFor(lapTimes[i]);
      if (isBest) {
        canvas.drawCircle(Offset(x, y), 6, Paint()
          ..color = const Color(0xFFFF00FF).withValues(alpha: 0.3));
        canvas.drawCircle(Offset(x, y), 4, Paint()
          ..color = const Color(0xFFFF00FF));
      } else if (i % 5 == 0) {
        canvas.drawCircle(Offset(x, y), 2.5, Paint()
          ..color = const Color(0xFF00E5FF));
      }
    }

    // Fastest lap label
    if (bestIdx < drawCount) {
      final tx = xFor(bestIdx);
      final ty = yFor(lapTimes[bestIdx]);
      final tp = TextPainter(
        text: TextSpan(text: 'FASTEST', style: TextStyle(
          fontFamily: 'Courier', fontSize: 8, fontWeight: FontWeight.w900,
          color: const Color(0xFFFF00FF),
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, ty - 20));
    }
  }

  @override
  bool shouldRepaint(_LapChartPainter old) =>
      old.animValue != animValue;
}