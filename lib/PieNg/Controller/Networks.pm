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

    # We will want to remember the referring URI so that
    # we can get directed to it.
    my $referer;
    my $path = $c->req->path;
    if( defined $c->req->params->{'referer'} ) {
        $referer = $c->req->params->{'referer'};
    }
    else {
        $referer = $c->req->referer;
    }

    $c->stash->{'referer'} = $referer;

    # Handle URI arguments.
    if( $id eq 'root' ) {
        # used by the form
        $c->stash->{'parent_id'} = 'root';
    }
    elsif( $id =~ /\A\d+\z/ ) {
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

    if( $id ne 'root' ) {
        $c->stash->{'fsfirst'} = $params->{'fsfirst'};
        $c->stash->{'fslast'} = $params->{'fslast'};
        $c->stash->{'rmask'} = $params->{'rmask'};
        my $freespace = PieDB::FreeSpace->new(
                          { first_ip => NetAddr::IP::Lite->new($params->{'fsfirst'}),
                            last_ip => NetAddr::IP::Lite->new($params->{'fslast'}),
                            subnet => $parent->net_addr_ip } );

        $c->stash->{'fillnets'} = $freespace->fillnets(
                                    $params->{'rmask'},
                                    PieNg->config->{'fillnet_limit'} );
    }

    # if we are actually submitting a form
    if(lc $c->req->method eq 'post' ) {

        # The masks will be in a text field, but we want an array.
        my @masks = $params->{'valid_masks'} =~ /(\d+)/g;
        @masks = sort {$a <=> $b} @masks;

        # Is the network a valid network?  (meaning Net::Addr::IP thinks so)
        my $netaddrip;
        if($params->{'selected_address_range'} eq 'manual_input' and
           $params->{'address_range'}) {
            $netaddrip = NetAddr::IP::Lite->new($params->{'address_range'});
        }
        elsif( defined $params->{'selected_address_range'} ) {
            $netaddrip = NetAddr::IP::Lite->new(
                             $params->{'selected_address_range'});
        }
        elsif( defined $params->{'address_range'} ) {
            $netaddrip = NetAddr::IP::Lite->new($params->{'address_range'});
        }
        if(!defined $netaddrip) {
            $c->stash->{'message'} = $params->{'address_range'} .
                                     " is not a valid network.";
            return;
        }

        if( defined $params->{'service'} and $params->{'service'} ne '' and
            $params->{'service'} =~ m/[^0-9.]/ ) {

            $c->stash->{'message'} = "Service ID should be an integer.";
            return
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
                              service     => $params->{'service'} eq '' ?
                                                 undef : $params->{'service'}});

        # Do we have logical masks? (always true if we aren't subdividing)
        if( ! $new_network->masks_are_logical ) {
            $c->stash->{'message'} = $params->{'valid_masks'} .
                                     " aren't logical masks here.";
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

        if( defined $referer and $referer !~ /$path/ ) {
            $c->res->redirect($referer);
        }
        else {
            $c->response->redirect($c->uri_for(
                $c->controller('Networks')->action_for('roots')));
        }
        $c->detach();

    }
}

=head2 branch

Display the portion of the tree under a specific network.

=cut

