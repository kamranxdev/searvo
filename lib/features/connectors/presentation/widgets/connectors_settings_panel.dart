import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:searvo/features/connectors/presentation/bloc/connector_bloc.dart';
import 'package:searvo/features/connectors/presentation/widgets/connector_card.dart';

class ConnectorsSettingsPanel extends StatelessWidget {
  const ConnectorsSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          GetIt.instance<ConnectorBloc>()..add(LoadConnectors()),
      child: BlocBuilder<ConnectorBloc, ConnectorState>(
        builder: (context, state) {
          if (state is ConnectorLoading && state is! ConnectorLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConnectorError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ConnectorLoaded) {
            if (state.connectors.isEmpty) {
              return const Center(child: Text('No connectors available'));
            }

            return Column(
              children: state.connectors.map((connector) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ConnectorCard(
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
                    onDisconnect: () {
                      context.read<ConnectorBloc>().add(
                        ToggleConnector(
                          connectorId: connector.id,
                          connect: false,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
