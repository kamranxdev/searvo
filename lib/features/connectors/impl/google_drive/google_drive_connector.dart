import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:searvo/features/connectors/data/datasources/connector_integration.dart';
import 'package:searvo/features/connectors/domain/entities/connector.dart';
import 'package:searvo/features/connectors/domain/entities/connector_result.dart';

import 'google_drive_scopes.dart';

class GoogleDriveConnector extends ConnectorIntegration {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: GoogleDriveScopes.scopes,
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  @override
  String get id => 'google_drive';

  @override
  String get name => 'Google Drive';

  @override
  String get description => 'Search your Google Drive files';

  @override
  // Use a local asset or a Material icon identifier for now.
  // If using SVG assets, ensure the path exists.
  // For this generic impl, let's assume we have an asset or handle it in UI.
  String get iconPath => 'assets/icons/google-drive-avatar.svg';

  @override
  bool get isSearchSupported => true;

  @override
  Future<void> connect() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initializeClient();
      }
    } catch (e) {
      print('Google Drive Sign In Error: $e');
      // Prevent crash on Linux where plugin is likely missing
      if (e.toString().contains('MissingPluginException')) {
        print('Google Sign In not supported on this platform');
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  @override
  Future<ConnectorStatus> getStatus() async {
    // Check if implicitly signed in (silent sign-in)
    try {
      _currentUser ??= await _googleSignIn.signInSilently();
    } catch (e) {
      // Ignore silence sign in errors (common on unsupported platforms)
      print('Silent sign in failed: $e');
    }

    if (_currentUser != null) {
      if (_driveApi == null) {
        await _initializeClient();
      }
      return ConnectorStatus.connected;
    }
    return ConnectorStatus.disconnected;
  }

  Future<void> _initializeClient() async {
    if (_currentUser == null) return;
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient != null) {
        _driveApi = drive.DriveApi(httpClient);
      }
    } catch (e) {
      print('Error initializing Google Drive API client: $e');
    }
  }

  @override
  Future<List<ConnectorResult>> search(String query, {int? limit}) async {
    if (_driveApi == null) return [];

    try {
      // Clean query for Drive API
      // Drive uses "name contains 'foo'" format
      final q = "name contains '$query' and trashed = false";

      final fileList = await _driveApi!.files.list(
        q: q,
        pageSize: limit ?? 10,
        $fields:
            'files(id, name, description, webViewLink, webContentLink, mimeType, createdTime, modifiedTime, thumbnailLink)',
      );

      if (fileList.files == null) return [];

      return fileList.files!.map((file) {
        return ConnectorResult(
          id: file.id ?? '',
          connectorId: id,
          title: file.name ?? 'Untitled',
          description: file.description,
          url: file.webViewLink ?? '',
          downloadUrl: file.webContentLink,
          mimeType: file.mimeType ?? 'application/octet-stream',
          createdAt: file.createdTime,
          modifiedAt: file.modifiedTime,
          thumbnail: file.thumbnailLink,
          metadata: {'mimeType': file.mimeType},
        );
      }).toList();
    } catch (e) {
      print('Google Drive Search Error: $e');
      return [];
    }
  }
}
