package PieDB::FreeSpace;

=head1 PieDB::FreeSpace

PieDB::FreeSpace - A class to represent the space between
assigned subnets in the PieDB.

=head1 SYNOPSYS

my $subnet = NetAddr::IP::Lite->new('2001:db8:0040::/48');
my $first_ip = NetAddr::IP::Lite->new(
                   NetAddr::IP::Lite->new('2001:db8:40:4:6::')->addr);
my $last_ip = NetAddr::IP::Lite->new(
                   NetAddr::IP::Lite->new('2001:db8:40:2f::')->addr);

my $space = PieDB::FreeSpace->new(
              first_ip => $first_ip,
              last_ip => $last_ip,
              subnet => $subnet );

my $nets = $space->fillnets(64,256);

foreach my $net (@{$nets}) {
    say $net->addr . "/" . $net->masklen;
}

=cut

use Moose;
use NetAddr::IP qw(:lower);

has 'first_ip' => (
        is => 'ro',
        isa => 'NetAddr::IP::Lite',
        required => 1 );

has 'last_ip' => (
        is => 'ro',
        isa => 'NetAddr::IP::Lite',
        required => 1 );

# The subnet that contains the free space
has 'subnet' => (
        is => 'ro',
        isa => 'NetAddr::IP::Lite',
        required => 1 );

sub BUILD {
    my $self = shift;

    if( $self->first_ip->version() != $self->last_ip->version() ||
        $self->first_ip->version() != $self->subnet->version() ) {
        die 'All addresses are not of the same IP version.';
    }

    if( $self->first_ip->version() == 4 ) {
        if( $self->first_ip->masklen() != 32 ||
            $self->last_ip->masklen() != 32 ) {
            die 'first_ip and last_ip should not contain more than one address.';
        }
    }
    else {
        if( $self->first_ip->masklen() != 128 ||
            $self->last_ip->masklen() != 128 ) {
            die $self->last_ip->cidr . 'first_ip and last_ip should not contain more than one address.';
        }
    }

    if( !$self->subnet->contains($self->first_ip) ||
        !$self->subnet->contains($self->last_ip) ) {
        die 'This space is not contained within the configured subnet';
    }
}

sub fillnets {
    my ($self, $mask, $limit) = @_;

    my $dip = NetAddr::IP::Lite->new($self->first_ip->addr . '/' . $mask);
    my @nets;

    # The first IP may or may not be a valid base address for a network
    # that we want to get back.
    if(NetAddr::IP::Lite->new($dip->addr) >= $self->first_ip &&
                         $dip->broadcast <= $self->last_ip &&
                         $dip eq $dip->network) {
        push(@nets, $dip);
        $limit = $limit - 1;
    }

    $dip = $self->next_subnet($dip);

    for (1..$limit) {
        if(NetAddr::IP::Lite->new($dip->addr) >= $self->first_ip &&
                         $dip->broadcast <= $self->last_ip) {
            push(@nets, $dip);
            $dip = $self->next_subnet($dip);
        }
        else { last; }
    }

    return \@nets;
}

sub first_ip_compact {
    my $self = shift;

    if( $self->first_ip->version == 4) {
        return $self->first_ip->addr;
    }
    else {
        return $self->first_ip->short;
    }
}

sub last_ip_compact {
    my $self = shift;

    if( $self->last_ip->version == 4) {
        return $self->last_ip->addr;
    }
    else {
        return $self->last_ip->short;
    }
}

sub next_subnet {
    my ($self, $cur_subnet) = @_;
    my $scratch = NetAddr::IP::Lite->new(
                      $cur_subnet->broadcast->addr . '/' .
                      $self->subnet->mask) + 1;
    return NetAddr::IP::Lite->new($scratch->addr . '/' .
                            $cur_subnet->mask);
}

no Moose;
__PACKAGE__->meta->make_immutable;
