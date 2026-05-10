import 'package:flutter_riverpod/flutter_riverpod.dart';

// ViewModel quản lý Lộ trình tuần (ngày đang được chọn)
final selectedDayProvider = StateProvider<int>(( ref) => 0);