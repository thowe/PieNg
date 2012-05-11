function range_input_status() {
  if ($('#select_address_range').val() == 'manual_input') {
    $('#input_address_range').attr( 'disabled', false );
  }
  else {
    $('#input_address_range').attr( 'disabled', 'disabled' );
  }
}

function valid_masks_status() {
  if ($('input[name="subdivide"]:checked').val() == 'true') {
    $('#valid_masks').attr( 'disabled', false );
  }
  else {
    $('#valid_masks').attr( 'disabled', 'disabled' );
  }
}

function expand_network_details() {
  $('div.expander', $(this).closest('div.address_range')).html('&darr;');
  $('div.details', $(this).closest('div.address_range')).removeClass('collapsed');
};

function collapse_network_details() {
  $('div.expander', $(this).closest('div.address_range')).html('&rarr;');
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
