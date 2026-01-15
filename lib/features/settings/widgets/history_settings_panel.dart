import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/features/history/presentation/cubit/history_cubit.dart';
import 'package:searvo/features/settings/services/settings_service.dart';
import 'package:searvo/features/settings/widgets/settings_card.dart';
import 'package:searvo/core/di/injection_container.dart';

class HistorySettingsPanel extends StatefulWidget {
  const HistorySettingsPanel({super.key});

  @override
  State<HistorySettingsPanel> createState() => _HistorySettingsPanelState();
}

class _HistorySettingsPanelState extends State<HistorySettingsPanel> {
  late SettingsService _settingsService;
  bool _autoSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    _settingsService = sl<SettingsService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _autoSaveEnabled = _settingsService.getAutoSaveEnabled();
    });
  }

  Future<void> _toggleAutoSave(bool value) async {
    await _settingsService.setAutoSaveEnabled(value);
    setState(() {
      _autoSaveEnabled = value;
    });
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete ALL conversation history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<HistoryCubit>().deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All history cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'History Management',
          subtitle: 'Manage your conversation history and saving preferences',
        ),
        ToggleCard(
          icon: Icons.save_outlined,
          title: 'Auto-save conversations',
          description: 'Automatically save your search sessions',
          value: _autoSaveEnabled,
          onChanged: _toggleAutoSave,
        ),
        const SizedBox(height: 12),
        SettingsCard(
          icon: Icons.delete_sweep_outlined,
          title: 'Clear All History',
          description: 'Permanently delete all saved conversations',
          iconColor: Colors.red,
          onTap: _clearAllHistory,
          showChevron: false,
        ),
      ],
    );
  }
}
