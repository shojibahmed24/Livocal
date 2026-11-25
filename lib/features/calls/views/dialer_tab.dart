import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/views/widgets/different_language_call_sheet.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/ui/livocal_avatar.dart';
import 'package:livocal/shared/ui/pill_chip.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/dialer_strings.dart';
import 'package:livocal/shared/utils/phone_normalizer.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';

/// Keypad tab: large display, live contact match, recents and a branded
/// call button. Replaces the old "type a number in a bottom sheet" flow.
class DialerTab extends ConsumerStatefulWidget {
  final User user;

  const DialerTab({super.key, required this.user});

  @override
  ConsumerState<DialerTab> createState() => _DialerTabState();
}

class _DialerTabState extends ConsumerState<DialerTab> {
  String _number = '';
  User? _match;
  bool _looking = false;
  Timer? _debounce;

  static const int _maxDigits = 15;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  DialerStrings get _s => DialerStrings.of(
        ref.watch(appLocaleProvider).languageCode,
      );

  void _append(String digit) {
    if (_number.length >= _maxDigits) return;
    setState(() => _number += digit);
    _scheduleLookup();
  }

  void _appendPlus() {
    if (_number.startsWith('+') || _number.length >= _maxDigits) return;
    setState(() => _number = '+$_number');
    _scheduleLookup();
  }

  void _backspace() {
    if (_number.isEmpty) return;
    setState(() {
      _number = _number.substring(0, _number.length - 1);
      _match = null;
    });
    _scheduleLookup();
  }

