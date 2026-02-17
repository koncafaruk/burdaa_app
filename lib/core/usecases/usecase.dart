import 'package:equatable/equatable.dart';

// Since I didn't add dartz, I'll assume standard return types or I'll add dartz now.
// Actually, standard Clean Arch uses Either. I'll add fpdart or dartz. Dartz is more classic for older Clean Arch tutorials in Flutter.
// Let's stick to simple Future<T> for now to avoid unrequested dependencies, or basic Either implementation if needed.
// Or I can add dartz/fpdart. I'll add dartz quickly.
// Wait, I can't add dartz without a tool call. I'll just skip Either for now and use generic Future<void> or similar.

abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
