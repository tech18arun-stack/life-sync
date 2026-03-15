import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUpdaterDialog extends StatefulWidget {
  final String downloadUrl;
  final String latestVersion;
  final String releaseNotes;
  final bool forceUpdate;

  const AppUpdaterDialog({
    super.key,
    required this.downloadUrl,
    required this.latestVersion,
    this.releaseNotes = '',
    this.forceUpdate = false,
  });

  @override
  AppUpdaterDialogState createState() => AppUpdaterDialogState();
}

class AppUpdaterDialogState extends State<AppUpdaterDialog> {
  final Dio _dio = Dio();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Starting download...';
    });

    try {
      // 1. Request Storage / Install Permissions
      if (Platform.isAndroid) {
        final installStatus = await Permission.requestInstallPackages.request();
        if (installStatus != PermissionStatus.granted) {
          setState(() {
            _isDownloading = false;
            _statusText =
                'Install permission denied. Please enable in settings.';
          });
          return;
        }
      }

      // 2. Get the download directory
      final tempDir = await getTemporaryDirectory();
      final String savePath =
          '${tempDir.path}/app-update-v${widget.latestVersion}.apk';

      // 3. Download the file
      await _dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
              _statusText =
                  'Downloading: ${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB...';
            });
          }
        },
      );

      // 4. Download complete, start installation
      setState(() {
        _statusText = 'Download complete. Starting installation...';
      });

      final result = await OpenFilex.open(savePath);

      if (result.type != ResultType.done) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Error opening APK: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = 'Download failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forceUpdate && !_isDownloading,
      child: AlertDialog(
        title: Text(
          'Update Available',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${widget.latestVersion} is available.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (widget.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'What\'s New:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.releaseNotes),
            ],
            const SizedBox(height: 20),
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (!_isDownloading && _statusText.isNotEmpty) ...[
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.forceUpdate && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Update Later'),
            ),
          if (!_isDownloading)
            ElevatedButton(
              onPressed: _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Download & Install'),
            ),
        ],
      ),
    );
  }
}