sub branch :Local :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{'template'} = 'networks/branch.tt';
    $c->stash->{'message'} = $c->flash->{'message'};

    my $network = $c->model('PieDB::Network')->find({
                      id => $id });
    if( !defined $network ) {
        $c->flash->{'message'} = "No network with that id.";
        $c->response->redirect($c->uri_for(
                    $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }

    if( $network->subdivide ) { 
        $c->stash->{'network'} = $network;
        $c->stash->{'branch'} = $network->branch_with_space;
    }
    elsif( $network->parent and $network->parent->subdivide ) {
        $c->stash->{'network'} = $network->parent;
        $c->stash->{'branch'} = $network->parent->branch_with_space;
    }
    else {
        $c->flash->{'message'} = "No valid branch for that network.";
        $c->response->redirect($c->uri_for(
                    $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }
}

=head2 delete

=cut

sub delete :Local :Args(1) {
    my ($self, $c, $id) = @_;
    my $network;

    # We will want to remember the referring URI so that
    # we can get directed to it.
    my $referer = $c->req->referer;

    # Are we a creator?  If not, fail.
    if( !$c->check_any_user_role( qw/ administrator creator / ) ) {
        $c->flash->{'message'} = "You are not allowed to delete networks.";
        $c->res->redirect($referer);
        $c->detach();
    }

    # make sure it's an integer so DBIC doesn't complain
    if( $id =~ /\A\d+\z/ ) {
        $network = $c->model('PieDB::Network')->find( { id => $id } );
    }
    else {
        $c->flash->{'message'} = "That's not even an integer.  What are you trying to pull?";
        $c->res->redirect($referer);
        $c->detach();
    }

    # it has to actually exist
    if( !defined $network ){
        $c->flash->{'message'} = "There is no network with that id.";
        $c->res->redirect($referer);
        $c->detach();
    }

    if( $network->has_children ) {
        $c->flash->{'message'} = "There are networks under " . $network->cidr_compact;
        $c->res->redirect($referer);
        $c->detach();
    }

    if( $network->hosts->count ) {
        $c->flash->{'message'} = "There are hosts defined under " . $network->cidr_compact;
        $c->res->redirect($referer);
        $c->detach();
    }

    $network->delete;

    if( not $network->in_storage ) {
        $c->flash->{'message'} = "Deleted " . $network->cidr_compact;
        $c->res->redirect($referer);
        $c->detach();
    }
    else {
        $c->flash->{'message'} = "Network didn't delete.  I don't know why.";
        $c->res->redirect($referer);
        $c->detach();
    }
}

=head2 edit

=cut

sub edit :Local :Args(1) {
    my ($self, $c, $id) = @_;
    $c->stash->{'template'} = 'networks/edit.tt';

    # Are we an editor?  If not, fail.
    if( !$c->check_any_user_role( qw/ administrator creator editor / ) ) {
        $c->flash->{'message'} = "You are not allowed to edit networks.";
        $c->response->redirect($c->uri_for(
            $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }

    my $network = $c->model('PieDB::Network')->find({ id => $id });
    if( !defined $network ) {
        $c->flash->{'message'} = "No network with that id.";
        $c->response->redirect($c->uri_for(
                    $c->controller('Networks')->action_for('roots')));
        $c->detach();
    }

    $c->stash->{'network'} = $network;

    # We will want to remember the referring URI so that once login
    # works we can get directed to it.
    my $referer;
    my $path = $c->req->path;
    if( defined $c->req->params->{'referer'} ) {
        $referer = $c->req->params->{'referer'};
    }
    else {
        $referer = $c->req->referer;
    }

    $c->stash->{'referer'} = $referer;

    # if we are actually submitting a form
    if(lc $c->req->method eq 'post' ) {
        my $params = $c->req->params;

        # The masks will be in a text field, but we want an array.
        my @masks = $params->{'valid_masks'} =~ /(\d+)/g;
        @masks = sort {$a <=> $b} @masks;

        if( defined $params->{'service'} and $params->{'service'} ne '' and
            $params->{'service'} =~ m/[^0-9.]/ ) {

            $c->stash->{'message'} = "Service ID should be an integer.";
            return;
        }

        $network->set_columns({
                description => $params->{'description'},
                subdivide   => $params->{'subdivide'},
                valid_masks => \@masks,
                owner       => $params->{'owner'},
                account     => $params->{'account'},
                service     => $params->{'service'} eq '' ?
                                   undef : $params->{'service'} });

        my %changed_cols = $network->get_dirty_columns;

        # We don't want to exclude existing children when changing valid_masks.
        if( defined $changed_cols{'valid_masks'} and $network->subdivide and
            $network->has_children ) {

            my @net_children = $network->networks;
            foreach my $child (@net_children) {
                if( ! grep {$_ eq $child->net_addr_ip->masklen} @{$network->valid_masks} ) {
                    $c->stash->{'message'} =
                        "You can't change your masks to exclude an existing child.";
                    return;
                }
            }
        }

        # Do we have logical masks? (always true if we aren't subdividing)
        if( ! $network->masks_are_logical ) {
            $c->stash->{'message'} = $params->{'valid_masks'} .
                                     " aren't logical netmasks here.";
            return;
        }

        $network->update;
        $c->flash->{'message'} = $network->address_range . " edited";
        if( defined $referer and $referer !~ /$path/ ) {
            $c->res->redirect($referer);
        }
        else {
            $c->response->redirect($c->uri_for(
                $c->controller('Networks')->action_for('roots')));
        }
        $c->detach();
    }
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

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Tim Howe <timh@dirtymonday.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Tim Howe.

This program is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties. For details,
see the full text of the license in the file LICENSE.

This code is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text of the
license in the file LICENSE.

=cut

1;
