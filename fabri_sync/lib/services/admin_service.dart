// import 'package:supabase_flutter/supabase_flutter.dart';

// class AdminDashboardService {
//   final SupabaseClient supabase;

//   AdminDashboardService(this.supabase);

//   Future<List<Map<String, dynamic>>> fetchOrdersRaw() async {
//     final data = await supabase
//         .from('ordersmain')
//         .select()
//         .order('created_at', ascending: false);

//     return (data as List).cast<Map<String, dynamic>>();
//   }

//   Future<Map<String, double>> fetchEstimatedDeptHours() async {
//     final data = await supabase
//         .from('master_time_config')
//         .select('department, estimated_hours')
//         .order('department');

//     final Map<String, double> map = {};
//     for (final row in (data as List)) {
//       final dept = (row['department'] ?? '').toString();
//       final hrs = (row['estimated_hours'] as num?)?.toDouble() ?? 0.0;
//       if (dept.trim().isNotEmpty) map[dept] = hrs;
//     }
//     return map;
//   }
// }
