import 'dart:async';
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
              drive.DriveApi.driveFileScope,
              drive.DriveApi.driveScope,
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
  // and returns the fileId with real-time upload progress tracking
  Future<String> uploadAndMakePublic({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    Function(int uploadedBytes, int totalBytes)? onProgress,
  }) async {
    final driveApi = await _getDriveApi();

    final drive.File fileMetadata = drive.File()
      ..name = fileName
      ..mimeType = mimeType;

    final int totalBytes = bytes.length;
    int uploadedBytes = 0;

    // Create a stream controller to track actual upload progress
    final streamController = StreamController<List<int>>();
    
    // Report initial progress
    if (onProgress != null) {
      onProgress(0, totalBytes);
    }

    // Split bytes into chunks for progress tracking (256KB chunks for smooth progress)
    const int chunkSize = 256 * 1024; // 256KB chunks
    int offset = 0;

    // Start async process to feed chunks to the stream
    Future.microtask(() async {
      try {
        while (offset < totalBytes) {
          final int end = (offset + chunkSize < totalBytes) 
              ? offset + chunkSize 
              : totalBytes;
          
          final chunk = bytes.sublist(offset, end);
          streamController.add(chunk);
          
          uploadedBytes += chunk.length;
          
          // Report progress after each chunk
          if (onProgress != null) {
            onProgress(uploadedBytes, totalBytes);
          }
          
          offset = end;
          
          // Small delay to allow UI updates and prevent blocking
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        await streamController.close();
      } catch (e) {
        streamController.addError(e);
        await streamController.close();
      }
    });

    final media = drive.Media(streamController.stream, totalBytes);

    // Perform the upload
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
    HttpClient()..connectionTimeout = const Duration(seconds: 60),
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}