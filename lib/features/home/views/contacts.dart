import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/views/widgets/direct_dial_sheet.dart';
import 'package:livocal/features/calls/views/outgoing_call_screen.dart';
import 'package:livocal/features/home/controllers/contacts_controller.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/widgets/search.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/theme.dart';

class ContactsPage extends ConsumerStatefulWidget {
  final User user;
  const ContactsPage({super.key, required this.user});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
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

    bool buildLivocalContactsList = contactsOnLivocal.isNotEmpty;
    bool buildLocalContactsList = contactsNotOnLivocal.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldWithSearch(
      appBar: AppBar(
        elevation: 0.0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select contact',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
                      'Invite a friend',
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
                      'Contacts',
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
                      'Refresh',
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
                      'Help',
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
            if (!buildLivocalContactsList &&
                !buildLocalContactsList &&
                searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No results found for \'${searchQuery.trim()}\'',
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
                                  'Dial Phone Number (সরাসরি কল/চ্যাট)',
                                  style: Theme.of(context).custom.textTheme.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Enter number to call or chat directly',
                                  style: Theme.of(context).custom.textTheme.caption,
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
                          Text('New contact',
                              style: Theme.of(context).custom.textTheme.bold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                  'More',
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
                          Text('New Contact',
                              style: Theme.of(context).custom.textTheme.bold),
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
                        Text('Share invite link',
                            style: Theme.of(context).custom.textTheme.bold),
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
                        Text('Contacts help',
                            style: Theme.of(context).custom.textTheme.bold),
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
          'Contacts on Livocal',
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
          'Invite to Livocal',
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
    return Column(
      children: [
        for (var contact in contactsNotOnLivocal)
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
                  IconButton(
                    icon: const Icon(Icons.phone_forwarded_rounded, size: 20),
                    tooltip: 'Direct Call / Check Livocal',
                    color: Theme.of(context).custom.colorTheme.greenColor,
                    onPressed: () => showDirectDialSheet(
                      context,
                      currentUser: user,
                      initialPhone: contact.phoneNumber,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(contactPickerControllerProvider.notifier)
                        .sendSms(contact.phoneNumber),
                    child: Text(
                      'INVITE',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color:
                              Theme.of(context).custom.colorTheme.greenColor),
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
    return Column(
      children: [
        for (var contact in contactsOnLivocal)
          InkWell(
            onTap: () => ref
                .read(contactPickerControllerProvider.notifier)
                .pickContact(context, user, contact),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  _ContactAvatar(
                    displayName: contact.displayName,
                    avatarUrl: contact.avatarUrl,
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
                        const SizedBox(height: 2),
                        Text(
                          contact.phoneNumber.isNotEmpty
                              ? contact.phoneNumber
                              : 'Hey there! I\'m using Livocal.',
                          style: Theme.of(context).custom.textTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      final receiver =
                          await IsarDb.getUserById(contact.userId!);
                      if (receiver != null && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OutgoingCallScreen(
                              caller: user,
                              callee: receiver,
                              calleeDisplayName: contact.displayName,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
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
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          child: SizedBox(
            width: radius,
            height: radius,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitials(),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final initials = _getInitials(displayName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getAvatarColor(displayName),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      final res = '$first$second'.toUpperCase();
      if (res.isNotEmpty) return res;
    }
    return name.trim().substring(0, name.trim().length.clamp(1, 2)).toUpperCase();
  }

  static Color _getAvatarColor(String name) {
    const colors = [
      AppColors.primary,
      Color(0xFF1E88E5),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFFFB8C00),
      Color(0xFF00897B),
      Color(0xFF3949AB),
      Color(0xFF43A047),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

