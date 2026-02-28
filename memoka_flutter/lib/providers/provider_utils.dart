import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'connection_provider.dart';

/// Whether the app currently has a server connection.
bool isOnline(Ref ref) =>
    ref.read(connectionProvider) == ConnectionState.connected;

/// Whether an exception indicates a network/connectivity failure.
bool isNetworkError(Object e) =>
    e is ServerpodClientException && e.statusCode == -1;
