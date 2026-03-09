import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManagerOrdersDataSource extends DataTableSource {
  final List<Map<String, dynamic>> rows;

  ManagerOrdersDataSource(this.rows);

  String _fmtDate(dynamic v) {
    if (v == null) return "-";
    final d = DateTime.parse(v.toString());
    return DateFormat("dd MMM yyyy").format(d);
  }

  String _fmtTime(dynamic v) {
    if (v == null) return "-";
    final t = DateFormat.Hms().parse(v.toString());
    return DateFormat("hh:mm a").format(DateTime(2000, 1, 1, t.hour, t.minute));
  }

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;

    final r = rows[index];
    final status = (r['status'] ?? '').toString().toLowerCase();

    final rowColor = MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white.withOpacity(0.10);
      }
      return index.isEven
          ? Colors.white.withOpacity(0.04)
          : Colors.white.withOpacity(0.02);
    });

    return DataRow.byIndex(
      index: index,
      color: rowColor,
      cells: [
        DataCell(
          Text(
            (index + 1).toString(),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            (r['order_id'] ?? '').toString(),
            style: TextStyle(color: Colors.white.withOpacity(0.90)),
          ),
        ),
        DataCell(
          Text(
            (r['department'] ?? '').toString(),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            _fmtDate(r['date_in']),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            _fmtTime(r['time_in']),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            (((r['expected_hours'] ?? 0) as num).toString()),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            _fmtDate(r['date_out']),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(
          Text(
            _fmtTime(r['time_out']),
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ),
        DataCell(_statusChip(status)),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color accent;
    if (status == "completed") {
      accent = Colors.greenAccent;
    } else if (status == "inprogress") {
      accent = Colors.orangeAccent;
    } else {
      accent = Colors.redAccent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: accent.withOpacity(0.45)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}
