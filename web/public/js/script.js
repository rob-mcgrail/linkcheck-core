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
