import 'package:flutter/material.dart';
import 'package:flutter_app/models/swipe.dart';
import 'package:provider/provider.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  @override
  void initState() {
    super.initState();

    Provider.of<SwipeModel>(context, listen: false).updateMatchingProfile();
    Provider.of<SwipeModel>(context, listen: false).updateContestantProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SwipeModel>(
      builder: (context, model, child) {
        return SafeArea(
          child: Center(
            child: Column(
              children: [
                Text(model.matchingProfile?.firstName ?? 'No matching profile'),
                Text(model.currentProfile?.firstName ?? 'No profiles'),
              ],
            ),
          ),
        );
      },
    );
  }
}
