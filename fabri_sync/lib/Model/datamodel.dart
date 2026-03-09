// import 'package:flutter/material.dart';

// enum Department {
//   cutting,
//   stitching,
//   threading,
//   qualityControl,
//   packaging,
//   dispatch,
// }

// enum WorkStatus { pending, inProgress, completed }

// class DepartmentTracking {
//   final String orderId;
//   final Department department;
//   final String managerAssigned;

//   final DateTime dateIn;
//   final TimeOfDay timeIn;

//   final DateTime? dateOut;
//   final TimeOfDay? timeOut;

//   final WorkStatus status;

//   /// Department specific extra fields
//   final Map<String, dynamic>? extraFields;

//   DepartmentTracking({
//     required this.orderId,
//     required this.department,
//     required this.managerAssigned,
//     required this.dateIn,
//     required this.timeIn,
//     this.dateOut,
//     this.timeOut,
//     required this.status,
//     this.extraFields,
//   });
// }
import 'package:flutter/material.dart';

/// ✅ Matches DB exactly (department_orders.department is UPPERCASE and may contain underscore)
enum Department {
  cutting,
  stitching,
  threading,
  quality_control,
  packing,
  inspection,
}

/// ✅ Matches DB exactly (department_orders.status uses lowercase: pending / inprogress / completed)
enum WorkStatus { pending, inprogress, completed }

/// ✅ Helper: Department <-> DB string
extension DepartmentDb on Department {
  /// DB value (e.g. QUALITY_CONTROL)
  String get db => name.toUpperCase();

  /// UI label (e.g. Quality Control)
  String get label {
    switch (this) {
      case Department.quality_control:
        return 'Quality Control';
      default:
        final s = name.replaceAll('_', ' ');
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  /// Parse DB value safely
  static Department? fromDb(String? value) {
    if (value == null) return null;
    final v = value.trim().toUpperCase();
    for (final d in Department.values) {
      if (d.db == v) return d;
    }
    return null;
  }
}

/// ✅ Helper: WorkStatus <-> DB string
extension WorkStatusDb on WorkStatus {
  /// DB value (e.g. inprogress)
  String get db => name.toLowerCase();

  static WorkStatus fromDb(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    for (final s in WorkStatus.values) {
      if (s.db == v) return s;
    }
    return WorkStatus.pending; // safe fallback
  }
}

class DepartmentTracking {
  final String orderId;

  /// ✅ department_orders.department
  final Department department;

  /// ✅ optional (department_orders doesn't have managerAssigned in schema)
  final String? managerAssigned;

  /// ✅ department_orders.date_in (date)
  final DateTime dateIn;

  /// ✅ department_orders.time_in (time)
  final TimeOfDay timeIn;

  /// ✅ department_orders.date_out (date)
  final DateTime? dateOut;

  /// ✅ department_orders.time_out (time)
  final TimeOfDay? timeOut;

  /// ✅ department_orders.status
  final WorkStatus status;

  /// ✅ department_orders.expected_hours
  final double expectedHours;

  /// Department specific extra fields (optional)
  final Map<String, dynamic>? extraFields;

  DepartmentTracking({
    required this.orderId,
    required this.department,
    this.managerAssigned,
    required this.dateIn,
    required this.timeIn,
    this.dateOut,
    this.timeOut,
    required this.status,
    required this.expectedHours,
    this.extraFields,
  });

  /// ✅ Parse from department_orders row
  factory DepartmentTracking.fromDb(Map<String, dynamic> row) {
    final dept =
        DepartmentDb.fromDb(row['department']?.toString()) ??
        Department.cutting;

    final dateIn = DateTime.parse(row['date_in'].toString());

    // time_in is "HH:mm:ss" usually
    final timeParts = row['time_in'].toString().split(':');
    final h = int.tryParse(timeParts[0]) ?? 0;
    final m = int.tryParse(timeParts[1]) ?? 0;
    final todIn = TimeOfDay(hour: h, minute: m);

    TimeOfDay? todOut;
    if (row['time_out'] != null) {
      final outParts = row['time_out'].toString().split(':');
      todOut = TimeOfDay(
        hour: int.tryParse(outParts[0]) ?? 0,
        minute: int.tryParse(outParts[1]) ?? 0,
      );
    }

    return DepartmentTracking(
      orderId: (row['order_id'] ?? '').toString(),
      department: dept,
      managerAssigned: row['manager_name']?.toString(), // optional if joined
      dateIn: dateIn,
      timeIn: todIn,
      dateOut: row['date_out'] != null
          ? DateTime.parse(row['date_out'].toString())
          : null,
      timeOut: todOut,
      status: WorkStatusDb.fromDb(row['status']?.toString()),
      expectedHours: (row['expected_hours'] as num?)?.toDouble() ?? 0.0,
      extraFields: row['extra_fields'] as Map<String, dynamic>?,
    );
  }
}
