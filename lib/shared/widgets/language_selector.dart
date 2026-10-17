import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/settings/cubit/settings_cubit.dart';

/// Picks the interface language, or the device language.
class LanguageSelector extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          _LanguageOption(
            code: null,
            label: l10n.settingsLanguageDevice,
            flag: const Icon(Icons.smartphone, size: 22),
          ),
          _LanguageOption(
            code: 'ca',
            label: 'Català',
            flag: Image.asset(
              Assets.images.cataloniaFlag.path,
              height: 22,
              width: 30,
              fit: BoxFit.contain,
            ),
          ),
          const _LanguageOption(
            code: 'es',
            label: 'Español',
            flag: Text('🇪🇸', style: TextStyle(fontSize: 20)),
          ),
          const _LanguageOption(
            code: 'en',
            label: 'English',
            flag: Text('🇬🇧', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const new({required this.code, required this.label, required this.flag});

  /// The language code, or null for the device language.
  final String? code;
  final String label;
  final Widget flag;

  @override
  Widget build(BuildContext context) {
    final current = context.select<SettingsCubit, String?>(
      (cubit) => cubit.state.settings.languageCode,
    );
    final isSelected = current == code;
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      key: Key('language_${code ?? 'device'}'),
      avatar: flag,
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: colors.primary.withValues(alpha: 0.3),
      onSelected: (_) =>
          unawaited(context.read<SettingsCubit>().setLanguage(code)),
    );
  }
}
