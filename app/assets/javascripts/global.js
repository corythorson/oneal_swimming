$(function () {
  $('[data-toggle="tooltip"]').tooltip();
  $('#global-modal').on('shown.bs.modal', function (e) {
    var slider = $(".slider").bootstrapSlider();
    slider.on("change", function (event) {
      $('#quantity-label').html(event.value.newValue);
    });
  });
});
