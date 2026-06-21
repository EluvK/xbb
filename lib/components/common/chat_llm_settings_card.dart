import 'package:deepseek_client/deepseek_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/utils.dart';

class ChatLLMSettingsCard extends StatefulWidget {
  const ChatLLMSettingsCard({super.key});

  @override
  State<ChatLLMSettingsCard> createState() => _ChatLLMSettingsCardState();
}

class _ChatLLMSettingsCardState extends State<ChatLLMSettingsCard> {
  final settingController = Get.find<SettingController>();
  late ChatLLMProvider _chatProvider;
  late TextEditingController _chatBaseUrlController;
  late TextEditingController _chatModelController;
  late TextEditingController _chatApiKeyController;
  late TextEditingController _chatTemperatureController;
  bool _isFetchingChatModels = false;
  List<String> _chatModelCandidates = const [];

  void _onChatSettingsEdited() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _chatProvider = settingController.chatProvider;
    _chatBaseUrlController = TextEditingController(text: settingController.chatBaseUrl);
    _chatModelController = TextEditingController(text: settingController.chatModel);
    _chatApiKeyController = TextEditingController(text: settingController.chatApiKey ?? '');
    _chatTemperatureController = TextEditingController(text: settingController.chatTemperature.toString());
    _chatBaseUrlController.addListener(_onChatSettingsEdited);
    _chatModelController.addListener(_onChatSettingsEdited);
    _chatApiKeyController.addListener(_onChatSettingsEdited);
    _chatTemperatureController.addListener(_onChatSettingsEdited);
    _chatModelCandidates = settingController.chatModelCandidates;
    if (_chatModelController.text.trim().isNotEmpty &&
        !_chatModelCandidates.contains(_chatModelController.text.trim())) {
      _chatModelCandidates = [_chatModelController.text.trim(), ..._chatModelCandidates];
    }
  }

  @override
  void dispose() {
    _chatBaseUrlController.removeListener(_onChatSettingsEdited);
    _chatModelController.removeListener(_onChatSettingsEdited);
    _chatApiKeyController.removeListener(_onChatSettingsEdited);
    _chatTemperatureController.removeListener(_onChatSettingsEdited);
    _chatBaseUrlController.dispose();
    _chatModelController.dispose();
    _chatApiKeyController.dispose();
    _chatTemperatureController.dispose();
    super.dispose();
  }

  bool _hasPendingChatLLMChanges() {
    final providerChanged = _chatProvider != settingController.chatProvider;
    final baseUrlChanged = _chatBaseUrlController.text.trim() != settingController.chatBaseUrl;
    final modelChanged = _chatModelController.text.trim() != settingController.chatModel;
    final currentApiKey = _chatApiKeyController.text.trim();
    final normalizedApiKey = currentApiKey.isEmpty ? null : currentApiKey;
    final apiKeyChanged = normalizedApiKey != settingController.chatApiKey;
    final parsedTemperature = double.tryParse(_chatTemperatureController.text.trim());
    final temperatureChanged = parsedTemperature == null || parsedTemperature != settingController.chatTemperature;
    return providerChanged || baseUrlChanged || modelChanged || apiKeyChanged || temperatureChanged;
  }

  Future<void> _saveChatLLMSettings() async {
    final baseUrl = _chatBaseUrlController.text.trim();
    final model = _chatModelController.text.trim();
    final apiKey = _chatApiKeyController.text.trim();
    final temperatureText = _chatTemperatureController.text.trim();
    final parsedTemperature = double.tryParse(temperatureText);
    if (baseUrl.isEmpty || model.isEmpty || parsedTemperature == null) {
      flushBar(FlushLevel.WARNING, null, 'chat_settings_validation_error'.tr);
      return;
    }

    final candidates = <String>{..._chatModelCandidates};
    if (model.isNotEmpty) {
      candidates.add(model);
    }
    final nextCandidates = candidates.toList()..sort();

    settingController.updateChatLLMSetting(
      provider: _chatProvider,
      baseUrl: baseUrl,
      model: model,
      modelCandidates: nextCandidates,
      apiKey: apiKey.isEmpty ? null : apiKey,
      temperature: parsedTemperature,
    );
    setState(() {
      _chatModelCandidates = nextCandidates;
    });
    successSimpleFlushBar('input_saved'.tr);
  }

  Future<void> _resetChatLLMSettingsToDefault() async {
    final defaults = ChatLLMSetting.defaults();
    setState(() {
      _chatProvider = defaults.provider;
      _chatBaseUrlController.text = defaults.baseUrl;
      _chatModelController.text = defaults.model;
      _chatApiKeyController.text = defaults.apiKey ?? '';
      _chatTemperatureController.text = defaults.temperature.toString();
      _chatModelCandidates = settingController.chatModelCandidates;
    });
    await _saveChatLLMSettings();
  }

  Future<void> _fetchChatModels() async {
    if (_isFetchingChatModels) return;
    final baseUrl = _chatBaseUrlController.text.trim();
    final apiKey = _chatApiKeyController.text.trim();
    if (baseUrl.isEmpty) {
      flushBar(FlushLevel.WARNING, null, 'chat_settings_model_fetch_invalid'.tr);
      return;
    }

    setState(() {
      _isFetchingChatModels = true;
    });

    try {
      final client = DeepSeekClient(baseUrl: baseUrl, apiKey: apiKey.isEmpty ? null : apiKey);
      final response = await client.models.list();
      client.close();
      final models = response.data.map((item) => item.id).where((id) => id.isNotEmpty).toSet().toList()..sort();
      final currentModel = _chatModelController.text.trim();
      String? nextModel;
      if (models.isEmpty) {
        nextModel = '';
      } else if (!models.contains(currentModel)) {
        nextModel = models.first;
      }
      if (!mounted) return;
      setState(() {
        _chatModelCandidates = models;
        if (nextModel != null) {
          _chatModelController.text = nextModel;
        }
      });
      settingController.updateChatLLMSetting(modelCandidates: models, model: nextModel);
      if (nextModel != null && nextModel.isNotEmpty) {
        flushBar(FlushLevel.INFO, null, 'chat_settings_model_replaced'.trParams({'model': nextModel}));
      }
      if (models.isEmpty && currentModel.isNotEmpty) {
        flushBar(FlushLevel.INFO, null, 'chat_settings_model_cleared'.tr);
      }
      if (models.isEmpty) {
        flushBar(FlushLevel.INFO, null, 'chat_settings_model_fetch_empty'.tr);
      }
    } catch (e) {
      if (mounted) {
        flushBar(FlushLevel.WARNING, null, 'chat_settings_model_fetch_failed'.trParams({'error': '$e'}));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingChatModels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedModel = _chatModelController.text.trim();
    final dropdownValue = _chatModelCandidates.contains(selectedModel) ? selectedModel : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('chat_settings_title'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<ChatLLMProvider>(
              initialValue: _chatProvider,
              decoration: InputDecoration(labelText: 'chat_settings_provider'.tr, border: const OutlineInputBorder()),
              items: ChatLLMProvider.values
                  .map((provider) => DropdownMenuItem(value: provider, child: Text(provider.name)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _chatProvider = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chatBaseUrlController,
              decoration: InputDecoration(labelText: 'chat_settings_base_url'.tr, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chatApiKeyController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'chat_settings_api_key'.tr, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: dropdownValue,
                    decoration: InputDecoration(
                      labelText: 'chat_settings_model'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    items: _chatModelCandidates
                        .map((model) => DropdownMenuItem<String>(value: model, child: Text(model)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _chatModelController.text = value;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isFetchingChatModels ? null : _fetchChatModels,
                  icon: _isFetchingChatModels
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text('chat_settings_fetch_models'.tr),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _chatTemperatureController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'chat_settings_temperature'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _hasPendingChatLLMChanges() ? _saveChatLLMSettings : null,
                  icon: const Icon(Icons.save_outlined),
                  label: Text('save'.tr),
                ),
                OutlinedButton.icon(
                  onPressed: _resetChatLLMSettingsToDefault,
                  icon: const Icon(Icons.restore),
                  label: Text('chat_settings_reset_default'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
