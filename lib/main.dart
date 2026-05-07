import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apex_f1/features/splash/presentation/splash_screen.dart';
import 'package:apex_f1/features/onboarding/presentation/profile_setup_screen.dart';
import 'package:apex_f1/features/home/presentation/home_screen.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/presentation/calendar_screen.dart';
import 'package:apex_f1/features/races/presentation/race_detail_screen.dart';
import 'package:apex_f1/features/races/presentation/season_import_screen.dart'; // FIX: added
import 'package:apex_f1/features/simulation/presentation/race_sim_screen.dart';
import 'package:apex_f1/features/simulation/presentation/qualifying_screen.dart';
import 'package:apex_f1/features/standings/presentation/standings_screen.dart';
import 'package:apex_f1/features/drivers/presentation/drivers_screen.dart';
import 'package:apex_f1/features/teams/presentation/teams_screen.dart';
import 'package:apex_f1/features/championship/presentation/championship_screen.dart';
import 'package:apex_f1/core/utils/responsive_helper.dart';


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
    return ResponsiveBuilder(
      child: MaterialApp(
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
      ),
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

  void _onSplashFinished() => setState(() => _screen = 'profile');
  void _onProfileFinished(UserProfile p) =>
      setState(() {
        _profile = p;
        _screen = 'home';
      });

  void _onNavigate(String route) {
    switch (route) {
      case 'calendar':
      case 'sim':
        _push(CalendarScreen(onRaceTapped: _openRaceDetail));
        break;
      case 'standings':
        _push(const StandingsScreen());
        break;
      case 'drivers':
        _push(const DriversScreen());
        break;
      case 'teams':
        _push(const TeamsScreen());
        break;
      case 'championship':
        _push(const ChampionshipScreen());
        break;
    // FIX: added season import route — triggered from home screen settings
      case 'season_import':
        _push(const SeasonImportScreen());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF0A0A14),
          content: Text(
            'COMING SOON: ${route.toUpperCase()}',
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 11,
              color: Color(0xFF00E5FF),
              letterSpacing: 2,
            ),
          ),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  void _openRaceDetail(RaceModel race) {
    _push(RaceDetailScreen(
      race: race,
      onStartSim: () => _openRaceSim(race),
      onStartQualifying: () => _openQualifying(race),
    ));
  }

  void _openQualifying(RaceModel race) {
    final driver = _profile!.favDriver;
    final team = _profile!.favTeam;
    _push(QualifyingScreen(
      race: race,
      playerDriverId: driver?.id ?? 'player',
      playerDriverName: driver?.name ?? _profile!.name,
      playerTeamName: team?.name ?? 'Independent',
      playerFlag: driver?.flag ?? '🏳️',
    ));
  }

  void _openRaceSim(RaceModel race) {
    final driver = _profile!.favDriver;
    final team = _profile!.favTeam;
    _push(RaceSimScreen(
      race: race,
      playerDriverId: driver?.id ?? 'player',
      playerDriverName: driver?.name ?? _profile!.name,
      playerTeamName: team?.name ?? 'Independent',
      playerFlag: driver?.flag ?? '🏳️',
    ));
  }

  void _push(Widget screen) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => screen,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      'splash' => SplashScreen(onFinished: _onSplashFinished),
      'profile' => ProfileSetupScreen(onFinished: _onProfileFinished),
      'home' => HomeScreen(profile: _profile!, onNavigate: _onNavigate),
      _ => const SizedBox.shrink(),
    };
  }
}