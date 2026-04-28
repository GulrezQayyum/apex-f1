import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Drivers Screen
//  Location: lib/features/drivers/presentation/drivers_screen.dart
// ─────────────────────────────────────────────────────────────────

const Color _kBg     = Color(0xFF030308);
const Color _kCyan   = Color(0xFF00E5FF);
const Color _kWhite  = Colors.white;

// ── 2024 Driver Data ────────────────────────────────────────────
class _Driver {
  final String id, name, shortName, flag, team, nationality;
  final Color teamColor;
  final int number, points, wins, podiums, poles;
  final double rating; // 0-10

  const _Driver({
    required this.id, required this.name, required this.shortName,
    required this.flag, required this.team, required this.nationality,
    required this.teamColor, required this.number,
    required this.points, required this.wins,
    required this.podiums, required this.poles, required this.rating,
  });
}

const _drivers = [
  _Driver(id:'ver',name:'Max Verstappen',   shortName:'VERSTAPPEN', flag:'🇳🇱',team:'Red Bull Racing',   nationality:'Dutch',   teamColor:Color(0xFF3671C6),number:1,  points:575,wins:19,podiums:21,poles:12,rating:9.9),
  _Driver(id:'per',name:'Sergio Pérez',     shortName:'PÉREZ',      flag:'🇲🇽',team:'Red Bull Racing',   nationality:'Mexican', teamColor:Color(0xFF3671C6),number:11, points:285,wins:2, podiums:9, poles:1, rating:7.8),
  _Driver(id:'lec',name:'Charles Leclerc',  shortName:'LECLERC',    flag:'🇲🇨',team:'Ferrari',           nationality:'Monegasque',teamColor:Color(0xFFE8002D),number:16, points:307,wins:3, podiums:12,poles:5, rating:9.0),
  _Driver(id:'sai',name:'Carlos Sainz',     shortName:'SAINZ',      flag:'🇪🇸',team:'Ferrari',           nationality:'Spanish', teamColor:Color(0xFFE8002D),number:55, points:290,wins:1, podiums:10,poles:3, rating:8.7),
  _Driver(id:'ham',name:'Lewis Hamilton',   shortName:'HAMILTON',   flag:'🇬🇧',team:'Mercedes',          nationality:'British', teamColor:Color(0xFF27F4D2),number:44, points:174,wins:0, podiums:2, poles:0, rating:9.2),
  _Driver(id:'rus',name:'George Russell',   shortName:'RUSSELL',    flag:'🇬🇧',team:'Mercedes',          nationality:'British', teamColor:Color(0xFF27F4D2),number:63, points:162,wins:1, podiums:4, poles:1, rating:8.5),
  _Driver(id:'nor',name:'Lando Norris',     shortName:'NORRIS',     flag:'🇬🇧',team:'McLaren',           nationality:'British', teamColor:Color(0xFFFF8000),number:4,  points:374,wins:4, podiums:13,poles:4, rating:9.3),
  _Driver(id:'pia',name:'Oscar Piastri',    shortName:'PIASTRI',    flag:'🇦🇺',team:'McLaren',           nationality:'Australian',teamColor:Color(0xFFFF8000),number:81, points:292,wins:2, podiums:8, poles:2, rating:8.8),
  _Driver(id:'alo',name:'Fernando Alonso',  shortName:'ALONSO',     flag:'🇪🇸',team:'Aston Martin',      nationality:'Spanish', teamColor:Color(0xFF358C75),number:14, points:70, wins:0, podiums:0, poles:0, rating:9.0),
  _Driver(id:'str',name:'Lance Stroll',     shortName:'STROLL',     flag:'🇨🇦',team:'Aston Martin',      nationality:'Canadian',teamColor:Color(0xFF358C75),number:18, points:24, wins:0, podiums:0, poles:0, rating:6.8),
  _Driver(id:'gas',name:'Pierre Gasly',     shortName:'GASLY',      flag:'🇫🇷',team:'Alpine',            nationality:'French',  teamColor:Color(0xFF0090FF),number:10, points:8,  wins:0, podiums:0, poles:0, rating:7.5),
  _Driver(id:'oco',name:'Esteban Ocon',     shortName:'OCON',       flag:'🇫🇷',team:'Alpine',            nationality:'French',  teamColor:Color(0xFF0090FF),number:31, points:5,  wins:0, podiums:0, poles:0, rating:7.2),
  _Driver(id:'alb',name:'Alexander Albon',  shortName:'ALBON',      flag:'🇹🇭',team:'Williams',          nationality:'Thai',    teamColor:Color(0xFF64C4FF),number:23, points:12, wins:0, podiums:0, poles:0, rating:7.8),
  _Driver(id:'sar',name:'Logan Sargeant',   shortName:'SARGEANT',   flag:'🇺🇸',team:'Williams',          nationality:'American',teamColor:Color(0xFF64C4FF),number:2,  points:1,  wins:0, podiums:0, poles:0, rating:5.9),
  _Driver(id:'tsu',name:'Yuki Tsunoda',     shortName:'TSUNODA',    flag:'🇯🇵',team:'RB',                nationality:'Japanese',teamColor:Color(0xFF6692FF),number:22, points:22, wins:0, podiums:0, poles:0, rating:7.6),
  _Driver(id:'ric',name:'Daniel Ricciardo', shortName:'RICCIARDO',  flag:'🇦🇺',team:'RB',                nationality:'Australian',teamColor:Color(0xFF6692FF),number:3,  points:12, wins:0, podiums:0, poles:0, rating:7.3),
  _Driver(id:'hul',name:'Nico Hülkenberg',  shortName:'HÜLKENBERG', flag:'🇩🇪',team:'Haas',             nationality:'German',  teamColor:Color(0xFFB6BABD),number:27, points:31, wins:0, podiums:0, poles:0, rating:7.7),
  _Driver(id:'mag',name:'Kevin Magnussen',  shortName:'MAGNUSSEN',  flag:'🇩🇰',team:'Haas',             nationality:'Danish',  teamColor:Color(0xFFB6BABD),number:20, points:14, wins:0, podiums:0, poles:0, rating:7.0),
  _Driver(id:'bot',name:'Valtteri Bottas',  shortName:'BOTTAS',     flag:'🇫🇮',team:'Kick Sauber',       nationality:'Finnish', teamColor:Color(0xFF52E252),number:77, points:0,  wins:0, podiums:0, poles:0, rating:7.1),
  _Driver(id:'zho',name:'Zhou Guanyu',      shortName:'ZHOU',       flag:'🇨🇳',team:'Kick Sauber',       nationality:'Chinese', teamColor:Color(0xFF52E252),number:24, points:0,  wins:0, podiums:0, poles:0, rating:6.8),
];

