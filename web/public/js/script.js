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
