function range_input_status() {
  if( $('#select_address_range').val() == 'manual_input' ) {
    $('#input_address_range').attr( 'disabled', false );
  }
  else {
    $('#input_address_range').attr( 'disabled', 'disabled' );
  }
};

function valid_masks_status() {
  if( $('input[name="subdivide"]:checked').val() == 'true' ) {
    $('#valid_masks').attr( 'disabled', false );
  }
  else {
    $('#valid_masks').attr( 'disabled', 'disabled' );
  }
};

function genAddHost(net_id) {
  return $('div.template.add_host').children().clone().prepend(
      $('<input>', { type: "hidden", name: "networkid", value: net_id }) );
}

function expand_network_details() {
  $('div.expander', $(this).closest('div.address_range')).html('[&minus;]');
  var detail_div = $('div.details', $(this).closest('div.address_range'));
  detail_div.removeClass('collapsed');

  if( $(this).closest('div.address_range').hasClass('nosubdivide') ) {
    if( $('form.add_host', $(this).closest('div.address_range')).length == 0 ) {
      var networkID = $(this).closest('div.address_range').data('networkid');
      detail_div.append($('div.template.hosts').children().clone());
      detail_div.append(genAddHost(networkID));
    }
  }
};

function collapse_network_details() {
  $('div.expander', $(this).closest('div.address_range')).html('[+]');
  $('div.details', $(this).closest('div.address_range')).addClass('collapsed');
};

$(function() {
    $('#select_address_range').change(range_input_status);
});

$(function() {
    $('input[type=radio][name="subdivide"]').change(valid_masks_status);
});

$(function() {
    $('div.expander').toggle(expand_network_details, collapse_network_details);
});
