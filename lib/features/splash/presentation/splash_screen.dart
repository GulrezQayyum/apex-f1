import 'dart:math';
import 'package:flutter/material.dart';


class SplashScreen extends StatefulWidget {
  /// Called when splash finishes — push ProfileScreen or HomeScreen here
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animation Controllers ───────────────────
  late AnimationController _logoController;
  late AnimationController _lineController;
  late AnimationController _taglineController;
  late AnimationController _loadBarController;
  late AnimationController _pulseController;
  late AnimationController _speedLinesController;
  late AnimationController _particleController;

  // ── Animations ──────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _lineWidth;
  late Animation<double> _taglineOpacity;
  late Animation<double> _loadBarProgress;
  late Animation<double> _pulse;

  // ── Neon Colors ─────────────────────────────
  static const Color _cyan    = Color(0xFF00E5FF);
  static const Color _magenta = Color(0xFFFF00FF);
  static const Color _green   = Color(0xFF39FF14);
  static const Color _yellow  = Color(0xFFFFE600);
  static const Color _red     = Color(0xFFFF073A);
  static const Color _bg      = Color(0xFF030308);

  // ── Speed Lines ─────────────────────────────
  final List<_SpeedLine> _speedLines = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _buildSpeedLines();
    _setupAnimations();
    _startSequence();
  }

  void _buildSpeedLines() {
    final colors = [_cyan, _magenta, _green, _yellow, _red];
    for (int i = 0; i < 16; i++) {
      _speedLines.add(_SpeedLine(
        y: _rng.nextDouble(),
        speed: 0.4 + _rng.nextDouble() * 0.6,
        length: 0.06 + _rng.nextDouble() * 0.14,
        color: colors[i % colors.length].withOpacity(0.35 + _rng.nextDouble() * 0.3),
        width: 0.5 + _rng.nextDouble() * 1.0,
      ));
    }
  }

  void _setupAnimations() {
    // Speed lines — continuous loop
    _speedLinesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Particles — continuous loop
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Logo scale + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // Horizontal neon line under logo
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineController, curve: Curves.easeOut),
    );

    // Tagline fade
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    // Loading bar
    _loadBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadBarProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadBarController, curve: Curves.easeInOut),
    );

    // Glow pulse — continuous
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _lineController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();
    _loadBarController.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _lineController.dispose();
    _taglineController.dispose();
    _loadBarController.dispose();
    _pulseController.dispose();
    _speedLinesController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Particle field ──────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleController.value),
              size: size,
            ),
          ),

          // ── Speed lines ─────────────────────────
          AnimatedBuilder(
            animation: _speedLinesController,
            builder: (_, __) => CustomPaint(
              painter: _SpeedLinePainter(_speedLines, _speedLinesController.value),
              size: size,
            ),
          ),

          // ── Scanlines ───────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _ScanlinePainter()),
          ),

          // ── Corner brackets ─────────────────────
          ..._buildCornerBrackets(size),

          // ── Center content ──────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _buildLogo(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Neon divider line
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (_, __) => SizedBox(
                    width: 280,
                    height: 2,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _lineWidth.value,
                        child: Container(
                          height: 2,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent, _cyan, _magenta, Colors.transparent,
                            ]),
                            boxShadow: [BoxShadow(color: _cyan, blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tagline
                AnimatedBuilder(
                  animation: _taglineController,
                  builder: (_, __) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: Text(
                      'FEEL THE SPEED  ·  LIVE THE RACE',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 3.5,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading bar
                AnimatedBuilder(
                  animation: _loadBarController,
                  builder: (_, __) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: _buildLoadingBar(_loadBarProgress.value),
                  ),
                ),
              ],
            ),
          ),

          // ── Skip button ─────────────────────────
          Positioned(
            bottom: 32,
            right: 24,
            child: GestureDetector(
              onTap: widget.onFinished,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'SKIP ›',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo widget ──────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, _cyan, _magenta],
              stops: [0.0, 0.45, 1.0],
            ).createShader(bounds),
            child: Text(
              'APEX',
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                fontSize: 80,
                height: 0.9,
                letterSpacing: -1,
                color: Colors.white,
                shadows: [
                  Shadow(color: _cyan.withOpacity(0.6 * _pulse.value), blurRadius: 30),
                  Shadow(color: _magenta.withOpacity(0.4 * _pulse.value), blurRadius: 50),
                ],
              ),
            ),
          ),
          Text(
            'F1',
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 14,
              color: _magenta,
              shadows: [
                Shadow(color: _magenta.withOpacity(_pulse.value), blurRadius: 20),
                Shadow(color: _magenta.withOpacity(0.5 * _pulse.value), blurRadius: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading bar ──────────────────────────────
  Widget _buildLoadingBar(double progress) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 2,
              child: Stack(
                children: [
                  Container(color: Colors.white.withOpacity(0.06)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [_cyan, _magenta]),
                        boxShadow: [BoxShadow(color: _cyan, blurRadius: 6)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'INITIALIZING SYSTEMS...',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 9,
              letterSpacing: 2,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Corner bracket decorations ───────────────
  List<Widget> _buildCornerBrackets(Size size) {
    const double sz = 28;
    const Color col = Color(0x8800E5FF);
    const double thickness = 1;

    return [
      // Top-left
      Positioned(top: 20, left: 20, child: _CornerBracket(size: sz, color: col, thickness: thickness, corner: Corner.topLeft)),
      // Top-right
      Positioned(top: 20, right: 20, child: _CornerBracket(size: sz, color: col, thickness: thickness, corner: Corner.topRight)),
      // Bottom-left
      Positioned(bottom: 20, left: 20, child: _CornerBracket(size: sz, color: col, thickness: thickness, corner: Corner.bottomLeft)),
      // Bottom-right
      Positioned(bottom: 20, right: 20, child: _CornerBracket(size: sz, color: col, thickness: thickness, corner: Corner.bottomRight)),
    ];
  }
}

// ══════════════════════════════════════════════
//  Corner Bracket Widget
// ══════════════════════════════════════════════
enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  final double size;
  final Color color;
  final double thickness;
  final Corner corner;

  const _CornerBracket({
    required this.size,
    required this.color,
    required this.thickness,
    required this.corner,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerBracketPainter(color: color, thickness: thickness, corner: corner),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final Corner corner;

  _CornerBracketPainter({required this.color, required this.thickness, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke;
    final w = size.width; final h = size.height;
    final path = Path();

    switch (corner) {
      case Corner.topLeft:
        path.moveTo(w, 0); path.lineTo(0, 0); path.lineTo(0, h);
      case Corner.topRight:
        path.moveTo(0, 0); path.lineTo(w, 0); path.lineTo(w, h);
      case Corner.bottomLeft:
        path.moveTo(0, 0); path.lineTo(0, h); path.lineTo(w, h);
      case Corner.bottomRight:
        path.moveTo(w, 0); path.lineTo(w, h); path.lineTo(0, h);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) => false;
}

// ══════════════════════════════════════════════
//  Speed Line Model
// ══════════════════════════════════════════════
class _SpeedLine {
  final double y;       // 0..1 relative vertical position
  final double speed;   // relative speed multiplier
  final double length;  // 0..1 relative length
  final Color color;
  final double width;

  const _SpeedLine({
    required this.y,
    required this.speed,
    required this.length,
    required this.color,
    required this.width,
  });
}

// ══════════════════════════════════════════════
//  Speed Lines Painter
// ══════════════════════════════════════════════
class _SpeedLinePainter extends CustomPainter {
  final List<_SpeedLine> lines;
  final double progress; // 0..1 looping

  _SpeedLinePainter(this.lines, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      // Each line moves at different speed, offset by y for variation
      final offset = (progress * line.speed + line.y * 0.7) % 1.2;
      final x = (offset - line.length) * (size.width + size.width * line.length);
      final y = line.y * size.height;

      canvas.drawLine(Offset(x, y), Offset(x + line.length * size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_SpeedLinePainter old) => old.progress != progress;
}

// ══════════════════════════════════════════════
//  Particle Painter
// ══════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final Random _rng = Random(42); // fixed seed for stable particles
  static final List<_Particle> _particles = List.generate(
    80,
        (i) => _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      speed: 0.05 + _rng.nextDouble() * 0.15,
      radius: 0.5 + _rng.nextDouble() * 1.5,
      color: [
        const Color(0xFF00E5FF),
        const Color(0xFFFF00FF),
        const Color(0xFF39FF14),
        const Color(0xFFFFE600),
        const Color(0xFFFF3E3E),
      ][i % 5].withOpacity(0.4 + _rng.nextDouble() * 0.3),
    ),
  );

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.y - progress * p.speed) % 1.0) * size.height;
      final x = p.x * size.width;
      final paint = Paint()..color = p.color;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, speed, radius;
  final Color color;
  const _Particle({required this.x, required this.y, required this.speed, required this.radius, required this.color});
}

// ══════════════════════════════════════════════
//  Scanline Painter
// ══════════════════════════════════════════════
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}