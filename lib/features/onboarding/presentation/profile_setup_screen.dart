import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';
import 'package:apex_f1/features/races/presentation/season_import_screen.dart';

// ─────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────

class F1Team {
  final String id;
  final String name;
  final Color color;
  final Color accent;

  const F1Team({
    required this.id,
    required this.name,
    required this.color,
    required this.accent,
  });
}

class F1Driver {
  final String id;
  final String name;
  final int number;
  final String teamId;
  final String nationality;
  final String flag;

  const F1Driver({
    required this.id,
    required this.name,
    required this.number,
    required this.teamId,
    required this.nationality,
    required this.flag,
  });
}

// ─────────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────────

const List<F1Team> kTeams = [
  F1Team(id: 'rb',  name: 'Red Bull Racing',  color: Color(0xFF3671C6), accent: Color(0xFFCC1E4A)),
  F1Team(id: 'fer', name: 'Ferrari',           color: Color(0xFFE8002D), accent: Color(0xFFFFD700)),
  F1Team(id: 'mer', name: 'Mercedes',          color: Color(0xFF27F4D2), accent: Color(0xFFFFFFFF)),
  F1Team(id: 'mcl', name: 'McLaren',           color: Color(0xFFFF8000), accent: Color(0xFF000000)),
  F1Team(id: 'ast', name: 'Aston Martin',      color: Color(0xFF358C75), accent: Color(0xFFCEF92D)),
  F1Team(id: 'alp', name: 'Alpine',            color: Color(0xFF0090FF), accent: Color(0xFFFF87BC)),
  F1Team(id: 'wil', name: 'Williams',          color: Color(0xFF64C4FF), accent: Color(0xFFFFFFFF)),
  F1Team(id: 'vis', name: 'RB Visa Cash App',  color: Color(0xFF6692FF), accent: Color(0xFFFF0000)),
  F1Team(id: 'haa', name: 'Haas',              color: Color(0xFFB6BABD), accent: Color(0xFFFF0000)),
  F1Team(id: 'sau', name: 'Kick Sauber',       color: Color(0xFF52E252), accent: Color(0xFF000000)),
];

const List<F1Driver> kDrivers = [
  F1Driver(id: 'ver', name: 'Max Verstappen',   number: 1,  teamId: 'rb',  nationality: 'Dutch',      flag: '🇳🇱'),
  F1Driver(id: 'per', name: 'Sergio Pérez',     number: 11, teamId: 'rb',  nationality: 'Mexican',    flag: '🇲🇽'),
  F1Driver(id: 'lec', name: 'Charles Leclerc',  number: 16, teamId: 'fer', nationality: 'Monégasque', flag: '🇲🇨'),
  F1Driver(id: 'sai', name: 'Carlos Sainz',     number: 55, teamId: 'fer', nationality: 'Spanish',    flag: '🇪🇸'),
  F1Driver(id: 'ham', name: 'Lewis Hamilton',   number: 44, teamId: 'mer', nationality: 'British',    flag: '🇬🇧'),
  F1Driver(id: 'rus', name: 'George Russell',   number: 63, teamId: 'mer', nationality: 'British',    flag: '🇬🇧'),
  F1Driver(id: 'nor', name: 'Lando Norris',     number: 4,  teamId: 'mcl', nationality: 'British',    flag: '🇬🇧'),
  F1Driver(id: 'pia', name: 'Oscar Piastri',    number: 81, teamId: 'mcl', nationality: 'Australian', flag: '🇦🇺'),
  F1Driver(id: 'alo', name: 'Fernando Alonso',  number: 14, teamId: 'ast', nationality: 'Spanish',    flag: '🇪🇸'),
  F1Driver(id: 'str', name: 'Lance Stroll',     number: 18, teamId: 'ast', nationality: 'Canadian',   flag: '🇨🇦'),
  F1Driver(id: 'gas', name: 'Pierre Gasly',     number: 10, teamId: 'alp', nationality: 'French',     flag: '🇫🇷'),
  F1Driver(id: 'oco', name: 'Esteban Ocon',     number: 31, teamId: 'alp', nationality: 'French',     flag: '🇫🇷'),
  F1Driver(id: 'alb', name: 'Alexander Albon',  number: 23, teamId: 'wil', nationality: 'Thai',       flag: '🇹🇭'),
  F1Driver(id: 'sar', name: 'Logan Sargeant',   number: 2,  teamId: 'wil', nationality: 'American',   flag: '🇺🇸'),
  F1Driver(id: 'tsu', name: 'Yuki Tsunoda',     number: 22, teamId: 'vis', nationality: 'Japanese',   flag: '🇯🇵'),
  F1Driver(id: 'ric', name: 'Daniel Ricciardo', number: 3,  teamId: 'vis', nationality: 'Australian', flag: '🇦🇺'),
  F1Driver(id: 'hul', name: 'Nico Hülkenberg',  number: 27, teamId: 'haa', nationality: 'German',     flag: '🇩🇪'),
  F1Driver(id: 'mag', name: 'Kevin Magnussen',  number: 20, teamId: 'haa', nationality: 'Danish',     flag: '🇩🇰'),
  F1Driver(id: 'bot', name: 'Valtteri Bottas',  number: 77, teamId: 'sau', nationality: 'Finnish',    flag: '🇫🇮'),
  F1Driver(id: 'zho', name: 'Zhou Guanyu',      number: 24, teamId: 'sau', nationality: 'Chinese',    flag: '🇨🇳'),
];

