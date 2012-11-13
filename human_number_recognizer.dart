
#library("human_number_recognizer");

#import("dart:math");

class HumanNumber {
  // TODO: have state = setup "locale", "learn", etc.
  
  // Ex: -1 165 849.918
  static RegExp validEnglishLargeNumber = 
      const RegExp(@"^\s*([-+]?\s*([0-9]{1,3}[, ])+[0-9]{3}(\.?[0-9]+)*)\s*$");
  // Ex: -1.165.849,918
  static RegExp validCzechLargeNumber = 
      const RegExp(@"^\s*([-+]?\s*([0-9]{1,3}[. ])+[0-9]{3}(\,?[0-9]+)*)\s*$");
  // Ex: 1,400
  static RegExp thousandLookingNumber =
      const RegExp(@"^\s*([-+]?\s*[0-9]{1,3}[,\. ][0-9]{2}0)\s*$");
  // Ex: 15616.8, but also "489,48984,,,6.46,"
  static RegExp numberCharsString = 
      const RegExp(@"^\s*([-+]?\s*[0-9,\. ]*[0-9])\s*$");
  static RegExp numberCharsStringWithEndingDot = 
      const RegExp(@"^\s*([-+]?\s*[0-9,\. ]*[0-9])[\.,]\s*$");
  static RegExp numberCharsStringWithEndingPercentage = 
      const RegExp(@"^\s*([-+]?\s*[0-9,\. ]*[0-9])[\.,]?\s*%\s*$");
  
  static RegExp whiteSpace = const RegExp(@"\s");
  static RegExp commaOrDot = const RegExp(@"[\.,]");
  
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
      else if (s[i] == ",")
        numberOfCommas++;
    }
        
    if ((numberOfDots > 0 && numberOfCommas > 0) || (numberOfDots > 1 || numberOfCommas > 1)) {
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
      result = parseDouble(s.replaceAll(whiteSpace, ""));
    } on FormatException catch (e) {
      print("Format Exception for string '$s': $e");
    }
    
    return result;
  
  }
}
