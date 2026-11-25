import 'package:flutter/material.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/theme.dart';

class ChatField extends StatelessWidget {
  const ChatField({
    super.key,
    required this.leading,
    this.actions,
    required this.textController,
    this.onTextChanged,
    this.focusNode,
    this.onSubmitted,
  });

  final Widget leading;
  final List<Widget>? actions;
  final TextEditingController textController;
  final Function(String)? onTextChanged;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enterIsSend =
        SharedPref.instance.getBool('chat_enter_is_send') ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.0),
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.94),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E7F4),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 11.0),
            child: leading,
          ),
          const SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: TextField(
              onChanged: onTextChanged,
              controller: textController,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction:
                  enterIsSend ? TextInputAction.send : TextInputAction.newline,
              onSubmitted: enterIsSend ? onSubmitted : null,
              maxLines: enterIsSend ? 1 : 6,
              minLines: 1,
              cursorColor: colorTheme.greenColor,
              cursorHeight: 20,
              decoration: InputDecoration(
                hintText: AppStrings.get(
                  'messageHint',
                  Localizations.localeOf(context).languageCode,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          if (actions != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 11.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: actions!
                    .map((e) => Padding(
                          padding: const EdgeInsetsDirectional.only(start: 22),
                          child: e,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
