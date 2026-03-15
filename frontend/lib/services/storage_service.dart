import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'appwrite_service.dart';

/// Storage Service for handling file uploads to Appwrite Storage
/// 
/// Used primarily for health record images and attachments.
/// 
/// Storage Configuration:
/// - Bucket: health-images
/// - Max file size: 5MB
/// - Allowed formats: png, jpg, jpeg, gif, webp
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final AppwriteService _appwrite = AppwriteService();

  /// Upload a file to the health-images bucket
  /// 
  /// Returns a map containing:
  /// - fileId: The Appwrite file ID
  /// - url: The file URL for viewing/downloading
  /// - path: The storage path
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    String? bucketId,
  }) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split(Platform.pathSeparator).last;
      
      // Create InputFile from path
      final inputFile = InputFile(
        path: filePath,
        filename: fileName,
      );

      final uploadedFile = await _appwrite.storage.createFile(
        bucketId: bucketId ?? AppwriteService.healthImagesBucket,
        fileId: ID.unique(),
        file: inputFile,
      );

      // Get the file URL
      final url = getFileUrl(
        fileId: uploadedFile.$id,
        bucketId: bucketId ?? AppwriteService.healthImagesBucket,
      );

      return {
        'fileId': uploadedFile.$id,
        'url': url,
        'path': '${AppwriteService.healthImagesBucket}/$fileName',
        'name': fileName,
        'size': uploadedFile.sizeOriginal,
        'mimeType': uploadedFile.mimeType,
      };
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload a file from bytes
  Future<Map<String, dynamic>> uploadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    String? bucketId,
  }) async {
    try {
      final inputFile = InputFile.fromBytes(
        bytes: bytes,
        filename: fileName,
      );

      final uploadedFile = await _appwrite.storage.createFile(
        bucketId: bucketId ?? AppwriteService.healthImagesBucket,
        fileId: ID.unique(),
        file: inputFile,
      );

      final url = getFileUrl(
        fileId: uploadedFile.$id,
        bucketId: bucketId ?? AppwriteService.healthImagesBucket,
      );

      return {
        'fileId': uploadedFile.$id,
        'url': url,
        'path': '${AppwriteService.healthImagesBucket}/$fileName',
        'name': fileName,
        'size': uploadedFile.sizeOriginal,
        'mimeType': uploadedFile.mimeType,
      };
    } catch (e) {
      debugPrint('Error uploading file from bytes: $e');
      rethrow;
    }
  }

  /// Pick and upload a file from device
  Future<Map<String, dynamic>?> pickAndUploadFile({
    String? bucketId,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: allowedExtensions ?? ['png', 'jpg', 'jpeg', 'gif', 'webp'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('No file path found');
      }

      return await uploadFile(filePath: filePath, bucketId: bucketId);
    } catch (e) {
      debugPrint('Error picking and uploading file: $e');
      rethrow;
    }
  }

  /// Upload multiple files
  Future<List<Map<String, dynamic>>> uploadMultipleFiles({
    required List<String> filePaths,
    String? bucketId,
  }) async {
    final uploadedFiles = <Map<String, dynamic>>[];

    for (final filePath in filePaths) {
      try {
        final result = await uploadFile(filePath: filePath, bucketId: bucketId);
        uploadedFiles.add(result);
      } catch (e) {
        debugPrint('Error uploading file $filePath: $e');
      }
    }

    return uploadedFiles;
  }

  /// Get file preview URL
  String getFileUrl({
    required String fileId,
    required String bucketId,
  }) {
    return _appwrite.storage.getFilePreview(
      bucketId: bucketId,
      fileId: fileId,
    ).toString();
  }

  /// Get file download URL
  String getFileDownloadUrl({
    required String fileId,
    required String bucketId,
  }) {
    return _appwrite.storage.getFileDownload(
      bucketId: bucketId,
      fileId: fileId,
    ).toString();
  }

  /// Delete a file
  Future<void> deleteFile({
    required String fileId,
    String? bucketId,
  }) async {
    try {
      await _appwrite.storage.deleteFile(
        bucketId: bucketId ?? AppwriteService.healthImagesBucket,
        fileId: fileId,
      );
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles({
    required List<String> fileIds,
    String? bucketId,
  }) async {
    for (final fileId in fileIds) {
      try {
        await deleteFile(fileId: fileId, bucketId: bucketId);
      } catch (e) {
        debugPrint('Error deleting file $fileId: $e');
      }
    }
  }

  /// Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata({
    required String fileId,
    String? bucketId,
  }) async {
    try {
      final file = await _appwrite.storage.getFile(
        bucketId: bucketId ?? AppwriteService.healthImagesBucket,
        fileId: fileId,
      );
      return {
        'id': file.$id,
        'name': file.name,
        'size': file.sizeOriginal,
        'mimeType': file.mimeType,
      };
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }
}
