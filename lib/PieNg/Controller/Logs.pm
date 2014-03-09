package PieNg::Controller::Logs;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

PieNg::Controller::Logs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PieNg::Controller::Logs in Logs.');
}

=head2 newlog

A log entry for a newly created network.
I'll assume the new network is in the stash.

=cut

sub newlog :Private {
    my ( $self, $c ) = @_;

    my $new_network = $c->stash->{'new_network'};
    my $user = $c->user;
    my $new_changelog = $c->model('PieDB::Changelog')->new({
                              'user'   => $user->id,
                              'prefix' => $new_network->cidr_compact,
                              'change' => 'Created'});
    $new_changelog->insert;
}

=encoding utf8

=head1 AUTHOR

Tim Howe,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
