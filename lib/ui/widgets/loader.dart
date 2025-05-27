import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Define a placeholder for complimentWhite color
const complimentWhite = Colors.black; // Change to your desired color

// Define a placeholder for randomComment
const loadingComments = [
  "life is too short to give a f, just say meow and move on",
  "meowtivation loading...",
  "stay pawsitive, it's almost done!",
  "chillin' like a villain while we load...",
  "your purrfect experience is almost ready",
  "fur-matting the final touches...",
  "hold on, chasing one last bug 🐛😼",
  "taking a quick catnap before starting...",
  "loading... please don't wake the cat",
  "scratching behind the scenes...",
  "meowgic is happening, just a sec...",
  "fetching data with feline finesse...",
  "aligning the stars for your purrfect journey...",
  "making sure every pixel is pawfect...",
  "deploying whisker protocol...",
  "uploading 9 lives worth of fun...",
  "building your kitty-approved experience...",
  "still faster than a cat chasing a laser!",
  "whiskers synced, tail wagging... almost there!",
  "meow-mentarily booting up greatness..."
];

    final random = Random();
    final randomComment = loadingComments[random.nextInt(loadingComments.length)];

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LottieSplashAnimation(),
            const LottieLoader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                randomComment,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: complimentWhite,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LottieSplashAnimation extends StatelessWidget {
  const LottieSplashAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/images/cat_animation.json',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
    );
  }
}

class LottieLoader extends StatelessWidget {
  const LottieLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/images/loader.json',
      width: 200,
      height: 50,
      fit: BoxFit.contain,
    );
  }
}