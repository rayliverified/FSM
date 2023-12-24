import 'dart:math';

class AutoID {
  AutoID._();

  static const int autoIdLength = 20;
  static const String autoIdAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static final Random _random = Random();

  static String get autoID {
    final StringBuffer stringBuffer = StringBuffer();
    const int maxRandom = autoIdAlphabet.length;

    for (int i = 0; i < autoIdLength; ++i) {
      stringBuffer.write(autoIdAlphabet[_random.nextInt(maxRandom)]);
    }

    return stringBuffer.toString();
  }
}
