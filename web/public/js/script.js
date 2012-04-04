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


$("form").submit(function(event) {
  event.preventDefault();
  var $form = $( this ),
  site = $form.find( 'input[name="site"]' ).val(),
  link = $form.find( 'input[name="link"]' ).val(),
  url = $form.attr( 'action' );
  id = $form.attr( 'id' );
  $.post( url, { site: site, link: link },
    function( data ) {
      $('#tab-pages').load('/ajax/count/pages', {site: site});
      $('#tab-temp').load('/ajax/count/temp', {site: site});
      $('#tab-blacklist').load('/ajax/count/blacklist', {site: site});
    }
  );
  id = id.split('-');
  id = '.row-' + id[1];
  $(id).fadeOut();
});
