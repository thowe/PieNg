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

sub add :Local :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{current_view} = 'Service';

    #my $network;     # a Network instance

    # Are we an editor?
    if( $c->check_any_user_role( qw/ administrator creator editor / ) ) {

    }

    $c->stash->{'jsondata'}->{'code'} = 0;
    $c->stash->{'jsondata'}->{'message'} = 'Changes complete.';

}

=head1 AUTHOR

TimH

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
