import 'package:flutter/material.dart';
import '../data/models/chat_message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final String shopName = "ElectroShop";
  final String shopSubtitle = "Battery Replacement Service";
  final List<ChatMessageModel> messages = [
    ChatMessageModel(
      "Hello, I'd like to inquire about a battery replacement for my phone. It's a Model X.",
      true,
      "10:00 AM",
    ),
    ChatMessageModel(
      "Hi there! We can certainly help with that. The cost for a Model X battery replacement is \$89 and it takes about 45 minutes.",
      false,
      "10:01 AM",
    ),
    ChatMessageModel(
      "That sounds great. Can I book a time to bring my device in?",
      true,
      "10:03 AM",
    ),
    ChatMessageModel(
      "Of course. We have an opening today at 2 PM. Does that work for you?",
      false,
      "10:04 AM",
    ),
  ];
}
