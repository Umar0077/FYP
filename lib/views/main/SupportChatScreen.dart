import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/support/support_chat_model.dart';
import '../../models/support/support_message_model.dart';
import '../../services/support/support_chat_service.dart';
import '../widgets/AppScaffold.dart';

class SupportChatScreen extends StatefulWidget {
	const SupportChatScreen({super.key});

	@override
	State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
	final SupportChatService _supportChatService = SupportChatService();
	final TextEditingController _messageController = TextEditingController();
	final ScrollController _scrollController = ScrollController();
	final DateFormat _timeFormat = DateFormat('h:mm a');

	String? _chatId;
	bool _isInitializing = true;
	bool _isSending = false;
	String? _error;

	@override
	void initState() {
		super.initState();
		_initChat();
	}

	@override
	void dispose() {
		_messageController.dispose();
		_scrollController.dispose();
		super.dispose();
	}

	Future<void> _initChat() async {
		setState(() {
			_isInitializing = true;
			_error = null;
		});

		try {
			final SupportChatModel chat = await _supportChatService.getOrCreateUserSupportChat();
			if (!mounted) return;
			setState(() {
				_chatId = chat.chatId;
				_isInitializing = false;
			});
			await _supportChatService.markMessagesAsReadForUser(chatId: chat.chatId);
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_error = e.toString();
				_isInitializing = false;
			});
		}
	}

	Future<void> _sendMessage() async {
		if (_chatId == null || _isSending) return;

		final text = _messageController.text.trim();
		if (text.isEmpty) return;

		setState(() => _isSending = true);
		try {
			await _supportChatService.sendUserMessage(chatId: _chatId!, text: text);
			_messageController.clear();
			_scrollToBottom();
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed to send message: $e')),
			);
		} finally {
			if (mounted) {
				setState(() => _isSending = false);
			}
		}
	}

	void _scrollToBottom() {
		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!_scrollController.hasClients) return;
			_scrollController.animateTo(
				_scrollController.position.maxScrollExtent,
				duration: const Duration(milliseconds: 250),
				curve: Curves.easeOut,
			);
		});
	}

	Widget _buildMessageBubble(SupportMessageModel message, bool isDark) {
		final isUser = message.isUserMessage;
		final bubbleColor = isUser
				? (isDark ? const Color(0xFF1B215E) : const Color(0xFFDCE3FF))
				: (isDark ? const Color(0xFF0A1733) : const Color(0xFFF1F3FC));
		final textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);

		return Align(
			alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
			child: ConstrainedBox(
				constraints: const BoxConstraints(maxWidth: 300),
				child: Container(
					margin: const EdgeInsets.symmetric(vertical: 5),
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
					decoration: BoxDecoration(
						color: bubbleColor,
						borderRadius: BorderRadius.circular(12),
					),
					child: Column(
						crossAxisAlignment:
								isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
						children: [
							Text(
								message.text,
								style: TextStyle(color: textColor),
							),
							const SizedBox(height: 4),
							Text(
								message.createdAt != null
										? _timeFormat.format(message.createdAt!)
										: 'Sending...',
								style: TextStyle(
									fontSize: 10,
									color: isDark ? Colors.white70 : const Color(0xFF5D6691),
								),
							),
						],
					),
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color inputBgColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF2F4FF);
		final Color inputFieldColor = isDark ? const Color(0xFF0A0F2E) : Colors.white;
		final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color iconBgColor = isDark ? Colors.white10 : const Color(0xFFE8EBF8);
		final Color iconColor = isDark ? const Color(0xFF0A0F2E) : const Color(0xFF00002E);
		final Color inputHintColor = isDark ? Colors.white54 : const Color(0xFF7C86B2);
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;

		return AppScaffold(
			appBarTitle: 'Customer Support',
			resizeToAvoidBottomInset: true,
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: _isInitializing
						? const Center(child: CircularProgressIndicator())
						: _error != null
								? Center(
										child: Padding(
											padding: const EdgeInsets.all(20),
											child: Column(
												mainAxisSize: MainAxisSize.min,
												children: [
													Text(
														'Failed to load support chat',
														style: TextStyle(
															color: isDark ? Colors.white : const Color(0xFF0A0F2E),
															fontWeight: FontWeight.w700,
														),
													),
													const SizedBox(height: 8),
													Text(_error!),
													const SizedBox(height: 12),
													ElevatedButton(onPressed: _initChat, child: const Text('Retry')),
												],
											),
										),
								)
								: Column(
										children: [
											Expanded(
												child: StreamBuilder<List<SupportMessageModel>>(
													stream: _supportChatService.streamUserSupportMessages(chatId: _chatId!),
													builder: (context, snapshot) {
														if (snapshot.connectionState == ConnectionState.waiting) {
															return const Center(child: CircularProgressIndicator());
														}

														if (snapshot.hasError) {
															return Center(child: Text('Error loading messages: ${snapshot.error}'));
														}

														final messages = snapshot.data ?? <SupportMessageModel>[];
														if (messages.isNotEmpty) {
															_supportChatService.markMessagesAsReadForUser(chatId: _chatId!);
															_scrollToBottom();
														}

														if (messages.isEmpty) {
															return Center(
																child: Text(
																	'Start conversation with support',
																	style: TextStyle(
																		color: isDark ? Colors.white70 : const Color(0xFF27308A),
																		fontWeight: FontWeight.w600,
																	),
																),
															);
														}

														return ListView.builder(
															controller: _scrollController,
															padding: EdgeInsets.fromLTRB(
																16,
																16,
																16,
																MediaQuery.of(context).viewInsets.bottom + 96,
															),
															itemCount: messages.length,
															itemBuilder: (_, index) => _buildMessageBubble(messages[index], isDark),
														);
													},
												),
											),
											SafeArea(
												top: false,
												child: Container(
													padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
													color: inputBgColor,
													child: Row(
														children: [
															Expanded(
																child: Container(
																	padding: const EdgeInsets.symmetric(horizontal: 12),
																	decoration: BoxDecoration(
																		color: inputFieldColor,
																		borderRadius: BorderRadius.circular(30),
																		border: Border.all(color: borderColor),
																	),
																	child: TextField(
																		controller: _messageController,
																		textInputAction: TextInputAction.send,
																		onSubmitted: (_) => _sendMessage(),
																		minLines: 1,
																		maxLines: 4,
																		decoration: InputDecoration.collapsed(
																			hintText: 'Write now..',
																			hintStyle: TextStyle(color: inputHintColor),
																		),
																		style: TextStyle(color: isDark ? Colors.white : Colors.black87),
																	),
																),
															),
															const SizedBox(width: 10),
															Container(
																decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
																child: IconButton(
																	onPressed: _isSending ? null : _sendMessage,
																	icon: _isSending
																			? SizedBox(
																				width: 18,
																				height: 18,
																				child: CircularProgressIndicator(
																					strokeWidth: 2,
																					color: iconColor,
																				),
																			)
																			: Icon(Icons.send, color: iconColor, size: 18),
																),
															),
														],
													),
												),
											),
										],
								),
			),
		);
	}
}