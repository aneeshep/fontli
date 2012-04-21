// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.core
//= require jquery.ui.widget
//= require jquery.ui.position
//= require jquery.ui.autocomplete
//= require tooltip
//= require typestry
//= require_self

var MAX_FILE_SIZE = 5242880;
var ACCEPT_FILE_TYPE = /image\/(jpg|jpeg|png)/i;

function showFormError(msg, form) {
  var errorDiv = document.createElement('div');
  errorDiv.className = 'errors';
  errorDiv.innerHTML = msg;
  form.find('div.errors').remove();
  form.prepend(errorDiv);
}

// acts as labelled-input and takes care of swapping label text based on data-label attr.
function defaultLabel(evnt, elem) {
  var curVal = elem.val();
  var lbl = elem.attr('data-label');
  //console.log('checking label..');
  if(evnt == 'focus' && curVal == lbl) {
    elem.val('');
  }
  if((evnt == 'blur' || evnt == 'load') && curVal == '') {
    elem.val(lbl);
  }
}

function update_crop(coords) {
  var ratio = 1;
  $("#crop_x").val(Math.round(coords.x * ratio));
  $("#crop_y").val(Math.round(coords.y * ratio));
  $("#crop_w").val(Math.round(coords.w * ratio));
  $("#crop_h").val(Math.round(coords.h * ratio));
}

function handleFileSelect(evt) {
  var files = evt.target.files;
  // FileList object
  var form = $(evt.target).closest('form');

  // Loop through the FileList and render image files as thumbnails.
  for(var i = 0, f; f = files[i]; i++) {

    // Only process image files.
    if(!f.type.match(ACCEPT_FILE_TYPE)) {
      showFormError('File is not an image', form);
      continue;
    }

    if(parseInt(f.size) > MAX_FILE_SIZE) {
      showFormError('File size exceeds 5MB.', form);
      continue;
    }

    var reader = new FileReader();

    // Closure to capture the file information.
    reader.onload = (function(theFile) {
      return function(e) {
        // Render thumbnail.
        var img = ['<img id="cropbox" src="', e.target.result, '" title="', theFile.name, '"/>'].join('');

        form.find('.preview').prepend(img);
        form.find('.preview').show();
      };
    })(f);

    // Read in the image file as a data URL.
    reader.readAsDataURL(f);
  }
}


$(document).ready(function() {
  $('.labelled-input').each(function() {
    defaultLabel('load', $(this));
    $(this).focus(function() { defaultLabel('focus', $(this));
    });
    $(this).blur(function() { defaultLabel('blur', $(this));
    });
  });

  $('form').live('submit ajax:before', function(e) {
    $(this).find('.labelled-input').each(function() {
      defaultLabel('focus', $(this));
    });
  });
  //$('#post_feed input[type=file]').change(handleFileSelect);

});
