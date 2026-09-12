import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'youtube_search_url.dart';

Widget buildYoutubeSearchFrame(String query) {
  return _YoutubeSearchWebView(query: query);
}

class _YoutubeSearchWebView extends StatefulWidget {
  const _YoutubeSearchWebView({required this.query});

  final String query;

  @override
  State<_YoutubeSearchWebView> createState() => _YoutubeSearchWebViewState();
}

class _YoutubeSearchWebViewState extends State<_YoutubeSearchWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..loadRequest(Uri.parse(youtubeSearchEmbedUrl(widget.query)));

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
