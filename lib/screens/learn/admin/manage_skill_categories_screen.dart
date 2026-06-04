import 'package:flutter/material.dart';

import '../../../core/colors.dart';
import '../../../models/skill_category.dart';
import '../../../repositories/course_repository.dart';
import '../../../utils/icon_mapper.dart';

class ManageSkillCategoriesScreen extends StatefulWidget {
  const ManageSkillCategoriesScreen({super.key});

  @override
  State<ManageSkillCategoriesScreen> createState() =>
      _ManageSkillCategoriesScreenState();
}

class _ManageSkillCategoriesScreenState
    extends State<ManageSkillCategoriesScreen> {
  List<SkillCategory> _categories = [];
  bool _loading = true;

  static const _iconOptions = <String, IconData>{
    'record_voice_over_rounded': Icons.record_voice_over_rounded,
    'devices_rounded': Icons.devices_rounded,
    'explore_rounded': Icons.explore_rounded,
    'shield_rounded': Icons.shield_rounded,
    'account_balance_wallet_rounded': Icons.account_balance_wallet_rounded,
    'code_rounded': Icons.code_rounded,
    'campaign_rounded': Icons.campaign_rounded,
    'security_rounded': Icons.security_rounded,
    'psychology_rounded': Icons.psychology_rounded,
  };

  static const _colorOptions = [
    '#FFE7C8',
    '#DDF1FF',
    '#E9E2FF',
    '#E0F8E8',
    '#FFF3D0',
    '#DDF7F4',
    '#FFDCDC',
    '#F5E0FF',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final categories = await CourseRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([SkillCategory? category]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryEditorSheet(
        category: category,
        iconOptions: _iconOptions,
        colorOptions: _colorOptions,
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(SkillCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skill'),
        content: Text('Delete "${category.title}" from the skill section?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.softRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CourseRepository.deleteCategory(category.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete skill.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        title: const Text(
          'Manage Skills',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add skill',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.muted.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: category.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category.icon, color: AppColors.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openEditor(category),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit skill',
                      ),
                      IconButton(
                        onPressed: () => _delete(category),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.softRed,
                        tooltip: 'Delete skill',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({
    required this.iconOptions,
    required this.colorOptions,
    this.category,
  });

  final SkillCategory? category;
  final Map<String, IconData> iconOptions;
  final List<String> colorOptions;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late String _iconName;
  late String _colorHex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _titleCtrl = TextEditingController(text: category?.title ?? '');
    _iconName = category == null
        ? widget.iconOptions.keys.first
        : _iconNameFromIcon(category.icon);
    _colorHex = category == null
        ? widget.colorOptions.first
        : _colorHexFromColor(category.color);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final category = widget.category;
      if (category == null) {
        await CourseRepository.createCategory(
          title: _titleCtrl.text.trim(),
          iconName: _iconName,
          colorHex: _colorHex,
        );
      } else {
        await CourseRepository.updateCategory(
          category.id,
          title: _titleCtrl.text.trim(),
          iconName: _iconName,
          colorHex: _colorHex,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save skill.'),
          backgroundColor: AppColors.softRed,
        ),
      );
    }
  }

  String _iconNameFromIcon(IconData icon) {
    return widget.iconOptions.entries
        .firstWhere(
          (entry) => entry.value == icon,
          orElse: () => widget.iconOptions.entries.first,
        )
        .key;
  }

  String _colorHexFromColor(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    final hex = '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return widget.colorOptions.contains(hex) ? hex : widget.colorOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category == null ? 'Add Skill' : 'Edit Skill',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Skill title',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.iconOptions.entries.map((entry) {
                  final selected = _iconName == entry.key;
                  return _PickButton(
                    selected: selected,
                    child: Icon(
                      entry.value,
                      color: selected ? AppColors.primary : AppColors.muted,
                    ),
                    onTap: () => setState(() => _iconName = entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.colorOptions.map((hex) {
                  final selected = _colorHex == hex;
                  return _PickButton(
                    selected: selected,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: IconMapper.colorFromHex(hex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () => setState(() => _colorHex = hex),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
