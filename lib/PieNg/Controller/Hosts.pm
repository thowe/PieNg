package PieNg::Controller::Hosts;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

PieNg::Controller::Hosts - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PieNg::Controller::Hosts in Hosts.');
}

=head2 add

=cut

sub edit :Local :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{current_view} = 'Service';

    # Are we an editor?
    if( !$c->check_any_user_role( qw/ administrator creator editor / ) ) {
        $c->stash->{'jsondata'}->{'code'} = 1;
        $c->stash->{'jsondata'}->{'message'} = 'Permission Denied';
        return;
    }

    # hostaddress, hostdescription, networkid
    my $params = $c->req->params;
    my ($network, $host);

    $network = $c->model('PieDB::Network')->find(
                   { id => $params->{'networkid'} });
    if( !defined $network ){
        $c->stash->{'jsondata'}->{'code'} = 2;
        $c->stash->{'jsondata'}->{'message'} = 'That network is undefined.';
        return;
    }

    if( ! $params->{'hostaddress'} or
        ! NetAddr::IP::Lite->new( $params->{'hostaddress'} ) or
        ! $network->net_addr_ip->contains(
          NetAddr::IP::Lite->new( $params->{'hostaddress'} ) ) ) {
        $c->stash->{'jsondata'}->{'code'} = 3;
        $c->stash->{'jsondata'}->{'message'} = 'not a valid host within this network';
        return;
    }

    $host = $c->model('PieDB::Host')->find(
                   { address => $params->{'hostaddress'} });

    if( defined $host ) {

        # If the description is empty, assume we want to delete it.
        if( ! $params->{'hostdescription'} ) {
            $host->delete;
            $c->stash->{'jsondata'}->{'code'} = 0;
            $c->stash->{'jsondata'}->{'message'} = 'deleted host';
            $c->stash->{'jsondata'}->{'id'} = $params->{'networkid'};
            return
        }

        $host->description($params->{'hostdescription'});
        $host->update;
    }
    else {
        $host = $c->model('PieDB::Host')->new({
                     'network' => $params->{'networkid'},
                     'address' => $params->{'hostaddress'},
                     'description' => $params->{'hostdescription'} });
        $host->insert;
    }

    $c->stash->{'jsondata'}->{'code'} = 0;
    $c->stash->{'jsondata'}->{'message'} = 'updated hosts';
    $c->stash->{'jsondata'}->{'id'} = $params->{'networkid'};
}

=head2 listtable

=cut

sub listtable :Local :Args(1) {
    my ($self, $c, $network_id) = @_;
    my $network;
    my $hosts_rs;

    $c->stash->{'template'} = 'hosts/listtable.tt';

    if( $network_id =~ /\A\d+\z/ ) {
        $network = $c->model('PieDB::Network')->find({ id => $network_id });
        if( defined $network ) {
            $hosts_rs = $network->hosts({},{ 'order_by' => 'address' });
            $c->stash->{'hosts'} = $hosts_rs if $hosts_rs->count;
        }
    }
}

=head1 AUTHOR

TimH

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
