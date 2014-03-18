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

For the moment, let's just show the last 100 log entries.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{'template'} = 'logs/last.tt';
    $c->stash->{'log_limit'} = PieNg->config->{'last_logs_limit'};
    my $changelogs = $c->model('PieDB::Changelog')->search(
                         { user => 1},
                         { order_by => {-desc => 'change_time'} });
    $c->stash->{'changes'} = $changelogs;
}

=head2 netlog

Record the changes of an update.
This expects the network prefix (cidr_compact works best in most cases)
in $c->stash->{'prefix'}, a hashref of the columns that changed in
$c->stash->{'changed_cols'}, and a log type
(one of 'created', 'updated', or 'deleted' is appropriate).

=cut

sub netlog :Private {
    my ( $self, $c ) = @_;

    use JSON;
    my $json = JSON->new->pretty([1]);

    my $prefix = $c->stash->{'prefix'};
    my $cols = $c->stash->{'changed_cols'};
    my $log_type = $c->stash->{'log_type'};

    my $new_changelog = $c->model('PieDB::Changelog')->new({
                              'user'   => $c->user->id,
                              'prefix' => $prefix,
                              'change' => $json->pretty->encode(
                                              { $log_type => $cols } ) });
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