// ─────────────────────────────────────────────────────────────────
//  PROFILE MODEL
// ─────────────────────────────────────────────────────────────────

class UserProfile {
  final String name;
  final F1Team? favTeam;
  final F1Driver? favDriver;

  const UserProfile({
    required this.name,
    this.favTeam,
    this.favDriver,
  });
}

// ─────────────────────────────────────────────────────────────────
//  SEASON OPTION MODEL (for step 3)
// ─────────────────────────────────────────────────────────────────

class _SeasonOption {
  final String season;
  final String title;
  final String subtitle;
  final Color  color;
  final String emoji;
  final bool   hasAsset; // true = bundled JSON exists, false = needs import

  const _SeasonOption({
    required this.season,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.emoji,
    this.hasAsset = false,
  });
}

const _seasonOptions = [
  _SeasonOption(season: '2025', title: '2025 SEASON',
      subtitle: '24 races · Current season',
      color: Color(0xFF39FF14), emoji: '🔥', hasAsset: true),
  _SeasonOption(season: '2024', title: '2024 SEASON',
      subtitle: 'Import your races.json to unlock',
      color: Color(0xFF00E5FF), emoji: '🏆'),
  _SeasonOption(season: '2023', title: '2023 SEASON',
      subtitle: 'Import your races.json to unlock',
      color: Color(0xFFFFE600), emoji: '⚡'),
];

// ─────────────────────────────────────────────────────────────────
//  PROFILE SETUP SCREEN
//  Steps: 0 = name · 1 = team · 2 = season · 3 = driver
// ─────────────────────────────────────────────────────────────────

class ProfileSetupScreen extends StatefulWidget {
  final void Function(UserProfile profile) onFinished;

