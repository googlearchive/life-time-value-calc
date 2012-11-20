library ltv_model;

import 'dart:html';
import 'dart:uri';
import 'dart:math';
import 'human_number_recognizer.dart';

final String TITLE = "Life-Time Value and Break-Even Online Calculator";

class BoundValue {
  List<Element> _elements;
  num _value;
  bool isPercentage;

  /**
   * Function [autoGetValue] is called on each recalculate and will update
   * value from the return of that function, unless the value has been
   * manually changed.
   */
  Function autoGetValue;
  bool _autoValueOverridden = false;

  LtvModel model;

  int precision = 2;

  BoundValue(String query, LtvModel this.model, {bool this.isPercentage: false}) {
    _elements = new List<Element>();
    _elements.add(document.query(query));
    _value = _readNumberFrom(_elements[0]);

    _elements[0].on.input.add((e) => inputListener(e));
    _elements[0].on.blur.add((e) {
      if (model != null)
        model.pushState();
    });

    _addAutoValueBlurListenerTo(_elements[0]);

    if (isPercentage)
      _addPercentageBlurListenerTo(_elements[0]);
  }

  void addElements(List<Element> newElements) {
    newElements.forEach((Element el) {
      _elements.add(el);
      el.on.input.add((e) => inputListener(e));
      _addAutoValueBlurListenerTo(el);
      if (isPercentage)
        _addPercentageBlurListenerTo(el);
      _writeValueTo(el);
    });
  }

  void inputListener(Event e, {bool forceNoRecalculate: false}) {
    Element eventEl = (e != null && e.target != null) ? e.target : _elements[0];
    num n = _readNumberFrom(eventEl);
    if (n != null) {
      bool sameValue = _value == n;
      _value = n;
      _elements.forEach((el) {
        if (el != eventEl)
          if (!sameValue) {
            _writeValueTo(el);
          }
          el.classes.remove("invalid");
      });
      if (!sameValue && autoGetValue != null) {
        String autoValue = _getStringRepresentation(autoGetValue());
        String currValue = elValue;
        _autoValueOverridden = autoValue != currValue;
      }
      if (model != null && !forceNoRecalculate && !sameValue) {
        model.recalculate(e);
      }
    } else {
      eventEl.classes.add("invalid");
    }
  }

  void _addPercentageBlurListenerTo(Element el) {
    el.on.blur.add((Event e) {
      String s = _getStringFrom(el);
      if (!HumanNumber.numberCharsStringWithEndingPercentage.hasMatch(s)) {
        _setTextOrValueTo(el, "$s%");
      }
    });
  }

  void _addAutoValueBlurListenerTo(Element el) {
    el.on.blur.add((Event e) {
      if (autoGetValue != null && _getStringFrom(el).trim() == "") {
        value = autoGetValue();
        if (model != null) {
          model.recalculate(null);
        }
      }
    });
  }

  /**
   * Reads the string value of the DOM element.
   * Returns [:null:] on invalid input.
   */
  num _readNumberFrom(Element el) {
    String s = _getStringFrom(el);

    num result = HumanNumber.recognizeString(s);

    if (result == null)
      return null;
    else if (isPercentage) {
      return result / 100.0;
    } else {
      return result;
    }
  }

  String _getStringFrom(Element el) {
    if (el is InputElement) {
      return (el as InputElement).value;
    } else {
      return el.text;
    }
  }

  void _setTextOrValueTo(Element el, String s) {
    if (el is InputElement) {
      (el as InputElement).value = s;
    } else {
      el.text = s;
    }
  }

  String _getStringRepresentation([num number]) {
    if (number == null) {
      number = _value;
    }
    String s;
    if (number.isInfinite && !number.isNegative)
      s = "∞";
    else if (number.isInfinite && number.isNegative)
      s = "-∞";
    else if (number.isNaN)
      s = "not calculable";
    else if (isPercentage)
      s = "${(number * 100.0).toStringAsFixed(precision)}%";
    else
      s = number.toStringAsFixed(precision);

    return s;
  }

  void _writeValueTo(Element el) {
    String s = _getStringRepresentation();

    if (el is InputElement) {
      (el as InputElement).value = s;
    } else {
      el.text = s;
      if (_value.isNegative)
        el.classes.add("negative-number");
      else
        el.classes.remove("negative-number");
    }

    blink(el);
  }

