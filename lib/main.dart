import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_faceapp/utils/colors.dart';
import 'package:my_faceapp/view/home_page.dart';


    void main() {
        WidgetsFlutterBinding.ensureInitialized();
        // Tam ekran yap - saati tamamen gizle
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        runApp(const MyApp());
    }

    class MyApp extends StatelessWidget {
        const MyApp({Key? key}) : super(key: key);

        @override
        Widget build(BuildContext context) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Flutter Intro Screen',
                // 🎯 Localization desteği ekledik
                localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                    Locale('tr', 'TR'), // Türkçe
                    Locale('en', 'US'), // İngilizce
                ],
                locale: const Locale('tr', 'TR'), // Varsayılan dil
                builder: (context, child) {
                    // Tam ekran ayarları - saati tamamen gizle
                    SystemChrome.setSystemUIOverlayStyle(
                        const SystemUiOverlayStyle(
                            statusBarColor: Colors.transparent,
                            statusBarIconBrightness: Brightness.light,
                            systemNavigationBarColor: Colors.transparent,
                            systemNavigationBarDividerColor: Colors.transparent,
                            systemNavigationBarIconBrightness: Brightness.light,
                        ),
                    );
                    return child!;
                },
                theme: ThemeData(
                    textTheme: const TextTheme(
                        displayLarge: TextStyle(
                            fontSize: 30,
                            color: MyColors.titleTextColor,
                            fontWeight: FontWeight.bold,
                        ),
                        displayMedium: TextStyle(
                            fontSize: 18,
                            color: MyColors.subTitleTextColor,
                            fontWeight: FontWeight.w400,
                            wordSpacing: 1.2,
                            height: 1.2),
                        displaySmall: TextStyle(
                            fontSize: 18,
                            color: MyColors.titleTextColor,
                            fontWeight: FontWeight.bold,
                        ),
                        headlineMedium: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                        ),
                    )),
                home: HomePage(),
            );
        }
    }