// ─────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen>
    with TickerProviderStateMixin {

  _Driver? _selected;
  String _sortBy = 'points';
  late AnimationController _detailCtrl;
  late Animation<double>   _detailAnim;

  List<_Driver> get _sorted {
    final list = [..._drivers];
    switch (_sortBy) {
      case 'points':  list.sort((a,b) => b.points.compareTo(a.points));
      case 'wins':    list.sort((a,b) => b.wins.compareTo(a.wins));
      case 'rating':  list.sort((a,b) => b.rating.compareTo(a.rating));
      case 'number':  list.sort((a,b) => a.number.compareTo(b.number));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _detailCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _detailAnim = CurvedAnimation(parent: _detailCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _detailCtrl.dispose(); super.dispose(); }

  void _openDriver(_Driver d) {
    setState(() => _selected = d);
    _detailCtrl.forward(from: 0);
  }

  void _closeDriver() {
    _detailCtrl.reverse().then((_) => setState(() => _selected = null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSortBar(),
                Expanded(child: _buildList()),
              ],
            ),
          ),
          if (_selected != null) _buildDetailOverlay(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kCyan.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: _kWhite.withOpacity(0.4), size: 18),
          ),
          const SizedBox(width: 12),
          Text('DRIVERS', style: GoogleFonts.orbitron(
            fontSize: 16, fontWeight: FontWeight.w900,
            color: _kWhite, letterSpacing: 3,
          )),
          const SizedBox(width: 8),
          Text('2024', style: GoogleFonts.orbitron(
            fontSize: 10, color: _kCyan.withOpacity(0.6), letterSpacing: 2,
          )),
          const Spacer(),
          Text('${_drivers.length} DRIVERS', style: GoogleFonts.orbitron(
            fontSize: 9, color: _kWhite.withOpacity(0.3), letterSpacing: 1,
          )),
        ],
      ),
    );
  }

  // ── Sort bar ─────────────────────────────────────────────────
  Widget _buildSortBar() {
    const options = [('points','PTS'),('wins','WINS'),('rating','RATING'),('number','NUM')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('SORT  ', style: GoogleFonts.orbitron(
              fontSize: 8, color: _kWhite.withOpacity(0.3), letterSpacing: 2)),
          ...options.map((o) => GestureDetector(
            onTap: () => setState(() => _sortBy = o.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: _sortBy == o.$1
                    ? _kCyan.withOpacity(0.6)
                    : _kWhite.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(3),
                color: _sortBy == o.$1
                    ? _kCyan.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Text(o.$2, style: GoogleFonts.orbitron(
                fontSize: 8, letterSpacing: 1,
                color: _sortBy == o.$1 ? _kCyan : _kWhite.withOpacity(0.3),
                fontWeight: _sortBy == o.$1 ? FontWeight.w700 : FontWeight.w400,
              )),
            ),
          )),
        ],
      ),
    );
  }

  // ── Driver list ───────────────────────────────────────────────
  Widget _buildList() {
    final list = _sorted;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final d = list[i];
        final rank = i + 1;
        return GestureDetector(
          onTap: () => _openDriver(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: d.teamColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
              color: d.teamColor.withOpacity(0.04),
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 28,
                  child: Text('$rank',
                      style: GoogleFonts.orbitron(
                        fontSize: 13, fontWeight: FontWeight.w900,
                        color: rank <= 3
                            ? [const Color(0xFFFFE600), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)][rank-1]
                            : _kWhite.withOpacity(0.25),
                      )),
                ),

                // Driver number badge
                Container(
                  width: 28, height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: d.teamColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: d.teamColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text('${d.number}',
                        style: GoogleFonts.orbitron(
                          fontSize: 9, fontWeight: FontWeight.w900,
                          color: d.teamColor,
                        )),
                  ),
                ),

                // Flag + Name
                Text(d.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.shortName,
                          style: GoogleFonts.orbitron(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: _kWhite, letterSpacing: 0.5,
                          )),
                      Text(d.team,
                          style: GoogleFonts.rajdhani(
                            fontSize: 11, color: d.teamColor.withOpacity(0.7),
                          )),
                    ],
                  ),
                ),

                // Stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${d.points} PTS',
                        style: GoogleFonts.orbitron(
                          fontSize: 11, fontWeight: FontWeight.w900,
                          color: _kCyan,
                        )),
                    Text('${d.wins}W  ${d.podiums}P',
                        style: GoogleFonts.orbitron(
                          fontSize: 8, color: _kWhite.withOpacity(0.3),
                        )),
                  ],
                ),

                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: _kWhite.withOpacity(0.2), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Driver detail overlay ─────────────────────────────────────
  Widget _buildDetailOverlay() {
    final d = _selected!;
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeDriver,
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: FadeTransition(
              opacity: _detailAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15), end: Offset.zero,
                ).animate(_detailAnim),
                child: GestureDetector(
                  onTap: () {}, // prevent close on card tap
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: d.teamColor.withOpacity(0.6), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      color: _kBg,
                      boxShadow: [BoxShadow(color: d.teamColor.withOpacity(0.2), blurRadius: 30)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: _closeDriver,
                            child: Icon(Icons.close_rounded,
                                color: _kWhite.withOpacity(0.3), size: 20),
                          ),
                        ),

                        // Number
                        Text('#${d.number}',
                            style: GoogleFonts.orbitron(
                              fontSize: 48, fontWeight: FontWeight.w900,
                              color: d.teamColor,
                              shadows: [Shadow(color: d.teamColor.withOpacity(0.6), blurRadius: 20)],
                            )),

                        // Name
                        Text('${d.flag}  ${d.name}',
                            style: GoogleFonts.orbitron(
                              fontSize: 16, fontWeight: FontWeight.w900,
                              color: _kWhite, letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(d.team,
                            style: GoogleFonts.rajdhani(
                              fontSize: 13, color: d.teamColor.withOpacity(0.8),
                              letterSpacing: 1,
                            )),
                        Text(d.nationality,
                            style: GoogleFonts.rajdhani(
                              fontSize: 11, color: _kWhite.withOpacity(0.3),
                            )),

                        const SizedBox(height: 20),

                        // Stats grid
                        _statGrid(d),

                        const SizedBox(height: 16),

                        // Rating bar
                        _ratingBar(d),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statGrid(_Driver d) {
    final stats = [
      ('POINTS', '${d.points}'),
      ('WINS', '${d.wins}'),
      ('PODIUMS', '${d.podiums}'),
      ('POLES', '${d.poles}'),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: stats.map((s) => Container(
        decoration: BoxDecoration(
          color: d.teamColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: d.teamColor.withOpacity(0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.$2, style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w900, color: d.teamColor)),
          const SizedBox(height: 2),
          Text(s.$1, style: GoogleFonts.orbitron(
              fontSize: 7, letterSpacing: 1, color: _kWhite.withOpacity(0.3))),
        ]),
      )).toList(),
    );
  }

  Widget _ratingBar(_Driver d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('DRIVER RATING', style: GoogleFonts.orbitron(
              fontSize: 8, letterSpacing: 2, color: _kWhite.withOpacity(0.3))),
          Text('${d.rating}/10', style: GoogleFonts.orbitron(
              fontSize: 10, fontWeight: FontWeight.w900, color: d.teamColor)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 5,
            child: Stack(children: [
              Container(color: _kWhite.withOpacity(0.07)),
              FractionallySizedBox(
                widthFactor: d.rating / 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: d.teamColor,
                    boxShadow: [BoxShadow(color: d.teamColor.withOpacity(0.5), blurRadius: 4)],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}