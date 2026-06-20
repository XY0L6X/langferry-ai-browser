import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/translation_provider.dart';
import '../../../models/api_config.dart';

/// API配置子页面
class ApiConfigPage extends ConsumerStatefulWidget {
  final ApiConfig? initialConfig;

  const ApiConfigPage({
    super.key,
    this.initialConfig,
  });

  @override
  ConsumerState<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends ConsumerState<ApiConfigPage> {
  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _promptController;
  
  bool _isTesting = false;
  bool _testSuccess = false;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialConfig?.name ?? '');
    _endpointController = TextEditingController(text: widget.initialConfig?.endpoint ?? '');
    _apiKeyController = TextEditingController(text: widget.initialConfig?.apiKey ?? '');
    _modelController = TextEditingController(text: widget.initialConfig?.model ?? '');
    _promptController = TextEditingController(text: widget.initialConfig?.systemPrompt ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewConfig = widget.initialConfig == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewConfig ? AppStrings.addApiConfig : AppStrings.editApiConfig),
        actions: [
          if (!isNewConfig)
            IconButton(
              onPressed: _deleteConfig,
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预设模板选择
            _buildPresetSection(theme),
            
            const SizedBox(height: AppDimens.spacing24),
            
            // API配置输入
            _buildConfigSection(theme),
            
            const SizedBox(height: AppDimens.spacing24),
            
            // 自定义Prompt
            _buildPromptSection(theme),
            
            const SizedBox(height: AppDimens.spacing24),
            
            // 测试连接按钮
            _buildTestButton(theme),
            
            const SizedBox(height: AppDimens.spacing16),
            
            // 保存按钮
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  /// 预设模板选择
  Widget _buildPresetSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.apiPresetTemplate,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.spacing16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                hintText: '选择预设模板',
              ),
              items: const [
                DropdownMenuItem(
                  value: '',
                  child: Text('自定义'),
                ),
                DropdownMenuItem(
                  value: 'deepseek-flash',
                  child: Text('DeepSeek V4 Flash'),
                ),
                DropdownMenuItem(
                  value: 'deepseek-pro',
                  child: Text('DeepSeek V4 Pro'),
                ),
                DropdownMenuItem(
                  value: 'mimo-flash',
                  child: Text('Mimo V2 Flash'),
                ),
                DropdownMenuItem(
                  value: 'mimo-omni',
                  child: Text('Mimo V2 Omni'),
                ),
              ],
              onChanged: (value) {
                _applyPreset(value ?? '');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 应用预设模板
  void _applyPreset(String preset) {
    switch (preset) {
      case 'deepseek-flash':
        _nameController.text = AppStrings.presetDeepSeek;
        _endpointController.text = 'https://api.deepseek.com';
        _modelController.text = 'deepseek-v4-flash';
        break;
      case 'deepseek-pro':
        _nameController.text = AppStrings.presetDeepSeek;
        _endpointController.text = 'https://api.deepseek.com';
        _modelController.text = 'deepseek-v4-pro';
        break;
      case 'mimo-flash':
        _nameController.text = AppStrings.presetMimo;
        _endpointController.text = 'https://api.mimo.ai';
        _modelController.text = 'mimo-v2-flash';
        break;
      case 'mimo-omni':
        _nameController.text = AppStrings.presetMimo;
        _endpointController.text = 'https://api.mimo.ai';
        _modelController.text = 'mimo-v2-omni';
        break;
      default:
        break;
    }
  }

  /// API配置输入
  Widget _buildConfigSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API配置',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.spacing16),
            
            // 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.apiName,
                hintText: '如：DeepSeek',
              ),
            ),
            const SizedBox(height: AppDimens.spacing16),
            
            // API端点
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: AppStrings.apiEndpoint,
                hintText: 'https://api.deepseek.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppDimens.spacing16),
            
            // API Key
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: AppStrings.apiKey,
                hintText: 'sk-...',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showApiKey = !_showApiKey;
                    });
                  },
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              obscureText: !_showApiKey,
            ),
            const SizedBox(height: AppDimens.spacing16),
            
            // 模型名称
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: AppStrings.apiModel,
                hintText: 'deepseek-chat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 自定义Prompt
  Widget _buildPromptSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.customPrompt,
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    _promptController.clear();
                  },
                  child: const Text(AppStrings.restoreDefault),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacing8),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: '你是一个专业的网页翻译助手...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  /// 测试连接按钮
  Widget _buildTestButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isTesting ? null : _testConnection,
        icon: _isTesting
            ? const SizedBox(
                width: AppDimens.iconSizeSmall,
                height: AppDimens.iconSizeSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _testSuccess ? Icons.check_circle : Icons.wifi_find,
                color: _testSuccess ? Colors.green : null,
              ),
        label: Text(
          _isTesting
              ? '测试中...'
              : _testSuccess
                  ? AppStrings.apiTestSuccess
                  : AppStrings.apiTestConnection,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.spacing12,
          ),
        ),
      ),
    );
  }

  /// 测试连接
  Future<void> _testConnection() async {
    if (_endpointController.text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写API端点和API Key')),
      );
      return;
    }

    final theme = Theme.of(context);
    
    setState(() {
      _isTesting = true;
      _testSuccess = false;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final config = ApiConfig(
        name: _nameController.text,
        endpoint: _endpointController.text,
        apiKey: _apiKeyController.text,
        model: _modelController.text,
      );
      
      final result = await apiClient.testConnection(config);
      
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = result.success;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? '连接成功: ${result.response}' : '连接失败: ${result.message}'),
            backgroundColor: result.success ? null : theme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
        });
        String errorMsg = '测试失败';
        if (e.toString().contains('401')) {
          errorMsg = 'API Key无效，请检查';
        } else if (e.toString().contains('404')) {
          errorMsg = 'API端点错误，请检查URL';
        } else if (e.toString().contains('SocketException')) {
          errorMsg = '网络连接失败';
        } else {
          final errStr = e.toString();
          errorMsg = errStr.length > 100 ? '测试失败: ${errStr.substring(0, 100)}...' : '测试失败: $errStr';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 保存按钮
  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saveConfig,
        child: const Text(AppStrings.save),
      ),
    );
  }

  /// 保存配置
  void _saveConfig() {
    if (_nameController.text.isEmpty ||
        _endpointController.text.isEmpty ||
        _apiKeyController.text.isEmpty ||
        _modelController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有必填项')),
      );
      return;
    }

    final config = ApiConfig(
      name: _nameController.text,
      endpoint: _endpointController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      systemPrompt: _promptController.text.isEmpty ? null : _promptController.text,
      isActive: true,
    );

    if (widget.initialConfig != null) {
      ref.read(apiConfigsProvider.notifier).updateConfig(config);
    } else {
      ref.read(apiConfigsProvider.notifier).addConfig(config);
    }
    
    // 自动激活此配置
    ref.read(apiConfigsProvider.notifier).setActive(_nameController.text);

    Navigator.pop(context);
  }

  /// 删除配置
  void _deleteConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text('确定要删除此API配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(apiConfigsProvider.notifier).deleteConfig(
                widget.initialConfig!.name,
              );
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}