  void blink(Element el) {
    el.classes.add("highlight");
    window.setTimeout(() => el.classes.remove("highlight"), 500);
    //new Timer(500, (_) => el.classes.remove("highlight"));
  }

  void recalculate() {
    if (autoGetValue != null && !_autoValueOverridden) {
      value = autoGetValue();
    }
  }

  num get value => _value;

  set value(val) {
    if (val == _value)
      return;
    _value = val;
    _elements.forEach((el) {
      _writeValueTo(el);
      el.classes.remove("invalid");
    });
  }

  String get elValue {
    return _getStringFrom(_elements[0]);
  }

  set elValue(String val) {
    _setTextOrValueTo(_elements[0], val);
    inputListener(null, forceNoRecalculate:true);
  }


}


class LtvModel {
  // currency element
  InputElement _currencyInputEl;

  // input values
  BoundValue cpc, conversionRate, firstPurchaseValue, customerLifetime, repurchase,
  referralRate, grossMargin, ropoCoefficient, costOfCapital;

  // advanced input values
  BoundValue purchasesPerYear, year2PurchaseValue, year3PurchaseValue,
  year2PurchasesPerYear, year3PurchasesPerYear, year2RetentionRate,
  year3RetentionRate;

  // output values
  BoundValue suggestedRopoCoefficient, cpa, totalOnOffPurchase, totalPurchasePlusRepeat,
  referralAdditionalRevenue, totalPurchasePlusRepeatAndReferral, lifetimeValue, profitPerCustomer, roi,
  breakEvenCPC;

  // dropdowns
  SelectElement ropoCategoryEl, destinationCountryEl;

  // graph table rows
  TableRowElement graphRowTop, graphRowMiddle, graphRowBottom;
  num tableHeight = 10;

  // sharing link element
  InputElement _linkForSharing;

  /**
   * Constructor.
   */
  LtvModel() {
  }

  /**
   *
   */
  void start() {
    // set automatic recalculation of values - this can be overridden by user
    year2PurchaseValue.autoGetValue = () => firstPurchaseValue.value;
    year3PurchaseValue.autoGetValue = () => year2PurchaseValue.value;
    year2PurchasesPerYear.autoGetValue = () => purchasesPerYear.value;
    year3PurchasesPerYear.autoGetValue = () => purchasesPerYear.value;
    year2RetentionRate.autoGetValue =
        () => (customerLifetime.value - 1)/customerLifetime.value;
    year3RetentionRate.autoGetValue = () {
      return (customerLifetime.value - 1)/customerLifetime.value
          * (customerLifetime.value - 1)/customerLifetime.value;
    };

    window.on.popState.add((e) {
      parseUrl();
      recalculate(null);
    });
  }

