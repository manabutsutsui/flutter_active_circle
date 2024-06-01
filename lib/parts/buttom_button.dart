import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ButtomButton extends StatelessWidget {
  const ButtomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 0, // 影を取り除く
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => context.go('/profile_list'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