  void _clear() {
    setState(() {
      _number = '';
      _match = null;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = PhoneNormalizer.digitsOnly(data?.text ?? '');
    if (pasted.isEmpty) return;
    setState(() {
      _number =
          pasted.length > _maxDigits ? pasted.substring(0, _maxDigits) : pasted;
      _match = null;
    });
    _scheduleLookup();
  }

  void _scheduleLookup() {
    _debounce?.cancel();
    final e164 = PhoneNormalizer.parse(
      countryCode: '880',
      input: _number,
    )?.e164;
    if (e164 == null) {
      if (mounted && _match != null) setState(() => _match = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _looking = true);
      User? found;
      try {
        found = await IsarDb.getUserByPhone(e164);
        found ??= await ref
            .read(firebaseFirestoreRepositoryProvider)
            .getUserByPhone(e164);
      } catch (_) {
        found = null;
      }
      if (!mounted) return;
      setState(() {
        _match = found;
        _looking = false;
      });
    });
  }

  Future<User?> _resolveTarget(String raw) async {
    final parts = PhoneNormalizer.parse(countryCode: '880', input: raw);
    if (parts == null) return null;

    User? target = _match;
    target ??= await IsarDb.getUserByPhone(parts.e164);
    target ??= await ref
        .read(firebaseFirestoreRepositoryProvider)
        .getUserByPhone(parts.e164);
    target ??= User(
      id: 'phone_${parts.e164}',
      name: parts.e164,
      avatarUrl: '',
      phone: Phone(
        code: parts.code,
        number: parts.number,
        formattedNumber: parts.e164,
      ),
      activityStatus: UserActivityStatus.online,
    );
    return target;
  }

  Future<void> _placeCall(BuildContext context, String raw,
      {User? known}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final target = known ?? await _resolveTarget(raw);
    if (target == null) {
      if (context.mounted) {
        showSnackBar(
          context: context,
          content: _s.invalidNumber,
          type: SnacBarType.error,
        );
      }
      return;
    }
    if (!context.mounted) return;
    await initiateSmartCall(
      context,
      ref,
      caller: widget.user,
      callee: target,
      calleeDisplayName: target.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _s;
    final history = ref.watch(callControllerProvider).callHistory;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildNumberHeader(isDark, s),
          Expanded(child: _buildSuggestions(context, s, history, isDark)),
          _buildKeypad(context, isDark),
          _buildActions(context, s, isDark),
        ],
      ),
    );
  }

  /// Compact header: a quiet hint line when idle, the large number when typing.
  /// The old 92 px block left a dead band above the keypad.
  Widget _buildNumberHeader(bool isDark, DialerStrings s) {
    if (_number.isEmpty) {
      return Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            Icon(
              Icons.dialpad_rounded,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              s.enterNumber,
              style: TextStyle(
                fontFamily: CustomTextTheme.body,
                fontSize: 13.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 72,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _number,
              maxLines: 1,
              style: TextStyle(
                fontFamily: CustomTextTheme.display,
                fontSize: 34,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(
    BuildContext context,
    DialerStrings s,
    List<CallHistoryRecord> history,
    bool isDark,
  ) {
    if (_looking) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_number.isNotEmpty) {
      final match = _match;
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          if (match != null)
            _SuggestionTile(
              name: match.name,
              subtitle: match.phone.getFormattedNumber(),
              avatarUrl: match.avatarUrl,
              chip: s.onLivocal,
              chipTone: ChipTone.accent,
              onTap: () => _placeCall(context, _number, known: match),
            )
          else if (_number.replaceAll(RegExp(r'\D'), '').length >= 6)
            _SuggestionTile(
              name: _number,
              subtitle: s.notOnLivocal,
              avatarUrl: '',
              chip: s.call,
              chipTone: ChipTone.brand,
              onTap: () => _placeCall(context, _number),
            ),
        ],
      );
    }

    if (history.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.lightDivider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.recent,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.noRecents,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 2),
          child: Text(
            s.recent.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 0, bottom: 8),
            itemCount: history.length > 6 ? 6 : history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              final peer = _userFromRecord(record);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: LivocalAvatar(
                  name: record.peerName,
                  imageUrl: record.peerAvatar,
                  size: 40,
                ),
                title: Text(
                  record.peerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: CustomTextTheme.body,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: record.isMissed
                        ? AppColors.errorLight
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                ),
                subtitle: Text(
                  record.peerPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.call_rounded, size: 20),
                  color: AppColors.primary,
                  onPressed: () =>
                      _placeCall(context, record.peerPhone, known: peer),
                ),
                onTap: () => _placeCall(context, record.peerPhone, known: peer),
              );
            },
          ),
        ),
      ],
    );
  }

  User _userFromRecord(CallHistoryRecord record) {
    final parts = PhoneNormalizer.parse(
      countryCode: '880',
      input: record.peerPhone,
    );
    return User(
      id: record.peerId,
      name: record.peerName,
      avatarUrl: record.peerAvatar,
      phone: Phone(
        code: parts?.code ?? '+880',
        number: parts?.number ?? record.peerPhone,
        formattedNumber: parts?.e164 ?? record.peerPhone,
      ),
      activityStatus: UserActivityStatus.offline,
    );
  }

  Widget _buildKeypad(BuildContext context, bool isDark) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];
    const letters = {
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '0': '+',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: _DialKey(
                      label: key,
                      sublabel: letters[key],
                      isDark: isDark,
                      onTap: () => key == '0' ? _append('0') : _append(key),
                      onLongPress: key == '0' ? _appendPlus : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    DialerStrings s,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: s.paste,
            onPressed: _paste,
            icon: Icon(
              Icons.content_paste_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          GestureDetector(
            onTap: _number.isEmpty ? null : () => _placeCall(context, _number),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _number.isEmpty ? 0.45 : 1,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  boxShadow: _number.isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.34),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: s.clear,
            onPressed: _number.isEmpty ? null : _backspace,
            onLongPress: _number.isEmpty ? null : _clear,
            icon: Icon(
              Icons.backspace_outlined,
              color: _number.isEmpty
                  ? (isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                      : AppColors.lightTextSecondary.withValues(alpha: 0.4))
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialKey extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DialKey({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.sublabel,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress,
        child: SizedBox(
          height: 62,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: CustomTextTheme.display,
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    color: foreground,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: TextStyle(
                      fontFamily: CustomTextTheme.body,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String avatarUrl;
  final String chip;
  final ChipTone chipTone;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.chip,
    required this.chipTone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                LivocalAvatar(
                  name: name,
                  imageUrl: avatarUrl,
                  size: 46,
                  ring: AvatarRing.brand,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: CustomTextTheme.display,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PillChip(label: chip, tone: chipTone),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
