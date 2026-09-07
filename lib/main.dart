import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants/app_colors.dart';
import 'screens/guruji_login_screen.dart';
import 'screens/home_screen.dart';
import 'services/admin_data_service.dart';
import 'services/guruji_auth_service.dart';
import 'services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GurujiAuthService.init();
  await LocaleService.init();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (_, locale, __) => _buildApp(locale),
    );
  }

  Widget _buildApp(Locale locale) {
    return MaterialApp(
      // Remounts the whole app on a language switch so every screen picks
      // up the new tr() results immediately, without needing each widget to
      // listen for locale changes itself.
      key: ValueKey(locale),
      title: 'Trimbakeshwar Guruji',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdminColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AdminColors.grey100,
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
      home: ValueListenableBuilder<bool>(
        valueListenable: GurujiAuthService.isLoggedIn,
        builder: (_, loggedIn, __) {
          if (loggedIn) {
            AdminDataService.init();
            return const HomeScreen();
          }
          AdminDataService.dispose();
          return const GurujiLoginScreen();
        },
      ),
    );
  }
}
