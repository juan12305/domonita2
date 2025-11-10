import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domotica_app/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations renders Spanish title by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context).t('app_title'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Domótica App'), findsOneWidget);
  });
}
