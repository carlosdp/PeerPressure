import 'package:flutter/material.dart';
import 'package:flutter_app/models/swipe.dart';

class SupportCard extends StatelessWidget {
  final Match match;
  final void Function() onTap;

  const SupportCard({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 103,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromRGBO(106, 0, 212, 0.8),
          border: Border.all(
            color: const Color.fromRGBO(98, 0, 222, 0.7),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(29, 10, 38, 0.5),
              offset: Offset(0, 5),
              blurRadius: 8.8,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            '${match.totalVotes}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
