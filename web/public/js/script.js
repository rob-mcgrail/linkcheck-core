// Make buttons in targetable divs opaque unless hovered.

// <div class="targetable" id="row-1">
//     <form class="form-1 opacitize">
//     </form>
// </div>

var currentId = '';
$(".targetable").hover(
  function () {
    currentId = $(this).attr('id');
    currentId = currentId.replace('row', 'form');
    $('.' + currentId).removeClass("opacitize");
  },
  function () {
    $('.' + currentId).addClass("opacitize");
  }
);

// Submit forms with class blacklistManagement without page-refresh

$("form.backlistManagement").submit(function(event) {
  event.preventDefault();
  var $form = $( this ),
  site = $form.find( 'input[name="site"]' ).val(),
  link = $form.find( 'input[name="link"]' ).val(),
  url = $form.attr( 'action' );
  id = $form.attr( 'id' );
  $.post( url, { site: site, link: link });
  id = id.split('-');
  id = '.row-' + id[1];
  $(id).fadeOut();
});

// updating linkchecker status

$(document).ready(function() {
 	 $("#checkStatus").load("/check-status");
   var refreshId = setInterval(function() {
      $("#checkStatus").load('/check-status');
   }, 9000);
   $.ajaxSetup({ cache: false });
});
