import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/auth_provider.dart' as myAuth;
import 'package:weather_app/screens/login_screen.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _replyController = TextEditingController();
  String? selectedUserId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> deleteMessage(BuildContext context, String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('GP3_chats')
          .doc('Alexandria')
          .collection('group_chat')
          .doc(messageId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.black, Colors.indigo.shade900]
              : [Colors.lightBlue.shade100, Colors.blue.shade300],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'support_management'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
                color: isDarkMode ? Colors.tealAccent : Colors.blue,
              ),
              onPressed: () async {
                try {
                  final authProvider =
                      Provider.of<myAuth.AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  if (!mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('logged_out'.tr())),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('logout_failed'.tr())),
                  );
                }
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: isDarkMode ? Colors.tealAccent : Colors.blue,
            labelColor: isDarkMode ? Colors.tealAccent : Colors.blue,
            unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.black54,
            tabs: [
              Tab(text: 'support_chat'.tr()),
              Tab(text: 'reported_messages'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Support Chats Tab
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? Colors.tealAccent : Colors.blue,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'no_users'.tr(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userId = userDoc.id;
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final userName = userData['displayName'] ?? 'Unknown User';
                    final userEmail = userData['email'] ?? 'No Email';
                    final supportChatId = 'support_$userId';

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('GP3_chats')
                          .doc(supportChatId)
                          .snapshots(),
                      builder: (context, chatSnapshot) {
                        // Check if document exists and has data
                        final hasUnreadWarning = chatSnapshot.hasData &&
                            chatSnapshot.data!.exists &&
                            chatSnapshot.data!.get('hasUnreadWarning') == true;

                        final lastMessageTime =
                            chatSnapshot.hasData && chatSnapshot.data!.exists
                                ? chatSnapshot.data!.get('lastMessageTime')
                                    as Timestamp?
                                : null;

                        return Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: isDarkMode
                              ? Colors.black54
                              : Colors.white.withOpacity(0.9),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isDarkMode
                                      ? Colors.tealAccent
                                      : Colors.blue,
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                if (hasUnreadWarning)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.black54
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('GP3_chats')
                                  .doc(supportChatId)
                                  .collection('group_chat')
                                  .orderBy('time', descending: true)
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, messageSnapshot) {
                                if (!messageSnapshot.hasData ||
                                    messageSnapshot.data!.docs.isEmpty) {
                                  return Text(
                                    'no_messages'.tr(),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  );
                                }

                                final lastMessage =
                                    messageSnapshot.data!.docs.first;
                                final timestamp =
                                    lastMessage['time'] as Timestamp?;
                                final timeStr = timestamp != null
                                    ? DateFormat('MMM d, HH:mm')
                                        .format(timestamp.toDate())
                                    : '';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lastMessage['message'] ??
                                          'no_message'.tr(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    if (timeStr.isNotEmpty)
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black45,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedUserId = userId;
                                });
                                _showChatDialog(context, supportChatId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.tealAccent
                                    : Colors.blue,
                                foregroundColor:
                                    isDarkMode ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'view_chat'.tr(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            // Reported Messages Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? Colors.tealAccent : Colors.blue,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'no_reported_messages'.tr(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final report = snapshot.data!.docs[index];
                    final data = report.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: isDarkMode
                          ? Colors.black54
                          : Colors.white.withOpacity(0.9),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          'Reported by: ${data['reportedByName'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Reason: ${data['reason']}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        iconColor: isDarkMode ? Colors.tealAccent : Colors.blue,
                        collapsedIconColor:
                            isDarkMode ? Colors.tealAccent : Colors.blue,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reported Message:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['reportedMessage'],
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Reported User:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['reportedUser'],
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final String? reportedUserId =
                                            data['reportedUserId'];
                                        if (reportedUserId == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Cannot warn user: No user ID found'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        _showWarningDialog(
                                            context, reportedUserId);
                                      },
                                      icon: Icon(
                                        Icons.warning_amber_rounded,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      label: Text(
                                        'warn_user'.tr(),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StreamBuilder<DocumentSnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(data['reportedUserId'])
                                          .snapshots(),
                                      builder: (context, userSnapshot) {
                                        if (!userSnapshot.hasData ||
                                            !userSnapshot.data!.exists) {
                                          return const SizedBox.shrink();
                                        }

                                        final userData = userSnapshot.data!
                                            .data() as Map<String, dynamic>?;
                                        final isBanned =
                                            userData?['isBanned'] == true;

                                        return ElevatedButton.icon(
                                          onPressed: () => isBanned
                                              ? _showUnbanDialog(context,
                                                  data['reportedUserId'])
                                              : _showBanDialog(context,
                                                  data['reportedUserId']),
                                          icon: Icon(
                                            isBanned
                                                ? Icons.lock_open
                                                : Icons.lock,
                                            color: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                          label: Text(
                                            isBanned
                                                ? 'unban_user'.tr()
                                                : 'ban_user'.tr(),
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isBanned
                                                ? Colors.green
                                                : Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                  ],
                                ),
                                const SizedBox(height: 15,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    
                                ElevatedButton.icon(
                                      onPressed: () {
                                        final String? messageId =
                                            data['messageId'];
                                        if (messageId == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Cannot delete message: No message ID found'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        deleteMessage(
                                            context, messageId);
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      label: Text(
                                        'Delete message'.tr(),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatDialog(BuildContext context, String chatId) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(selectedUserId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      final userData =
                          userSnapshot.data?.data() as Map<String, dynamic>?;
                      final userName = userData?['name'] ?? 'Unknown User';
                      final userEmail = userData?['email'] ?? 'No Email';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.tealAccent : Colors.blue,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('GP3_chats')
                      .doc(chatId)
                      .collection('group_chat')
                      .orderBy('time', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: isDarkMode ? Colors.tealAccent : Colors.blue,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'no_messages'.tr(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final message = snapshot.data!.docs[index];
                        final isAdmin = message['senderId'] == 'admin';
                        final timestamp = message['time'] as Timestamp?;
                        final timeStr = timestamp != null
                            ? DateFormat('HH:mm').format(timestamp.toDate())
                            : '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isAdmin
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isAdmin) ...[
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(message['senderId'])
                                      .snapshots(),
                                  builder: (context, userSnapshot) {
                                    final userData = userSnapshot.data?.data()
                                        as Map<String, dynamic>?;
                                    final userName =
                                        userData?['name'] ?? 'Unknown User';

                                    return Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isDarkMode
                                              ? Colors.tealAccent
                                              : Colors.blue,
                                          child: Text(
                                            userName.isNotEmpty
                                                ? userName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? (isDarkMode
                                            ? Colors.tealAccent
                                            : Colors.blue)
                                        : (isDarkMode
                                            ? Colors.black54
                                            : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isAdmin
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['message'] ?? 'no_message'.tr(),
                                        style: TextStyle(
                                          color: isAdmin
                                              ? (isDarkMode
                                                  ? Colors.black
                                                  : Colors.white)
                                              : (isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                      ),
                                      if (timeStr.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isAdmin
                                                ? (isDarkMode
                                                    ? Colors.black54
                                                    : Colors.white70)
                                                : (isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isDarkMode
                                      ? Colors.tealAccent
                                      : Colors.blue,
                                  child: Icon(
                                    Icons.admin_panel_settings,
                                    size: 16,
                                    color: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: 'type_message'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? Colors.tealAccent : Colors.blue,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.tealAccent.withOpacity(0.5)
                                  : Colors.blue.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDarkMode ? Colors.tealAccent : Colors.blue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.black26 : Colors.white,
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        if (_replyController.text.trim().isEmpty) return;

                        try {
                          await FirebaseFirestore.instance
                              .collection('GP3_chats')
                              .doc(chatId)
                              .collection('group_chat')
                              .add({
                            'message': _replyController.text.trim(),
                            'senderId': 'admin',
                            'time': FieldValue.serverTimestamp(),
                          });

                          // Update the last message time in the chat document
                          await FirebaseFirestore.instance
                              .collection('GP3_chats')
                              .doc(chatId)
                              .update({
                            'lastMessageTime': FieldValue.serverTimestamp(),
                          });

                          _replyController.clear();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('error_sending_message'.tr())),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.send,
                        color: isDarkMode ? Colors.tealAccent : Colors.blue,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWarningDialog(BuildContext context, String userId) async {
    final TextEditingController warningController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'warn_user'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: warningController,
                decoration: InputDecoration(
                  hintText: 'enter_warning_message'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.tealAccent : Colors.blue,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.tealAccent.withOpacity(0.5)
                          : Colors.blue.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.tealAccent : Colors.blue,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.black26 : Colors.white,
                ),
                maxLines: 3,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'cancel'.tr(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.tealAccent : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (warningController.text.trim().isEmpty) return;

                      try {
                        final supportChatId = 'support_$userId';
                        await FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(supportChatId)
                            .collection('group_chat')
                            .add({
                          'message': warningController.text.trim(),
                          'senderId': 'admin',
                          'time': FieldValue.serverTimestamp(),
                          'isWarning': true,
                          'isRead': false,
                        });

                        await FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(supportChatId)
                            .set({
                          'hasUnreadWarning': true,
                          'lastWarningTime': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('warning_sent'.tr())),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('warning_failed'.tr()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text('send'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBanDialog(BuildContext context, String userId) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ban_user'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'confirm_ban_user'.tr(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'cancel'.tr(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.tealAccent : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({
                          'isBanned': true,
                          'bannedAt': FieldValue.serverTimestamp(),
                          'bannedBy': 'admin',
                        });

                        // Update the report status to Resolved
                        await FirebaseFirestore.instance
                            .collection('reports')
                            .where('reportedUserId', isEqualTo: userId)
                            .where('status', isEqualTo: 'Pending')
                            .get()
                            .then((snapshot) {
                          for (var doc in snapshot.docs) {
                            doc.reference.update({'status': 'Resolved'});
                          }
                        });

                        final supportChatId = 'support_$userId';
                        await FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(supportChatId)
                            .collection('group_chat')
                            .add({
                          'message':
                              'You have been banned from participating in city chats. You can still use the support chat.',
                          'senderId': 'admin',
                          'time': FieldValue.serverTimestamp(),
                          'isWarning': true,
                          'isRead': false,
                        });

                        await FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(supportChatId)
                            .set({
                          'hasUnreadWarning': true,
                          'lastWarningTime': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('user_banned'.tr())),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ban_failed'.tr())),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text('ban'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUnbanDialog(BuildContext context, String userId) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDarkMode ? Colors.black87 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'unban_user'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'confirm_unban_user'.tr(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'cancel'.tr(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.tealAccent : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({
                          'isBanned': false,
                          'unbannedAt': FieldValue.serverTimestamp(),
                          'unbannedBy': 'admin',
                        });

                        // Update the report status to Resolved
                        await FirebaseFirestore.instance
                            .collection('reports')
                            .where('reportedUserId', isEqualTo: userId)
                            .where('status', isEqualTo: 'Pending')
                            .get()
                            .then((snapshot) {
                          for (var doc in snapshot.docs) {
                            doc.reference.update({'status': 'Resolved'});
                          }
                        });

                        final supportChatId = 'support_$userId';
                        await FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(supportChatId)
                            .collection('group_chat')
                            .add({
                          'message':
                              'Your ban has been lifted. You can now participate in city chats again.',
                          'senderId': 'admin',
                          'time': FieldValue.serverTimestamp(),
                          'isWarning': true,
                          'isRead': false,
                        });

                        await FirebaseFirestore.instance
                            .collection('GP3_chats')
                            .doc(supportChatId)
                            .set({
                          'hasUnreadWarning': true,
                          'lastWarningTime': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('user_unbanned'.tr())),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('unban_failed'.tr())),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text('unban'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
