import 'dart:io';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class FileIO {
  static String get albumName => 'tieba_parsed';
  static String get tempDirName => 'tieba_parsed_temp';

  static Future<String> saveImage(Uint8List bytes, String fileName) async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final requestGranted = await Gal.requestAccess(toAlbum: true);
      if (!requestGranted) {
        throw Exception('Permission denied');
      }
    }
    final path = await createTempFile(bytes, fileName);
    await Gal.putImage(path, album: albumName);
    deleteFile(path);
    return '$albumName/$fileName';
  }

  static Future<String> createTempFile(Uint8List bytes, String fileName) async {
    await createCacheDir();
    final file =
        await File('${Directory.systemTemp.path}/$tempDirName/$fileName')
            .create();
    await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    return file.path;
  }

  static Future<void> createCacheDir() async {
    final dir = Directory('${Directory.systemTemp.path}/$tempDirName');
    if (!dir.existsSync()) {
      await dir.create();
    }
  }

  static Future<void> clearCache() async {
    final dir = Directory('${Directory.systemTemp.path}/$tempDirName');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  static Future<Uint8List> fileToBytes(File file) async {
    return await file.readAsBytes();
  }

  static Future<Uint8List> assetToBytes(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    return data.buffer.asUint8List();
  }

  static Future<Uint8List> urlToBytes(String url) async {
    final http.Response response = await http
        .get(Uri.parse('https://api.uyanide.com/proxy/?url=$url'))
        .timeout(const Duration(seconds: 20), onTimeout: () {
      throw Exception('Request timed out');
    });
    if (response.statusCode != 200) {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  static Future<String> getMimeTypeFromUrl(String url) async {
    final http.Response response = await http
        .head(Uri.parse(url))
        .timeout(const Duration(seconds: 20), onTimeout: () {
      throw Exception('Request timed out');
    });
    if (response.statusCode != 200) {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
    final mimeType = response.headers['content-type'];
    if (mimeType == null) {
      throw Exception('Could not determine MIME type');
    }
    return mimeType;
  }

  static String? getMimeTypeFromPath(String path) {
    return lookupMimeType(path);
  }

  static String? getExtNameFromMimeType(String mimeType) {
    return extensionFromMime(mimeType);
  }

  static Future<void> copyToClipboard(String text) async {
    return await Clipboard.setData(ClipboardData(text: text));
  }
}
