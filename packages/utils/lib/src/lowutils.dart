bool isDigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

void rassert(bool cond, [String? msg]) {
  if (cond) return;
  throw Exception(msg);
}
