import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 16,
          children: [
            _LanguageOption(
              code: 'ca',
              label: 'Català',
              flag: 'asset:assets/images/catalonia_flag.png',
            ),
            _LanguageOption(
              code: 'es',
              label: 'Español',
              flag: '🇪🇸',
            ),
            _LanguageOption(
              code: 'en',
              label: 'English',
              flag: '🇬🇧',
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.flag,
  });

  final String code;
  final String label;
  final String flag;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<SettingsCubit>().state.languageCode;
    final isSelected = current == code;

    final isAsset = flag.startsWith('asset:');
    final flagWidget = isAsset
        ? Image.asset(
            flag.replaceFirst('asset:', ''),
            height: 30,
            width: 36,
            fit: BoxFit.contain,
          )
        : Text(flag, style: const TextStyle(fontSize: 20));

    return GestureDetector(
      onTap: () => context.read<SettingsCubit>().changeLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected ? Border.all(color: Colors.white70, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            flagWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
