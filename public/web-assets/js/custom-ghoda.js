$('.dropdown-toggle').dropdown();
$('#main-tabs a').click(function (e) {
	e.preventDefault();
	$(this).tab('show');
});
$('#bar-b-tabs a').click(function (e) {
	e.preventDefault();
	$(this).tab('show');
});
$('#bar-b-tabs-b a').click(function (e) {
	e.preventDefault();
	$(this).tab('show');
});
$('#tata a').click(function (e) {
	e.preventDefault();
	$(this).tab('show');
});
$('#main-tabs-a a').click(function (e) {
	e.preventDefault();
	$(this).tab('show');
});
$('.mc-b-collapsed .bar-d').on('click',function () {
	$('.mc-b-collapsed').removeClass('mc-b-collapsed').addClass('mc-b-expanded');
	$('.mc-a-expanded').removeClass('mc-a-expanded').addClass('mc-a-collapsed');
});

$('.mc-b-expanded .bar-d').on('click',function () {
	$('.mc-b-expanded').removeClass('mc-b-expanded').addClass('mc-b-collapsed');
	$('.mc-a-collapsed').removeClass('mc-a-collapsed').addClass('mc-a-expanded');
});

$('#test-connection').on('click',function () {
	$('#test-connection-expand').css('display','block');
});

(function($){
	$(window).load(function(){
		$(".aa").mCustomScrollbar({
			scrollButtons:{
				enable:true
			}
  	});
		$(".bb").mCustomScrollbar({
			horizontalScroll:true,
			scrollButtons:{
				enable:true
			}
		});
	});
})(jQuery);

// custom added
$(document).ready(function() {
 //popup
	$('.bigpic, .collapse').live('click', function() {
		$('.popup').toggleClass('closed open');		
	});
  $('.popup .cross').live('click', function() {
    $('#popup_container').html('').hide();
  });
  // signup
  $('#join_fontli').click(function() {
    location.href = $(this).attr('href');
  });
  $('#slider1').lemmonSlider({
    infinite: true
  });
  $('li[rel=popitup],div[rel=popitup]').live('click', function() {
    var url = $(this).attr('href');
    var id  = $(this).attr('data-id');
    showAjaxLoader(true);
    if(interval) clearInterval(interval);
    spottedContentLoaded = false;
    $.ajax({
      url: url,
      data: {id:id},
      success: function(data, textStatus) {
        hideAjaxLoader();
        $('#popup_container').html(data);
      },
      error: function() {
        hideAjaxLoader();
        alert('Oops, An error occured!');
        $('#popup_container').hide();
      }
    });
  });
  $('li.banner-cta, .notifications-count-box').live('click', function() {
    var url = $(this).attr('href');
    location.href = url;
  });
  // ajax request links with remote=true
  $('a[remote=true]').live('click', function() {
    var url = $(this).attr('data-href');
    showAjaxLoader();
    $.ajax({
      url: url,
      dataType: 'script',
      complete: hideAjaxLoader
    });
  });
  spottedContentLoaded = false;
  $('.popup .bottom-nav .view-spotted').live('click', function() {
    var url = $(this).attr('data-url');
    if(spottedContentLoaded) {
      animateSpottedPopup();
    }else {
      $(this).attr('disabled', true);
      $.ajax({
        url: url,
        success: function(data, textStatus) {
          $('.popup .right-pop.spotted').html(data);
          spottedContentLoaded = true;
          $(this).attr('disabled', false);
          animateSpottedPopup();
        }
      });
    }
  });
  $('.popup .bottom-nav .view-typetalk').live('click', function() {
    animateTypetalkPopup();
  });
  $('.qrcode a').click(function() {
    var klass = $(this).attr('class');
    $('#qr_pop .img-qrcode').hide(); // hide both codes
    $('#qr_pop .img-qrcode.'+klass).show(); //show relavant
    $('#qr_pop').show();
  });
  $('#qr_pop a.close-icon').click(function() {
    $('#qr_pop').hide();
  });
  interval = setInterval(function() {
    $('#slider1').trigger('nextSlide');
  }, 3000);
  $('.controls a').click(function() {
    clearInterval(interval);
  });
});

function showAjaxLoader(popup) {
  var offset = $(window).scrollTop();
  $('#ajax_loader').css('top', offset + 'px').show();
  if(popup) $('#popup_container').css('top', offset + 5 + 'px').show();
}
function hideAjaxLoader() {
  $('#ajax_loader').hide();
}
function getDocHeight() {
  var D = document;
  return Math.max(
    Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
    Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
    Math.max(D.body.clientHeight, D.documentElement.clientHeight)
  );
}
function animateSpottedPopup() {
  $('.popup .right-pop.spotted').fadeIn(1000);
  $('.popup .right-pop.typetalk').hide();
}
function animateTypetalkPopup() {
  $('.popup .right-pop.typetalk').fadeIn(1000);
  $('.popup .right-pop.spotted').hide();
}
