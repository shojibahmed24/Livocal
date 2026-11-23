import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/views/widgets/different_language_call_sheet.dart';
import 'package:livocal/features/calls/views/widgets/direct_dial_sheet.dart';
import 'package:livocal/features/home/controllers/contacts_controller.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/ui/livocal_app_bar.dart';
import 'package:livocal/shared/ui/livocal_avatar.dart';
import 'package:livocal/shared/ui/pill_chip.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/contact_filter_strings.dart';
import 'package:livocal/shared/utils/contact_grouping.dart';
import 'package:livocal/shared/widgets/search.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/text_theme.dart';
import 'package:livocal/theme/theme.dart';

class ContactsPage extends ConsumerStatefulWidget {
  final User user;
  const ContactsPage({super.key, required this.user});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

enum _ContactFilter { all, livocal, invite }

class _ContactsPageState extends ConsumerState<ContactsPage> {
  _ContactFilter _filter = _ContactFilter.all;

  @override
  void initState() {
    ref.read(contactPickerControllerProvider.notifier).init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final searchResults = ref.watch(contactPickerControllerProvider);
    final contactsOnLivocal =
        searchResults.where((contact) => contact.userId != null).toList();
    final contactsNotOnLivocal =
        searchResults.where((contact) => contact.userId == null).toList();

    String searchQuery = ref
        .read(contactPickerControllerProvider.notifier)
        .searchController
        .text;

    final filters = ContactFilterStrings.of(
      ref.watch(appLocaleProvider).languageCode,
    );
    final showLivocal = _filter != _ContactFilter.invite;
    final showInvite = _filter != _ContactFilter.livocal;

    final bool buildLivocalContactsList =
        contactsOnLivocal.isNotEmpty && showLivocal;
    final bool buildLocalContactsList =
        contactsNotOnLivocal.isNotEmpty && showInvite;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldWithSearch(
      appBar: livocalAppBar(
        context,
        title: Text(
          AppStrings.tr(ref, 'selectContact'),
          style: TextStyle(
            fontFamily: CustomTextTheme.display,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ref.watch(contactsProvider).isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorTheme.greenColor,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          PopupMenuButton(
            onSelected: (value) {},
            color: colorTheme.appBarColor,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.more_vert),
            ),
            itemBuilder: (context) {
              TextStyle popupMenuTextStyle = Theme.of(context)
                  .custom
                  .textTheme
                  .bodyText2
                  .copyWith(color: Colors.white);
              return <PopupMenuEntry>[
                PopupMenuItem(
                    onTap: () => ref
                        .read(contactPickerControllerProvider.notifier)
                        .shareInviteLink(
                          context.findRenderObject() as RenderBox?,
                        ),
                    child: Text(
                      AppStrings.tr(ref, 'inviteFriend'),
                      style: Theme.of(context)
                          .custom
                          .textTheme
                          .bodyText2
                          .copyWith(color: Colors.white),
                    )),
                PopupMenuItem(
                    onTap: ref
                        .read(contactPickerControllerProvider.notifier)
                        .openContacts,
                    child: Text(
                      AppStrings.tr(ref, 'contacts'),
                      style: Theme.of(context)
                          .custom
                          .textTheme
                          .bodyText2
                          .copyWith(color: Colors.white),
                    )),
                PopupMenuItem(
                    onTap: () {
                      ref
                          .read(contactPickerControllerProvider.notifier)
                          .refreshContactsList();
                    },
                    child: Text(
                      AppStrings.tr(ref, 'refresh'),
                      style: Theme.of(context)
                          .custom
                          .textTheme
                          .bodyText2
                          .copyWith(color: Colors.white),
                    )),
                PopupMenuItem(
                    onTap: ref
                        .read(contactPickerControllerProvider.notifier)
                        .showHelp,
                    child: Text(
                      AppStrings.tr(ref, 'help'),
                      style: popupMenuTextStyle,
                    )),
              ];
            },
          ),
        ],
      ),
      searchController:
          ref.read(contactPickerControllerProvider.notifier).searchController,
      onChanged: (value) => ref
          .read(contactPickerControllerProvider.notifier)
          .updateSearchResults(value),
      onCloseBtnPressed:
          ref.read(contactPickerControllerProvider.notifier).onCloseBtnPressed,
      searchIconActionIndex: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          children: [
            if (searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    PillChip(
                      label:
                          '${filters.all} · ${contactsOnLivocal.length + contactsNotOnLivocal.length}',
                      tone: ChipTone.brand,
                      filled: _filter == _ContactFilter.all,
                      onTap: () => setState(() => _filter = _ContactFilter.all),
                    ),
                    const SizedBox(width: 8),
                    PillChip(
                      label:
                          '${filters.onLivocal} · ${contactsOnLivocal.length}',
                      tone: ChipTone.accent,
                      filled: _filter == _ContactFilter.livocal,
                      onTap: () =>
                          setState(() => _filter = _ContactFilter.livocal),
                    ),
                    const SizedBox(width: 8),
                    PillChip(
                      label:
                          '${filters.invite} · ${contactsNotOnLivocal.length}',
                      tone: ChipTone.neutral,
                      filled: _filter == _ContactFilter.invite,
                      onTap: () =>
                          setState(() => _filter = _ContactFilter.invite),
                    ),
                  ],
                ),
              ),
            if (!buildLivocalContactsList &&
                !buildLocalContactsList &&
                searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  AppStrings.tr(
                    ref,
                    'noResultsFor',
                    args: {'query': searchQuery.trim()},
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).custom.textTheme.caption,
                ),
              ),
            if (searchQuery.isEmpty)
              Column(
                children: [
                  InkWell(
                    onTap: () => showDirectDialSheet(
                      context,
                      currentUser: widget.user,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorTheme.greenColor,
                            child: const Icon(
                              Icons.dialpad_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 18.0,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr(ref, 'dialPhoneNumber'),
                                  style:
                                      Theme.of(context).custom.textTheme.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppStrings.tr(ref, 'dialPhoneNumberSub'),
                                  style: Theme.of(context)
                                      .custom
                                      .textTheme
                                      .caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: ref
                        .read(contactPickerControllerProvider.notifier)
                        .createNewContact,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorTheme.greenColor,
                            child: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 18.0,
                          ),
                          Expanded(
                            child: Text(
                              AppStrings.tr(ref, 'newContact'),
                              style: Theme.of(context).custom.textTheme.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (searchQuery.isEmpty &&
                (!showLivocal || contactsOnLivocal.isEmpty) &&
                (!showInvite || contactsNotOnLivocal.isEmpty))
              _ContactsEmptyState(ref: ref),
            if (contactsOnLivocal.isNotEmpty)
              ..._buildLivocalContactsList(context, contactsOnLivocal),
            if (contactsNotOnLivocal.isNotEmpty)
              ..._buildLocalContactsList(context, contactsNotOnLivocal),
            if (searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Text(
                  AppStrings.tr(ref, 'more'),
                  style: Theme.of(context).custom.textTheme.caption,
                ),
              ),
            Column(
              children: [
                if (searchQuery.isNotEmpty)
                  InkWell(
                    onTap: ref
                        .read(contactPickerControllerProvider.notifier)
                        .createNewContact,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorTheme.appBarColor,
                            child: Icon(
                              Icons.person_add,
                              color: colorTheme.iconColor,
                            ),
                          ),
                          const SizedBox(
                            width: 18.0,
                          ),
                          Expanded(
                            child: Text(
                              AppStrings.tr(ref, 'newContact'),
                              style: Theme.of(context).custom.textTheme.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () => ref
                      .read(contactPickerControllerProvider.notifier)
                      .shareInviteLink(
                        context.findRenderObject() as RenderBox?,
                      ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorTheme.appBarColor,
                          child: Icon(
                            Icons.share,
                            color: colorTheme.iconColor,
                          ),
                        ),
                        const SizedBox(
                          width: 18.0,
                        ),
                        Expanded(
                          child: Text(
                            AppStrings.tr(ref, 'shareInviteLink'),
                            style: Theme.of(context).custom.textTheme.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: ref
                      .read(contactPickerControllerProvider.notifier)
                      .showHelp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorTheme.appBarColor,
                          child: Icon(
                            Icons.question_mark,
                            color: colorTheme.iconColor,
                          ),
                        ),
                        const SizedBox(
                          width: 18.0,
                        ),
                        Expanded(
                          child: Text(
                            AppStrings.tr(ref, 'contactsHelp'),
                            style: Theme.of(context).custom.textTheme.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLivocalContactsList(
    BuildContext context,
    List<Contact> contactsOnLivocal,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        child: Text(
          '${AppStrings.tr(ref, 'contactsOnLivocal')} · ${contactsOnLivocal.length}',
          style: Theme.of(context).custom.textTheme.caption,
        ),
      ),
      LivocalContactsList(
        user: widget.user,
        contactsOnLivocal: contactsOnLivocal,
        ref: ref,
      )
    ];
  }

  List<Widget> _buildLocalContactsList(
    BuildContext context,
    List<Contact> contactsNotOnLivocal,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        child: Text(
          '${AppStrings.tr(ref, 'inviteToLivocal')} · ${contactsNotOnLivocal.length}',
          style: Theme.of(context).custom.textTheme.caption,
        ),
      ),
      LocalContactsList(
        user: widget.user,
        contactsNotOnLivocal: contactsNotOnLivocal,
        ref: ref,
      ),
    ];
  }
}

class LocalContactsList extends StatelessWidget {
  final User user;
  final List<Contact> contactsNotOnLivocal;
  final WidgetRef ref;

  const LocalContactsList({
    super.key,
    required this.user,
    required this.contactsNotOnLivocal,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...contactsNotOnLivocal]..sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
      );

    return Column(
      children: [
        for (var contact in sorted)
          InkWell(
            onTap: () => showDirectDialSheet(
              context,
              currentUser: user,
              initialPhone: contact.phoneNumber,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  _ContactAvatar(
                    displayName: contact.displayName,
                    radius: 20,
                  ),
                  const SizedBox(
                    width: 18.0,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.displayName,
                          style: Theme.of(context).custom.textTheme.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          contact.phoneNumber,
                          style: Theme.of(context).custom.textTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(contactPickerControllerProvider.notifier)
                        .sendSms(contact.phoneNumber),
                    icon: const Icon(Icons.send_rounded, size: 15),
                    label: Text(AppStrings.tr(ref, 'invite')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class LivocalContactsList extends StatelessWidget {
  final User user;
  final List<Contact> contactsOnLivocal;
  final WidgetRef ref;

  const LivocalContactsList({
    super.key,
    required this.user,
    required this.contactsOnLivocal,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final groups = ContactGrouping.byInitial(
      contactsOnLivocal,
      nameOf: (contact) => contact.displayName,
    );

    return Column(
      children: [
        for (final entry in groups.entries) ...[
          _ContactSectionHeader(letter: entry.key, count: entry.value.length),
          for (final contact in entry.value)
            _LivocalContactRow(
              user: user,
              contact: contact,
              ref: ref,
            ),
        ],
      ],
    );
  }
}

class _LivocalContactRow extends StatelessWidget {
  final User user;
  final Contact contact;
  final WidgetRef ref;

  const _LivocalContactRow({
    required this.user,
    required this.contact,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final langCode = CallRepository.inferPeerLanguageCode(
      contact.userId ?? '',
      contact.displayName,
      phone: contact.phoneNumber,
    );
    final lang = CallLanguageRegistry.fromCode(langCode);
    return InkWell(
      onTap: () => ref
          .read(contactPickerControllerProvider.notifier)
          .pickContact(context, user, contact),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            _ContactAvatar(
              displayName: contact.displayName,
              avatarUrl: contact.avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: 18.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: Theme.of(context).custom.textTheme.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          contact.phoneNumber.isNotEmpty
                              ? contact.phoneNumber
                              : 'Hey there! I\'m using Livocal.',
                          style: Theme.of(context).custom.textTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${lang.flagEmoji} ${lang.nativeName}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.call_rounded,
                color: AppColors.primary,
              ),
              tooltip: 'Call with Live AI Translation',
              onPressed: () async {
                final receiver = await IsarDb.getUserById(contact.userId!);
                if (receiver != null && context.mounted) {
                  await initiateSmartCall(
                    context,
                    ref,
                    caller: user,
                    callee: receiver,
                    calleeDisplayName: contact.displayName,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSectionHeader extends StatelessWidget {
  final String letter;
  final int count;

  const _ContactSectionHeader({required this.letter, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            letter,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final double radius;

  const _ContactAvatar({
    required this.displayName,
    this.avatarUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return LivocalAvatar(
      name: displayName,
      imageUrl: avatarUrl,
      size: radius * 2,
      ring: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
          ? AvatarRing.brand
          : AvatarRing.none,
    );
  }
}

/// Shown when the address book produced nothing: either permission was never
/// granted or the phone genuinely has no contacts. Gives the user a way back
/// instead of an unexplained empty screen.
class _ContactsEmptyState extends StatelessWidget {
  final WidgetRef ref;

  const _ContactsEmptyState({required this.ref});

  Future<void> _allowAccess(BuildContext context) async {
    final granted = await ref
        .read(contactPickerControllerProvider.notifier)
        .requestContactsPermission();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.tr(
            ref,
            granted ? 'contactsPermissionGranted' : 'contactsPermissionDenied',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bodyColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: const Icon(
              Icons.contacts_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.tr(ref, 'contactsPermissionTitle'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.tr(ref, 'contactsPermissionBody'),
            style: TextStyle(fontSize: 13, height: 1.35, color: bodyColor),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _allowAccess(context),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(AppStrings.tr(ref, 'allowContactsAccess')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
