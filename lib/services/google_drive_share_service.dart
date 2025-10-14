import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Service that handles Google Sign-In, uploading a .lambook file to Drive,
// making it public, and returning a shareable fileId + web URL.
class GoogleDriveShareService {
  GoogleDriveShareService({GoogleSignIn? googleSignIn, String? serverClientId})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            serverClientId: serverClientId,
            scopes: <String>[
              drive.DriveApi.driveFileScope, // Create files you open/create
              drive.DriveApi.driveScope, // Broader access for permissions
            ],
          );

  final GoogleSignIn _googleSignIn;

  Future<drive.DriveApi> _getDriveApi() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    final GoogleSignInAccount signedInAccount =
        account ?? (await _googleSignIn.signIn())!;

    final authHeaders = await signedInAccount.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  // Uploads bytes to Drive as a file, sets "anyone with the link" reader,
  // and returns the fileId.
  Future<String> uploadAndMakePublic({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) async {  
    final driveApi = await _getDriveApi();

    final drive.File fileMetadata = drive.File()
      ..name = fileName
      ..mimeType = mimeType;

    final media = drive.Media(
      Stream<List<int>>.fromIterable(<List<int>>[bytes]),
      bytes.length,
    );

    final created = await driveApi.files.create(
      fileMetadata,
      uploadMedia: media,
    );

    final String fileId = created.id!;

    // Make it public readable
    await driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      fileId,
    );

    return fileId;
  }
}

// Simple auth client using headers from GoogleSignIn
class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = IOClient(
    HttpClient()..connectionTimeout = const Duration(seconds: 30),
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
