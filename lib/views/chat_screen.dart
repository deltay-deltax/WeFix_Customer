import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModels/chat_viewmodel.dart';
import '../widgets/message_bubble.dart';
import '../core/constants/app_routes.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: Consumer<ChatViewModel>(
        builder: (context, vm, child) => Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {},
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.store, color: Colors.black),
                ),
                SizedBox(width: 12),
                Text(
                  vm.shopName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.call, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(height: 12),
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Today",
                  style: TextStyle(
                    backgroundColor: Colors.grey[200],
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: vm.messages.length,
                  reverse: false,
                  itemBuilder: (context, i) =>
                      MessageBubble(message: vm.messages[i]),
                ),
              ),
              // Hardcoded Message Input Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Material(
                      color: Color(0xFF4285F4),
                      shape: CircleBorder(),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: () {},
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
            currentIndex: 2,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, AppRoutes.orders);
                  break;
                case 2:
                  // already here
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, AppRoutes.profile);
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}
