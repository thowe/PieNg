package PieNg::View::HTML;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

PieNg::View::HTML - TT View for PieNg

=head1 DESCRIPTION

TT View for PieNg.

=head1 SEE ALSO

L<PieNg>

=head1 AUTHOR

TimH

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