  /**
   * This is the main workhorse business logic function. Called whenever
   * an input is changed.
   */
  void recalculate(Event e) {
    // recalculate (if not overridden)
    year2PurchaseValue.recalculate();
    year3PurchaseValue.recalculate();
    year2PurchasesPerYear.recalculate();
    year3PurchasesPerYear.recalculate();
    year2RetentionRate.recalculate();
    year3RetentionRate.recalculate();

    // first year
    num firstYearOnlinePurchase = firstPurchaseValue.value * purchasesPerYear.value;
    num firstYearTotalOnOffPurchase = firstYearOnlinePurchase * ropoCoefficient.value;

    // year 2
    num year2OnlinePurchase = year2PurchaseValue.value * year2PurchasesPerYear.value;
    num year2TotalOnOffPurchase = year2OnlinePurchase * year2RetentionRate.value * ropoCoefficient.value;
    num year2TotalDiscounted = year2TotalOnOffPurchase / (1 + costOfCapital.value);

    // year 3
    num year3OnlinePurchase = year3PurchaseValue.value * year3PurchasesPerYear.value;
    num year3TotalOnOffPurchase = year3OnlinePurchase * year3RetentionRate.value * ropoCoefficient.value;
    num year3TotalDiscounted = year3TotalOnOffPurchase / pow(1 + costOfCapital.value, 2);

    // year 4
    num year4PurchaseValue = year3OnlinePurchase;
    num year4RetentionRate = year3RetentionRate.value * ((customerLifetime.value - 1) / customerLifetime.value);
    num year4TotalOnOffPurchase = year4PurchaseValue * year4RetentionRate * ropoCoefficient.value;
    num year4TotalDiscounted = year4TotalOnOffPurchase / pow(1 + costOfCapital.value, 3);

    // year 5
    num year5PurchaseValue = year3OnlinePurchase;
    num year5RetentionRate = year4RetentionRate * ((customerLifetime.value - 1) / customerLifetime.value);
    num year5TotalOnOffPurchase = year5PurchaseValue * year5RetentionRate * ropoCoefficient.value;
    num year5TotalDiscounted = year5TotalOnOffPurchase / pow(1 + costOfCapital.value, 4);

    // year 6 to infinity (allOther)
    num allOtherYearsPurchaseValue = year3OnlinePurchase;
    num allOtherYearsRetentionRate = year5RetentionRate * ((customerLifetime.value - 1) / customerLifetime.value);
    num allOtherYearsTotalOnOffPurchase = allOtherYearsPurchaseValue * allOtherYearsRetentionRate * ropoCoefficient.value;
    //=(K26/(K27-(($'Inputs & Results'.L12-1)/$'Inputs & Results'.L12-1)))/((1+K27)^5)
    num sumOfAllOtherYearsTotalDiscounted = allOtherYearsTotalOnOffPurchase /
        (costOfCapital.value - (((customerLifetime.value - 1) / customerLifetime.value) - 1)) /
        pow(1 + costOfCapital.value, 5);

    // total
    totalPurchasePlusRepeat.value = firstYearTotalOnOffPurchase +
        year2TotalDiscounted + year3TotalDiscounted + year4TotalDiscounted
        + year5TotalDiscounted + sumOfAllOtherYearsTotalDiscounted;
    referralAdditionalRevenue.value = totalPurchasePlusRepeat.value
        * (1 / (1 - referralRate.value))
        - totalPurchasePlusRepeat.value;
    totalPurchasePlusRepeatAndReferral.value = totalPurchasePlusRepeat.value
        + referralAdditionalRevenue.value;
    lifetimeValue.value = totalPurchasePlusRepeatAndReferral.value * grossMargin.value;

    cpa.value = cpc.value / conversionRate.value;
    profitPerCustomer.value = lifetimeValue.value - cpa.value;
    roi.value = profitPerCustomer.value / cpa.value;
    breakEvenCPC.value = lifetimeValue.value * conversionRate.value;

    // update graph
    if (graphRowTop != null && graphRowMiddle != null
        && graphRowBottom != null) {
      if (lifetimeValue.value > cpa.value) {
        num wholeRange = lifetimeValue.value;
        graphRowTop.style.height =
            "${(cpa.value / wholeRange * tableHeight)}em";
        graphRowMiddle.style.display = "table-row";
        graphRowMiddle.style.height =
            "${((1 - cpa.value / wholeRange) * tableHeight)}em";
        graphRowBottom.style.display = "none";
      } else {
        num wholeRange = lifetimeValue.value - profitPerCustomer.value;
        graphRowTop.style.height =
            "${(lifetimeValue.value / wholeRange * tableHeight)}em";
        graphRowMiddle.style.display = "none";
        graphRowBottom.style.display = "table-row";
        graphRowBottom.style.height =
            "${((-profitPerCustomer.value / wholeRange) * tableHeight)}em";
      }
    }
  }

  void pushState() {
    Map data = _getInputs();
    String url = _constructUrl(data);
    if (!window.location.href.endsWith(url)) {
      window.history.pushState(data, TITLE, url);
      if (_linkForSharing != null)
        _linkForSharing.value = window.location.href;
    }
  }

  Map _getInputs() {
    return {
      "currency": _currencyInputEl.value,
      "cpc": cpc.elValue,
      "conversionRate": conversionRate.elValue,
      "customerLifetime": customerLifetime.elValue,
      "firstPurchase": firstPurchaseValue.elValue,
      "purchasesPerYear": purchasesPerYear.elValue,
      "year2PurchaseValue": year2PurchaseValue.elValue,
      "year3PurchaseValue": year3PurchaseValue.elValue,
      "year2PurchasesPerYear": year2PurchasesPerYear.elValue,
      "year3PurchasesPerYear": year3PurchasesPerYear.elValue,
      "year2RetentionRate": year2RetentionRate.elValue,
      "year3RetentionRate": year3RetentionRate.elValue,
      "referralRate": referralRate.elValue,
      "grossMargin": grossMargin.elValue,
      "ropoCategory": ropoCategoryEl.value,
      "destinationCountry": destinationCountryEl.value,
      "ropoCoefficient": ropoCoefficient.elValue,
      "costOfCapital": costOfCapital.elValue
    };
  }

