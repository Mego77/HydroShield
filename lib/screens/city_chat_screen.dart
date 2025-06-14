import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/providers/auth_provider.dart' as myAuth;
import 'package:easy_localization/easy_localization.dart';

// Custom painter for message bubble tail
class MessageTailPainter extends CustomPainter {
  final bool isSender;
  final Color color;
  final bool isDarkMode;

  MessageTailPainter(
      {required this.isSender, required this.color, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isSender) {
      // Right tail for sender
      path.moveTo(0, 0);
      path.lineTo(10, 0);
      path.lineTo(0, 10);
      path.close();
    } else {
      // Left tail for receiver
      path.moveTo(0, 0);
      path.lineTo(-10, 0);
      path.lineTo(0, 10);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CityChatScreen extends StatefulWidget {
  final bool isAlexandriaChat;
  final bool isSupportChat;

  const CityChatScreen({
    super.key,
    this.isAlexandriaChat = false,
    this.isSupportChat = false,
  });

  @override
  State<CityChatScreen> createState() => _CityChatScreenState();
}

class _CityChatScreenState extends State<CityChatScreen> {
  final TextEditingController _message = TextEditingController();
  final TextEditingController _reportReason = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isSupportChat) {
      _markWarningsAsRead();
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _reportReason.dispose();
    super.dispose();
  }

  Future<void> _markWarningsAsRead() async {
    if (!widget.isSupportChat) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final supportChatDoc = FirebaseFirestore.instance
          .collection('GP3_chats')
          .doc('support_${user.uid}');

      // Mark all unread warnings as read
      await FirebaseFirestore.instance
          .collection('GP3_chats')
          .doc('support_${user.uid}')
          .collection('group_chat')
          .where('isWarning', isEqualTo: true)
          .where('isRead', isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'isRead': true});
        }
      });

      // Update the support chat document
      await supportChatDoc.update({
        'hasUnreadWarning': false,
        'lastWarningTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking warnings as read: $e');
    }
  }

  Future<void> _showReportDialog(BuildContext context, String messageId,
      String senderName, String messageText, String senderId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('report_message'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('report_reason'.tr()),
            const SizedBox(height: 8),
            TextField(
              controller: _reportReason,
              decoration: InputDecoration(
                hintText: 'enter_report_reason'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _reportReason.clear();
              Navigator.pop(context);
            },
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_reportReason.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('report_reason_required'.tr())),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser!;
                print('=== Creating Report ===');
                print('Message ID: $messageId');
                print('Message Text: $messageText');
                print('Sender Name: $senderName');
                print('Sender ID: $senderId');

                final reportData = {
                  'messageId': messageId,
                  'reportedMessage': messageText,
                  'reportedBy': user.uid,
                  'reportedByName': user.displayName ?? 'unknown'.tr(),
                  'reportedUser': senderName,
                  'reportedUserId': senderId,
                  'reason': _reportReason.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'pending',
                };

                print('Report Data to be stored: $reportData');

                await FirebaseFirestore.instance
                    .collection('reports')
                    .add(reportData);

                print('Report created successfully');

                _reportReason.clear();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('report_submitted'.tr())),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('report_failed'.tr())),
                );
              }
            },
            child: Text('submit'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<WeatherProvider>(context);
    final authProvider = Provider.of<myAuth.AuthProvider>(context);
    final String cityName = widget.isSupportChat
        ? 'support_${FirebaseAuth.instance.currentUser!.uid}'
        : (widget.isAlexandriaChat ? 'Alexandria' : locationProvider.cityName!);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSupportChat
              ? "customer_support".tr()
              : (widget.isAlexandriaChat
                  ? "alexandria_chat".tr()
                  : "group_chat".tr(namedArgs: {'city': cityName})),
          style: TextStyle(
            color: isDarkMode
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      theme.colorScheme.surface,
                      theme.colorScheme.primaryContainer
                    ]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.primaryContainer.withOpacity(0.7)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: theme.shadowColor.withOpacity(0.3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('GP3_chats')
                    .doc(cityName)
                    .collection('group_chat')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isSupportChat
                                ? "no_support_messages".tr()
                                : (widget.isAlexandriaChat
                                    ? "no_messages_alexandria".tr()
                                    : "no_messages".tr()),
                            style: TextStyle(
                              color: isDarkMode
                                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.isSupportChat) ...[
                            const SizedBox(height: 16),
                            Text(
                              "support_help_text".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDarkMode
                                    ? theme.colorScheme.onSurface
                                        .withOpacity(0.7)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  var messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      print('=== Message Data ===');
                      print('Message ID: ${message.id}');
                      print('Message Data: ${message.data()}');

                      // Get the message data safely
                      final Map<String, dynamic>? messageData =
                          message.data() as Map<String, dynamic>?;
                      if (messageData == null) {
                        print('Message data is null');
                        return const SizedBox.shrink();
                      }

                      final String? senderId = messageData['senderId'];
                      final bool isMe = senderId != null &&
                          senderId == FirebaseAuth.instance.currentUser!.uid;

                      final bubbleColor = isMe
                          ? (isDarkMode
                              ? theme.colorScheme.primaryContainer
                                  .withOpacity(0.9)
                              : theme.colorScheme.primaryContainer)
                          : (isDarkMode
                              ? theme.colorScheme.surfaceContainer
                              : theme.colorScheme.surface);

                      return GestureDetector(
                        onLongPress: isMe
                            ? null
                            : () {
                                print('=== Message Data for Report ===');
                                print('Raw message data: $messageData');

                                final String? reportSenderId =
                                    messageData['senderId'];
                                print('Found sender ID: $reportSenderId');

                                if (reportSenderId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Cannot report: No sender ID found'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                _showReportDialog(
                                  context,
                                  message.id,
                                  messageData['senderName'] ?? 'unknown'.tr(),
                                  messageData['message'] ?? 'no_message'.tr(),
                                  reportSenderId,
                                );
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 4),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: isDarkMode
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.7)
                                      : theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        minWidth: 50,
                                      ),
                                      margin: EdgeInsets.only(
                                        left: isMe ? 8 : 0,
                                        right: isMe ? 0 : 8,
                                        bottom: 10,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bubbleColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(12),
                                          topRight: const Radius.circular(12),
                                          bottomLeft: isMe
                                              ? const Radius.circular(12)
                                              : const Radius.circular(0),
                                          bottomRight: isMe
                                              ? const Radius.circular(0)
                                              : const Radius.circular(12),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.shadowColor
                                                .withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IntrinsicWidth(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isMe
                                                  ? (authProvider.displayName ??
                                                      'unknown'.tr())
                                                  : (messageData[
                                                          'senderName'] ??
                                                      'unknown'.tr()),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDarkMode
                                                    ? theme
                                                        .colorScheme.onSurface
                                                        .withOpacity(0.9)
                                                    : theme
                                                        .colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              messageData['message'] ??
                                                  'no_message'.tr(),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDarkMode
                                                    ? theme
                                                        .colorScheme.onSurface
                                                    : theme
                                                        .colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                messageData['time'] != null
                                                    ? DateFormat('HH:mm')
                                                        .format(
                                                            messageData['time']
                                                                .toDate())
                                                    : "sending".tr(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? theme
                                                          .colorScheme.onSurface
                                                          .withOpacity(0.6)
                                                      : theme
                                                          .colorScheme.onSurface
                                                          .withOpacity(0.6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: isMe ? null : -4,
                                      right: isMe ? -4 : null,
                                      child: CustomPaint(
                                        size: const Size(10, 10),
                                        painter: MessageTailPainter(
                                          isSender: isMe,
                                          color: bubbleColor,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: isDarkMode
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.7)
                                      : theme.colorScheme.onSurface,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      decoration: InputDecoration(
                        hintText: widget.isSupportChat
                            ? "type_support_message".tr()
                            : "type_message".tr(),
                        filled: true,
                        fillColor: isDarkMode
                            ? theme.colorScheme.surfaceContainer
                            : theme.colorScheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      if (_message.text.trim().isEmpty) return;
                      try {
                        final user = FirebaseAuth.instance.currentUser!;

                        // Check if user is banned
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();

                        // If user is banned and trying to send message in city chat
                        if (userDoc.exists &&
                            userDoc.data() != null &&
                            userDoc.data()?['isBanned'] == true &&
                            !widget.isSupportChat) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('you_are_banned'.tr()),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // If user is banned and this is support chat, allow sending
                        if (widget.isSupportChat) {
                          final currentName =
                              authProvider.displayName ?? 'unknown'.tr();
                          await FirebaseFirestore.instance
                              .collection('GP3_chats')
                              .doc(cityName)
                              .collection('group_chat')
                              .add({
                            'message': _message.text.trim(),
                            'senderId': user.uid,
                            'senderName': currentName,
                            'time': FieldValue.serverTimestamp(),
                            'isSupportMessage': true,
                          });

                          // Mark any unread warnings as read
                          await FirebaseFirestore.instance
                              .collection('GP3_chats')
                              .doc(cityName)
                              .collection('group_chat')
                              .where('isWarning', isEqualTo: true)
                              .where('isRead', isEqualTo: false)
                              .get()
                              .then((snapshot) {
                            for (var doc in snapshot.docs) {
                              doc.reference.update({'isRead': true});
                            }
                          });

                          // Update the support chat document to mark warnings as read
                          await FirebaseFirestore.instance
                              .collection('GP3_chats')
                              .doc(cityName)
                              .update({'hasUnreadWarning': false});
                        } else {
                          // Normal message sending for non-banned users in city chats
                          final currentName =
                              authProvider.displayName ?? 'unknown'.tr();
                          await FirebaseFirestore.instance
                              .collection('GP3_chats')
                              .doc(cityName)
                              .collection('group_chat')
                              .add({
                            'message': _message.text.trim(),
                            'senderId': user.uid,
                            'senderName': currentName,
                            'time': FieldValue.serverTimestamp(),
                          });
                        }

                        _message.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('send_message_failed'
                                  .tr(args: [e.toString()]))),
                        );
                      }
                    },
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
