import "dart:async";
import "dart:html";

import "package:lifetimevalue/ltv_model.dart";
import "package:lifetimevalue/src/ropo_values.dart";

void main() {
  LtvModel model = new LtvModel();

  model.currencyInputEl = querySelector("#currency-set");

  model.cpc = new BoundValue("#cpc", model);
  model.cpc.addElements([querySelector("#cpc-considering")]);
  model.conversionRate =
      new BoundValue("#conversionRate", model, isPercentage: true);
  model.customerLifetime = new BoundValue("#customerLifetime", model);
  model.firstPurchaseValue = new BoundValue("#firstPurchase", model);
  model.firstPurchaseValue.precision = 0;
  model.firstPurchaseValue.addElements([querySelector("#firstPurchase-table")]);
  model.repurchase = new BoundValue("#repurchase", model, isPercentage: true);

  // advanced
  model.purchasesPerYear = new BoundValue("#purchasesPerYear", model);
  model.purchasesPerYear.precision = 0;
  model.purchasesPerYear
      .addElements([querySelector("#purchasesPerYear-table")]);
  model.year2PurchaseValue = new BoundValue("#year-2-purchase", model);
  model.year2PurchaseValue.precision = 0;
  model.year3PurchaseValue = new BoundValue("#year-3-purchase", model);
  model.year3PurchaseValue.precision = 0;
  model.year2PurchasesPerYear =
      new BoundValue("#year-2-purchasesPerYear", model);
  model.year2PurchasesPerYear.precision = 0;
  model.year3PurchasesPerYear =
      new BoundValue("#year-3-purchasesPerYear", model);
  model.year3PurchasesPerYear.precision = 0;
  model.year2RetentionRate =
      new BoundValue("#year-2-retentionRate", model, isPercentage: true);
  model.year2RetentionRate.precision = 0;
  model.year3RetentionRate =
      new BoundValue("#year-3-retentionRate", model, isPercentage: true);
  model.year3RetentionRate.precision = 0;

  model.referralRate =
      new BoundValue("#referralRate", model, isPercentage: true);
  model.grossMargin = new BoundValue("#grossMargin", model, isPercentage: true);
  model.costOfCapital =
      new BoundValue("#costOfCapital", model, isPercentage: true);

  model.ropoCategoryEl = querySelector("#ropoCategory");
  model.destinationCountryEl = querySelector("#destinationCountry");

  void update(Event _) {
    var country = model.destinationCountryEl.value;
    var category = model.ropoCategoryEl.value;
    var val = RopoValues.getCoefficient(country, category);
    assert(val != null,
        "Value for $country & $category doesn't exist among ropoCoefficiets.");
    model.ropoCoefficient.value = val;
    model.recalculate(null);
    model.pushState();
  }

  model.ropoCategoryEl.onChange.listen(update);

  model.destinationCountryEl.onChange.listen((e) {
    var country = model.destinationCountryEl.value;
    var previousCategory = model.ropoCategoryEl.value;
    model.ropoCategoryEl.children.clear();
    for (var category in RopoValues.ropoCategories) {
      if (RopoValues.getCoefficient(country, category) == null) continue;
      model.ropoCategoryEl.children.add(new OptionElement(
          data: category,
          value: category,
          selected: category == previousCategory));
    }
    update(e);
  });

  model.suggestedRopoCoefficient =
      new BoundValue("#suggestedRopoCoefficient", model);
  model.ropoCoefficient = new BoundValue("#ropoCoefficient", model);

  model.cpa = new BoundValue("#cpa", model);
  model.cpa.precision = 0;
  model.totalOnOffPurchase = new BoundValue("#totalOnOffPurchase", model);
  model.totalPurchasePlusRepeat =
      new BoundValue("#totalPurchasePlusRepeat", model);
  model.referralAdditionalRevenue =
      new BoundValue("#referralAdditionalRevenue", model);
  model.totalPurchasePlusRepeatAndReferral =
      new BoundValue("#totalPurchasePlusRepeatAndReferral", model);
  model.lifetimeValue = new BoundValue("#lifetimeValue", model);
  model.lifetimeValue.precision = 0;
  model.profitPerCustomer = new BoundValue("#profitPerCustomer", model);
  model.profitPerCustomer.precision = 0;
  model.roi = new BoundValue("#roi", model, isPercentage: true);
  model.roi.precision = 0;
  model.breakEvenCPC = new BoundValue("#breakEvenCPC", model);

  model.graphRowTop = querySelector("table#graph tr.r2");
  model.graphRowMiddle = querySelector("table#graph tr.r3");
  model.graphRowBottom = querySelector("table#graph tr.r4");

  model.linkForSharing = querySelector("input#link-for-sharing");

  // setup value dependencies
  model.start();

  // check if url contains values
  model.parseUrl();

  // recalculate for the first time
  update(null);
  model.recalculate(null);
  model.pushState();

  // hide loading
  var loadingDiv = querySelector("div#loading-div");
  loadingDiv.classes.add("hide3d");
  // Normally, we would use loadingDiv.onTransitionEnd here, but that doesn't
  // work in Opera (and possibly other browsers).
  new Timer(const Duration(milliseconds: 300), () => loadingDiv.remove());

  // roll out the methodology
  var methodologyLink = querySelector("a#methodology-link");
  methodologyLink.onClick.listen((e) {
    e.preventDefault();
    var methodology = querySelector("div#methodology");
    if (methodology.style.height == null ||
        methodology.style.height.startsWith("0") ||
        methodology.style.height == "") {
      var cssStyle =
          querySelector("div#methodology-inside-wrapper").getComputedStyle();
      methodology.style.height = cssStyle.height;
      methodologyLink.text = "Hide methodology";
    } else {
      methodology.style.height = "0";
      methodologyLink.text = "Learn about the methodology";
    }
  });

  // basic/advanced tabs
  var basicTab = querySelector("a#basic-tab");
  var advancedTab = querySelector("a#advanced-tab");
  basicTab.onClick.listen((e) {
    basicTab.classes.add("selected");
    advancedTab.classes.remove("selected");
    for (var el in querySelectorAll("div#inputs tr.advanced")) {
      el.style.display = "none";
    }
  });

  advancedTab.onClick.listen((e) {
    basicTab.classes.remove("selected");
    advancedTab.classes.add("selected");
    for (var el in querySelectorAll("div#inputs tr.advanced")) {
      el.style.display = "table-row";
    }
  });
}
