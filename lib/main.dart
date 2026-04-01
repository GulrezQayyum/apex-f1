import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apex_f1/features/splash/presentation/splash_screen.dart';
import 'package:apex_f1/features/onboarding/presentation/profile_setup_screen.dart';
import 'package:apex_f1/features/home/presentation/home_screen.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/presentation/calendar_screen.dart';
import 'package:apex_f1/features/races/presentation/race_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ApexF1App());
}

class ApexF1App extends StatelessWidget {
  const ApexF1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APEX F1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF030308),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF00FF),
          surface: Color(0xFF0A0A14),
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  String _screen = 'splash';
  UserProfile? _profile;

  void _onSplashFinished() =>
      setState(() => _screen = 'profile');

  void _onProfileFinished(UserProfile p) =>
      setState(() { _profile = p; _screen = 'home'; });

  void _onNavigate(String route) {
    if (route == 'calendar') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CalendarScreen(
            onRaceTapped: (race) => _openRaceDetail(race),
          ),
        ),
      );
      return;
    }

    // Other routes — coming in Phase 3 & 4
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0A0A14),
        content: Text(
          'NAVIGATING TO: ${route.toUpperCase()} — Coming soon',
          style: const TextStyle(
            fontFamily: 'Courier', fontSize: 11,
            color: Color(0xFF00E5FF), letterSpacing: 2,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openRaceDetail(RaceModel race) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RaceDetailScreen(
          race: race,
          onStartSim: () {
            // TODO: push RaceSimScreen in Phase 3
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF0A0A14),
                content: Text(
                  '🏁  RACE SIM FOR ${race.name.toUpperCase()} — Coming in Phase 3!',
                  style: const TextStyle(
                    fontFamily: 'Courier', fontSize: 11,
                    color: Color(0xFF39FF14), letterSpacing: 1,
                  ),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      'splash'  => SplashScreen(onFinished: _onSplashFinished),
      'profile' => ProfileSetupScreen(onFinished: _onProfileFinished),
      'home'    => HomeScreen(profile: _profile!, onNavigate: _onNavigate),
      _         => const SizedBox.shrink(),
    };
  }
}