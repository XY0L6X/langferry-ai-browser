import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/database_provider.dart';
import '../../models/favorite_item.dart';

/// 收藏夹页面
class FavoritePage extends ConsumerStatefulWidget {
  final ValueChanged<String>? onUrlSelected;
  
  const FavoritePage({
    super.key,
    this.onUrlSelected,
  });

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取过滤后的收藏
  List<FavoriteItem> _getFilteredFavorites(List<FavoriteItem> favorites) {
    var filtered = favorites;
    
    // 按分类过滤
    if (_selectedCategory != null && _selectedCategory != AppStrings.allCategories) {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }
    
    // 按搜索词过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.url.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider);
    final filteredFavorites = _getFilteredFavorites(favorites);
    final categories = ref.read(favoritesProvider.notifier).getAllCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.favoritesTitle),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            tooltip: _isGridView ? AppStrings.listView : AppStrings.gridView,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(AppDimens.spacing16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchFavorites,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 分类标签
          if (categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacing16,
                ),
                children: [
                  _CategoryChip(
                    label: AppStrings.allCategories,
                    isSelected: _selectedCategory == null || _selectedCategory == AppStrings.allCategories,
                    onTap: () {
                      setState(() {
                        _selectedCategory = AppStrings.allCategories;
                      });
                    },
                  ),
                  const SizedBox(width: AppDimens.spacing8),
                  ...categories.map((category) => Padding(
                    padding: const EdgeInsets.only(
                      right: AppDimens.spacing8,
                    ),
                    child: _CategoryChip(
                      label: category,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  )),
                ],
              ),
            ),
          
          const SizedBox(height: AppDimens.spacing8),
          
          // 收藏列表
          Expanded(
            child: filteredFavorites.isEmpty
                ? _buildEmptyState(theme)
                : _isGridView
                    ? _buildGridView(filteredFavorites, theme)
                    : _buildListView(filteredFavorites, theme),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimens.spacing16),
          Text(
            _searchQuery.isEmpty ? AppStrings.noFavorites : AppStrings.noMatchFavorites,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 网格视图
  Widget _buildGridView(List<FavoriteItem> favorites, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimens.spacing16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppDimens.spacing8,
        mainAxisSpacing: AppDimens.spacing8,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        return _FavoriteGridItem(
          item: item,
          onTap: () {
            // 打开网页
            if (widget.onUrlSelected != null && item.url.isNotEmpty) {
              widget.onUrlSelected!(item.url);
            }
          },
          onLongPress: () {
            _showEditMenu(item);
          },
          onDelete: () async {
            await ref.read(favoritesProvider.notifier).deleteFavorite(item.id);
          },
        );
      },
    );
  }

  /// 列表视图
  Widget _buildListView(List<FavoriteItem> favorites, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacing16,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        return _FavoriteListItem(
          item: item,
          onTap: () {
            // 打开网页
            if (widget.onUrlSelected != null && item.url.isNotEmpty) {
              widget.onUrlSelected!(item.url);
            }
          },
          onLongPress: () {
            _showEditMenu(item);
          },
          onDelete: () async {
            await ref.read(favoritesProvider.notifier).deleteFavorite(item.id);
          },
        );
      },
    );
  }

  void _showEditMenu(FavoriteItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _EditMenuSheet(
        item: item,
        onRename: (newTitle) {
          ref.read(favoritesProvider.notifier).updateFavorite(
            item.copyWith(title: newTitle),
          );
        },
        onMoveCategory: (category) {
          ref.read(favoritesProvider.notifier).updateFavorite(
            item.copyWith(category: category),
          );
        },
        onDelete: () {
          ref.read(favoritesProvider.notifier).deleteFavorite(item.id);
        },
      ),
    );
  }
}

/// 分类标签
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap,
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 收藏网格项
class _FavoriteGridItem extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _FavoriteGridItem({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图或图标
            Expanded(
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                child: item.thumbnail != null
                    ? Image.network(
                        item.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.language,
                            size: AppDimens.iconSizeLarge,
                          );
                        },
                      )
                    : const Icon(
                        Icons.language,
                        size: AppDimens.iconSizeLarge,
                      ),
              ),
            ),
            
            // 信息
            Padding(
              padding: const EdgeInsets.all(AppDimens.spacing8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacing4),
                  Text(
                    item.domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 收藏列表项
class _FavoriteListItem extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _FavoriteListItem({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(
        bottom: AppDimens.spacing8,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spacing12),
          child: Row(
            children: [
              // 缩略图或图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                ),
                child: item.thumbnail != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                        child: Image.network(
                          item.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.language,
                              size: AppDimens.iconSizeMedium,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.language,
                        size: AppDimens.iconSizeMedium,
                      ),
              ),
              
              const SizedBox(width: AppDimens.spacing12),
              
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.spacing8,
                              vertical: AppDimens.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimens.radiusButton),
                            ),
                            child: Text(
                              item.category!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimens.spacing8),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.spacing4),
                    Text(
                      item.domain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppDimens.spacing4),
                    Text(
                      item.formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 删除按钮
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: AppDimens.iconSizeSmall,
                ),
                tooltip: AppStrings.delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 编辑菜单底部弹窗
class _EditMenuSheet extends StatelessWidget {
  final FavoriteItem item;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onMoveCategory;
  final VoidCallback onDelete;

  const _EditMenuSheet({
    required this.item,
    required this.onRename,
    required this.onMoveCategory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacing16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text(AppStrings.rename),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text(AppStrings.moveToCategory),
            onTap: () {
              Navigator.pop(context);
              _showCategoryDialog(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              AppStrings.delete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: item.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.rename),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入新名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              onRename(controller.text);
              Navigator.pop(context);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.moveToCategory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FavoriteItem.defaultCategories.map((category) {
            return RadioListTile<String>(
              title: Text(category),
              value: category,
              groupValue: item.category,
              onChanged: (value) {
                if (value != null) {
                  onMoveCategory(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}