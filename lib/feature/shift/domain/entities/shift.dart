import 'package:equatable/equatable.dart';

enum ShiftStatus {
  open,
  closed;

  static ShiftStatus fromString(String value) {
    switch (value) {
      case 'open':
        return ShiftStatus.open;
      case 'closed':
        return ShiftStatus.closed;
      default:
        return ShiftStatus.open;
    }
  }

  String get toDbString {
    switch (this) {
      case ShiftStatus.open:
        return 'open';
      case ShiftStatus.closed:
        return 'closed';
    }
  }
}

class Shift extends Equatable {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final ShiftStatus status;
  final int? userId;
  final double cashStart;
  final double? cashEnd;
  final double? cashDifferent;
  final String? notes;

  const Shift({
    this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    this.userId,
    required this.cashStart,
    this.cashEnd,
    this.cashDifferent,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        status,
        userId,
        cashStart,
        cashEnd,
        cashDifferent,
        notes,
      ];

  Shift copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    ShiftStatus? status,
    int? userId,
    double? cashStart,
    double? cashEnd,
    double? cashDifferent,
    String? notes,
  }) {
    return Shift(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      cashStart: cashStart ?? this.cashStart,
      cashEnd: cashEnd ?? this.cashEnd,
      cashDifferent: cashDifferent ?? this.cashDifferent,
      notes: notes ?? this.notes,
    );
  }
}
