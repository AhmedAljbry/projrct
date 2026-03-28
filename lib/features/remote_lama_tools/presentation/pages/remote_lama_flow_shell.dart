import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:untitled2/features/remote_lama_tools/data/datasources/lama_remote_data_source.dart';
import 'package:untitled2/features/remote_lama_tools/data/repositories/lama_repository_impl.dart';
import 'package:untitled2/features/remote_lama_tools/domain/repositories/lama_repository.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/bloc/remote_lama_bloc.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/pages/remote_lama_editor_page.dart';

// NOTE: Usually URL and keys come from env config. Hardcoded as example based on prompt setup.
const _kApiUrl = 'http://127.0.0.1:8000';
const _kApiKey = '';

class RemoteLamaFlowShell extends StatefulWidget {
  final Uint8List? initialImage;

  const RemoteLamaFlowShell({super.key, this.initialImage});

  @override
  State<RemoteLamaFlowShell> createState() => _RemoteLamaFlowShellState();
}

class _RemoteLamaFlowShellState extends State<RemoteLamaFlowShell> {
  late final LamaRepository _repository;
  late final GoRouter _router;
  late final http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = http.Client();
    final dataSource = LamaRemoteDataSourceImpl(
      baseUrl: _kApiUrl,
      apiKey: _kApiKey,
      client: _client,
    );
    _repository = LamaRepositoryImpl(remoteDataSource: dataSource);

    _router = GoRouter(
      initialLocation: '/editor',
      routes: [
        GoRoute(
          path: '/editor',
          builder: (context, state) => RemoteLamaEditorPage(
             initialImage: widget.initialImage,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LamaRepository>.value(value: _repository),
        RepositoryProvider(create: (_) => SubmitJobUseCase(_repository)),
        RepositoryProvider(create: (_) => PollJobStatusUseCase(_repository)),
        RepositoryProvider(create: (_) => GetJobResultUseCase(_repository)),
      ],
      child: BlocProvider(
        create: (context) => RemoteLamaBloc(
          submitJobUseCase: context.read<SubmitJobUseCase>(),
          pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
          getJobResultUseCase: context.read<GetJobResultUseCase>(),
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          routerConfig: _router,
        ),
      ),
    );
  }
}
