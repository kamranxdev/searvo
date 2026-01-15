/// Interface for checking network connectivity status
abstract class NetworkInfo {
  Future<bool> get isConnected;
}
