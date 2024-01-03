
int calculateDecimalPlacePrice(double pairPrice) {
  if (pairPrice < 0.0099) {
    return 6;
  } else if (pairPrice < 0.099) {
    return 5;
  } else if (pairPrice < 0.99) {
    return 4;
  } else if (pairPrice < 9.9) {
    return 3;
  } else {
    return 2;
  }
}