import 'package:flutter/material.dart';
import 'package:flutter_app/supabase_types.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileCard extends StatefulWidget {
  final Profile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late Future<String> imageUrl;

  @override
  void initState() {
    super.initState();

    imageUrl = widget.profile.profileImageUrl();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            FutureBuilder(
              future: imageUrl,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return Image.network(
                  snapshot.data as String,
                );
              },
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.6, 1],
                    colors: [
                      Colors.transparent,
                      Color.fromARGB(0, 146, 146, 146),
                      Color.fromARGB(204, 19, 23, 39)
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const Flexible(
                  flex: 4,
                  fit: FlexFit.tight,
                  child: SizedBox(),
                ),
                Flexible(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 5,
                          child: AutoSizeText(
                            widget.profile.firstName,
                            minFontSize: 12,
                            maxFontSize: 66,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 66,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color.fromARGB(64, 19, 23, 39),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ]),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          flex: 1,
                          child: AutoSizeText(
                            '${widget.profile.age}',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color.fromARGB(64, 19, 23, 39),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
