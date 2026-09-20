import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tennis_manager/app.dart';
import 'package:tennis_manager/data/database/database_helper.dart';
import 'package:tennis_manager/presentation/onboarding/onboarding_screen.dart';

void main() {
  late Directory directory;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    directory = await Directory.systemTemp.createTemp('tennis-onboarding-');
    await databaseFactory.setDatabasesPath(directory.path);
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    await db.execute('DROP TRIGGER IF EXISTS fail_session_insert');
    for (final table in ['sessions', 'payments', 'packages', 'player']) {
      await db.delete(table);
    }
  });

  tearDownAll(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  testWidgets('finishing setup reaches home with all scheduled sessions',
      (tester) async {
    await _fillSetup(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'شروع کنید'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect((await db.query('player')).single['onboarding_complete'], 1);
    final package = (await db.query('packages')).single;
    final sessions = await db.query('sessions');
    expect(package['price'], 800000);
    expect(sessions, hasLength(8));
    expect(sessions.every((s) => s['package_id'] == package['id']), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed setup keeps the form retryable without partial records',
      (tester) async {
    await db.execute('''
      CREATE TRIGGER fail_session_insert BEFORE INSERT ON sessions
      WHEN (SELECT COUNT(*) FROM sessions) = 3
      BEGIN SELECT RAISE(ABORT, 'test write failure'); END
    ''');
    await _fillSetup(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'شروع کنید'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    final button = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'شروع کنید'));
    expect(button.onPressed, isNotNull);
    expect(await db.query('player'), isEmpty);
    expect(await db.query('packages'), isEmpty);
    expect(await db.query('sessions'), isEmpty);

    await tester.drag(find.byType(SnackBar), const Offset(0, 100));
    await tester.pumpAndSettle();
    await db.execute('DROP TRIGGER fail_session_insert');
    await tester.tap(find.widgetWithText(FilledButton, 'شروع کنید'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(await db.query('packages'), hasLength(1));
    expect(await db.query('sessions'), hasLength(8));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _fillSetup(WidgetTester tester) async {
  tester.view.physicalSize = const Size(480, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const TennisApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('شروع کنید'));
  await tester.pumpAndSettle();
  await tester.enterText(_field('نام شما *'), 'بازیکن آزمایشی');
  await _next(tester);
  await tester.enterText(_field('نام مربی *'), 'مربی آزمایشی');
  await _next(tester);
  await tester.tap(find.text('روزهای زوج'));
  await _next(tester);
  await tester.enterText(_field('مبلغ را وارد کنید'), '800000');
  await _next(tester);
}

Finder _field(String hint) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint);

Future<void> _next(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'بعدی'));
  await tester.pumpAndSettle();
}
