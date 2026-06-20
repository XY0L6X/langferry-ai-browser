import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';

/// 快捷链接数据模型
class QuickLink {
  final String id;
  final String name;
  final String url;
  final String icon;
  final DateTime createdAt;

  QuickLink({
    required this.id,
    required this.name,
    required this.url,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };

  factory QuickLink.fromJson(Map<String, dynamic> json) => QuickLink(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    icon: json['icon'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class HomePage extends StatefulWidget {
  final ValueChanged<String> onUrlSelected;
  final ValueChanged<String> onSearchSubmitted;

  const HomePage({
    super.key,
    required this.onUrlSelected,
    required this.onSearchSubmitted,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<QuickLink> _quickLinks = [];
  late Box _box;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuickLinks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadQuickLinks() {
    _box = Hive.box('settings');
    final saved = _box.get('quick_links', defaultValue: <dynamic>[]);
    setState(() {
      _quickLinks = (saved as List).map((e) => QuickLink.fromJson(Map<String, dynamic>.from(e))).toList();
    });
  }

  void _saveQuickLinks() {
    _box.put('quick_links', _quickLinks.map((e) => e.toJson()).toList());
  }

  void _addQuickLink() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加快捷方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '如：GitHub',
              ),
            ),
            const SizedBox(height: AppDimens.spacing12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '网址',
                hintText: 'https://github.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final link = QuickLink(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  url: urlController.text.startsWith('http')
                      ? urlController.text
                      : 'https://${urlController.text}',
                  icon: _getIconForUrl(urlController.text),
                  createdAt: DateTime.now(),
                );
                setState(() {
                  _quickLinks.insert(0, link);
                });
                _saveQuickLinks();
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _deleteQuickLink(String id) {
    setState(() {
      _quickLinks.removeWhere((link) => link.id == id);
    });
    _saveQuickLinks();
  }

  String _getIconForUrl(String url) {
    if (url.contains('github')) return 'github';
    if (url.contains('youtube')) return 'youtube';
    if (url.contains('google')) return 'google';
    if (url.contains('twitter') || url.contains('x.com')) return 'twitter';
    if (url.contains('bilibili')) return 'bilibili';
    if (url.contains('zhihu')) return 'zhihu';
    return 'website';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 6 : (screenWidth > 500 ? 4 : 3);

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.spacing32,
            AppDimens.spacing48,
            AppDimens.spacing32,
            AppDimens.spacing32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppDimens.spacing16),
                  Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索网页',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spacing12,
                        ),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          widget.onSearchSubmitted(value);
                        }
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: IconButton(
                      onPressed: () {
                        final text = _searchController.text;
                        if (text.isNotEmpty) {
                          widget.onSearchSubmitted(text);
                        }
                      },
                      icon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 快捷链接网格
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacing32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1,
                  crossAxisSpacing: AppDimens.spacing16,
                  mainAxisSpacing: AppDimens.spacing16,
                ),
                itemCount: _quickLinks.length + 1,
                itemBuilder: (context, index) {
                  if (index == _quickLinks.length) {
                    // 添加按钮
                    return _buildAddButton(theme);
                  }
                  return _buildQuickLinkItem(
                    _quickLinks[index],
                    theme,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return InkWell(
      onTap: _addQuickLink,
      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            ),
            child: Icon(
              Icons.add,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.spacing8),
          Text(
            '添加快捷方式',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkItem(QuickLink link, ThemeData theme) {
    return InkWell(
      onTap: () => widget.onUrlSelected(link.url),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(link.name),
            content: Text(link.url),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  _deleteQuickLink(link.id);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
            ),
            child: Center(
              child: Text(
                link.name.isNotEmpty ? link.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacing8),
          Text(
            link.name,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}