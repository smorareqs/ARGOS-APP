enum SyncMode { full, incremental }

enum SyncStatus { idle, inProgress, completed, failed }

class SyncStep {
  const SyncStep({
    required this.name,
    required this.current,
    required this.total,
  });

  final String name;
  final int current;
  final int total;

  double get progress => total == 0 ? 0 : current / total;
}

class SyncState {
  const SyncState({
    required this.status,
    this.mode,
    this.currentStep,
    this.errorMessage,
  });

  const SyncState.idle() : this(status: SyncStatus.idle);

  final SyncStatus status;
  final SyncMode? mode;
  final SyncStep? currentStep;
  final String? errorMessage;

  SyncState copyWith({
    SyncStatus? status,
    SyncMode? mode,
    SyncStep? currentStep,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
