var targetX, targetY;
var tagCounter = 0;

$(document).ready(function() {
  $('#tag_fonts').click(function() {
    $('#on_image_element').hide();
    show_font_tag();
    return false;
  });
});
function show_font_tag() {
  $("img#foto").wrap('<div id="tag-wrapper"></div>');
  //Dynamically size wrapper div based on image dimensions
  $("#tag-wrapper").width($("img#foto").outerWidth());
  $("#tag-wrapper").height($("img#foto").outerHeight());

  //Append #tag-target content and #tag-input content
  $("#tag-wrapper").prepend('<div id="tag-target"></div><div id="tag-input"><p>Please click on the below image to tag font <button type="button" class="tag_close_button" onclick="closeTagInput();">Cancel</button></p></div>');
  $("img#foto").css("cursor", "crosshair");
  //$("#tag-wrapper").click(function(e){
  $("img#foto").click(function(e) {

    //Determine area within element that mouse was clicked
    mouseX = e.pageX - $("#tag-wrapper").offset().left;
    mouseY = e.pageY - $("#tag-wrapper").offset().top;

    //Get height and width of #tag-target
    targetWidth = $("#tag-target").outerWidth();
    targetHeight = $("#tag-target").outerHeight();

    //Determine position for #tag-target
    targetX = mouseX - targetWidth / 2;
    targetY = mouseY - targetHeight / 2;

    //Determine position for #tag-input
    inputX = mouseX + targetWidth / 2;
    inputY = mouseY - targetHeight / 2;

    $('#tag-input').remove();
    $('#tag-target').append('<div id="tag-input"><input type="text" name="font" id="font"><button type="button" class="tag_close_button" onclick="closeTagInput();">Cancel</button></div>');
    $("#font").val("").focus();
    $("ul").removeClass("preview_active");

    $("#font").autocomplete({
      minLength : 3,
      source : "/fetch_font_families",
      focus : function(event, ui) {
        $("#font").val(ui.item.name);
        return false;
      },
      select : function(event, ui) {
        $("#font").val(ui.item.name);
        $("#tag-target").append('<div id="loading"><img src="/assets/ajax-loader.gif" alt="Ajax-loader"></div>');
        show_font_list();
        return false;
      }
    }).data("autocomplete")._renderItem = function(ul, item) {
      return $("<li></li>").data("item.autocomplete", item).append("<a>" + item.name + "</a>").appendTo(ul);
    };
    $("#font").keydown(function(event) {
      if(event.keyCode == '8') {
        $(".ui-autocomplete").removeClass("preview_active");
      }
    });
  });
}

function submitTag(obj) {
  coords = targetX + ',' + targetY;
  photo_id = $("#foto").attr("class");
  $(obj).append('<input type="hidden" name="font[coords]" value=' + coords + '><input type="hidden" name="photo_id" value=' + photo_id + '>').submit();
  tagCounter++;
  closeTagInput();
}

function closeTagInput() {
  $("#tag-target").fadeOut();
  $("#tag-input").fadeOut();
  $("#font").val("");
  $("ul").removeClass("preview_active");
  $('#on_image_element').show();
}

function removeTag(i) {
  $("#hotspot-item-" + i).fadeOut();
  $("#hotspot-" + i).fadeOut();
}

function showTag(i) {
  $("#hotspot-" + i).addClass("hotspothover");
}

function hideTag(i) {
  $("#hotspot-" + i).removeClass("hotspothover");
}

function show_font_list() {
  var selected_font = $("#font").val();
  $("ul.ui-autocomplete").children().replaceWith('<li><div id="loading"><img src="/assets/ajax-loader.gif" alt="Ajax-loader"></div></li>');
  $("#loading").show();
  $.ajax({
    method : 'get',
    url : '/get_font_details?font_name=' + selected_font,
    dataType : 'html',
    success : function(data) {
      $("#loading").remove();
      $(".ui-autocomplete").addClass("preview_active").html(data);
    }
  });
}

function show_sub_font_list(uniqueid, name, id, event) {
  event.preventDefault();
  $("ul.ui-autocomplete").children().replaceWith('<li><div id="loading"><img src="/assets/ajax-loader.gif" alt="Ajax-loader"></div></li>');
  $("#loading").show();
  $.ajax({
    method : 'get',
    url : '/get_sub_font_details?family_name=' + name + '&family_id=' + id + '&uniqueid=' + uniqueid,
    dataType : 'html',
    success : function(data) {
      $("#loading").remove();
      $(".ui-autocomplete").addClass("preview_active").html(data);
    }
  });
}