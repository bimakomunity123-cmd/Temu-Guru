import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ruangguru/app/app.dart';
import 'package:flutter_ruangguru/core/constants/app_constants.dart';

void main() {
  testWidgets('App launches and renders Splash screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: TemuGuruApp(),
      ),
    );

    // Initial frame shows the splash branding
    expect(find.text(AppConstants.appName), findsOneWidget);

    // Pump past the splash screen timer and animations
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verifies it transitions to Welcome screen
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
    expect(find.text('Daftar sebagai Siswa'), findsOneWidget);
    expect(find.text('Daftar sebagai Guru'), findsOneWidget);
  });

  testWidgets('Navigate to Student Registration screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: TemuGuruApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Tap Daftar sebagai Siswa
    await tester.tap(find.text('Daftar sebagai Siswa'));
    await tester.pumpAndSettle();

    // Verify Student Registration Screen is rendered with form fields
    expect(find.text('Registrasi Siswa Baru'), findsOneWidget);
    expect(find.text('Nama Lengkap Siswa *'), findsOneWidget);
    expect(find.text('Tanggal Lahir & Usia *'), findsOneWidget);
    expect(find.text('Area Lokasi Les yang Diinginkan *'), findsOneWidget);
  });

  testWidgets('Navigate to Teacher Registration screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: TemuGuruApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Tap Daftar sebagai Guru
    await tester.tap(find.text('Daftar sebagai Guru'));
    await tester.pumpAndSettle();

    // Verify Teacher Registration Screen is rendered with form fields
    expect(find.text('Registrasi Guru Baru'), findsOneWidget);
    expect(find.text('Nomor Induk Kependudukan (NIK) *'), findsOneWidget);
    expect(find.text('Tanggal Lahir & Usia (Maks. 35 Tahun) *'), findsOneWidget);
    expect(find.text('Upload Dokumen PDF Hasil Tes Bahasa Inggris *'), findsOneWidget);
  });
}
