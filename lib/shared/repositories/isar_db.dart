import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whatsapp_clone/features/chat/models/attachement.dart';
import 'package:whatsapp_clone/features/chat/models/recent_chat.dart';
import 'package:whatsapp_clone/features/home/data/repositories/contact_repository.dart';
import 'package:whatsapp_clone/shared/models/contact.dart';
import 'package:whatsapp_clone/shared/models/messages.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/shared/repositories/firebase_firestore.dart';
import 'package:whatsapp_clone/shared/utils/abc.dart';
import 'package:whatsapp_clone/shared/utils/shared_pref.dart';

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
      await isar.storedMessages.put(storedMsg);
    });
  }

  static Future<void> addMessages(List<Message> messages) async {
    final storedMessages = messages
        .map(
          (message) => StoredMessage(
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
          ),
        )
        .toList();

    await isar.writeTxn(() async {
      await isar.storedMessages.putAll(storedMessages);
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
      msg.status = status ?? msg.status;

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

  static Stream<List<Message>> getChatStream(String chatId) {
    return isar.storedMessages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByTimestampDesc()
        .build()
        .watch(fireImmediately: true)
        .map((event) => event
            .map(
              (msg) => Message(
                id: msg.messageId,
                content: msg.content,
                senderId: msg.senderId,
                receiverId: msg.receiverId,
                timestamp: Timestamp.fromDate(msg.timestamp),
                status: msg.status,
                attachment: msg.attachment != null
                    ? Attachment(
                        fileName: msg.attachment!.fileName!,
                        fileExtension: msg.attachment!.fileExtension!,
                        fileSize: msg.attachment!.fileSize!,
                        width: msg.attachment!.width,
                        height: msg.attachment!.height,
                        uploadStatus: msg.attachment!.uploadStatus!,
                        autoDownload: msg.attachment!.autoDownload ?? false,
                        url: msg.attachment!.url!,
                        type: msg.attachment!.type!,
                        samples: msg.attachment!.samples,
                      )
                    : null,
              ),
            )
            .toList());
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

        var sender = await IsarDb.getUserById(
          clientIsSender ? msg.receiverId : msg.senderId,
        );

        Contact? contact;
        if (sender != null) {
          contact = await ref
              .read(contactsRepositoryProvider)
              .getContactByPhone(sender.phone.number!);
        }

        sender ??= await ref
            .read(firebaseFirestoreRepositoryProvider)
            .getUserById(
              msg.senderId == currentUser.id ? msg.receiverId : msg.senderId,
            );

        final senderName =
            contact?.displayName ?? sender!.phone.formattedNumber;

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
                      fileName: msg.attachment!.fileName!,
                      fileExtension: msg.attachment!.fileExtension!,
                      fileSize: msg.attachment!.fileSize!,
                      width: msg.attachment!.width,
                      height: msg.attachment!.height,
                      uploadStatus: msg.attachment!.uploadStatus!,
                      autoDownload: msg.attachment!.autoDownload ?? false,
                      url: msg.attachment!.url!,
                      type: msg.attachment!.type!,
                    )
                  : null,
            ),
            user: User.fromMap(
              sender!.toMap()..addAll({'name': senderName}),
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

  static List<User> getDemoUsers() {
    return const [];
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
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    await isar.writeTxn(() async {
      await isar.contacts.putAll(localContacts);
    });
  }

  static Future<void> refreshContacts() async {
    try {
      await isar.writeTxn(() async {
        await isar.contacts.clear();
        await isar.users.clear();
      });
      await IsarDb.addContacts();
    } catch (_) {}
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

  static Future<User?> getUserById(String id) async {
    return await isar.users.filter().idEqualTo(id).findFirst();
  }

  static Future<List<Contact>> getWhatsAppContacts() async {
    final list = await isar.contacts.filter().userIdIsNotNull().findAll();
    if (list.isEmpty) {
      await addContacts();
      return await isar.contacts.filter().userIdIsNotNull().findAll();
    }
    return list;
  }
}
