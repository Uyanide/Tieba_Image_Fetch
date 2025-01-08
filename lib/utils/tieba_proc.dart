import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;

class TiebaOrigImageParser {
  late final String _threadUrl;
  late final String _threadId;
  late final String _channelName;
  late final int _pageNumber;
  String? _threadAuthor;

  final List<String> _detailUrls = [];
  final List<String> _picUrls = [];

  late final Function(String) _logCallback;

  final Completer<void> _completer = Completer();

  TiebaOrigImageParser({
    required String input,
    required Function(String) logCallback,
  }) : _logCallback = logCallback {
    _parseInput(input);
    _fetchThreadPages().catchError((e) {
      _completer.completeError(e);
    });
  }

  Future<List<String>> getResults() async {
    await _completer.future;
    return _picUrls;
  }

  @pragma('vm:prefer-inline')
  void _log(String msg) {
    _logCallback('- TiebaOrigImageParser: $msg');
  }

  void _parseInput(String input) {
    if (input.startsWith('http') || input.startsWith('tieba')) {
      _threadId = input.split('?')[0].split('/').last;
    } else if (int.tryParse(input) != null) {
      _threadId = input;
    } else {
      throw Exception('Invalid input');
    }
    _threadUrl = 'https://tieba.baidu.com/p/$_threadId';
    _log('Thread URL: $_threadUrl');
    _log('Thread ID: $_threadId');
  }

  Future<void> _fetchThreadPages() async {
    var doc = await _fetchPage(_threadUrl);
    _parsePageNumber(doc);
    _parseChannelName(doc);

    for (var pn = 1; pn <= _pageNumber; pn++) {
      if (pn != 1) {
        try {
          doc = await _fetchPage('$_threadUrl?pn=$pn');
        } catch (e) {
          _log('Failed to fetch page $pn: $e, skipping');
          continue;
        }
      }
      _parsePage(doc);
    }

    await _fetchDetailPages();

    _completer.complete();
  }

  Future<Document> _fetchPage(String url) async {
    _log('Fetching page: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
      },
    ).timeout(const Duration(seconds: 20), onTimeout: () {
      throw Exception('Request timed out');
    });
    final bytes = response.bodyBytes;

    Document doc = parse(String.fromCharCodes(bytes));

    final meta = doc.querySelector('meta[charset]');
    String encoding = 'utf-8';
    if (meta != null) {
      encoding = meta.attributes['charset']?.toLowerCase() ?? 'utf-8';
    } else {
      // tieba pages never set charset in http-equiv meta tag though
      final metaContent = doc.querySelector('meta[http-equiv="Content-Type"]');
      if (metaContent != null) {
        final content = metaContent.attributes['content']?.toLowerCase() ?? '';
        final match = RegExp(r'charset=([^\s;]+)').firstMatch(content);
        if (match != null) {
          encoding = match.group(1) ?? 'utf-8';
        }
      }
    }

    switch (encoding) {
      case 'utf-8':
        doc = parse(utf8.decode(bytes));
        break;
      case 'gbk':
        // luckily non-ascii characters will never be needed in any GBK page.
        // until now, at least.
        break;
      default:
        break;
    }

    _log('Fetched page: $url');
    return doc;
  }

  void _parsePageNumber(Document doc) {
    final pageNumContainer = doc.querySelector('.l_reply_num');
    if (pageNumContainer == null) {
      throw Exception('Failed to parse page number');
    }
    final pageNumSpans = pageNumContainer.querySelectorAll('.red');
    if (pageNumSpans.length != 2) {
      throw Exception('Failed to parse page number');
    }
    final pageNum = int.tryParse(pageNumSpans[1].text.trim());
    if (pageNum == null) {
      throw Exception('Failed to parse page number');
    }
    _pageNumber = pageNum;
    _log('Page number: $_pageNumber');
  }

  void _parseChannelName(Document doc) {
    final channelNameContainer = doc.querySelector('.card_title_fname');
    if (channelNameContainer == null) {
      throw Exception('Failed to parse channel name');
    }
    _channelName = channelNameContainer.text.trim().replaceFirst('吧', '');
    _log('Channel name: $_channelName');
  }

  void _parsePage(Document doc) {
    final posts = doc.querySelectorAll('.l_post');
    for (final post in posts) {
      final postId = post.attributes['data-pid'];
      if (postId == null) {
        continue;
      }
      final author = post.querySelector('.p_author_name')?.text;
      if (author == null) {
        continue;
      }
      _threadAuthor ??= author;

      var imageCount = 0;
      for (final img in post.querySelectorAll('.BDE_Image')) {
        final src = img.attributes['src'];
        if (src == null) {
          continue;
        }
        final picId = src.split('/').last.split('.').first;
        _detailUrls.add(_generateDetailUrl(author, postId, picId));
        imageCount++;
      }

      _log(
          'Post parsed: postId=$postId, imageCount=$imageCount, author=$author');
    }
  }

  Future<void> _fetchDetailPages() async {
    final futures = <Future<void>>[];
    for (final url in _detailUrls) {
      Completer<void> completer = Completer();
      futures.add(completer.future);
      _fetchPage(url).then((Document doc) {
        final waterurlIndex = doc.outerHtml.indexOf('waterurl');
        if (waterurlIndex == -1) {
          completer.complete();
          return;
        }
        final picUrl =
            doc.outerHtml.substring(waterurlIndex + 11).split('"')[0];
        _picUrls.add(picUrl);
        completer.complete();
      }).catchError((e) {
        _log('Failed to fetch detail page: $e');
        completer.complete();
      });
    }
    await Future.wait(futures);
  }

  @pragma('vm:prefer-inline')
  String _generateDetailUrl(String author, String postId, String picId) {
    // return ('https://tieba.baidu.com/photo/p?kw=$_channelName&flux=1&tid=$_threadId&pic_id=$picId&pn=1&fp=2&see_lz=${author == _threadAuthor! ? '1' : '0'}&post_id=$postId');
    return Uri.https('tieba.baidu.com', '/photo/p', {
      'kw': _channelName,
      'flux': '1',
      'tid': _threadId,
      'pic_id': picId,
      'pn': '1',
      'fp': '2',
      'see_lz': author == _threadAuthor! ? '1' : '0',
      'post_id': postId,
    }).toString();
  }
}
