import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:searvo/core/network/network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnection internetConnection;

  NetworkInfoImpl(this.internetConnection);

  @override
  Future<bool> get isConnected => internetConnection.hasInternetAccess;
}
