import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({
    required this.isOnline,
    this.hasConnectionType = true,
    this.hasShownOfflineEvent = false,
  });

  const ConnectivityState.initial()
      : isOnline = true,
        hasConnectionType = true,
        hasShownOfflineEvent = false;

  final bool isOnline;
  final bool hasConnectionType;
  final bool hasShownOfflineEvent;

  ConnectivityState copyWith({
    bool? isOnline,
    bool? hasConnectionType,
    bool? hasShownOfflineEvent,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      hasConnectionType: hasConnectionType ?? this.hasConnectionType,
      hasShownOfflineEvent: hasShownOfflineEvent ?? this.hasShownOfflineEvent,
    );
  }

  @override
  List<Object?> get props => [isOnline, hasConnectionType, hasShownOfflineEvent];
}
