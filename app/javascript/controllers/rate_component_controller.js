import { Controller } from "@hotwired/stimulus";
import { initFlatpickr as flatpickr } from "../plugins/flatpickr";

export default class extends Controller {
  static targets = ["checkin", "checkout"];

  connect() {
    flatpickr();
    console.log("Rate component controller connected");
    const unavailableDates = JSON.parse(this.element.dataset.unavailable);
    const defaultCheckin = JSON.parse(this.element.dataset.defaultcheckin);
    let checkinDate = new Date(defaultCheckin);

    const checkinPicker = this.checkinTarget.flatpickr({
      allowInput: true,
      altInput: true,
      altFormat: "d/m/Y",
      dateFormat: "Y-m-d",
      defaultDate: defaultCheckin,
      disable: unavailableDates,
      onChange: function (selectedDates, dateStr, instance) {
        checkoutPicker.set("minDate", new Date(selectedDates).fp_incr(1));
      },
    });

    const checkoutPicker = this.checkoutTarget.flatpickr({
      allowInput: true,
      altInput: true,
      altFormat: "d/m/Y",
      dateFormat: "Y-m-d",
      defaultDate: checkinDate.setDate(checkinDate.getDate() + 7),
      disable: unavailableDates,
      onChange: function (selectedDates, dateStr, instance) {
        checkinPicker.set("maxDate", dateStr);
      },
    });
  }
}
