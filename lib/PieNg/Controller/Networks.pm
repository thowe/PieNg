package PieNg::Controller::Networks;
use Moose;
use namespace::autoclean;

use NetAddr::IP qw(:lower);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

PieNg::Controller::Networks - Catalyst Controller

=head1 DESCRIPTION

Networks Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->detach('roots');
}

=head2 add

=cut

sub add :Local :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{'template'} = 'networks/add.tt';

    my $parent_id;  # will remain undef for roots
    my $parent;     # a Network instance

    # Are we a creator?  If not, fail.
    if( !$c->check_any_user_role( qw/ administrator creator / ) ) {
        $c->flash->{'message'} = "You are not allowed to create networks.";
        $c->response->redirect($c->uri_for(
            $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }

    # Handle URI arguments.
    if( $id eq 'root' ) {
        # used by the form
        $c->stash->{'parent_id'} = 'root';
    }
    elsif( $id =~ /^\d+$/ ) {
        $parent = $c->model('PieDB::Network')->find({
                      id => $id });
        if( !defined $parent ) {
            $c->flash->{'message'} = "No parent network with that id.";
            $c->response->redirect($c->uri_for(
                        $c->controller('Networks')->action_for('roots')));
            $c->detach();
        }

        $c->stash->{'parent_id'} = $parent_id = $id;
        $c->stash->{'parent_network'} = $parent;
    }
    else {
        $c->flash->{'message'} = "somethin screwy going on here";
        $c->response->redirect($c->uri_for(
            $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }

    my $params = $c->req->params;

    # if we are actually submitting a form
    if(lc $c->req->method eq 'post' ) {

        # The masks will be in a text field, but we want an array.
        my @masks = $params->{'valid_masks'} =~ /(\d+)/g;
        @masks = sort {$a <=> $b} @masks;

        # Is the network a valid network?  (meaning Net::Addr::IP thinks so)
        my $netaddrip = NetAddr::IP::Lite->new($params->{'address_range'});
        if(!defined $netaddrip) {
            $c->stash->{'message'} = $params->{'address_range'} .
                                     " is not a valid network.";
            return;
        }

        # Let's create our (potential) new network instance.
        my $new_network = $c->model('PieDB::Network')->new({
                              parent => $parent_id,
                              address_range => $netaddrip->cidr,
                              description => $params->{'description'},
                              subdivide   => $params->{'subdivide'},
                              valid_masks => \@masks,
                              owner       => $params->{'owner'},
                              account     => $params->{'account'},
                              service     => $params->{'service'} eq '' ? undef : $params->{'service'}});

        # Do we have logical masks? (always true if we aren't subdividing)
        if( ! $new_network->masks_are_logical ) {
            $c->stash->{'message'} = $params->{'masks'} .
                                     " doesn't make sense here.";
            return;
        }

        # If it is a root, does it already overlap with another network
        # in the database?
        if( $id eq 'root' && $new_network->overlaps_any) {
            $c->stash->{'message'} = $params->{'address_range'} .
                                     " can't be a root; overlaps with another network.";
            return;
        }

        # We shouldn't need any more root tests, I think.

        if( $id ne 'root' ) {
            # Can the parent be subdivided?
            if( ! $parent->subdivide ) {
                $c->stash->{'message'} = $params->{'address_range'} .
                                         " can't be added while the parent can't be subdivided.";
                return;
            }
            # Does the parent network allow this length of mask?
            if( ! grep { $_ == $netaddrip->masklen } @{$parent->valid_masks} ){
                $c->stash->{'message'} = "The parent doesn't allow";
                return;
            }
            # Does the specified network overlap at this level of the tree?
            if($new_network->overlaps) {
                $c->stash->{'message'} = $params->{'address_range'} .
                                     " overlaps with another network at this level.";
                return;
            }
            # Is the specified parent the right place for this in the hierarchy?
            if( !($parent->net_addr_ip == $new_network->smallest_container->net_addr_ip) ) {
                $c->stash->{'message'} = $params->{'address_range'} .
                                     " doesn't belong in this part of the tree";
                return;
            }
        }

        $new_network->insert;
        $c->flash->{'message'} = $new_network->address_range . " added";
        $c->response->redirect($c->uri_for(
            $c->controller('Networks')->action_for('roots')));
        $c->detach();

    }
    else { # We need to display a form.

        if( $id ne 'root' ) {
            $c->stash->{'fsfirst'} = $params->{'fsfirst'};
            $c->stash->{'fslast'} = $params->{'fslast'};
            my $freespace = PieDB::FreeSpace->new(
                              { first_ip => NetAddr::IP::Lite->new($params->{'fsfirst'}),
                                last_ip => NetAddr::IP::Lite->new($params->{'fslast'}),
                                subnet => $parent->net_addr_ip } );

            $c->stash->{'fillnets'} = $freespace->fillnets(
                                        $params->{'rmask'},
                                        PieNg->config->{'fillnet_limit'} );
        }
    }
}

=head2 branch

Display the portion of the tree under a specific network.

=cut

sub branch :Local :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{'template'} = 'networks/branch.tt';

    my $network = $c->model('PieDB::Network')->find({
                      id => $id });
    if( !defined $network ) {
        $c->flash->{'message'} = "No network with that id.";
        $c->response->redirect($c->uri_for(
                    $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }

    $c->stash->{'network'} = $network;
    $c->stash->{'branch'} = $network->branch_with_space;
}

=head2 roots

Display a list of the base networks.
to the list.

=cut

sub roots :Local :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{'template'} = 'networks/roots.tt';

    my $roots_rs = $c->model('PieDB::Network')->search(
                    { parent => undef } );
    $c->stash->{'roots'} = $roots_rs;
    $c->stash->{'message'} = $c->flash->{'message'};
}

=head1 AUTHOR

Tim Howe

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
