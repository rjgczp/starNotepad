import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/scheduler.dart';
import 'begin/lead.dart';
import 'core/theme/theme_provider.dart';
import 'core/db/db_instance.dart';
import 'tools/localData.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalData.init();
  // Initialize database to ensure migration completes
  await DbInstance.db.customSelect('SELECT 1').get();
  await ThemeProvider().loadFromLocal();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeProvider = ThemeProvider();
  bool _themeRebuildQueued = false;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_themeRebuildQueued) return;
      _themeRebuildQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _themeRebuildQueued = false;
        if (!mounted) return;
        setState(() {});
      });
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final seedColor = _themeProvider.primaryColor;

    return ScreenUtilInit(
      //pixel 9的尺寸
      designSize: const Size(1080, 2424),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '星记事',
          theme: _buildTheme(seedColor),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          home: Lead(),
        );
      },
    );
  }

  ThemeData _buildTheme(Color seedColor) {
    // Generate base palette from seed, then override primary with the exact color
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    // Compute a lighter container variant of the exact color
    final primaryContainer = Color.lerp(seedColor, Colors.white, 0.7)!;
    final onPrimaryContainer =
        seedColor.computeLuminance() > 0.4 ? Colors.black87 : seedColor;

    final colorScheme = base.copyWith(
      primary: seedColor,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      inversePrimary: Color.lerp(seedColor, Colors.white, 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