  const ProfileSetupScreen({super.key, required this.onFinished});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {

  // ── State ─────────────────────────────────────────────────────
  int     _step = 0; // 0=name 1=team 2=season 3=driver
  final   _nameController = TextEditingController();
  String? _nameError;
  String? _selectedTeamId;
  String  _selectedSeason = '2025'; // default
  String? _selectedDriverId;
  bool    _seasonLoading = false;

  // ── Animation ─────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  // ── Colors ────────────────────────────────────────────────────
  static const Color _bg    = Color(0xFF030308);
  static const Color _cyan  = Color(0xFF00E5FF);
  static const Color _white = Colors.white;

  Color get _accentColor {
    if (_step == 2) {
      // use the selected season's color
      return _seasonOptions
          .firstWhere((s) => s.season == _selectedSeason,
          orElse: () => _seasonOptions.first)
          .color;
    }
    if (_selectedTeamId == null) return _cyan;
    return kTeams.firstWhere((t) => t.id == _selectedTeamId).color;
  }

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Step transition ───────────────────────────────────────────
  Future<void> _goToStep(int step) async {
    await _fadeController.reverse();
    if (!mounted) return;
    setState(() => _step = step);
    _fadeController.forward();
  }

  // ── Navigation ────────────────────────────────────────────────
  void _onNext() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _nameError = 'Enter your name to continue');
        return;
      }
      setState(() => _nameError = null);
      _goToStep(1);
    } else if (_step == 1) {
      _goToStep(2);
    } else if (_step == 2) {
      _applySeason();
    } else {
      _saveAndFinish();
    }
  }

  void _onBack() {
    if (_step > 0) _goToStep(_step - 1);
  }

  /// For 2025 (has asset) — load directly and move on.
  /// For 2023/2024 (no asset) — push SeasonImportScreen, wait for result,
  /// then move on only if the user successfully imported data.
  Future<void> _applySeason() async {
    final opt = _seasonOptions.firstWhere((o) => o.season == _selectedSeason);

    if (!opt.hasAsset) {
      // Push import screen — it will save the JSON and pop itself
      final result = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => SeasonImportScreen(
            targetSeason: _selectedSeason,
            onSeasonLoaded: (_) {
              // pop with success flag
              Navigator.of(context).pop(true);
            },
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
      // Only advance if user actually imported data
      if (result != true || !mounted) return;
      _goToStep(3);
      return;
    }

    // 2025 — bundle exists, just switch and continue
    setState(() => _seasonLoading = true);
    try {
      await RaceServiceV2().switchSeason(_selectedSeason);
    } catch (_) { /* non-fatal */ }
    if (!mounted) return;
    setState(() => _seasonLoading = false);
    _goToStep(3);
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('selected_season', _selectedSeason);
    if (_selectedTeamId != null)   await prefs.setString('fav_team',   _selectedTeamId!);
    if (_selectedDriverId != null) await prefs.setString('fav_driver', _selectedDriverId!);
    await prefs.setBool('profile_complete', true);

    final team   = _selectedTeamId   != null
        ? kTeams.firstWhere((t) => t.id == _selectedTeamId)   : null;
    final driver = _selectedDriverId != null
        ? kDrivers.firstWhere((d) => d.id == _selectedDriverId) : null;

    if (!mounted) return;
    widget.onFinished(UserProfile(
      name: _nameController.text.trim(),
      favTeam: team,
      favDriver: driver,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────
  List<F1Driver> get _teamDrivers => _selectedTeamId == null
      ? kDrivers
      : kDrivers.where((d) => d.teamId == _selectedTeamId).toList();

  List<F1Driver> get _otherDrivers => _selectedTeamId == null
      ? []
      : kDrivers.where((d) => d.teamId != _selectedTeamId).toList();

  String get _stepLabel => const [
    'YOUR NAME',
    'PICK YOUR TEAM',
    'PICK YOUR SEASON',
    'PICK YOUR DRIVER',
  ][_step];

  String get _ctaLabel {
    if (_step == 0) return 'NEXT ›';
    if (_step == 1) return _selectedTeamId != null ? 'NEXT ›' : 'SKIP';
    if (_step == 2) return 'CONFIRM SEASON ›';
    return _selectedDriverId != null ? "LET'S RACE ›" : 'SKIP';
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bg,
      body: Stack(
        children: [
          const _ParticleBackground(),
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          ..._corners(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildStepContent(),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Text(
            '◆  STEP ${_step + 1} OF 4  ◆',
            style: GoogleFonts.orbitron(
                fontSize: 10, letterSpacing: 4,
                color: _accentColor.withValues(alpha: _pulseAnim.value)),
          ),
        ),
        const SizedBox(height: 10),
        Text(_stepLabel, style: GoogleFonts.orbitron(
            fontSize: 26, fontWeight: FontWeight.w900,
            color: _white, letterSpacing: 2)),
        const SizedBox(height: 16),
        // Progress dots — now 4
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final active = i == _step;
            final done   = i < _step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 32 : 12, height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: done || active
                    ? _accentColor
                    : _white.withValues(alpha: 0.15),
                boxShadow: active
                    ? [BoxShadow(color: _accentColor.withValues(alpha: 0.6), blurRadius: 6)]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              _accentColor.withValues(alpha: 0.6),
              Colors.transparent,
            ]),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── Footer ────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 1,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              _accentColor.withValues(alpha: 0.3),
              Colors.transparent,
            ]),
          ),
        ),
        GestureDetector(
          onTap: _seasonLoading ? null : _onNext,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              color: _step == 3 ? _accentColor : Colors.transparent,
              border: Border.all(color: _accentColor, width: 1),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3), blurRadius: 16)],
            ),
            child: Center(child: _seasonLoading
                ? SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: _accentColor, strokeWidth: 2))
                : Text(_ctaLabel, style: GoogleFonts.orbitron(
                fontSize: 13, fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: _step == 3 ? Colors.black : _accentColor))),
          ),
        ),
        if (_step > 0) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _onBack,
            child: Text('‹  BACK', style: GoogleFonts.orbitron(
                fontSize: 10, letterSpacing: 3,
                color: _white.withValues(alpha: 0.25))),
          ),
        ],
      ]),
    );
  }

  // ── Step content switcher ─────────────────────────────────────
  Widget _buildStepContent() => switch (_step) {
    0 => _buildNameStep(),
    1 => _buildTeamStep(),
    2 => _buildSeasonStep(),
    3 => _buildDriverStep(),
    _ => const SizedBox.shrink(),
  };

  // ─────────────────────────────────────────────────────────────
  //  STEP 0 — NAME
  // ─────────────────────────────────────────────────────────────

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('What should we call you on the grid?',
            style: GoogleFonts.rajdhani(
                fontSize: 15, color: _white.withValues(alpha: 0.5),
                letterSpacing: 0.5)),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _nameError != null
                    ? const Color(0xFFFF073A)
                    : _nameController.text.isNotEmpty
                    ? _accentColor.withValues(alpha: 0.8)
                    : _white.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(4),
              color: _white.withValues(alpha: 0.03),
              boxShadow: _nameController.text.isNotEmpty
                  ? [BoxShadow(
                  color: _accentColor.withValues(alpha: 0.1),
                  blurRadius: 12)]
                  : null,
            ),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() => _nameError = null),
              onSubmitted: (_) => _onNext(),
              style: GoogleFonts.orbitron(
                  fontSize: 16, color: _white, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: 'e.g. VERSTAPPEN FAN',
                hintStyle: GoogleFonts.orbitron(
                    fontSize: 13, color: _white.withValues(alpha: 0.2),
                    letterSpacing: 2),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
              cursorColor: _accentColor,
            ),
          ),
        ),
        if (_nameError != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF073A), size: 14),
            const SizedBox(width: 6),
            Text(_nameError!, style: GoogleFonts.rajdhani(
                fontSize: 13, color: const Color(0xFFFF073A))),
          ]),
        ],
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _accentColor.withValues(alpha: 0.5), width: 2),
            ),
          ),
          child: Text(
            'Your name will appear on the leaderboard during race simulations.',
            style: GoogleFonts.rajdhani(
                fontSize: 13, color: _white.withValues(alpha: 0.35), height: 1.6),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 1 — TEAM
  // ─────────────────────────────────────────────────────────────

  Widget _buildTeamStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choose your constructor allegiance',
            style: GoogleFonts.rajdhani(
                fontSize: 15, color: _white.withValues(alpha: 0.5))),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 2.8,
            crossAxisSpacing: 10, mainAxisSpacing: 10,
          ),
          itemCount: kTeams.length,
          itemBuilder: (_, i) => _buildTeamCard(kTeams[i]),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildTeamCard(F1Team team) {
    final selected = _selectedTeamId == team.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTeamId   = team.id;
        _selectedDriverId = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? team.color : _white.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(4),
          color: selected
              ? team.color.withValues(alpha: 0.1)
              : _white.withValues(alpha: 0.02),
          boxShadow: selected
              ? [BoxShadow(color: team.color.withValues(alpha: 0.25), blurRadius: 12)]
              : null,
        ),
        child: Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: team.color,
                boxShadow: [BoxShadow(
                    color: team.color.withValues(alpha: 0.6), blurRadius: 6)],
              )),
          const SizedBox(width: 8),
          Expanded(child: Text(team.name, style: GoogleFonts.rajdhani(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? _white : _white.withValues(alpha: 0.6),
              letterSpacing: 0.3),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (selected)
            Text('✓', style: TextStyle(fontSize: 12, color: team.color)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 2 — SEASON PICKER
  // ─────────────────────────────────────────────────────────────

  Widget _buildSeasonStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 4),
        Text('Which F1 calendar do you want to race?',
            style: GoogleFonts.rajdhani(
                fontSize: 15, color: _white.withValues(alpha: 0.5))),
        const SizedBox(height: 20),

        // Built-in season cards
        ...List.generate(_seasonOptions.length, (i) {
          final opt      = _seasonOptions[i];
          final selected = _selectedSeason == opt.season;
          final locked   = !opt.hasAsset;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeason = opt.season),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(
                    color: selected
                        ? opt.color
                        : opt.color.withValues(alpha: locked ? 0.12 : 0.2),
                    width: selected ? 2 : 1),
                borderRadius: BorderRadius.circular(10),
                color: selected
                    ? opt.color.withValues(alpha: 0.08)
                    : _white.withValues(alpha: 0.02),
                boxShadow: selected
                    ? [BoxShadow(color: opt.color.withValues(alpha: 0.2), blurRadius: 16)]
                    : null,
              ),
              child: Row(children: [
                Text(locked ? '🔒' : opt.emoji,
                    style: TextStyle(fontSize: 28,
                        color: locked ? null : null)),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.title, style: GoogleFonts.orbitron(
                        fontSize: 15, fontWeight: FontWeight.w900,
                        color: selected
                            ? opt.color
                            : locked
                            ? _white.withValues(alpha: 0.35)
                            : _white)),
                    const SizedBox(height: 3),
                    Text(opt.subtitle, style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        color: selected
                            ? opt.color.withValues(alpha: 0.75)
                            : locked
                            ? _white.withValues(alpha: 0.25)
                            : _white.withValues(alpha: 0.4))),
                  ],
                )),
                if (selected)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: opt.color.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(6),
                        color: opt.color.withValues(alpha: 0.12),
                      ),
                      child: Text(
                          locked ? 'IMPORT' : 'SELECTED',
                          style: GoogleFonts.orbitron(
                              fontSize: 9, fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: opt.color.withValues(alpha: _pulseAnim.value))),
                    ),
                  )
                else
                  Icon(
                    locked ? Icons.upload_file_rounded : Icons.chevron_right_rounded,
                    color: opt.color.withValues(alpha: locked ? 0.3 : 0.4),
                    size: 22,
                  ),
              ]),
            ),
          );
        }),

        // Divider + hint for custom import
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Divider(color: _white.withValues(alpha: 0.08))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR', style: GoogleFonts.orbitron(
                fontSize: 9, letterSpacing: 2,
                color: _white.withValues(alpha: 0.2))),
          ),
          Expanded(child: Divider(color: _white.withValues(alpha: 0.08))),
        ]),
        const SizedBox(height: 12),

        // Custom import hint — user can do this later from settings too
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(10),
            color: _white.withValues(alpha: 0.02),
          ),
          child: Row(children: [
            Text('📂', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CUSTOM SEASON', style: GoogleFonts.orbitron(
                    fontSize: 11, fontWeight: FontWeight.w900,
                    color: _white.withValues(alpha: 0.4))),
                const SizedBox(height: 3),
                Text('Import your own races.json anytime from Settings',
                    style: GoogleFonts.rajdhani(
                        fontSize: 12, color: _white.withValues(alpha: 0.25))),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 3 — DRIVER
  // ─────────────────────────────────────────────────────────────

  Widget _buildDriverStep() {
    final team = _selectedTeamId != null
        ? kTeams.firstWhere((t) => t.id == _selectedTeamId)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(team != null
            ? '${team.name} drivers shown first'
            : 'Pick your favourite driver',
            style: GoogleFonts.rajdhani(
                fontSize: 15, color: _white.withValues(alpha: 0.5))),
        const SizedBox(height: 12),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ..._teamDrivers.map((d) => _buildDriverTile(d, highlight: true)),
            if (_otherDrivers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Expanded(child: Divider(color: _white.withValues(alpha: 0.08))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OTHER DRIVERS', style: GoogleFonts.orbitron(
                        fontSize: 9, letterSpacing: 2,
                        color: _white.withValues(alpha: 0.2))),
                  ),
                  Expanded(child: Divider(color: _white.withValues(alpha: 0.08))),
                ]),
              ),
              ..._otherDrivers.map((d) => _buildDriverTile(d, highlight: false)),
            ],
          ],
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildDriverTile(F1Driver driver, {required bool highlight}) {
    final selected = _selectedDriverId == driver.id;
    final team     = kTeams.firstWhere((t) => t.id == driver.teamId);
    return GestureDetector(
      onTap: () => setState(() => _selectedDriverId = driver.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? team.color : _white.withValues(alpha: highlight ? 0.1 : 0.05),
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(4),
          color: selected
              ? team.color.withValues(alpha: 0.1)
              : _white.withValues(alpha: highlight ? 0.03 : 0.01),
          boxShadow: selected
              ? [BoxShadow(color: team.color.withValues(alpha: 0.2), blurRadius: 10)]
              : null,
        ),
        child: Row(children: [
          Text(driver.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(driver.name, style: GoogleFonts.rajdhani(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: selected ? _white : _white.withValues(alpha: highlight ? 0.9 : 0.45))),
              Text(team.name, style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  color: selected ? team.color : _white.withValues(alpha: 0.3))),
            ],
          )),
          Text('#${driver.number}', style: GoogleFonts.orbitron(
              fontSize: 14, fontWeight: FontWeight.w900,
              color: team.color.withValues(alpha: selected ? 0.9 : 0.4))),
          if (selected) ...[
            const SizedBox(width: 8),
            Text('✓', style: TextStyle(color: team.color, fontSize: 14)),
          ],
        ]),
      ),
    );
  }

  // ── Corner brackets ───────────────────────────────────────────
  List<Widget> _corners() {
    const double sz  = 22;
    const Color  col = Color(0x6600E5FF);
    return [
      Positioned(top: 16, left: 16,
          child: _CornerBracket(size: sz, color: col, corner: Corner.topLeft)),
      Positioned(top: 16, right: 16,
          child: _CornerBracket(size: sz, color: col, corner: Corner.topRight)),
      Positioned(bottom: 16, left: 16,
          child: _CornerBracket(size: sz, color: col, corner: Corner.bottomLeft)),
      Positioned(bottom: 16, right: 16,
          child: _CornerBracket(size: sz, color: col, corner: Corner.bottomRight)),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────
//  PARTICLE BACKGROUND
// ─────────────────────────────────────────────────────────────────

class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();
  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static final _rng = Random(99);
  static final _particles = List.generate(60, (i) => _Particle(
    x:      _rng.nextDouble(),
    y:      _rng.nextDouble(),
    speed:  0.04 + _rng.nextDouble() * 0.1,
    radius: 0.4  + _rng.nextDouble() * 1.2,
    color: [
      const Color(0xFF00E5FF),
      const Color(0xFFFF00FF),
      const Color(0xFF39FF14),
      const Color(0xFFFFE600),
    ][i % 4].withValues(alpha: 0.35 + _rng.nextDouble() * 0.25),
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      painter: _ParticlePainter(_ctrl.value, _particles),
      size: MediaQuery.of(context).size,
    ),
  );
}

class _Particle {
  final double x, y, speed, radius;
  final Color color;
  const _Particle({
    required this.x, required this.y,
    required this.speed, required this.radius,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  _ParticlePainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = ((p.y - progress * p.speed) % 1.0) * size.height;
      canvas.drawCircle(Offset(p.x * size.width, y), p.radius,
          Paint()..color = p.color);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────
//  SCANLINE PAINTER
// ─────────────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.025);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), paint);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}

// ─────────────────────────────────────────────────────────────────
//  CORNER BRACKET
// ─────────────────────────────────────────────────────────────────

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  final double size;
  final Color  color;
  final Corner corner;
  const _CornerBracket({
    required this.size, required this.color, required this.corner,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _CornerPainter(color: color, corner: corner),
  );
}

class _CornerPainter extends CustomPainter {
  final Color  color;
  final Corner corner;
  _CornerPainter({required this.color, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color ..strokeWidth = 1 ..style = PaintingStyle.stroke;
    final w = size.width; final h = size.height;
    final path = Path();
    switch (corner) {
      case Corner.topLeft:     path.moveTo(w, 0); path.lineTo(0, 0); path.lineTo(0, h);
      case Corner.topRight:    path.moveTo(0, 0); path.lineTo(w, 0); path.lineTo(w, h);
      case Corner.bottomLeft:  path.moveTo(0, 0); path.lineTo(0, h); path.lineTo(w, h);
      case Corner.bottomRight: path.moveTo(w, 0); path.lineTo(w, h); path.lineTo(0, h);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CornerPainter _) => false;}
