import 'package:flutter/material.dart';
import 'package:flutter_app/components/profile_card.dart';
import 'package:flutter_app/components/support_allocator.dart';
import 'package:flutter_app/components/top_bar.dart';
import 'package:flutter_app/supabase_types.dart';

class MatchScreen extends StatefulWidget {
  final Profile matchingProfile;
  final Profile swipedProfile;

  const MatchScreen({
    super.key,
    required this.matchingProfile,
    required this.swipedProfile,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Container(
        color: Colors.white,
        height: double.infinity,
        child: SafeArea(
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 200,
                    child: ProfileCard(profile: widget.matchingProfile),
                  ),
                  SizedBox(
                    width: 200,
                    child: ProfileCard(profile: widget.swipedProfile),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: SupportAllocator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
