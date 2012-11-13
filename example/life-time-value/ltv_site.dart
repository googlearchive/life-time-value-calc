import "package:life-time-value/ltv_model.dart";
import "package:life-time-value/src/ropo_values.dart";
import "dart:html";


void main() {
  LtvModel model = new LtvModel();

  model.currencyInputEl = query("#currency-set");

  model.cpc = new BoundValue("#cpc", model);
  model.cpc.addElements([query("#cpc-considering")]);
  model.conversionRate = new BoundValue("#conversionRate", model, isPercentage:true);
  model.firstPurchase = new BoundValue("#firstPurchase", model);
  model.customerLifetime = new BoundValue("#customerLifetime", model);
  model.repurchase = new BoundValue("#repurchase", model, isPercentage:true);
  model.referralRate = new BoundValue("#referralRate", model, isPercentage:true);
  model.grossMargin = new BoundValue("#grossMargin", model, isPercentage:true);
  model.costOfCapital = new BoundValue("#costOfCapital", model, isPercentage:true);

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

  model.suggestedRopoCoefficient = new BoundValue("#suggestedRopoCoefficient", model);
  model.ropoCoefficient = new BoundValue("#ropoCoefficient", model);

  model.cpa = new BoundValue("#cpa", model);
  model.cpa.precision = 0;
  model.totalOnOffPurchase = new BoundValue("#totalOnOffPurchase", model);
  model.totalPurchasePlusRepeat = new BoundValue("#totalPurchasePlusRepeat", model);
  model.referralAdditionalRevenue = new BoundValue("#referralAdditionalRevenue", model);
  model.totalPurchasePlusRepeatAndReferral = new BoundValue("#totalPurchasePlusRepeatAndReferral", model);
  model.lifetimeValue = new BoundValue("#lifetimeValue", model);
  model.lifetimeValue.precision = 0;
  model.profitPerCustomer = new BoundValue("#profitPerCustomer", model);
  model.profitPerCustomer.precision = 0;
  model.roi = new BoundValue("#roi", model, isPercentage:true);
  model.roi.precision = 0;
  model.breakEvenCPC = new BoundValue("#breakEvenCPC", model);

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
    var arrow = query("span#methodology-arrow");
    if (methodology.style.height == null || methodology.style.height.startsWith("0")
        || methodology.style.height == "") {
      query("div#methodology-inside-wrapper").computedStyle
      .then((cssStyle) {
        methodology.style.height = cssStyle.height;
        arrow.innerHTML = "&#x25B2;";
      });
    } else {
      methodology.style.height = "0";
      arrow.innerHTML = "&#x25BC;";
    }

  });

}