import 'package:equatable/equatable.dart';

// Abstract class dasar untuk semua jenis kegagalan
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Kegagalan kalau ada masalah di API / Internet
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Kegagalan kalau ada masalah di Database Lokal (SQLite)
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Kegagalan kalau device tidak ada koneksi internet
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
