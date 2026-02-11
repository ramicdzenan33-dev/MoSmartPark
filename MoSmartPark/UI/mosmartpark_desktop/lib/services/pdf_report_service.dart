import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:mosmartpark_desktop/model/business_report.dart';
import 'package:mosmartpark_desktop/model/reservation.dart';

class PdfReportService {
  static final _currencyFormat =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _numberFormat = NumberFormat('#,##0');
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _dateOnlyFormat = DateFormat('yyyy-MM-dd');

  static const PdfColor _brown = PdfColor.fromInt(0xFF8B6F47);
  static const PdfColor _darkText = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _greyText = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _greenAccent = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _blueAccent = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _orangeAccent = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor _purpleAccent = PdfColor.fromInt(0xFF8B5CF6);
  static const PdfColor _tableHeaderBg = PdfColor.fromInt(0xFF8B6F47);
  static const PdfColor _tableAltRow = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFE5E7EB);

  // ──────────────────────────────────────────────────────────────────
  // REPORT 1: Business Analytics PDF
  // ──────────────────────────────────────────────────────────────────
  static Future<void> generateBusinessReport(BusinessReport report) async {
    final pdf = pw.Document(
      title: 'MoSmartPark Business Analytics Report',
      author: 'MoSmartPark',
    );

    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          'Business Analytics Report',
          'Generated on ${_dateFormat.format(now)}',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildKpiSection(report),
          pw.SizedBox(height: 20),
          _buildRevenueByTypeSection(report),
          pw.SizedBox(height: 20),
          _buildReservationsByTypeSection(report),
          pw.SizedBox(height: 20),
          _buildRevenueByZoneSection(report),
          pw.SizedBox(height: 20),
          _buildPopularZonesSection(report),
          pw.SizedBox(height: 20),
          _buildRecentReservationsSection(report),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'MoSmartPark_Business_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }

  static pw.Widget _buildKpiSection(BusinessReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Key Performance Indicators'),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _kpiCard('Total Revenue', _currencyFormat.format(report.totalRevenue), _greenAccent),
            pw.SizedBox(width: 10),
            _kpiCard('Total Reservations', _numberFormat.format(report.totalReservations), _blueAccent),
            pw.SizedBox(width: 10),
            _kpiCard('Active Users', _numberFormat.format(report.activeUsers), _orangeAccent),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _kpiCard('Active / Total Spots', '${report.activeParkingSpots} / ${report.totalParkingSpots}', _purpleAccent),
            pw.SizedBox(width: 10),
            _kpiCard('Avg. Price', _currencyFormat.format(report.averageReservationPrice), _brown),
            pw.SizedBox(width: 10),
            _kpiCard(
              'Utilization Rate',
              report.totalParkingSpots > 0
                  ? '${(report.activeParkingSpots / report.totalParkingSpots * 100).toStringAsFixed(1)}%'
                  : 'N/A',
              _blueAccent,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Expanded _kpiCard(String label, String value, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, color: _greyText),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildRevenueByTypeSection(BusinessReport report) {
    if (report.revenueByReservationType.isEmpty) return pw.SizedBox();

    final totalRevenue = report.revenueByReservationType
        .fold<double>(0, (sum, item) => sum + item.revenue);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Revenue by Reservation Type'),
        pw.SizedBox(height: 8),
        _dataTable(
          headers: ['Reservation Type', 'Revenue', 'Count', '% of Total'],
          rows: report.revenueByReservationType.map((item) {
            final pct = totalRevenue > 0
                ? (item.revenue / totalRevenue * 100).toStringAsFixed(1)
                : '0.0';
            return [
              item.reservationTypeName,
              _currencyFormat.format(item.revenue),
              _numberFormat.format(item.count),
              '$pct%',
            ];
          }).toList(),
          footerRow: [
            'TOTAL',
            _currencyFormat.format(totalRevenue),
            _numberFormat.format(
              report.revenueByReservationType.fold<int>(0, (s, i) => s + i.count),
            ),
            '100.0%',
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildReservationsByTypeSection(BusinessReport report) {
    if (report.reservationsByType.isEmpty) return pw.SizedBox();

    final total = report.reservationsByType
        .fold<int>(0, (sum, item) => sum + item.count);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Reservations by Type'),
        pw.SizedBox(height: 8),
        _dataTable(
          headers: ['Reservation Type', 'Count', '% of Total'],
          rows: report.reservationsByType.map((item) {
            final pct = total > 0
                ? (item.count / total * 100).toStringAsFixed(1)
                : '0.0';
            return [
              item.reservationTypeName,
              _numberFormat.format(item.count),
              '$pct%',
            ];
          }).toList(),
          footerRow: ['TOTAL', _numberFormat.format(total), '100.0%'],
        ),
      ],
    );
  }

  static pw.Widget _buildRevenueByZoneSection(BusinessReport report) {
    if (report.revenueByZone.isEmpty) return pw.SizedBox();

    final totalRevenue =
        report.revenueByZone.fold<double>(0, (sum, item) => sum + item.revenue);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Revenue by Parking Zone'),
        pw.SizedBox(height: 8),
        _dataTable(
          headers: ['Zone', 'Revenue', 'Reservations', '% of Revenue'],
          rows: report.revenueByZone.map((item) {
            final pct = totalRevenue > 0
                ? (item.revenue / totalRevenue * 100).toStringAsFixed(1)
                : '0.0';
            return [
              item.zoneName,
              _currencyFormat.format(item.revenue),
              _numberFormat.format(item.count),
              '$pct%',
            ];
          }).toList(),
          footerRow: [
            'TOTAL',
            _currencyFormat.format(totalRevenue),
            _numberFormat.format(
              report.revenueByZone.fold<int>(0, (s, i) => s + i.count),
            ),
            '100.0%',
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPopularZonesSection(BusinessReport report) {
    if (report.mostPopularZones.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Most Popular Zones (Ranked)'),
        pw.SizedBox(height: 8),
        _dataTable(
          headers: ['Rank', 'Zone', 'Reservations', 'Total Revenue'],
          rows: report.mostPopularZones.asMap().entries.map((entry) {
            final zone = entry.value;
            return [
              '#${entry.key + 1}',
              zone.zoneName,
              _numberFormat.format(zone.reservationCount),
              _currencyFormat.format(zone.totalRevenue),
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildRecentReservationsSection(BusinessReport report) {
    if (report.recentReservations.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recent Reservations'),
        pw.SizedBox(height: 8),
        _dataTable(
          headers: ['ID', 'Spot', 'Zone', 'User', 'Type', 'Price'],
          rows: report.recentReservations.map((r) {
            return [
              '${r.id}',
              r.parkingSpotNumber,
              r.zoneName,
              r.userFullName,
              r.reservationTypeName,
              _currencyFormat.format(r.finalPrice),
            ];
          }).toList(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // REPORT 2: Reservations List PDF
  // ──────────────────────────────────────────────────────────────────
  static Future<void> generateReservationsReport(
    List<Reservation> reservations, {
    DateTime? startDateFrom,
    DateTime? startDateTo,
  }) async {
    final pdf = pw.Document(
      title: 'MoSmartPark Reservations Report',
      author: 'MoSmartPark',
    );

    final now = DateTime.now();

    // Calculate summary statistics
    final totalRevenue =
        reservations.fold<double>(0, (sum, r) => sum + r.finalPrice);
    final avgPrice =
        reservations.isNotEmpty ? totalRevenue / reservations.length : 0.0;

    // Group by type
    final byType = <String, List<Reservation>>{};
    for (final r in reservations) {
      final key = r.reservationTypeName ?? 'Unknown';
      byType.putIfAbsent(key, () => []).add(r);
    }

    // Group by spot
    final bySpot = <String, int>{};
    for (final r in reservations) {
      final key = r.parkingSpotNumber ?? 'Unknown';
      bySpot[key] = (bySpot[key] ?? 0) + 1;
    }

    // Date range string
    String dateRange = 'All dates';
    if (startDateFrom != null && startDateTo != null) {
      dateRange =
          '${_dateOnlyFormat.format(startDateFrom)} to ${_dateOnlyFormat.format(startDateTo)}';
    } else if (startDateFrom != null) {
      dateRange = 'From ${_dateOnlyFormat.format(startDateFrom)}';
    } else if (startDateTo != null) {
      dateRange = 'Up to ${_dateOnlyFormat.format(startDateTo)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(
          'Reservations Report',
          'Generated on ${_dateFormat.format(now)}  |  Period: $dateRange',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary cards
          pw.Row(
            children: [
              _kpiCard('Total Reservations', _numberFormat.format(reservations.length), _blueAccent),
              pw.SizedBox(width: 10),
              _kpiCard('Total Revenue', _currencyFormat.format(totalRevenue), _greenAccent),
              pw.SizedBox(width: 10),
              _kpiCard('Avg. Price', _currencyFormat.format(avgPrice), _orangeAccent),
              pw.SizedBox(width: 10),
              _kpiCard('Unique Spots', '${bySpot.length}', _purpleAccent),
            ],
          ),
          pw.SizedBox(height: 16),

          // Breakdown by type
          if (byType.isNotEmpty) ...[
            _sectionTitle('Breakdown by Reservation Type'),
            pw.SizedBox(height: 8),
            _dataTable(
              headers: ['Reservation Type', 'Count', 'Revenue', '% of Revenue'],
              rows: byType.entries.map((entry) {
                final typeRevenue = entry.value
                    .fold<double>(0, (sum, r) => sum + r.finalPrice);
                final pct = totalRevenue > 0
                    ? (typeRevenue / totalRevenue * 100).toStringAsFixed(1)
                    : '0.0';
                return [
                  entry.key,
                  _numberFormat.format(entry.value.length),
                  _currencyFormat.format(typeRevenue),
                  '$pct%',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 16),
          ],

          // Main reservations table
          _sectionTitle('Reservation Details (${reservations.length} records)'),
          pw.SizedBox(height: 8),
          _dataTable(
            headers: ['ID', 'Car', 'Client', 'Spot', 'Type', 'Start Date', 'End Date', 'Price'],
            rows: reservations.map((r) {
              final car = r.carBrandName != null && r.carModel != null
                  ? '${r.carBrandName} ${r.carModel}'
                  : r.carModel ?? 'N/A';
              return [
                '${r.id}',
                car,
                r.userFullName ?? 'N/A',
                r.parkingSpotNumber ?? 'N/A',
                r.reservationTypeName ?? 'N/A',
                r.startDate != null ? _dateFormat.format(r.startDate!) : 'N/A',
                r.endDate != null ? _dateFormat.format(r.endDate!) : 'N/A',
                _currencyFormat.format(r.finalPrice),
              ];
            }).toList(),
            footerRow: [
              '',
              '',
              '',
              '',
              '',
              '',
              'TOTAL:',
              _currencyFormat.format(totalRevenue),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'MoSmartPark_Reservations_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Shared helpers
  // ──────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _brown,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MoSmartPark',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColor.fromInt(0xFFE8DFD5),
                ),
              ),
            ],
          ),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFFD4C5B5),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderColor, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MoSmartPark - Confidential',
            style: pw.TextStyle(fontSize: 8, color: _greyText),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _greyText),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brown, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: _brown,
        ),
      ),
    );
  }

  static pw.Widget _dataTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? footerRow,
  }) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _tableHeaderBg),
      headerAlignment: pw.Alignment.centerLeft,
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _darkText),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      cellAlignments: {
        for (int i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _tableAltRow),
      headers: headers,
      data: [
        ...rows,
        if (footerRow != null) footerRow,
      ],
    );
  }
}
