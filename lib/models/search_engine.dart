/// 搜索引擎模型
class SearchEngine {
  final String id;
  final String name;
  final String icon;  // emoji or icon character
  final String searchUrl;  // {query} 将被替换为搜索关键词

  const SearchEngine({
    required this.id,
    required this.name,
    required this.icon,
    required this.searchUrl,
  });

  /// 构建搜索 URL
  String buildUrl(String query) {
    return searchUrl.replaceAll('{query}', Uri.encodeComponent(query));
  }

  /// 预设搜索引擎列表
  static const List<SearchEngine> presets = [
    SearchEngine(
      id: 'google',
      name: 'Google',
      icon: '🔍',
      searchUrl: 'https://www.google.com/search?q={query}',
    ),
    SearchEngine(
      id: 'baidu',
      name: '百度',
      icon: '🐾',
      searchUrl: 'https://www.baidu.com/s?wd={query}',
    ),
    SearchEngine(
      id: 'bing',
      name: '必应',
      icon: '🔎',
      searchUrl: 'https://www.bing.com/search?q={query}',
    ),
    SearchEngine(
      id: 'sogou',
      name: '搜狗',
      icon: '🐕',
      searchUrl: 'https://www.sogou.com/web?query={query}',
    ),
    SearchEngine(
      id: '360',
      name: '360搜索',
      icon: '🔄',
      searchUrl: 'https://www.so.com/s?q={query}',
    ),
    SearchEngine(
      id: 'duckduckgo',
      name: 'DuckDuckGo',
      icon: '🦆',
      searchUrl: 'https://duckduckgo.com/?q={query}',
    ),
    SearchEngine(
      id: 'metaso',
      name: '秘塔',
      icon: '🗼',
      searchUrl: 'https://metaso.cn/?q={query}',
    ),
    SearchEngine(
      id: 'quark',
      name: '夸克',
      icon: '⚛️',
      searchUrl: 'https://quark.sm.cn/s?q={query}',
    ),
    SearchEngine(
      id: 'yahoo',
      name: 'Yahoo',
      icon: '🅈',
      searchUrl: 'https://search.yahoo.com/search?p={query}',
    ),
    SearchEngine(
      id: 'yandex',
      name: 'Yandex',
      icon: '🇷🇺',
      searchUrl: 'https://yandex.com/search/?text={query}',
    ),
  ];

  /// 根据 id 查找搜索引擎
  static SearchEngine findById(String id) {
    return presets.firstWhere(
      (e) => e.id == id,
      orElse: () => presets.first,
    );
  }
}
