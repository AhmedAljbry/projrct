import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/remote_lama_tools/data/datasources/lama_remote_data_source.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';

abstract class LamaHubState {}

class LamaHubInitial extends LamaHubState {}
class LamaHubLoading extends LamaHubState {}
class LamaHubLoaded extends LamaHubState {
  final LamaServerHealth health;
  final LamaCapabilities capabilities;

  LamaHubLoaded({required this.health, required this.capabilities});
}
class LamaHubError extends LamaHubState {
  final String message;
  LamaHubError(this.message);
}

class RemoteLamaHubCubit extends Cubit<LamaHubState> {
  final LamaRemoteDataSource _remoteDataSource;

  RemoteLamaHubCubit({required LamaRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource,
        super(LamaHubInitial());

  Future<void> loadServerStatus() async {
    if (isClosed) return;
    emit(LamaHubLoading());
    try {
      final health = await _remoteDataSource.checkHealth();
      final capabilities = await _remoteDataSource.getCapabilities();
      if (isClosed) return;
      emit(LamaHubLoaded(health: health, capabilities: capabilities));
    } catch (e) {
      if (isClosed) return;
      emit(LamaHubError('Connection failed. Verify your ngrok URL and ensure the server is accepting requests.'));
    }
  }
}
