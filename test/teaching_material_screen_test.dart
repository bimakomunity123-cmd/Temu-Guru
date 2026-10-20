import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ruangguru/features/teaching_material/presentation/teacher_materials_screen.dart';

void main() {
  testWidgets('TeacherMaterialsScreen builds and renders without layout errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TeacherMaterialsScreen(),
        ),
      ),
    );

    // Initial pump (isLoading is true)
    await tester.pump();

    // Settle async loadInitialData
    await tester.pumpAndSettle();

    expect(find.text('Bahan Ajar Guru'), findsOneWidget);
  });
}
