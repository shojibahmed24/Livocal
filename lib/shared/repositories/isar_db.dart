import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/features/chat/models/recent_chat.dart';
import 'package:livocal/features/home/data/repositories/contact_repository.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

import '../../features/chat/models/message.dart';

final isarProvider = Provider((ref) => IsarDb());

class IsarDb {
  static Isar? _instance;
  static Isar get isar {
    if (_instance != null) return _instance!;
    final openInstance = Isar.getInstance();
    if (openInstance != null) {
      _instance = openInstance;
      return _instance!;
    }
    throw StateError('Isar is not opened');
  }

  static Isar? get instance => _instance ?? Isar.getInstance();

  static Future<void> init() async {
    final existing = Isar.getInstance();
    if (existing != null) {
      _instance = existing;
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    try {
      _instance = await Isar.open(
        [StoredMessageSchema, ContactSchema, UserSchema],
        directory: dir.path,
        inspector: false,
      );
    } catch (e) {
      debugPrint('Isar open error: $e, checking existing instance...');
      final fallback = Isar.getInstance();
      if (fallback != null) {
        _instance = fallback;
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
        _instance = Isar.getInstance() ??
            await Isar.open(
              [StoredMessageSchema, ContactSchema, UserSchema],
              directory: dir.path,
              inspector: false,
            );
      }
    }
  }

  static Future<void> addMessage(Message message) async {
    final storedMsg = StoredMessage(
      messageId: message.id,
      chatId: getChatId(message.senderId, message.receiverId),
      content: message.content,
      senderId: message.senderId,
      receiverId: message.receiverId,
      status: message.status,
      timestamp: message.timestamp.toDate(),
      attachment: message.attachment != null
          ? EmbeddedAttachment(
              fileName: message.attachment!.fileName,
              fileExtension: message.attachment!.fileExtension,
              fileSize: message.attachment!.fileSize,
              width: message.attachment!.width,
              height: message.attachment!.height,
              autoDownload: message.attachment!.autoDownload,
              uploadStatus: message.attachment!.uploadStatus,
              url: message.attachment!.url,
              type: message.attachment!.type,
              samples: message.attachment!.samples,
            )
          : null,
    );

    await isar.writeTxn(() async {
      final existing = await isar.storedMessages
          .filter()
          .messageIdEqualTo(message.id)
          .findFirst();
      if (existing != null) {
        // Enforce monotonic receipt status: seen (3) > delivered (2) > sent (1) > pending (0)
        if (message.status.index >= existing.status.index) {
          existing.status = message.status;
        }
        if (message.content.isNotEmpty) existing.content = message.content;
        if (message.attachment != null && existing.attachment != null) {
          existing.attachment!.url = message.attachment!.url;
          existing.attachment!.uploadStatus = message.attachment!.uploadStatus;
        }
        await isar.storedMessages.put(existing);
      } else {
        await isar.storedMessages.put(storedMsg);
      }
    });
  }

  static Future<void> addMessages(List<Message> messages) async {
    await isar.writeTxn(() async {
      for (final message in messages) {
        final existing = await isar.storedMessages
            .filter()
            .messageIdEqualTo(message.id)
            .findFirst();
        if (existing != null) {
          // Enforce monotonic receipt status: seen (3) > delivered (2) > sent (1) > pending (0)
          if (message.status.index >= existing.status.index) {
            existing.status = message.status;
          }
          if (message.content.isNotEmpty) existing.content = message.content;
          if (message.attachment != null && existing.attachment != null) {
            existing.attachment!.url = message.attachment!.url;
            existing.attachment!.uploadStatus = message.attachment!.uploadStatus;
          }
          await isar.storedMessages.put(existing);
        } else {
          final storedMsg = StoredMessage(
            messageId: message.id,
            chatId: getChatId(message.senderId, message.receiverId),
            content: message.content,
            senderId: message.senderId,
            receiverId: message.receiverId,
            status: message.status,
            timestamp: message.timestamp.toDate(),
            attachment: message.attachment != null
                ? EmbeddedAttachment(
                    fileName: message.attachment!.fileName,
                    fileExtension: message.attachment!.fileExtension,
                    fileSize: message.attachment!.fileSize,
                    width: message.attachment!.width,
                    height: message.attachment!.height,
                    uploadStatus: message.attachment!.uploadStatus,
                    autoDownload: message.attachment!.autoDownload,
                    url: message.attachment!.url,
                    type: message.attachment!.type,
                    samples: message.attachment!.samples,
                  )
                : null,
          );
          await isar.storedMessages.put(storedMsg);
        }
      }
    });
  }

  static Future<void> updateMessage(
    String messageId, {
    String? content,
    MessageStatus? status,
    Attachment? attachment,
  }) async {
    await isar.writeTxn(() async {
      StoredMessage? msg = await isar.storedMessages
          .filter()
          .messageIdEqualTo(messageId)
          .build()
          .findFirst();

      if (msg == null) return;

      msg.content = content ?? msg.content;
      // Enforce monotonic status updates: never downgrade seen -> delivered or delivered -> sent
      if (status != null && status.index >= msg.status.index) {
        msg.status = status;
      }

      if (attachment != null) {
        msg.attachment = EmbeddedAttachment(
          fileName: attachment.fileName,
          fileExtension: attachment.fileExtension,
          fileSize: attachment.fileSize,
          width: attachment.width,
          height: attachment.height,
          uploadStatus: attachment.uploadStatus,
          autoDownload: attachment.autoDownload,
          url: attachment.url,
          type: attachment.type,
          samples: attachment.samples,
        );
      }

      await isar.storedMessages.put(msg);
    });
  }

  static Future<void> deleteMessage(String messageId) async {
    await isar.writeTxn(() async {
      await isar.storedMessages
          .filter()
          .messageIdEqualTo(messageId)
          .deleteAll();
    });
  }

  static Future<void> deleteMessageForEveryone(String messageId) async {
    await isar.writeTxn(() async {
      StoredMessage? msg = await isar.storedMessages
          .filter()
          .messageIdEqualTo(messageId)
          .build()
          .findFirst();

      if (msg == null) return;
      msg.content = '🚫 This message was deleted';
      msg.attachment = null;
      await isar.storedMessages.put(msg);
    });
  }

  static Future<void> deleteMessageForEveryoneOnFirestore(
    String messageId,
    String receiverId,
  ) async {
    final updateData = {
      'content': '🚫 This message was deleted',
      'attachment': null,
      'deletedForEveryone': true,
    };

    // 1. Update in recipient inbox: chats/{receiverId}/messages/{messageId}
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(receiverId)
          .collection('messages')
          .doc(messageId)
          .update(updateData);
    } catch (e) {
      debugPrint('Firestore deleteMessage receiver error: $e');
    }

    // 2. Also update in sender inbox if stored there
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid != receiverId) {
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(currentUid)
            .collection('messages')
            .doc(messageId)
            .update(updateData);
      } catch (e) {
        debugPrint('[IsarDb] Firestore local chat update error: $e');
      }
    }
  }

  static Future<void> purgeDisappearingMessages() async {
    final setting = SharedPref.instance.getString('privacy_disappearing') ?? 'Off';
    if (setting == 'Off') return;

    Duration? duration;
    if (setting == '24 hours') {
      duration = const Duration(hours: 24);
    } else if (setting == '7 days') {
      duration = const Duration(days: 7);
    } else if (setting == '90 days') {
      duration = const Duration(days: 90);
    }

    if (duration == null) return;
    final cutoff = DateTime.now().subtract(duration);
    final starredIds = SharedPref.instance.getStringList('starred_message_ids') ?? [];

    try {
      final expired = await isar.storedMessages
          .filter()
          .timestampLessThan(cutoff)
          .findAll();

      final toDelete = expired
          .where((m) => !starredIds.contains(m.messageId))
          .map((m) => m.id)
          .toList();

      if (toDelete.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.storedMessages.deleteAll(toDelete);
        });
        debugPrint('[IsarDb] Purged ${toDelete.length} disappearing messages older than $setting');
      }
    } catch (e) {
      debugPrint('[IsarDb] Error purging disappearing messages: $e');
    }
  }

  static Message toMessage(StoredMessage msg) {
    return Message(
      id: msg.messageId,
      content: msg.content,
      senderId: msg.senderId,
      receiverId: msg.receiverId,
      timestamp: Timestamp.fromDate(msg.timestamp),
      status: msg.status,
      attachment: msg.attachment != null
          ? Attachment(
              fileName: msg.attachment!.fileName ?? '',
              fileExtension: msg.attachment!.fileExtension ?? '',
              fileSize: msg.attachment!.fileSize ?? 0,
              width: msg.attachment!.width,
              height: msg.attachment!.height,
              uploadStatus: msg.attachment!.uploadStatus ?? UploadStatus.notUploading,
              autoDownload: msg.attachment!.autoDownload ?? false,
              url: msg.attachment!.url ?? '',
              type: msg.attachment!.type ?? AttachmentType.document,
              samples: msg.attachment!.samples,
            )
          : null,
      isDeleted: msg.content == '🚫 This message was deleted' ||
          msg.content.contains('message was deleted'),
    );
  }

  static Future<List<Message>> getPendingMessages() async {
    final isarInstance = instance;
    if (isarInstance == null) return [];
    try {
      final pending = await isarInstance.storedMessages
          .filter()
          .statusEqualTo(MessageStatus.pending)
          .sortByTimestampDesc()
          .findAll();
      return pending.map((m) => toMessage(m)).toList();
    } catch (e) {
      debugPrint('[IsarDb] Error fetching pending messages: $e');
      return [];
    }
  }

  static Stream<List<Message>> getChatStream(String chatId, {int limit = 100}) {
    // Opportunistically run disappearing messages purge
    purgeDisappearingMessages();

    return isar.storedMessages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .limit(limit)
        .build()
        .watch(fireImmediately: true)
        .map((event) => event.map((msg) => toMessage(msg)).toList());
  }

  static Stream<List<RecentChat>> getRecentChatStream(WidgetRef ref) {
    final rawUser = SharedPref.instance.getString('user');
    if (rawUser == null) {
      return Stream.value(<RecentChat>[]);
    }
    final currentUser = User.fromMap(jsonDecode(rawUser));

    final isarInstance = _instance ?? Isar.getInstance();
    if (isarInstance == null) {
      return Stream.value(<RecentChat>[]);
    }

    return isarInstance.storedMessages
        .where()
        .sortByTimestampDesc()
        .watch(fireImmediately: true)
        .asyncMap((event) async {
      final Map<String, int> visitedChats = {};
      final recentChats = <RecentChat>[];

      for (final msg in event) {
        final clientIsSender = msg.senderId == currentUser.id;
        if (visitedChats.containsKey(msg.chatId)) {
          if (clientIsSender) continue;
          if (msg.status == MessageStatus.seen) continue;

          visitedChats[msg.chatId] = visitedChats[msg.chatId]! + 1;
          continue;
        }

        final peerId = clientIsSender ? msg.receiverId : msg.senderId;

        var sender = await IsarDb.getUserById(peerId);

        Contact? contact;
        if (sender != null && sender.phone.number != null && sender.phone.number!.isNotEmpty) {
          try {
            contact = await ref
                .read(contactsRepositoryProvider)
                .getContactByPhone(sender.phone.number!);
          } catch (e, st) {
            debugPrint('[IsarDb] getContactByPhone error: $e\n$st');
          }
        }

        if (sender == null) {
          try {
            sender = await ref
                .read(firebaseFirestoreRepositoryProvider)
                .getUserById(peerId);
          } catch (e, st) {
            debugPrint('[IsarDb] getUserById from Firestore error: $e\n$st');
          }
        }

        // Safe fallback user if not yet registered in Firestore
        if (sender == null) {
          String displayPhone = peerId;
          if (displayPhone.startsWith('phone_')) {
            displayPhone = displayPhone.replaceFirst('phone_', '');
          }
          sender = User(
            id: peerId,
            name: displayPhone,
            avatarUrl: '',
            phone: Phone(
              code: '',
              number: displayPhone,
              formattedNumber: displayPhone,
            ),
            activityStatus: UserActivityStatus.offline,
          );
        }

        final senderName = contact?.displayName ??
            (sender.name.isNotEmpty
                ? sender.name
                : (sender.phone.formattedNumber ?? sender.phone.number ?? peerId));

        recentChats.add(
          RecentChat(
            message: Message(
              id: msg.messageId,
              content: msg.content,
              senderId: msg.senderId,
              receiverId: msg.receiverId,
              timestamp: Timestamp.fromDate(msg.timestamp),
              status: msg.status,
              attachment: msg.attachment != null
                  ? Attachment(
                      fileName: msg.attachment!.fileName ?? 'file',
                      fileExtension: msg.attachment!.fileExtension ?? '',
                      fileSize: msg.attachment!.fileSize ?? 0,
                      width: msg.attachment!.width,
                      height: msg.attachment!.height,
                      uploadStatus: msg.attachment!.uploadStatus ?? UploadStatus.uploaded,
                      autoDownload: msg.attachment!.autoDownload ?? false,
                      url: msg.attachment!.url ?? '',
                      type: msg.attachment!.type ?? AttachmentType.document,
                      samples: msg.attachment!.samples,
                    )
                  : null,
              isDeleted: msg.content == '🚫 This message was deleted' ||
                  msg.content.contains('message was deleted'),
            ),
            user: User(
              id: sender.id,
              name: senderName,
              avatarUrl: sender.avatarUrl,
              phone: sender.phone,
              activityStatus: sender.activityStatus,
            ),
          ),
        );

        visitedChats[msg.chatId] =
            clientIsSender || msg.status == MessageStatus.seen ? 0 : 1;
      }

      for (final chat in recentChats) {
        chat.unreadCount = visitedChats[
            getChatId(chat.message.senderId, chat.message.receiverId)]!;
      }

      return recentChats;
    });
  }

  static Future<List<User>> getUsers() async {
    final isarInstance = _instance ?? Isar.getInstance();
    if (isarInstance == null) return [];
    return isarInstance.users.where().findAll();
  }

  static Future<void> addContacts() async {
    final providerContainer = ProviderContainer();
    final self = getCurrentUser();

    List<Contact> localContacts = [];
    if (self != null) {
      try {
        localContacts = await providerContainer
            .read(contactsRepositoryProvider)
            .getContacts(self: self)
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint('[IsarDb] addContacts error: $e');
      }
    }

    // Only update cache if new contacts were successfully loaded, never destroy offline cache
    if (localContacts.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.contacts.clear();
        await isar.contacts.putAll(localContacts);
      });
    }
  }

  static Future<void> refreshContacts() async {
    try {
      await IsarDb.addContacts();
    } catch (e) {
      debugPrint('[IsarDb] refreshContacts error: $e');
    }
  }

  static Future<List<Contact>> getContacts() async {
    if (_instance == null && Isar.getInstance() == null) {
      await init();
    }
    final isarInstance = _instance ?? Isar.getInstance();
    if (isarInstance == null) return [];

    final existing = await isarInstance.contacts.where().findAll();
    if (existing.isEmpty) {
      await addContacts();
      return isarInstance.contacts.where().findAll();
    }
    return existing;
  }

  static Future<void> saveUser(User user) async {
    try {
      final isarInstance = _instance ?? Isar.getInstance();
      if (isarInstance == null) return;
      await isarInstance.writeTxn(() async {
        final existing = await isarInstance.users.filter().idEqualTo(user.id).findFirst();
        if (existing != null) {
          user.isarId = existing.isarId;
        }
        await isarInstance.users.put(user);
      });
    } catch (e) {
      debugPrint('IsarDb saveUser error: $e');
    }
  }

  static Future<User?> getUserById(String id) async {
    final local = await isar.users.filter().idEqualTo(id).findFirst();
    if (local != null) return local;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final user = User.fromMap(doc.data()!);
        try {
          await isar.writeTxn(() async {
            await isar.users.put(user);
          });
        } catch (e) {
          debugPrint('[IsarDb] user cache put error: $e');
        }
        return user;
      }
    } catch (e) {
      debugPrint('IsarDb getUserById fallback error: $e');
    }
    return null;
  }

  static Future<List<Contact>> getLivocalContacts() async {
    final list = await isar.contacts.filter().userIdIsNotNull().findAll();
    if (list.isEmpty) {
      await addContacts();
      return await isar.contacts.filter().userIdIsNotNull().findAll();
    }
    return list;
  }

  static Future<void> deleteChat(String chatId) async {
    try {
      final isarInstance = _instance ?? Isar.getInstance();
      if (isarInstance != null) {
        await isarInstance.writeTxn(() async {
          await isarInstance.storedMessages.filter().chatIdEqualTo(chatId).deleteAll();
        });
      }
    } catch (e) {
      debugPrint('IsarDb deleteChat error: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      final isarInstance = _instance ?? Isar.getInstance();
      if (isarInstance != null) {
        await isarInstance.writeTxn(() async {
          await isarInstance.storedMessages.clear();
          await isarInstance.contacts.clear();
          await isarInstance.users.clear();
        });
      }
    } catch (e) {
      debugPrint('IsarDb clearAll error: $e');
    }
  }

  static Future<List<StoredMessage>> getStarredMessagesByIds(List<String> messageIds) async {
    try {
      final isarInstance = _instance ?? Isar.getInstance();
      if (isarInstance == null) return [];
      final List<StoredMessage> results = [];
      for (final id in messageIds) {
        final msg = await isarInstance.storedMessages.filter().messageIdEqualTo(id).findFirst();
        if (msg != null) results.add(msg);
      }
      return results;
    } catch (e) {
      debugPrint('IsarDb getStarredMessagesByIds error: $e');
      return [];
    }
  }

  static Future<List<StoredMessage>> getChatMediaMessages(String chatId) async {
    try {
      final isarInstance = _instance ?? Isar.getInstance();
      if (isarInstance == null) return [];
      return await isarInstance.storedMessages
          .filter()
          .chatIdEqualTo(chatId)
          .attachmentIsNotNull()
          .sortByTimestampDesc()
          .findAll();
    } catch (e) {
      debugPrint('IsarDb getChatMediaMessages error: $e');
      return [];
    }
  }
}
