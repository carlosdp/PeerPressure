import 'package:flutter/material.dart';
import 'package:flutter_app/components/profile_card.dart';
import 'package:flutter_app/models/swipe.dart';
import 'package:flutter_app/components/support_card.dart';
import 'package:flutter_app/screens/match.dart';
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: model.currentProfile != null
                        ? ProfileCard(
                            key: Key(model.currentProfile!.id),
                            profile: model.currentProfile!)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: model.previousProfile,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromRGBO(98, 0, 222, 0.7),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.25),
                              offset: Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child:
                            const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 65),
                    InkWell(
                      onTap: model.nextProfile,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromRGBO(98, 0, 222, 0.7),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.25),
                              offset: Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                model.match != null
                    ? SupportCard(
                        match: model.match!,
                        onTap: () {
                          if (model.matchingProfile != null &&
                              model.currentProfile != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MatchScreen(
                                  matchingProfile: model.matchingProfile!,
                                  swipedProfile: model.currentProfile!,
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }
}
