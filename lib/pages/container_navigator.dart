import 'package:flutter/material.dart';
import 'package:niteni/pages/chat/chat_page.dart';
import 'package:niteni/pages/home/home_page.dart';
import 'package:niteni/pages/panen/list_panen_page.dart';
import 'lahan/lahan_page.dart';
import 'semaian/semaian_page.dart';

// import 'profile/profile_page.dart';

class ContainerNavigator extends StatefulWidget {
  const ContainerNavigator({super.key});

  @override
  State<ContainerNavigator> createState() => _ContainerNavigatorState();
}

class _ContainerNavigatorState extends State<ContainerNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SemaianPage(),
    const LahanPage(),
    const ListPanenPage(),
    const ChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: const Color(0xFFEEEEEE),
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF2E7D32),
              unselectedItemColor: Colors.grey,
              enableFeedback: false,
              mouseCursor: SystemMouseCursors.basic,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.eco),
                  label: 'Semaian',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.terrain),
                  label: 'Lahan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.agriculture),
                  label: 'Panen',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome),
                  label: 'Tanya AI',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
