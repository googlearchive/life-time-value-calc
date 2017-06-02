import 'package:test/test.dart';
import 'package:lifetimevalue/human_number_recognizer.dart';

main() {
  Function rec = HumanNumber.recognizeString;

  test('integers', () {
    num x = rec("8");
    expect(x, equals(8));
    x = rec("0");
    expect(x, equals(0));
    x = rec("-2");
    expect(x, equals(-2));
  });
  test('doubles', () {
    num x = rec("1.3598");
    expect(x, equals(1.3598));
    x = rec("0.449999");
    expect(x, equals(0.449999));
    x = rec("-2.019884");
    expect(x, equals(-2.019884));
  });
  test('with spaces around', () {
    num x = rec(" 1.3598");
    expect(x, equals(1.3598));
    x = rec("0.449999 ");
    expect(x, equals(0.449999));
    x = rec("  -2.019884 ");
    expect(x, equals(-2.019884));
  });
  test('with dot in the end', () {
    num x = rec(" 1.");
    expect(x, equals(1));
    x = rec("0.");
    expect(x, equals(0));
    x = rec("  -2. ");
    expect(x, equals(-2));
  });
  test('with comma in the end', () {
    num x = rec(" 1,");
    expect(x, equals(1));
    x = rec("0,");
    expect(x, equals(0));
    x = rec("  -2, ");
    expect(x, equals(-2));
  });
  test('percentages', () {
    num x = rec("10%");
    expect(x, closeTo(10, 0.0001));
    x = rec("10 %");
    expect(x, closeTo(010, 0.0001));
    x = rec("12.3%");
    expect(x, closeTo(12.3, 0.0001));
    x = rec("-200.019884%");
    expect(x, closeTo(-200.019884, 0.0001));
    x = rec(" - 200.019884%  ");
    expect(x, closeTo(-200.019884, 0.0001));
  });
  test('decimal comma', () {
    num x = rec("10,6");
    expect(x, equals(10.6));
    x = rec("10,6 %");
    expect(x, equals(10.6));
    x = rec("-0,116");
    expect(x, equals(-0.116));
  });
  test('thousands space, decimal comma', () {
    num x;
    x = rec("11 510,6");
    expect(x, closeTo(11510.6, 0.0001));
    x = rec(" 11 510,6  ");
    expect(x, closeTo(11510.6, 0.0001));
    x = rec("- 11 510,6");
    expect(x, closeTo(-11510.6, 0.0001));
    x = rec("-11 510,6");
    expect(x, closeTo(-11510.6, 0.0001));
    x = rec("1 311 510,6");
    expect(x, closeTo(1311510.6, 0.0001));
    x = rec("-1 311 510,6");
    expect(x, closeTo(-1311510.6, 0.0001));
  });
  test('thousands dot, decimal comma', () {
    num x;
    x = rec("11.510,6");
    expect(x, closeTo(11510.6, 0.0001));
    x = rec(" 11.510,6  ");
    expect(x, closeTo(11510.6, 0.0001));
    x = rec("- 11.510,6");
    expect(x, closeTo(-11510.6, 0.0001));
    x = rec("-11.510,6");
    expect(x, closeTo(-11510.6, 0.0001));
    x = rec("1.311.510,6");
    expect(x, closeTo(1311510.6, 0.0001));
    x = rec("-1.311.510,6");
    expect(x, closeTo(-1311510.6, 0.0001));
  });
  test('thousand-looking numbers', () {
    num x;
    x = rec("11.500");
    expect(x, closeTo(11500, 0.0001));
    x = rec("11,500");
    expect(x, closeTo(11500, 0.0001));
    x = rec("1,000");
    expect(x, closeTo(1000, 0.0001));
    x = rec("1.000");
    expect(x, closeTo(1000, 0.0001));
    x = rec("1.234");
    expect(x, closeTo(1.234, 0.0001));
    x = rec("1,234");
    expect(x, closeTo(1.234, 0.0001));
  });
  test('malformed', () {
    num x = rec("not a number");
    expect(x, isNull);
    x = rec("-.");
    expect(x, isNull);
    x = rec("");
    expect(x, isNull);
  });
}