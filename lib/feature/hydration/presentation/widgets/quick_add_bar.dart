import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydration_tracker/core/theme/app_colors.dart';

/// Quick-add controls: +250, +500 and a custom amount. Each tap adds one log.
class QuickAddBar extends StatelessWidget {
  const QuickAddBar({required this.onAdd, this.enabled = true, super.key});

  final ValueChanged<int> onAdd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickButton(
            label: '+250 ml',
            icon: Icons.local_drink_outlined,
            onTap: enabled ? () => onAdd(250) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickButton(
            label: '+500 ml',
            icon: Icons.sports_bar_outlined,
            onTap: enabled ? () => onAdd(500) : null,
          ),
        ),
        const SizedBox(width: 12),
        _QuickButton(
          label: 'Custom',
          icon: Icons.add,
          compact: true,
          onTap: enabled ? () => _promptCustom(context) : null,
        ),
      ],
    );
  }

  Future<void> _promptCustom(BuildContext context) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomAmountDialog(),
    );
    if (amount != null && amount > 0) onAdd(amount);
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? AppColors.surface.withValues(alpha: 0.5)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 12,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accentSoft, size: 20),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAmountDialog extends StatefulWidget {
  const _CustomAmountDialog();

  @override
  State<_CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<_CustomAmountDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a number greater than 0.');
      return;
    }
    if (amount > 5000) {
      setState(() => _error = 'That seems too high (max 5000 ml).');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text(
        'Add custom amount',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: AppColors.textPrimary),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: 'ml',
          suffixStyle: const TextStyle(color: AppColors.textSecondary),
          errorText: _error,
          hintText: 'e.g. 350',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accent),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
