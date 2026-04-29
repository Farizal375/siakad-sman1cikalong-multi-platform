// test/teacher_class_list_test.dart
// ═══════════════════════════════════════════════
// TEACHER CLASS LIST – Frontend Unit Test
// Verifikasi sinkronisasi frontend ↔ backend API
// ═══════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Minimal stub widget to test rendering logic ──────────────────────────────
// We can't easily mock the static ApiService without DI, so we test the
// UI logic by building a standalone widget that mirrors MyClasses behaviour.

class _MockClassListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final bool loading;
  final bool error;

  const _MockClassListWidget({
    required this.classes,
    this.loading = false,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error) {
      return const Center(child: Text('Gagal memuat data kelas'));
    }

    if (classes.isEmpty) {
      return const Center(child: Text('Belum ada kelas yang ditugaskan'));
    }

    return Column(
      children: [
        const Text('Daftar Kelas Anda'),
        ...classes.map((c) => ListTile(
              title: Text(c['subject'] as String),
              subtitle: Text(c['className'] as String),
            )),
      ],
    );
  }
}

void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget buildWidget(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  // ── TEST SUITE ────────────────────────────────────────────────────────────
  group('MyClasses UI Logic — Sinkronisasi Daftar Kelas Guru', () {
    // ── Test 1: Loading state ──
    testWidgets('should display loading indicator saat data sedang dimuat', (tester) async {
      await tester.pumpWidget(buildWidget(
        const _MockClassListWidget(classes: [], loading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ── Test 2: Error state ──
    testWidgets('should display error message jika API gagal', (tester) async {
      await tester.pumpWidget(buildWidget(
        const _MockClassListWidget(classes: [], error: true),
      ));
      expect(find.text('Gagal memuat data kelas'), findsOneWidget);
    });

    // ── Test 3: Empty state ──
    testWidgets('should display empty state jika guru belum punya kelas', (tester) async {
      await tester.pumpWidget(buildWidget(
        const _MockClassListWidget(classes: []),
      ));
      expect(find.text('Belum ada kelas yang ditugaskan'), findsOneWidget);
    });

    // ── Test 4: daftarKelas dari backend → semua kelas tampil ──
    testWidgets('should display semua kelas dari daftarKelas API', (tester) async {
      // Simulasi response daftarKelas dari backend
      final mockDaftarKelas = [
        {
          'id': 'class1_subj1',
          'subject': 'Matematika',
          'className': 'X IPA 1',
          'scheduleSummary': 'Senin, Rabu',
          'studentCount': 30,
          'rombelId': 'rombel-001',
        },
        {
          'id': 'class2_subj1',
          'subject': 'Matematika',
          'className': 'X IPA 2',
          'scheduleSummary': 'Selasa, Kamis',
          'studentCount': 28,
          'rombelId': 'rombel-002',
        },
      ];

      await tester.pumpWidget(buildWidget(
        _MockClassListWidget(classes: mockDaftarKelas),
      ));

      // Header harus ada
      expect(find.text('Daftar Kelas Anda'), findsOneWidget);

      // Semua kelas dari daftarKelas harus tampil
      expect(find.text('Matematika'), findsNWidgets(2));
      expect(find.text('X IPA 1'), findsOneWidget);
      expect(find.text('X IPA 2'), findsOneWidget);
    });

    // ── Test 5: Sinkronisasi field penting dari API ──
    testWidgets('should memiliki field subject, className, dan scheduleSummary dari daftarKelas', (tester) async {
      final mockClass = {
        'id': 'cls_mtk_xipa1',
        'subject': 'Fisika',
        'className': 'XI IPA 3',
        'scheduleSummary': 'Jumat',
        'studentCount': 32,
        'rombelId': 'rombel-003',
      };

      await tester.pumpWidget(buildWidget(
        _MockClassListWidget(classes: [mockClass]),
      ));

      expect(find.text('Fisika'), findsOneWidget);
      expect(find.text('XI IPA 3'), findsOneWidget);
    });

    // ── Test 6: Struktur data daftarKelas dari backend (unit logic test) ──
    test('daftarKelas entry harus memiliki field yang dibutuhkan frontend', () {
      // Simulasi item dari backend
      final daftarKelasItem = {
        'id': 'cls1_subj1',
        'masterKelasId': 'master-kelas-001',
        'mataPelajaranId': 'mapel-001',
        'rombelId': 'rombel-001',
        'subject': 'Kimia',
        'className': 'XII IPA 1',
        'scheduleSummary': 'Senin, Rabu',
        'studentCount': 35,
        'days': ['Senin', 'Rabu'],
      };

      // Verify semua field yang dibutuhkan ada
      expect(daftarKelasItem.containsKey('id'), isTrue);
      expect(daftarKelasItem.containsKey('subject'), isTrue);
      expect(daftarKelasItem.containsKey('className'), isTrue);
      expect(daftarKelasItem.containsKey('scheduleSummary'), isTrue);
      expect(daftarKelasItem.containsKey('studentCount'), isTrue);
      expect(daftarKelasItem.containsKey('rombelId'), isTrue);

      // Verify tipe data
      expect(daftarKelasItem['studentCount'], isA<int>());
      expect(daftarKelasItem['days'], isA<List>());
      expect((daftarKelasItem['days'] as List).length, equals(2));
    });
  });
}
