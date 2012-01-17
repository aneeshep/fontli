var SITE = SITE || {};

SITE.fileInputs = function() {
  var $this = $(this),
      $val = $this.val(),
      valArray = $val.split('\\'),
      newVal = valArray[valArray.length-1],
      $button = $this.siblings('.button'),
      $fakeFile = $this.siblings('.browse-file');
  if(newVal !== '') {
    $this.text(newVal);
    $('#post_feed').submit();
    $this.val = "";
    }
  else {
    $fakeFile.text('Browse a picture');
  }
};

$(document).ready(function() {
  $('.file-wrapper input[type=file]').bind('change focus click', SITE.fileInputs);
});
