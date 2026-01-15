import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global Bloc observer for logging and debugging
/// Monitors all Bloc/Cubit state changes and events
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('✨ Bloc created: ${bloc.runtimeType}', name: 'BlocObserver');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log('📥 Event: ${bloc.runtimeType} - $event', name: 'BlocObserver');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log(
      '🔄 State change: ${bloc.runtimeType}\n'
      '   Current: ${change.currentState}\n'
      '   Next: ${change.nextState}',
      name: 'BlocObserver',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log(
      '➡️ Transition: ${bloc.runtimeType}\n'
      '   Event: ${transition.event}\n'
      '   Current: ${transition.currentState}\n'
      '   Next: ${transition.nextState}',
      name: 'BlocObserver',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log(
      '❌ Error in ${bloc.runtimeType}: $error',
      name: 'BlocObserver',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('🔒 Bloc closed: ${bloc.runtimeType}', name: 'BlocObserver');
  }
}
