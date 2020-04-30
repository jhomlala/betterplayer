import 'package:better_player/better_player.dart';
import 'package:better_player_example/playlist_page/playlist_page.dart';
import 'package:better_player_example/video_list/video_list_page.dart';
import 'package:flutter/material.dart';

import 'general_page/general_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better player demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const List<String> pageTitles = ["General", "Playlist", "Video list"];

  BetterPlayerController betterPlayerController;
  List dataSourceList = List<BetterPlayerDataSource>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Better Player - ${pageTitles[_selectedIndex]}"),
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            title: Text(pageTitles[0]),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            title: Text(pageTitles[1]),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text(pageTitles[2]),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedPage() {
    if (_selectedIndex == 0) {
      return GeneralPage();
    } else if (_selectedIndex == 1) {
      return PlaylistPage();
    } else {
      return VideoListPage();
    }
  }
}
