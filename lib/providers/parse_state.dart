import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tieba_image_parser/utils/file_io.dart';
import 'package:tieba_image_parser/utils/tieba_proc.dart';
import 'dart:ui' as ui;

class ParseState extends ChangeNotifier {
  ValueNotifier<List<ui.Image>> images = ValueNotifier<List<ui.Image>>([]);
  ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  ValueNotifier<bool> canStop = ValueNotifier<bool>(false);
  ValueNotifier<String> urls = ValueNotifier<String>('');
  ValueNotifier<String> log = ValueNotifier<String>('');
  int currIndex = 0;
  final List<String> _imgUrls = [];
  final List<Uint8List> _imgBytes = [];

  Isolate? _isolate;
  ReceivePort? _receivePort;
  Completer<List<String>>? _isolateCompleter;

  @override
  void dispose() {
    disposeImages();
    super.dispose();
  }

  void disposeImages() {
    for (final image in images.value) {
      image.dispose();
    }
    images.value.clear();
    images.notifyListeners();
  }

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

      final imgFutures = imgUrls.map((url) async {
        final imageBytes = await FileIO.urlToBytes(url);
        Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(imageBytes, (image) {
          completer.complete(image);
        });
        images.value.add(await completer.future);
        _imgBytes.add(imageBytes);
        _imgUrls.add(url);
      }).toList();

      await Future.wait(imgFutures);
      urls.value = _imgUrls.join('\n');
      images.notifyListeners();
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
    disposeImages();
    images.notifyListeners();
    _imgUrls.clear();
    _imgBytes.clear();
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
    if (images.value.isEmpty) {
      throw Exception('No image to save');
    }
    return await _saveImage(
      _imgBytes[currIndex % images.value.length],
      _imgUrls[currIndex % _imgUrls.length],
    );
  }

  Future<String> saveAllImages() async {
    if (images.value.isEmpty) {
      throw Exception('No image to save');
    }

    final futures = images.value.map((image) async {
      final index = images.value.indexOf(image);
      return await _saveImage(_imgBytes[index % images.value.length],
          _imgUrls[index % _imgUrls.length]);
    }).toList();

    return await Future.wait(futures).then((value) => value.join('\n'));
  }

  Future<void> copyCurrentUrl() async {
    if (images.value.isEmpty) {
      throw Exception('No image to copy');
    }
    await FileIO.copyToClipboard(_imgUrls[currIndex % images.value.length]);
  }

  Future<void> _protector() async {
    return;
  }
}