  void _setInputs(Map map) {
    if (map.containsKey("currency")) {
      currencyInputEl.value = map["currency"];
      currencyInputEl.on.input.dispatch(new Event('input'));
    }
    if (map.containsKey("cpc"))
      cpc.elValue = map["cpc"];
    if (map.containsKey("conversionRate"))
      conversionRate.elValue = map["conversionRate"];
    if (map.containsKey("customerLifetime"))
      customerLifetime.elValue = map["customerLifetime"];
    if (map.containsKey("firstPurchase"))
      firstPurchaseValue.elValue = map["firstPurchase"];
    if (map.containsKey("purchasesPerYear")) purchasesPerYear.elValue = map["purchasesPerYear"];
    if (map.containsKey("year2PurchaseValue")) year2PurchaseValue.elValue = map["year2PurchaseValue"];
    if (map.containsKey("year3PurchaseValue")) year3PurchaseValue.elValue = map["year3PurchaseValue"];
    if (map.containsKey("year2PurchasesPerYear")) year2PurchasesPerYear.elValue = map["year2PurchasesPerYear"];
    if (map.containsKey("year3PurchasesPerYear")) year3PurchasesPerYear.elValue = map["year3PurchasesPerYear"];
    if (map.containsKey("year2RetentionRate")) year2RetentionRate.elValue = map["year2RetentionRate"];
    if (map.containsKey("year3RetentionRate")) year3RetentionRate.elValue = map["year3RetentionRate"];
    if (map.containsKey("referralRate"))
      referralRate.elValue = map["referralRate"];
    if (map.containsKey("grossMargin"))
      grossMargin.elValue = map["grossMargin"];
    if (map.containsKey("ropoCategory"))
      ropoCategoryEl.value = map["ropoCategory"];
    if (map.containsKey("destinationCountry"))
      destinationCountryEl.value = map["destinationCountry"];
    if (map.containsKey("ropoCoefficient"))
      ropoCoefficient.elValue = map["ropoCoefficient"];
    if (map.containsKey("costOfCapital"))
      costOfCapital.elValue = map["costOfCapital"];
  }

  String _constructUrl(Map map) {
    StringBuffer strBuf = new StringBuffer("#");
    map.forEach((k, v) {
      var key = encodeUriComponent(k);
      var value = encodeUriComponent(v);
      strBuf.add("$key=$value&");
    });
    String url = strBuf.toString();
    url = url.substring(0, url.length - 1); // remove trailing "&"
    return url;
  }

  void parseUrl() {
    var url = window.location.href;
    if (!url.contains("#"))
      return;
    url = url.split("#")[1];
    var parts = url.split("&");

    Map map = new Map();
    parts.forEach((part) {
      var keyValuePair = part.split("=");
      if (keyValuePair.length == 2) {
        var k = decodeUriComponent(keyValuePair[0]);
        var v = decodeUriComponent(keyValuePair[1]);
        map[k] = v;
      }
    });

    _setInputs(map);
  }

  set currencyInputEl(InputElement val) {
    _currencyInputEl = val;
    _currencyInputEl.on.input.add((e) {
      queryAll("span.currency-placeholder").forEach((el) {
        el.text = _currencyInputEl.value;
      });
    });
    _currencyInputEl.on.blur.add((e) {
      pushState();
    });
  }

  InputElement get currencyInputEl => _currencyInputEl;

  set linkForSharing(InputElement val) {
    _linkForSharing = val;
    _linkForSharing.on.click.add((e) {
      _linkForSharing
        ..selectionStart = 0
        ..selectionEnd = _linkForSharing.value.length;
      e.stopPropagation();
    });
    _linkForSharing.value = window.location.href;
  }

  InputElement get linkForSharing => _linkForSharing;

}

