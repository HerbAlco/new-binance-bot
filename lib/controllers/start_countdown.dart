import 'package:quiver/async.dart';

class CountdownManager {
  late CountdownTimer countdownTimer;
  late String remainingText;
  late double progressValue;

  void startCountdown(Duration currentDuration) {

    int countdownDuration = currentDuration.inSeconds;
    const int updateInterval = 1;

    countdownTimer = CountdownTimer(
      Duration(seconds: countdownDuration),
      const Duration(seconds: updateInterval),
    );

    countdownTimer.listen((event) {
      int remainingSeconds = event.remaining.inSeconds;

      if (remainingSeconds >= 60) {
        int remainingMinutes = remainingSeconds ~/ 60;
        remainingSeconds %= 60;
        remainingText = '$remainingMinutes m $remainingSeconds s';
      } else {
        remainingText = '$remainingSeconds s';
      }

      progressValue = event.remaining.inSeconds / countdownDuration;
    });
    print(remainingText);
    print(progressValue);
  }

}
