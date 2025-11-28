import 'dart:async';
import 'dart:convert';
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

  Future<_GoogleAuthClient> _getAuthenticatedClient() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    final GoogleSignInAccount signedInAccount =
        account ?? (await _googleSignIn.signIn())!;

    final authHeaders = await signedInAccount.authHeaders;
    return _GoogleAuthClient(authHeaders);
  }

  // Uploads bytes to Drive as a file, sets "anyone with the link" reader,
  // and returns the fileId with real-time upload progress tracking
  Future<String> uploadAndMakePublic({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    Function(int uploadedBytes, int totalBytes)? onProgress,
  }) async {
    final client = await _getAuthenticatedClient();

    final drive.File fileMetadata = drive.File()
      ..name = fileName
      ..mimeType = mimeType;

    final int totalBytes = bytes.length;

    // Report initial progress
    if (onProgress != null) {
      onProgress(0, totalBytes);
    }

    // Use resumable upload with progress tracking
    final uploadUrl = await _initiateResumableUpload(
      client,
      fileMetadata,
      totalBytes,
    );

    // Upload with real progress tracking
    final fileId = await _uploadWithProgress(
      client,
      uploadUrl,
      bytes,
      totalBytes,
      onProgress,
    );

    // Make it public readable using DriveApi
    final driveApi = drive.DriveApi(client);
    await driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      fileId,
    );

    return fileId;
  }

  Future<String> _initiateResumableUpload(
    http.Client client,
    drive.File metadata,
    int totalBytes,
  ) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
    );

    final metadataJson = json.encode({
      'name': metadata.name,
      'mimeType': metadata.mimeType,
    });

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Length': totalBytes.toString(),
      },
      body: metadataJson,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to initiate upload: ${response.body}');
    }

    final location = response.headers['location'];
    if (location == null) {
      throw Exception('No upload URL returned');
    }

    return location;
  }

  Future<String> _uploadWithProgress(
    http.Client client,
    String uploadUrl,
    Uint8List bytes,
    int totalBytes,
    Function(int, int)? onProgress,
  ) async {
    const int chunkSize = 256 * 1024; // 256KB chunks
    int offset = 0;

    while (offset < totalBytes) {
      final int end = (offset + chunkSize < totalBytes)
          ? offset + chunkSize
          : totalBytes;

      final chunk = bytes.sublist(offset, end);

      final response = await client.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Length': chunk.length.toString(),
          'Content-Range': 'bytes $offset-${end - 1}/$totalBytes',
        },
        body: chunk,
      );

      // Report progress
      if (onProgress != null) {
        onProgress(end, totalBytes);
      }

      // If upload incomplete, continue
      if (response.statusCode == 308) {
        offset = end;
        continue;
      }

      // Upload complete
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseJson = json.decode(response.body) as Map<String, dynamic>;
          final fileId = responseJson['id'] as String?;
          if (fileId != null) {
            return fileId;
          }
        } catch (e) {
          // Fallback to regex if JSON parsing fails
          final fileIdMatch = RegExp(r'"id":\s*"([^"]+)"').firstMatch(response.body);
          if (fileIdMatch != null) {
            return fileIdMatch.group(1)!;
          }
        }
        throw Exception('Could not extract file ID from response');
      }

      throw Exception('Upload failed with status: ${response.statusCode}');
    }

    throw Exception('Upload completed but no file ID received');
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