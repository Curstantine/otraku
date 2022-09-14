import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otraku/home/home_provider.dart';
import 'package:otraku/utils/background_handler.dart';
import 'package:otraku/utils/route_arg.dart';
import 'package:otraku/utils/settings.dart';
import 'package:otraku/utils/theming.dart';

Future<void> main() async {
  await Settings.init();
  BackgroundHandler.init();
  runApp(const ProviderScope(child: App()));
}

class App extends StatefulWidget {
  const App();

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    Settings().addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    Settings().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer(
        builder: (context, ref, _) => DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            ColorScheme lightScheme;
            ColorScheme darkScheme;
            var theme = Settings().theme;

            /// The system schemes must be cached, so
            /// they can later be used in the settings.
            final notifier = ref.watch(homeProvider.notifier);
            final hasDynamic = lightDynamic != null && darkDynamic != null;

            final darkBackground =
                Settings().pureBlackDarkTheme ? Colors.black : null;

            if (hasDynamic) {
              lightDynamic = lightDynamic.harmonized();
              darkDynamic = darkDynamic.harmonized().copyWith(
                    background: darkBackground,
                  );
              notifier.setSystemSchemes(lightDynamic, darkDynamic);
            } else {
              notifier.setSystemSchemes(null, null);
            }

            if (theme == null && hasDynamic) {
              lightScheme = lightDynamic!;
              darkScheme = darkDynamic!;
            } else {
              theme ??= 0;
              if (theme >= ColorSeed.values.length) {
                theme = ColorSeed.values.length - 1;
              }

              final seed = ColorSeed.values.elementAt(theme);
              lightScheme = seed.scheme(Brightness.light);
              darkScheme = seed
                  .scheme(Brightness.dark)
                  .copyWith(background: darkBackground);
            }

            final mode = Settings().themeMode;
            final platform =
                SchedulerBinding.instance.window.platformBrightness;
            final isDark = mode == ThemeMode.system
                ? platform == Brightness.dark
                : mode == ThemeMode.dark;

            final ColorScheme scheme;
            final Brightness overlayBrightness;
            if (isDark) {
              scheme = darkScheme;
              overlayBrightness = Brightness.light;
            } else {
              scheme = lightScheme;
              overlayBrightness = Brightness.dark;
            }

            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: scheme.background,
              statusBarBrightness: scheme.brightness,
              statusBarIconBrightness: overlayBrightness,
              systemNavigationBarColor: scheme.background,
              systemNavigationBarIconBrightness: overlayBrightness,
            ));
            final data = themeDataFrom(scheme);

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Otraku',
              theme: data,
              darkTheme: data,
              navigatorKey: RouteArg.navKey,
              onGenerateRoute: RouteArg.generateRoute,
              builder: (context, child) {
                /// Override the [textScaleFactor], because some devices apply
                /// too high of a factor and it breaks the app visually.
                /// [child] can't be null, because [onGenerateRoute] is provided.
                final mediaQuery = MediaQuery.of(context);
                final scale =
                    mediaQuery.textScaleFactor.clamp(0.8, 1).toDouble();

                return MediaQuery(
                  data: mediaQuery.copyWith(textScaleFactor: scale),
                  child: child!,
                );
              },
            );
          },
        ),
      );
}
