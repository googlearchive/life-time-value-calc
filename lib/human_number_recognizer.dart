// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library human_number_recognizer;

class HumanNumber {
  // Ex: -1 165 849.918
  static RegExp validEnglishLargeNumber =
      new RegExp(r"^\s*([-+]?\s*([0-9]{1,3}[, ])+[0-9]{3}(\.?[0-9]+)*)\s*$");
  // Ex: -1.165.849,918
  static RegExp validCzechLargeNumber =
      new RegExp(r"^\s*([-+]?\s*([0-9]{1,3}[. ])+[0-9]{3}(\,?[0-9]+)*)\s*$");
  // Ex: 1,400
  static RegExp thousandLookingNumber =
      new RegExp(r"^\s*([-+]?\s*[0-9]{1,3}[,\. ][0-9]{2}0)\s*$");
  // Ex: 15616.8, but also "489,48984,,,6.46,"
  static RegExp numberCharsString =
      new RegExp(r"^\s*([-+]?\s*[0-9,\. ]*[0-9])\s*$");
  static RegExp numberCharsStringWithEndingDot =
      new RegExp(r"^\s*([-+]?\s*[0-9,\. ]*[0-9])[\.,]\s*$");
  static RegExp numberCharsStringWithEndingPercentage =
      new RegExp(r"^\s*([-+]?\s*[0-9,\. ]*[0-9])[\.,]?\s*%\s*$");

  static RegExp whiteSpace = new RegExp(r"\s");
  static RegExp commaOrDot = new RegExp(r"[\.,]");

  static num recognizeString(String s) {
    if (!numberCharsString.hasMatch(s)) {
      if (numberCharsStringWithEndingDot.hasMatch(s)) {
        s = numberCharsStringWithEndingDot.firstMatch(s).group(1);
      } else if (numberCharsStringWithEndingPercentage.hasMatch(s)) {
        s = numberCharsStringWithEndingPercentage.firstMatch(s).group(1);
      } else {
        return null;
      }
    }

    int numberOfDots = 0;
    int numberOfCommas = 0;
    for (int i = 0; i < s.length; i++) {
      if (s[i] == ".")
        numberOfDots++;
      else if (s[i] == ",") numberOfCommas++;
    }

    if ((numberOfDots > 0 && numberOfCommas > 0) ||
        (numberOfDots > 1 || numberOfCommas > 1)) {
      if (validEnglishLargeNumber.hasMatch(s)) {
        s = s.replaceAll(",", "");
      } else if (validCzechLargeNumber.hasMatch(s)) {
        s = s.replaceAll(".", "");
        s = s.replaceAll(",", ".");
      } else {
        return null;
      }
    } else if (thousandLookingNumber.hasMatch(s)) {
      s = s.replaceAll(commaOrDot, "");
    } else if (numberOfCommas == 1) {
      // TODO this would benefit from context - if all other numbers are english, a "1,234" probably means 1234
      // assuming czech format
      s = s.replaceAll(",", ".");
    }

    num result = null;

    try {
      result = double.parse(s.replaceAll(whiteSpace, ""));
    } on FormatException catch (e) {
      print("Format Exception for string '$s': $e");
    }

    return result;
  }
}
