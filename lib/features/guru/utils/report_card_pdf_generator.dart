// File: lib/features/guru/utils/report_card_pdf_generator.dart
// ===========================================
// REPORT CARD PDF GENERATOR
// ===========================================

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportCardPdfGenerator {
  /// Generates a PDF containing report cards for the given list of student IDs.
  /// If [digitalSignature] is true, adds placeholder signatures.
  static Future<Uint8List> generateBulkReportCards({
    required List<Map<String, dynamic>> students,
    required String semester,
    required bool digitalSignature,
  }) async {
    final pdf = pw.Document();

    for (final student in students) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return [
              _buildHeader(student, semester),
              pw.SizedBox(height: 20),
              _buildGradesTable(),
              pw.SizedBox(height: 20),
              _buildExtracurricularTable(),
              pw.SizedBox(height: 20),
              _buildAttendanceTable(),
              pw.SizedBox(height: 30),
              _buildSignatures(digitalSignature),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildHeader(Map<String, dynamic> student, String semester) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'LAPORAN HASIL BELAJAR PESERTA DIDIK',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeaderRow('Nama Sekolah', 'SMA Negeri 1 Cikalong'),
                _buildHeaderRow('Alamat', 'Jl. Raya Cikalong No. 1'),
                _buildHeaderRow('Nama Peserta Didik', student['name'] ?? '-'),
                _buildHeaderRow('Nomor Induk/NISN', student['nisn'] ?? '-'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeaderRow('Kelas', 'XI-1'),
                _buildHeaderRow('Semester', semester),
                _buildHeaderRow('Tahun Pelajaran', '2026/2027'),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildHeaderRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
          pw.Text(':', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildGradesTable() {
    final headers = ['No', 'Mata Pelajaran', 'KKM', 'Nilai Angka', 'Predikat', 'Deskripsi'];
    
    // Mock grades aligned with what was built in ClassDetail/Hasil Studi
    final grades = [
      ['1', 'Pendidikan Agama dan Budi Pekerti', '75', '85', 'B', 'Baik dalam penguasaan materi...'],
      ['2', 'Pendidikan Pancasila dan Kewarganegaraan', '75', '88', 'B', 'Memiliki pemahaman yang baik...'],
      ['3', 'Bahasa Indonesia', '75', '82', 'B', 'Mampu mengekspresikan gagasan...'],
      ['4', 'Matematika (Umum)', '75', '90', 'A', 'Sangat baik dalam pemecahan masalah...'],
      ['5', 'Sejarah Indonesia', '75', '84', 'B', 'Baik dalam mengingat kronologi...'],
      ['6', 'Bahasa Inggris', '75', '86', 'B', 'Mampu berkomunikasi dengan baik...'],
      ['7', 'Seni Budaya', '75', '89', 'B', 'Kreatif dan inovatif...'],
      ['8', 'Pendidikan Jasmani, Olahraga, dan Kesehatan', '75', '92', 'A', 'Sangat terampil...'],
      ['9', 'Prakarya dan Kewirausahaan', '75', '85', 'B', 'Mampu menghasilkan karya...'],
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: grades,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(50),
        5: const pw.FlexColumnWidth(3),
      },
    );
  }

  static pw.Widget _buildExtracurricularTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Kegiatan Ekstrakurikuler', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['No', 'Kegiatan Ekstrakurikuler', 'Keterangan'],
          data: [
            ['1', 'Pramuka', 'Sangat Baik'],
            ['2', 'PMR', 'Baik'],
          ],
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: const pw.TextStyle(fontSize: 10),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
          },
        ),
      ],
    );
  }

  static pw.Widget _buildAttendanceTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ketidakhadiran', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Alasan', 'Jumlah Hari'],
          data: [
            ['Sakit', '2 hari'],
            ['Izin', '0 hari'],
            ['Tanpa Keterangan', '0 hari'],
          ],
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellStyle: const pw.TextStyle(fontSize: 10),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
          },
        ),
      ],
    );
  }

  static pw.Widget _buildSignatures(bool digital) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Orang Tua/Wali', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 60),
            pw.Text('.............................', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Cikalong, 18 Desember 2026', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Wali Kelas', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            if (digital)
              pw.Container(
                height: 40,
                child: pw.Text('*** DIGITAL SIGNATURE ***', style: const pw.TextStyle(color: PdfColors.blue, fontSize: 9)),
              )
            else
              pw.SizedBox(height: 40),
            pw.SizedBox(height: 10),
            pw.Text('Siti Aminah, M.Pd.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text('NIP. 198001012005012000', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
