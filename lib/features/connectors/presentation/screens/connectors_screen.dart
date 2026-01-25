import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:searvo/features/connectors/presentation/bloc/connector_bloc.dart';
import 'package:searvo/features/connectors/presentation/widgets/connector_card.dart';
import 'package:searvo/features/connectors/domain/entities/connector.dart';

class ConnectorsScreen extends StatelessWidget {
  const ConnectorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GetIt.instance<ConnectorBloc>()..add(LoadConnectors()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Connect Data Sources')),
        body: BlocBuilder<ConnectorBloc, ConnectorState>(
          builder: (context, state) {
            if (state is ConnectorLoading && state is! ConnectorLoaded) {
              // Initial load
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ConnectorError) {
              return Center(child: Text(state.message));
            }

            if (state is ConnectorLoaded) {
              final installed = state.connectors
                  .where((c) => c.status == ConnectorStatus.connected)
                  .toList();
              final available = state.connectors
                  .where((c) => c.status != ConnectorStatus.connected)
                  .toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Installed Connectors',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connected tools provide Searvo with richer and more accurate answers, gated by permissions you have granted.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (installed.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 16,
                        ),
                        child: Center(
                          child: Text(
                            'Connect your apps to start using them with Searvo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final connector = installed[index];
                        return ConnectorCard(
                          connector: connector,
                          isLoading: state is ConnectorLoading,
                          onConnect: () {}, // Already connected
                          onDisconnect: () {
                            context.read<ConnectorBloc>().add(
                              ToggleConnector(
                                connectorId: connector.id,
                                connect: false,
                              ),
                            );
                          },
                        );
                      }, childCount: installed.length),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Connectors',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect your tools to Searvo to search across them and take action. Your permissions are always respected.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final connector = available[index];
                      return ConnectorCard(
                        connector: connector,
                        isLoading: state is ConnectorLoading,
                        onConnect: () {
                          context.read<ConnectorBloc>().add(
                            ToggleConnector(
                              connectorId: connector.id,
                              connect: true,
                            ),
                          );
                        },
                        onDisconnect: () {}, // Already disconnected
                      );
                    }, childCount: available.length),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              );
            }

            return const Center(child: Text('No connectors found'));
          },
        ),
      ),
    );
  }
}
