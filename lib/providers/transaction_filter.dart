import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TransactionFilterState {
  final String flowType; // 'all', 'income', 'expense'
  final String timeRange; // 'current_month', 'today', 'yesterday', 'last_5', 'last_7', 'last_30', 'custom_range'
  final DateTime selectedMonthYear;
  final DateTimeRange? customDateRange;

  TransactionFilterState({
    this.flowType = 'all',
    this.timeRange = 'current_month',
    DateTime? selectedMonthYear,
    this.customDateRange,
  }) : selectedMonthYear = selectedMonthYear ?? DateTime(DateTime.now().year, DateTime.now().month);

  TransactionFilterState copyWith({
    String? flowType,
    String? timeRange,
    DateTime? selectedMonthYear,
    DateTimeRange? customDateRange,
  }) {
    return TransactionFilterState(
      flowType: flowType ?? this.flowType,
      timeRange: timeRange ?? this.timeRange,
      selectedMonthYear: selectedMonthYear ?? this.selectedMonthYear,
      customDateRange: customDateRange ?? this.customDateRange,
    );
  }
}

class TransactionFilterNotifier extends StateNotifier<TransactionFilterState> {
  TransactionFilterNotifier() : super(TransactionFilterState());

  void setFlowType(String type) => state = state.copyWith(flowType: type);
  
  void setTimeRange(String range) => state = state.copyWith(timeRange: range);
  
  void setSelectedMonth(DateTime monthYear) {
    state = state.copyWith(
      timeRange: 'current_month', // We use this value for any specific month
      selectedMonthYear: DateTime(monthYear.year, monthYear.month),
    );
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(
      timeRange: 'custom_range',
      customDateRange: range,
    );
  }
}

final transactionFilterProvider = StateNotifierProvider<TransactionFilterNotifier, TransactionFilterState>((ref) {
  return TransactionFilterNotifier();
});
