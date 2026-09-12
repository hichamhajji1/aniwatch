String youtubeSearchEmbedUrl(String query) {
  final encoded = Uri.encodeQueryComponent('$query official trailer');
  return 'https://www.youtube.com/embed?listType=search&list=$encoded';
}
