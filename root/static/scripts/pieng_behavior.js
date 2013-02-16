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

function get_hosts(hosts_div) {
    networkID = hosts_div.closest('div.address_range').data('networkid');
    hosts_div.html("<p>Filled in from function for " + networkID + "</p>");
}

function add_host(event) {
    event.preventDefault();
     var $form = $(this),
        address = $form.find( 'input[name="hostaddress"]' ).val(),
        description = $form.find( 'input[name="hostdescription"]' ).val(),
        id = $form.find( 'input[name="networkid"]' ).val(),
        url = $form.attr( 'action' );
    var posting = $.post( url, { hostaddress: address,
                                 hostdescription: description,
                                 networkid: id }, 'json' );
    posting.done( function(data) {
        alert("Message: " + data.message);
    });
};

function expand_collapse_network_details() {
  if( $('div.details', $(this).closest('div.address_range')).hasClass('collapsed') ) {
    $('div.expander', $(this).closest('div.address_range')).html('[&minus;]');
    var detail_div = $('div.details', $(this).closest('div.address_range'));
    detail_div.removeClass('collapsed');

    if( $(this).closest('div.address_range').hasClass('nosubdivide') ) {
      if( $('form.add_host', $(this).closest('div.address_range')).length == 0 ) {
        var networkID = $(this).closest('div.address_range').data('networkid');
        $host_objs = $('div.template.hosts').children().clone();
        detail_div.append($host_objs);
        detail_div.append(genAddHost(networkID));
        $('form.add_host', $(this).closest('div.address_range')).on('submit', add_host);
        get_hosts($('div.hosts', $(this).closest('div.address_range')));
      }
    }
  }
  else {
    $('div.expander', $(this).closest('div.address_range')).html('[+]');
    $('div.details', $(this).closest('div.address_range')).addClass('collapsed');
  }
}

$(function() {
    $('#select_address_range').change(range_input_status);
});

$(function() {
    $('input[type=radio][name="subdivide"]').change(valid_masks_status);
});

$(function() {
    $('div.expander').on('click', expand_collapse_network_details);
});

$(function() {
    $('form.add_host').on('submit',function(event){ alert($(this).text()); });
});