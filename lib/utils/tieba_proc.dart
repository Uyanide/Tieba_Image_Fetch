import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:tieba_image_parser/utils/web_io.dart';

class TiebaOrigImageParser {
  late final String _threadUrl;
  late final String _threadId;
  late final String _channelName;
  late final int _pageNumber;
  String? _threadAuthor;

  final List<String> _detailUrls = [];
  late List<List<String>> _detailUrlsGroup;
  final List<String> _picUrls = [];

  late final Function(String) _logCallback;

  final Completer<void> _completer = Completer();

  TiebaOrigImageParser({
    required String input,
    required Function(String) logCallback,
  }) : _logCallback = logCallback {
    _parseInput(input);
    _fetchThreadPages().catchError((e) {
      _log('Parser failed: $e', isError: true);
      _completer.completeError(e);
    });
  }

  Future<List<String>> getResults() async {
    await _completer.future;
    return _picUrls;
  }

  @pragma('vm:prefer-inline')
  void _log(String msg, {bool isError = false}) {
    _logCallback('${isError ? ' ERROR ' : ' INFO '}: $msg');
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
    _log('Fetching first page...');
    var doc = await _fetchPage(_threadUrl);
    _log('Parsing thread info...');
    _parsePageNumber(doc);
    _parseChannelName(doc);

    _detailUrlsGroup = List.generate(_pageNumber, (_) => <String>[]);
    final futures = <Future<void>>[];

    for (var pn = 1; pn <= _pageNumber; pn++) {
      final completer = Completer<void>();
      if (pn != 1) {
        _log('Fetching page $pn...');
        _fetchPage('$_threadUrl?pn=$pn').then((doc) {
          _log('Parsing page $pn...');
          _parsePage(doc, pn);
          completer.complete();
        }).catchError((e) {
          _log('Failed to fetch page $pn: $e', isError: true);
          completer.completeError(e);
        });
      } else {
        _log('Parsing page $pn...');
        _parsePage(doc, pn);
        completer.complete();
      }
      futures.add(completer.future);
    }

    await Future.wait(futures);
    _detailUrls.addAll(_detailUrlsGroup.expand((e) => e));

    _log('Fetching ${_detailUrls.length} detail pages...');
    await _fetchDetailPages();

    _log('Parsing completed, ${_picUrls.length} images found.');
    _completer.complete();
  }

  Future<Document> _fetchPage(String url) async {
    final bytes = await WebIO.get(url);

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
    _log('Total pages: $_pageNumber');
  }

  void _parseChannelName(Document doc) {
    final channelNameContainer = doc.querySelector('.card_title_fname');
    if (channelNameContainer == null) {
      throw Exception('Failed to parse channel name');
    }
    _channelName = channelNameContainer.text.trim().replaceFirst('吧', '');
    _log('Channel name: $_channelName');
  }

  void _parsePage(Document doc, [int pageNumber = 1]) {
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
        _detailUrlsGroup[pageNumber - 1]
            .add(_generateDetailUrl(author, postId, picId));
        imageCount++;
      }

      _log('Post parsed: id: $postId');
      _log('Images found in the post: $imageCount, author: $author');
    }
  }

  Future<void> _fetchDetailPages() async {
    final futures = <Future<void>>[];
    final picUrls = List.filled(_detailUrls.length, '');
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
        picUrls[_detailUrls.indexOf(url)] = picUrl;
        completer.complete();
      }).catchError((e) {
        _log('Failed to fetch detail page: $e', isError: true);
        completer.complete();
      });
    }
    await Future.wait(futures);
    _picUrls.addAll(picUrls);
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
