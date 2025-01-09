import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tieba_image_parser/utils/file_io.dart';
import 'package:tieba_image_parser/utils/tieba_proc.dart';
import 'dart:ui' as ui;

class ParseState extends ChangeNotifier {
  ValueNotifier<List<Uint8List>> imgBytes = ValueNotifier<List<Uint8List>>([]);
  ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> canStop = ValueNotifier<bool>(false);
  ValueNotifier<String> urls = ValueNotifier<String>('');
  ValueNotifier<String> log = ValueNotifier<String>('');
  int currIndex = 0;
  final List<String> _imgUrls = [];

  Isolate? _isolate;
  ReceivePort? _receivePort;
  Completer<List<String>>? _isolateCompleter;

  Future<void> parse(String srcUrl) async {
    if (isLoading.value) return;
    try {
      if (srcUrl.isEmpty) return;
      await _protector();
      isLoading.value = true;

      clear();

      cancel();
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        parseAndSend,
        _receivePort!.sendPort,
      );

      canStop.value = true;

      _isolateCompleter = Completer();
      SendPort? sendPort;
      _receivePort!.listen((message) {
        if (sendPort == null) {
          sendPort = message as SendPort;
          sendPort!.send(srcUrl);
        } else if (message is Exception) {
          _isolateCompleter!.completeError(message);
        } else if (message is String) {
          log.value.isEmpty ? log.value = message : log.value += '\n$message';
        } else {
          _isolateCompleter!.complete(message as List<String>);
        }
      });

      final imgUrls = await _isolateCompleter!.future;
      _isolateCompleter = null;

      if (imgUrls.isEmpty) {
        return;
      }

      final tempImages = List<ui.Image?>.filled(imgUrls.length, null);
      final tempBytes = List<Uint8List?>.filled(imgUrls.length, null);
      final tempUrls = List<String?>.filled(imgUrls.length, null);

      final imgFutures = imgUrls.map((url) async {
        if (url.isEmpty) return;
        final imageBytes = await FileIO.urlToBytes(url);
        Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(imageBytes, (image) {
          completer.complete(image);
        });
        final index = imgUrls.indexOf(url);
        tempImages[index] = await completer.future;
        tempBytes[index] = imageBytes;
        tempUrls[index] = url;
      }).toList();

      await Future.wait(imgFutures);

      imgBytes.value
          .addAll(tempBytes.where((bytes) => bytes != null).cast<Uint8List>());
      _imgUrls.addAll(tempUrls.where((url) => url != null).cast<String>());

      urls.value = _imgUrls.join('\n');
      imgBytes.notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      cancel();
      isLoading.value = false;
    }
  }

  void cancel() {
    if (!canStop.value) return;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    if (_isolateCompleter != null && !_isolateCompleter!.isCompleted) {
      _isolateCompleter!.complete([]);
    }
    _isolateCompleter = null;
    canStop.value = false;
  }

  void clear() {
    _imgUrls.clear();
    imgBytes.value.clear();
    imgBytes.notifyListeners();
    urls.value = '';
    log.value = '';
  }

  static void parseAndSend(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final srcUrl = message as String;
      try {
        final imgUrls = await TiebaOrigImageParser(
          input: srcUrl,
          logCallback: (log) => sendPort.send(log),
        ).getResults();
        sendPort.send(imgUrls);
      } catch (e) {
        sendPort.send(e is Exception ? e : Exception(e.toString()));
      }
    });
  }

  // a little dumb. however, unfortunately there aren't any faster ways
  bool _isPng(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;
  }

  bool _isJpeg(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
  }

  bool _isWebp(Uint8List bytes) {
    return bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
  }

  Future<String> _saveImage(Uint8List bytes, String url) async {
    final fileName = 'tieba_parsed_${url.split('?')[0].split('/').last}';
    // basic type check
    if (_isPng(bytes)) {
      // is png, but not end with .png
      if (!fileName.endsWith('.png')) {
        return await FileIO.saveImage(bytes, '$fileName.png');
      }
    } else if (_isJpeg(bytes)) {
      // is jpg, but not end with .jpg
      if (!fileName.endsWith('.jpg') && !fileName.endsWith('.jpeg')) {
        return await FileIO.saveImage(bytes, '$fileName.jpg');
      }
    } else if (_isWebp(bytes)) {
      // is webp, but not end with .webp
      if (!fileName.endsWith('.webp')) {
        return await FileIO.saveImage(bytes, '$fileName.webp');
      }
    }
    return await FileIO.saveImage(bytes, fileName);
  }

  Future<String> saveCurrImage() async {
    if (imgBytes.value.isEmpty) {
      throw Exception('No image to save');
    }
    final bytes = imgBytes.value[currIndex % imgBytes.value.length];
    final url = _imgUrls[currIndex % _imgUrls.length];
    return await _saveImage(bytes, url);
  }

  Future<String> saveAllImages() async {
    if (imgBytes.value.isEmpty) {
      throw Exception('No image to save');
    }

    final futures = imgBytes.value.map((bytes) async {
      final index = imgBytes.value.indexOf(bytes);
      final url = _imgUrls[index % _imgUrls.length];
      return await _saveImage(bytes, url);
    }).toList();

    final results = await Future.wait(futures);
    return results.where((result) => result.isNotEmpty).join('\n');
  }

  Future<void> copyCurrentUrl() async {
    if (imgBytes.value.isEmpty) {
      throw Exception('No image to copy');
    }
    final url = _imgUrls[currIndex % _imgUrls.length];
    await FileIO.copyToClipboard(url);
  }

  Future<void> _protector() async {
    return;
  }
}
