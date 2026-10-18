import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/shared/services/translation_service.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/theme.dart';

import '../../models/attachement.dart';
import '../attachment_viewer.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({
    super.key,
    required this.message,
    required this.currentUserId,
    this.special = false,
  });

  final Message message;
  final bool special;
  final String currentUserId;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  String? _translatedContent;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();

    _checkAutoTranslation();
  }

  void _checkAutoTranslation() {
    final isSent = widget.currentUserId == widget.message.senderId;
    if (isSent || widget.message.isDeleted || widget.message.content.isEmpty) {
      return;
    }
    if (widget.message.content.startsWith('💰')) return;

    final peerId = widget.message.senderId;
    final isTransEnabled =
        SharedPref.instance.getBool('chat_trans_${peerId}_enabled') ?? false;
    final autoIncoming =
        SharedPref.instance.getBool('chat_trans_${peerId}_auto_incoming') ??
            true;

    if (isTransEnabled && autoIncoming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _translateCurrentMessage(null);
      });
    }
  }

  Future<void> _translateCurrentMessage(BuildContext? context) async {
    if (_isTranslating || _translatedContent != null) return;
    if (mounted) setState(() => _isTranslating = true);

    try {
      final peerId = widget.message.senderId == widget.currentUserId
          ? widget.message.receiverId
          : widget.message.senderId;

      final targetLangCode =
          SharedPref.instance.getString('chat_trans_${peerId}_my_lang') ??
              'bn';
      final targetLang = CallLanguageRegistry.allLanguages.firstWhere(
        (l) => l.code == targetLangCode,
        orElse: () => CallLanguageRegistry.allLanguages[0],
      );

      final result = await TranslationService.translateText(
        text: widget.message.content,
        targetLangName: targetLang.englishName,
      );

      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedContent = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Translation error: ${e.toString().replaceAll("Exception: ", "")}',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool shouldHaveBiggerFont(String text) {
    final x = EmojiParser().parseEmojis(text);
    return text.runes.length == x.length;
  }

  void _showMessageActionSheet(BuildContext context, bool isSender) {
    HapticFeedback.mediumImpact();
    final colorTheme = Theme.of(context).custom.colorTheme;
    final isDeleted = widget.message.isDeleted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1F2C34)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (!isDeleted && widget.message.content.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.copy_rounded, color: colorTheme.iconColor),
                    title: const Text('Copy Text'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.message.content));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                if (!isDeleted &&
                    !widget.message.content.startsWith('💰') &&
                    widget.message.content.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.translate_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      _translatedContent == null
                          ? 'Translate Message'
                          : 'Hide Translation',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (_translatedContent != null) {
                        setState(() => _translatedContent = null);
                      } else {
                        _translateCurrentMessage(context);
                      }
                    },
                  ),
                if (!isDeleted)
                  Builder(
                    builder: (context) {
                      final starred = SharedPref.instance.getStringList('starred_message_ids') ?? [];
                      final isStarred = starred.contains(widget.message.id);
                      return ListTile(
                        leading: Icon(
                          isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isStarred ? Colors.amber : colorTheme.iconColor,
                        ),
                        title: Text(isStarred ? 'Unstar' : 'Star'),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final list = SharedPref.instance.getStringList('starred_message_ids') ?? [];
                          if (isStarred) {
                            list.remove(widget.message.id);
                          } else {
                            list.add(widget.message.id);
                          }
                          await SharedPref.instance.setStringList('starred_message_ids', list);
                          if (mounted) setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isStarred ? 'Message unstarred' : 'Message starred'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete for me'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await IsarDb.deleteMessage(widget.message.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message deleted for you'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                if (isSender && widget.message.status == MessageStatus.pending)
                  ListTile(
                    leading: const Icon(Icons.refresh_rounded, color: Colors.green),
                    title: const Text('Resend message'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(widget.message.receiverId)
                            .collection('messages')
                            .doc(widget.message.id)
                            .set(widget.message.copyWith(status: MessageStatus.sent).toMap());
                        await IsarDb.updateMessage(widget.message.id, status: MessageStatus.sent);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message sent')),
                          );
                        }
                      } catch (e) {
                        debugPrint('Resend failed: $e');
                      }
                    },
                  ),
                if (isSender && !isDeleted)
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Delete for everyone',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await IsarDb.deleteMessageForEveryone(widget.message.id);
                      await IsarDb.deleteMessageForEveryoneOnFirestore(
                        widget.message.id,
                        widget.message.receiverId,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message deleted for everyone'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    bool isDark,
    bool isSent,
  ) {
    final content = widget.message.content;
    String amount = '\$0.00';
    String method = '';
    String refId = '';
    String note = '';

    final lines = content.split('\n');
    final mainLine = lines.isNotEmpty ? lines[0] : content;
    if (lines.length > 1) {
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].startsWith('Note: ')) {
          note = lines[i].replaceFirst('Note: ', '').trim();
        }
      }
    }

    final matchAmount = RegExp(r'\$([0-9.,]+)').firstMatch(mainLine);
    if (matchAmount != null) {
      amount = '\$${matchAmount.group(1)}';
    }

    final matchMethod = RegExp(r'via\s+([^(]+)').firstMatch(mainLine);
    if (matchMethod != null) {
      method = matchMethod.group(1)!.trim();
    }

    final matchRef = RegExp(r'\(Ref:\s*([^)]+)\)').firstMatch(mainLine);
    if (matchRef != null) {
      refId = matchRef.group(1)!.trim();
    }

    final isWallet = method.toLowerCase().contains('wallet');
    final isCrypto = method.toLowerCase().contains('usdt') ||
        method.toLowerCase().contains('binance');
    final primaryColor = isWallet
        ? AppColors.primary
        : isCrypto
            ? const Color(0xFFF0B90B)
            : const Color(0xFFE2136E);

    return Container(
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 280),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.65),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  isWallet
                      ? Icons.account_balance_wallet_rounded
                      : isCrypto
                          ? Icons.currency_bitcoin_rounded
                          : Icons.phone_android_rounded,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSent ? 'Payment Sent' : 'Payment Received',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      method.isNotEmpty ? method : 'Livocal Transfer',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 10, color: AppColors.success),
                    SizedBox(width: 3),
                    Text(
                      'PAID',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          if (refId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'TrxID: $refId',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '“$note”',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorTheme = Theme.of(context).custom.colorTheme;
    final size = MediaQuery.of(context).size;
    final hasAttachment = !widget.message.isDeleted && widget.message.attachment != null;
    final attachmentType = widget.message.attachment?.type;
    final isSentMessageCard = widget.currentUserId == widget.message.senderId;
    final messageHasText = widget.message.content.isNotEmpty;

    final showTimeStamp = !hasAttachment ||
        (hasAttachment &&
            attachmentType == AttachmentType.audio &&
            messageHasText) ||
        ((hasAttachment && attachmentType != AttachmentType.audio) &&
            (hasAttachment && attachmentType != AttachmentType.voice));

    final biggerFont = shouldHaveBiggerFont(widget.message.content);
    int padding = 2;

    if (!biggerFont) {
      if (isSentMessageCard) {
        padding = Platform.isAndroid
            ? (widget.special ? 13 : 12)
            : (widget.special ? 17 : 16);
      } else {
        padding = Platform.isAndroid ? 8 : 12;
      }
    }

    final textPadding = '\u00A0' * padding;
    final hasImageOrVideo = attachmentType == AttachmentType.image ||
        attachmentType == AttachmentType.video;
    final maxWidth = MediaQuery.of(context).size.width * 0.80;
    final maxHeight = MediaQuery.of(context).size.height * 0.40;
    final minWidth = 0.8 * maxWidth;
    final imgWidth = widget.message.attachment?.width ?? 1;
    final imgHeight = widget.message.attachment?.height ?? 1;
    final aspectRatio = imgWidth / imgHeight;

    double width, height;
    if (imgHeight > imgWidth) {
      height = min(imgHeight, maxHeight);
      width = max(aspectRatio * height, minWidth);
    } else {
      width = min(imgWidth, maxWidth);
      height = width / aspectRatio;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDeleted = widget.message.isDeleted;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onLongPress: () => _showMessageActionSheet(context, isSentMessageCard),
          child: Align(
            alignment:
                isSentMessageCard ? Alignment.centerRight : Alignment.centerLeft,
            child: ClipPath(
              clipper: widget.special
                  ? TriangleClipper(isSender: isSentMessageCard)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 34,
                  minWidth: widget.special ? (isSentMessageCard ? 98 : 76) : 60,
                  maxWidth: hasImageOrVideo
                      ? width
                      : size.width * 0.80 + (widget.special ? 10 : 0),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: widget.special && !isSentMessageCard
                        ? AppRadius.rXs
                        : AppRadius.rMd,
                    topRight: widget.special && isSentMessageCard
                        ? AppRadius.rXs
                        : AppRadius.rMd,
                    bottomLeft: AppRadius.rMd,
                    bottomRight: AppRadius.rMd,
                  ),
                  color: isSentMessageCard
                      ? (isDark
                          ? AppColors.darkOutgoingBubble
                          : AppColors.lightOutgoingBubble)
                      : (isDark
                          ? AppColors.darkIncomingBubble
                          : AppColors.lightIncomingBubble),
                ),
                margin: EdgeInsets.only(
                  bottom: 3.0,
                  top: widget.special ? 6.0 : 0,
                  left: widget.special ? 6 : 16.0,
                  right: widget.special ? 6 : 16.0,
                ),
                padding: hasAttachment
                    ? attachmentType == AttachmentType.audio && !messageHasText
                        ? EdgeInsets.only(
                            left: isSentMessageCard ? 8 : (widget.special ? 18 : 8),
                            right: isSentMessageCard ? (widget.special ? 10 : 0) : 0,
                          )
                        : EdgeInsets.only(
                            top: 4.0,
                            bottom: 4.0,
                            left: widget.special && !isSentMessageCard ? 14.0 : 4.0,
                            right: widget.special && isSentMessageCard ? 14.0 : 4.0,
                          )
                    : EdgeInsets.only(
                        left: 10,
                        right: widget.special && isSentMessageCard ? 16 : 10,
                        top: 4,
                        bottom: 6,
                      ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasAttachment) ...[
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  height < width ? 0.65 * width : double.infinity,
                            ),
                            child: AttachmentPreview(
                              message: widget.message,
                              width: width,
                              height: height,
                            ),
                          ),
                        ],
                        if (messageHasText || isDeleted) ...[
                          Padding(
                            padding: hasAttachment
                                ? const EdgeInsets.only(left: 4.0, top: 4.0)
                                : widget.special && !isSentMessageCard
                                    ? EdgeInsets.only(
                                        left: 10,
                                        top: 4,
                                        bottom: biggerFont
                                            ? 12
                                            : padding == 0
                                                ? 14.0
                                                : 0,
                                      )
                                    : EdgeInsets.only(
                                        top: 2.0,
                                        bottom: biggerFont
                                            ? (Platform.isAndroid ? 16.0 : 12.0)
                                            : padding == 0
                                                ? 14.0
                                                : 0,
                                      ),
                            child: isDeleted
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block_rounded,
                                        size: 15,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'This message was deleted $textPadding',
                                        textWidthBasis:
                                            TextWidthBasis.longestLine,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : widget.message.content.startsWith('💰 Payment sent:')
                                    ? _buildPaymentCard(context, isDark, isSentMessageCard)
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${widget.message.content} $textPadding',
                                            textWidthBasis:
                                                TextWidthBasis.longestLine,
                                            style: Theme.of(context)
                                                .custom
                                                .textTheme
                                                .bodyText1
                                                .copyWith(
                                                  fontSize: biggerFont ? 40 : 16,
                                                  color: colorTheme.textColor1,
                                                ),
                                            softWrap: true,
                                          ),
                                          if (_isTranslating) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Translating...',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: isDark
                                                        ? AppColors
                                                            .darkTextSecondary
                                                        : AppColors
                                                            .lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else if (_translatedContent !=
                                              null) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 2, bottom: 2),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.08)
                                                    : Colors.black.withValues(
                                                        alpha: 0.04),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: const Border(
                                                  left: BorderSide(
                                                      color: AppColors.primary,
                                                      width: 2.5),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .translate_rounded,
                                                          size: 10,
                                                          color: AppColors
                                                              .primary),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Translated',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.primary,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _translatedContent!,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: isDark
                                                          ? AppColors
                                                              .darkTextPrimary
                                                          : AppColors
                                                              .lightTextPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                          )
                        ],
                      ],
                    ),
                    Positioned(
                      right: widget.special && isSentMessageCard && (messageHasText || isDeleted)
                          ? -6
                          : 0,
                      bottom: -1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            if (!messageHasText &&
                                !isDeleted &&
                                (attachmentType != AttachmentType.document &&
                                    attachmentType != AttachmentType.audio &&
                                    attachmentType != AttachmentType.voice)) ...[
                              const BoxShadow(
                                color: Color.fromARGB(174, 1, 4, 21),
                                blurRadius: 20,
                              )
                            ],
                          ],
                        ),
                        margin: !messageHasText &&
                                hasAttachment &&
                                attachmentType != AttachmentType.audio
                            ? const EdgeInsets.all(4.0)
                            : null,
                        padding: !messageHasText &&
                                hasAttachment &&
                                attachmentType != AttachmentType.audio
                            ? const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 2.0,
                              )
                            : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (showTimeStamp) ...[
                              Text(
                                formattedTimestamp(
                                  widget.message.timestamp,
                                  true,
                                  Platform.isIOS,
                                ),
                                style: Theme.of(context)
                                    .custom
                                    .textTheme
                                    .caption
                                    .copyWith(
                                      fontSize: 11,
                                      color: (messageHasText || isDeleted)
                                          ? (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary)
                                          : Colors.white,
                                    ),
                              ),
                              if (SharedPref.instance.getStringList('starred_message_ids')?.contains(widget.message.id) == true) ...[
                                const SizedBox(width: 3.0),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                            if (isSentMessageCard) ...[
                              const SizedBox(
                                width: 2.0,
                              ),
                              Image.asset(
                                'assets/images/${widget.message.status.value}.png',
                                color: widget.message.status.value != 'SEEN'
                                    ? ((messageHasText || isDeleted)
                                        ? (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        : (isDark
                                            ? Colors.white
                                            : AppColors.lightTextSecondary))
                                    : null,
                                width: 14.0,
                              ),
                            ],
                            if (widget.special &&
                                isSentMessageCard &&
                                (messageHasText || isDeleted)) ...[const SizedBox(width: 9)],
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  final bool isSender;

  TriangleClipper({required this.isSender});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isSender) {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, 4);
      path.lineTo(size.width - 16, 16);
      path.lineTo(size.width - 16, size.height - 10);
      path.quadraticBezierTo(
          size.width - 16, size.height - 2, size.width - 36, size.height);
      path.lineTo(0, size.height);
    } else {
      path.lineTo(0, 4);
      path.lineTo(16, 16);
      path.lineTo(16, size.height - 10);
      path.quadraticBezierTo(16, size.height - 2, 36, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
