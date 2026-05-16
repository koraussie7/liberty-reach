import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import '../widgets/loops_preview_bar.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          automaticallyImplyLeading: false,
          expandedHeight: 620,
          collapsedHeight: 138,
          toolbarHeight: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: LoopsPreviewBar(),
          ),
        ),
        SliverToBoxAdapter(
          child: ChatListScreen(),
        ),
      ],
    );
  }
}
