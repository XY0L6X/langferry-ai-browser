/// 全局文案常量管理
/// 统一管理所有公共文案，禁止页面内硬编码
class AppStrings {
  AppStrings._();
  
  // ==================== 应用信息 ====================
  static const String appName = 'WebLingo';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI翻译浏览器';
  
  // ==================== 导航栏 ====================
  static const String navBrowser = '浏览器';
  static const String navHistory = '历史';
  static const String navFavorites = '收藏';
  static const String navSettings = '设置';
  
  // ==================== 浏览器 ====================
  static const String urlHint = '输入网址或搜索';
  static const String newTab = '新标签页';
  static const String tabManage = '标签页管理';
  static const String newTabTooltip = '新建标签';
  static const String closeTabTooltip = '关闭标签';
  static const String translatePage = '翻译页面';
  static const String openHomePage = '输入网址开始浏览';
  
  // ==================== 翻译 ====================
  static const String translate = '翻译';
  static const String translating = '翻译中';
  static const String translateComplete = '翻译完成';
  static const String translateFailed = '翻译失败';
  static const String translateRetry = '重试';
  static const String translatedOnly = '仅译文';
  static const String bilingualMode = '原文译文对照';
  static const String selectModel = '选择模型';
  static const String sourceLanguage = '源语言';
  static const String targetLanguage = '目标语言';
  static const String autoDetect = '自动检测';
  static const String chinese = '中文';
  static const String english = '英文';
  
  // ==================== 划词翻译 ====================
  static const String copy = '复制';
  static const String collect = '收藏';
  static const String share = '分享';
  static const String copySuccess = '复制成功';
  static const String collectSuccess = '收藏成功';
  
  // ==================== 历史记录 ====================
  static const String historyTitle = '翻译历史';
  static const String searchHistory = '搜索历史记录';
  static const String noHistory = '暂无翻译历史';
  static const String noMatchHistory = '未找到匹配的记录';
  static const String clearAll = '清空历史';
  static const String clearAllConfirm = '确定要清空所有翻译历史吗？此操作不可撤销。';
  static const String batchManage = '批量管理';
  static const String selectedCount = '已选择 %d 项';
  static const String selectAll = '全选';
  static const String deselectAll = '取消全选';
  static const String delete = '删除';
  static const String cancel = '取消';
  static const String confirm = '确定';
  
  // 时间相关
  static const String justNow = '刚刚';
  static const String minutesAgo = '%d分钟前';
  static const String hoursAgo = '%d小时前';
  static const String daysAgo = '%d天前';
  static const String today = '今天';
  static const String yesterday = '昨天';
  static const String earlier = '更早';
  
  // ==================== 收藏夹 ====================
  static const String favoritesTitle = '我的收藏';
  static const String searchFavorites = '搜索收藏';
  static const String noFavorites = '暂无收藏';
  static const String noMatchFavorites = '未找到匹配的收藏';
  static const String allCategories = '全部';
  static const String gridView = '网格视图';
  static const String listView = '列表视图';
  static const String category = '分类';
  static const String rename = '重命名';
  static const String moveToCategory = '移动分类';
  
  // 默认分类
  static const String categoryTech = '技术';
  static const String categoryNews = '新闻';
  static const String categoryStudy = '学习';
  static const String categoryWork = '工作';
  static const String categoryEntertainment = '娱乐';
  static const String categoryOther = '其他';
  
  // ==================== 设置 ====================
  static const String settingsTitle = '设置';
  
  // API配置
  static const String apiConfig = 'API配置';
  static const String noApiConfig = '未配置API';
  static const String noApiConfigHint = '请先配置翻译API才能使用翻译功能';
  static const String addApiConfig = '添加API配置';
  static const String editApiConfig = '编辑API配置';
  static const String apiName = '名称';
  static const String apiEndpoint = 'API端点';
  static const String apiKey = 'API Key';
  static const String apiModel = '模型名称';
  static const String apiPresetTemplate = '选择预设模板';
  static const String apiTestConnection = '测试连接';
  static const String apiTestSuccess = '连接成功';
  static const String apiTestFailed = '连接失败';
  
  // 预设模型
  static const String presetDeepSeek = 'DeepSeek';
  static const String presetMimo = 'Mimo';
  static const String presetCustom = '自定义';
  
  // 翻译设置
  static const String translationSettings = '翻译设置';
  static const String defaultTargetLang = '默认目标语言';
  static const String translationMode = '翻译模式';
  static const String customPrompt = '自定义Prompt';
  static const String defaultPromptHint = '使用默认提示词';
  static const String restoreDefault = '恢复默认';
  
  // 外观设置
  static const String appearanceSettings = '外观设置';
  static const String themeMode = '主题模式';
  static const String lightMode = '浅色模式';
  static const String darkMode = '深色模式';
  static const String systemMode = '跟随系统';
  static const String fontSize = '字体大小';
  static const String fontSizeSmall = '小';
  static const String fontSizeMedium = '中';
  static const String fontSizeLarge = '大';
  static const String translateTextColor = '译文颜色';
  static const String followTheme = '跟随主题';
  
  // 数据管理
  static const String dataManagement = '数据管理';
  static const String exportData = '导出数据';
  static const String exportDataHint = '导出配置、历史、收藏为JSON';
  static const String importData = '导入数据';
  static const String importDataHint = '从JSON文件导入数据';
  static const String clearCache = '清除缓存';
  static const String clearCacheHint = '清除翻译缓存';
  static const String clearCacheConfirm = '确定要清除翻译缓存吗？';
  static const String clearCacheSuccess = '缓存已清除';
  
  // 关于
  static const String about = '关于';
  static const String version = '版本';
  static const String checkUpdate = '检查更新';
  static const String usageGuide = '使用说明';
  static const String openSource = '开源地址';
  static const String feedback = '反馈渠道';
  
  // ==================== 错误信息 ====================
  static const String errorNetwork = '网络连接失败，请检查网络设置';
  static const String errorApi = 'API调用失败，请检查配置';
  static const String errorUnknown = '未知错误，请重试';
  static const String retry = '重试';
  
  // ==================== 通用 ====================
  static const String loading = '加载中';
  static const String noData = '暂无数据';
  static const String save = '保存';
  static const String edit = '编辑';
  static const String done = '完成';
  static const String back = '返回';
  static const String exitConfirm = '再按一次退出';
  
  // ==================== 存储Key ====================
  static const String translationCache = 'translation_cache';
  
  // ==================== Hive Box Names (ASCII) ====================
  static const String boxApiConfigs = 'api_configs';
  static const String boxHistory = 'history';
  static const String boxFavorites = 'favorites';
  static const String boxSettings = 'settings';
  static const String boxTranslationCache = 'translation_cache';
}