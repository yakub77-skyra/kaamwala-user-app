/// City input with free text + autocomplete suggestions.
///
/// The user can type ANY city; the suggestion list only helps speed up common
/// cities. Built on [FormField] so it participates in Form validation, and on
/// Flutter's [Autocomplete] for keyboard-friendly suggestions.
library;

import 'package:flutter/material.dart';

import 'package:kaamwala/core/constants/city_suggestions.dart';
import 'package:kaamwala/core/services/phone/phone_utils.dart';
import 'package:kaamwala/core/theme/app_theme.dart';

class KwCityField extends FormField<String> {
  KwCityField({
    super.key,
    super.initialValue,
    super.validator,
    super.autovalidateMode,
    required this.onChanged,
    this.hintText = 'e.g. Pune, Mumbai, Delhi',
    this.prefixIcon = const Icon(Icons.location_city_rounded),
  }) : super(
         builder: (state) => _KwCityFieldBuilder(
           state: state,
           onChanged: onChanged,
           hintText: hintText,
           prefixIcon: prefixIcon,
         ),
       );

  final ValueChanged<String> onChanged;
  final String hintText;
  final Widget? prefixIcon;
}

class _KwCityFieldBuilder extends StatelessWidget {
  const _KwCityFieldBuilder({
    required this.state,
    required this.onChanged,
    required this.hintText,
    required this.prefixIcon,
  });

  final FormFieldState<String> state;
  final ValueChanged<String> onChanged;
  final String hintText;
  final Widget? prefixIcon;

  void _commit(String raw) {
    final normalized = normalizeCity(raw);
    onChanged(normalized);
    state.didChange(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<String>(
          initialValue: TextEditingValue(text: state.value ?? ''),
          optionsBuilder: (TextEditingValue te) {
            if (te.text.trim().isEmpty) return const Iterable<String>.empty();
            final q = te.text.trim().toLowerCase();
            return kCitySuggestions
                .where((c) => c.toLowerCase().startsWith(q))
                .toList();
          },
          displayStringForOption: (c) => c,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: prefixIcon,
                errorText: state.errorText,
                errorMaxLines: 2,
              ),
              onChanged: (v) {
                onChanged(v);
                state.didChange(v);
              },
              onSubmitted: (_) {
                _commit(controller.text);
                onFieldSubmitted();
              },
              onEditingComplete: () => _commit(controller.text),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(KwRadius.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final option = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.location_city_rounded,
                          size: 18,
                          color: KwColors.muted,
                        ),
                        title: Text(option),
                        onTap: () {
                          _commit(option);
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
