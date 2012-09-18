#import('dart:html');
#import('dart:uri');
#import('dart:math');
#import('ropo_values.dart');
#import('human_number_recognizer.dart');

class BindedValue {
  List<Element> _elements;
  num _value;
  bool isPercentage;
  
  LtvModel model;
  
  int precision = 2;
  
  BindedValue(String query, [LtvModel this.model, bool this.isPercentage = false]) {
    _elements = new List<Element>();
    _elements.add(document.query(query));
    _value = _readNumberFrom(_elements[0]);

    _elements[0].on.input.add((e) => inputListener(e));
    _elements[0].on.blur.add((e) {
      if (model != null) 
        model.pushState();
    });
    
    if (isPercentage)
      _addPercentageBlurListenerTo(_elements[0]);
  }
  
  void addElements(List<Element> newElements) {
    newElements.forEach((Element el) {
      _elements.add(el);
      el.on.input.add((e) => inputListener(e));
      if (isPercentage)
        _addPercentageBlurListenerTo(el);
      _writeValueTo(el);
    });
  }
  
  void inputListener(Event e, [bool forceNoRecalculate = false]) {
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
      if (model != null && !forceNoRecalculate && !sameValue) {
        model.recalculate(e);
      }
    } else {
      eventEl.classes.add("invalid");
    }
  }
  
  void _addPercentageBlurListenerTo(Element el) {
    el.on.blur.add((Event e) {
      String s = _getTextOrValueFrom(el);
      if (!HumanNumber.numberCharsStringWithEndingPercentage.hasMatch(s)) {
        _setTextOrValueTo(el, "$s%");
      }
    });
  }
  
  /**
   * Reads the string value of the DOM element.
   * Returns [:null:] on invalid input.
   */
  num _readNumberFrom(Element el) {
    String s = _getTextOrValueFrom(el);
    
    num result = HumanNumber.recognizeString(s);
    
    if (result == null)
      return null;
    else if (isPercentage) {
      return result / 100.0;
    } else {
      return result;
    }
  }
  
  String _getTextOrValueFrom(Element el) {
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
  
  void _writeValueTo(Element el) {
    String s;
    if (_value.isInfinite() && !_value.isNegative())
      s = "∞";
    else if (_value.isInfinite() && _value.isNegative())
      s = "-∞";
    else if (_value.isNaN())
      s = "not calculable";
    else if (isPercentage) 
      s = "${(_value * 100.0).toStringAsFixed(precision)}%";
    else
      s = _value.toStringAsFixed(precision);
    
    if (el is InputElement) {
      (el as InputElement).value = s;
    } else {
      el.text = s;
      if (_value.isNegative())
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

  num get value() => _value;
  
  set value(val) {
    if (val == _value)
      return;
    _value = val;
    _elements.forEach((el) {
      _writeValueTo(el);
    });
  }
  
  String get elValue() {
    return _getTextOrValueFrom(_elements[0]);
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
  BindedValue cpc, conversionRate, firstPurchase, customerLifetime, repurchase,
  referralRate, grossMargin, ropoCoefficient, costOfCapital;
  
  // output values
  BindedValue suggestedRopoCoefficient, cpa, totalOnOffPurchase, totalPurchasePlusRepeat,
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
    repurchase.value = (customerLifetime.value - 1) / customerLifetime.value;
    
    cpa.value = cpc.value / conversionRate.value;
    totalOnOffPurchase.value = firstPurchase.value * ropoCoefficient.value;
    totalPurchasePlusRepeat.value = totalOnOffPurchase.value 
        + (totalOnOffPurchase.value * repurchase.value) 
        / (costOfCapital.value - (repurchase.value - 1));
    referralAdditionalRevenue.value = totalPurchasePlusRepeat.value 
        * (1 / (1 - referralRate.value))
        - totalPurchasePlusRepeat.value;
    totalPurchasePlusRepeatAndReferral.value = totalPurchasePlusRepeat.value
        + referralAdditionalRevenue.value;
    lifetimeValue.value = totalPurchasePlusRepeatAndReferral.value * grossMargin.value;
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
      "firstPurchase": firstPurchase.elValue,
      "customerLifetime": customerLifetime.elValue,
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
    if (map.containsKey("firstPurchase")) 
      firstPurchase.elValue = map["firstPurchase"];
    if (map.containsKey("customerLifetime")) 
      customerLifetime.elValue = map["customerLifetime"];
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
  }
  
  InputElement get linkForSharing => _linkForSharing;

}

final String TITLE = "Life-Time Value and Break-Even Online Calculator";


void main() {
  LtvModel model = new LtvModel();
  
  model.currencyInputEl = query("#currency-set");
    
  model.cpc = new BindedValue("#cpc", model);
  model.cpc.addElements([query("#cpc-considering")]);
  model.conversionRate = new BindedValue("#conversionRate", model, isPercentage:true);
  model.firstPurchase = new BindedValue("#firstPurchase", model);
  model.customerLifetime = new BindedValue("#customerLifetime", model);
  model.repurchase = new BindedValue("#repurchase", model, isPercentage:true);
  model.referralRate = new BindedValue("#referralRate", model, isPercentage:true);
  model.grossMargin = new BindedValue("#grossMargin", model, isPercentage:true);
  model.costOfCapital = new BindedValue("#costOfCapital", model, isPercentage:true);
  
  model.ropoCategoryEl = query("#ropoCategory");
  model.destinationCountryEl = query("#destinationCountry");
  
  [model.ropoCategoryEl, model.destinationCountryEl].forEach((SelectElement el) {
    el.on.change.add((e) {
      // get ROPO coefficients from table
      String key = "${model.destinationCountryEl.value} > ${model.ropoCategoryEl.value}";
      model.ropoCoefficient.value = RopoValues.ropoCoefficients[key];
      model.recalculate(e);
      model.pushState();
    });
  });
  
  model.suggestedRopoCoefficient = new BindedValue("#suggestedRopoCoefficient", model);
  model.ropoCoefficient = new BindedValue("#ropoCoefficient", model);
  
  model.cpa = new BindedValue("#cpa", model);
  model.cpa.precision = 0;
  model.totalOnOffPurchase = new BindedValue("#totalOnOffPurchase", model);
  model.totalPurchasePlusRepeat = new BindedValue("#totalPurchasePlusRepeat", model);
  model.referralAdditionalRevenue = new BindedValue("#referralAdditionalRevenue", model);
  model.totalPurchasePlusRepeatAndReferral = new BindedValue("#totalPurchasePlusRepeatAndReferral", model);
  model.lifetimeValue = new BindedValue("#lifetimeValue", model);
  model.lifetimeValue.precision = 0;
  model.profitPerCustomer = new BindedValue("#profitPerCustomer", model);
  model.profitPerCustomer.precision = 0;
  model.roi = new BindedValue("#roi", model, isPercentage:true);
  model.roi.precision = 0;
  model.breakEvenCPC = new BindedValue("#breakEvenCPC", model);

  model.graphRowTop = query("table#graph tr.r2");
  model.graphRowMiddle = query("table#graph tr.r3");
  model.graphRowBottom = query("table#graph tr.r4");
  
  model.linkForSharing = query("input#link-for-sharing");
  
  // check if url contains values
  model.parseUrl();
  
  // start the engine
  model.recalculate(null);
  model.pushState();
  
  // hide loading
  var loadingDiv = query("div#loading-div");
  loadingDiv.classes.add("hide3d");
  window.setTimeout(() => loadingDiv.remove(), 300);
  
  
  // roll out the methodology
  query("a#methodology-link").on.click.add((e) {
    e.preventDefault();
    var methodology = query("div#methodology");
    if (methodology.style.height == null || methodology.style.height.startsWith("0")
        || methodology.style.height == "") {
      query("div#methodology-inside-wrapper").computedStyle
      .then((cssStyle) {
        methodology.style.height = cssStyle.height;
      });
    } else {
      methodology.style.height = "0";
    }
    
  });
  
}