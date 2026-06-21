import '../../domain/entities/shift.dart';

class ShiftModel extends Shift {
  const ShiftModel({
    super.id,
    required super.startTime,
    super.endTime,
    required super.status,
    super.userId,
    required super.cashStart,
    super.cashEnd,
    super.cashDifferent,
    super.notes,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      status: ShiftStatus.fromString(map['status'] as String),
      userId: map['user_id'] as int?,
      cashStart: (map['cash_start'] as num).toDouble(),
      cashEnd: map['cash_end'] != null ? (map['cash_end'] as num).toDouble() : null,
      cashDifferent: map['cash_different'] != null ? (map['cash_different'] as num).toDouble() : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.toDbString,
      'user_id': userId,
      'cash_start': cashStart,
      'cash_end': cashEnd,
      'cash_different': cashDifferent,
      'notes': notes,
    };
  }

  factory ShiftModel.fromEntity(Shift entity) {
    return ShiftModel(
      id: entity.id,
      startTime: entity.startTime,
      endTime: entity.endTime,
      status: entity.status,
      userId: entity.userId,
      cashStart: entity.cashStart,
      cashEnd: entity.cashEnd,
      cashDifferent: entity.cashDifferent,
      notes: entity.notes,
    );
  }

  Shift toEntity() {
    return Shift(
      id: id,
      startTime: startTime,
      endTime: endTime,
      status: status,
      userId: userId,
      cashStart: cashStart,
      cashEnd: cashEnd,
      cashDifferent: cashDifferent,
      notes: notes,
    );
  }

  @override
  ShiftModel copyWith({
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
    return ShiftModel(
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
