var sliderInstance = $('#content-slider').royalSlider({
  slideTransitionSpeed : 400,
  keyboardNavEnabled : true,
  slideTransitionEasing : "easeInSine",
  slideTransitionSpeed : 300,
  directionNavEnabled : true,
  directionNavAutoHide : false,
  afterSlideChange : function() {

    var count = sliderInstance.currentSlideId;

    if(count === 1) {
      $("#font_spotted").removeClass("disabled");
      $("#font_comment").addClass("disabled");
      $(".photo_meta a.comments").removeClass("active");
      $(".photo_meta a.font_types").addClass("active");
      $("#new_comment").hide();
    } else if(count === 2) {
      $("#font_comment").removeClass("disabled").css("width", "684px");
      $("#new_comment").show();
      $(".photo_meta a.font_types").removeClass("active");
      $(".photo_meta a.comments").addClass("active");
    } else {
      $("#font_spotted").addClass("disabled");
      $(".photo_meta a.comments").removeClass("active");
      $(".photo_meta a.font_types").removeClass("active");
      $("#new_comment").hide();
    }

  }
}).data("royalSlider");

$(".photo_meta a.font_types").click(function() {
  sliderInstance.goTo(1);
});

$(".photo_meta a.comments").click(function() {
  sliderInstance.goTo(2);
}); (function($) {
  $.fn.ellipsis = function(enableUpdating) {
    var s = document.documentElement.style;
    if(!('textOverflow' in s || 'OTextOverflow' in s)) {
      return this.each(function() {
        var el = $(this);
        if(el.css("overflow") == "hidden") {
          var originalText = el.html();
          var w = el.width();

          var t = $(this.cloneNode(true)).hide().css({
            'position' : 'absolute',
            'width' : 'auto',
            'overflow' : 'visible',
            'max-width' : 'inherit'
          });
          el.after(t);

          var text = originalText;
          while(text.length > 0 && t.width() > el.width()) {
            text = text.substr(0, text.length - 1);
            t.html(text + "...");
          }
          el.html(t.html());

          t.remove();

          if(enableUpdating == true) {
            var oldW = el.width();
            setInterval(function() {
              if(el.width() != oldW) {
                oldW = el.width();
                el.html(originalText);
                el.ellipsis();
              }
            }, 200);
          }
        }
      });
    } else
      return this;
  };
})(jQuery);
