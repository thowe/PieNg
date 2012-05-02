package PieDB::Schema::Result::Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 NAME

PieDB::Schema::Result::Network

=cut

__PACKAGE__->table("networks");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'networks_id_seq'

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 address_range

  data_type: 'cidr'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 subdivide

  data_type: 'boolean'
  is_nullable: 0

=head2 valid_masks

  data_type: 'smallint[]'
  is_nullable: 1

=head2 owner

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 account

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 service

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "networks_id_seq",
  },
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "address_range",
  { data_type => "cidr", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "subdivide",
  { data_type => "boolean", is_nullable => 0 },
  "valid_masks",
  { data_type => "smallint[]", is_nullable => 1 },
  "owner",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "account",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "service",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("networks_address_range_key", ["address_range"]);

=head1 RELATIONS

=head2 hosts

Type: has_many

Related object: L<PieDB::Schema::Result::Host>

=cut

__PACKAGE__->has_many(
  "hosts",
  "PieDB::Schema::Result::Host",
  { "foreign.network" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 parent

Type: belongs_to

Related object: L<PieDB::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "PieDB::Schema::Result::Network",
  { id => "parent" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 networks

Type: has_many

Related object: L<PieDB::Schema::Result::Network>

=cut

__PACKAGE__->has_many(
  "networks",
  "PieDB::Schema::Result::Network",
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-30 23:41:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CYC+utZAUdgWO3y2Eim8FQ

use NetAddr::IP::Lite qw(:lower);

=head2 branch

=cut

sub branch {
    my ($self) = @_;
    my (@children, @branch);

    @children = $self->networks( undef, { order_by => 'address_range' } )->all;

    foreach my $child (@children) {
        push @branch, ({ description   => $child->description,
                         address_range => $child->address_range,
                         subdivide     => $child->subdivide,
                         valid_masks   => $child->valid_masks,
                         owner         => $child->owner,
                         account       => $child->account,
                         service       => $child->service,
                         children      => branch($child) });
    }

    return \@branch;
}

=head2 branch_with_space

The same as branch, except the open network space is
represented by FreeSpace objects.

=cut

use PieDB::FreeSpace;

sub branch_with_space {
    my ($self) = @_;
    my (@children, @branch);

    @children = $self->networks( undef,
                    { order_by => 'address_range' } )->all;

    # If there are no child networks, we may just want a full
    # spacer to fill up.
    if( ! @children ) {
        # I don't want any space to be created if the network
        # isn't able to be subdivided.
        return undef if(! $self->subdivide);

        push @branch, PieDB::FreeSpace->new(
                          first_ip => NetAddr::IP::Lite->new(
                                         $self->net_addr_ip->addr),
                          last_ip => NetAddr::IP::Lite->new(
                                         $self->net_addr_ip->broadcast->addr),
                          subnet => $self->net_addr_ip,
                          pieng_network_id => $self->id,
                          valid_masks => $self->valid_masks );
        return \@branch; # Why go on?
    }

    # if there is free space before the first child network
    if( @children and
        $self->net_addr_ip->addr ne $children[0]->net_addr_ip->addr ) {
        push @branch, PieDB::FreeSpace->new(
                          first_ip => NetAddr::IP::Lite->new(
                                          $self->net_addr_ip->addr),
                          last_ip => $children[0]->preceding_addr,
                          subnet => $self->net_addr_ip,
                          pieng_network_id => $self->id,
                          valid_masks => $self->valid_masks );
    }

    my $prev_child;

    foreach my $child (@children) {
        if( defined $prev_child and
            $prev_child->net_addr_ip->broadcast->addr
            ne $child->preceding_addr->addr ) {

            push @branch, PieDB::FreeSpace->new(
                first_ip => $prev_child->following_addr,
                last_ip => $child->preceding_addr,
                subnet => $self->net_addr_ip,
                pieng_network_id => $self->id,
                valid_masks => $self->valid_masks );
                                          
        }

        push @branch, ({ description   => $child->description,
                         address_range => $child->address_range,
                         subdivide     => $child->subdivide,
                         valid_masks   => $child->valid_masks,
                         owner         => $child->owner,
                         account       => $child->account,
                         service       => $child->service,
                         children      => branch_with_space($child) });

        $prev_child = $child;
    }

    if ( $prev_child and
         $prev_child->net_addr_ip->broadcast->addr
         ne $self->net_addr_ip->broadcast->addr ) {

        push @branch, PieDB::FreeSpace->new(
                 first_ip => $prev_child->following_addr,
                 last_ip => NetAddr::IP::Lite->new(
                                $self->net_addr_ip->broadcast->addr),
                 subnet => $self->net_addr_ip,
                 pieng_network_id => $self->id,
                 valid_masks => $self->valid_masks );
    }

    return \@branch;
}

=head2 cidr_compact

Always return a sensible cidr notation string.  For IPv4 this is the same
as NetAddr::IP cidr method.  For IPv6 it is the same as short with a mask
in slash notation.

=cut

sub cidr_compact {
    my ($self) = @_;

    if( $self->net_addr_ip->version == 4) {
        return $self->net_addr_ip->cidr;
    }
    else {
        return $self->net_addr_ip->short . '/' . $self->net_addr_ip->masklen;
    }
}

=head2 following_addr

Net::Addr::IP of the single IP address following this network.
If this is already the last possible network within its parent,
undef is returned.

=cut

sub following_addr {
    my ($self) = @_;

    if( ! $self->parent or
        $self->parent->net_addr_ip->broadcast->addr
        eq $self->net_addr_ip->broadcast->addr or
        ! $self->parent->net_addr_ip->contains($self->net_addr_ip) ) {

        return undef; 
    }

    return NetAddr::IP::Lite->new(
               ( NetAddr::IP::Lite->new(
                     $self->net_addr_ip->broadcast->addr
                     .  '/' .
                     $self->parent->net_addr_ip->mask) + 1
                 )->addr );
};

=head2 has_children

=cut

sub has_children {
    my ($self) = @_;

    if( $self->networks ) {
        return 1;
    }
    else { return 0; }
}

=head2 masks_are_logical

If it is a root network or it is meant to be subdivided,
does it have a logical list of valid netmasks?

=cut

sub masks_are_logical {
    my ($self) = @_;
    my $naip = $self->net_addr_ip;
    my ( @over, @under );

    if( !defined $self->parent ) {
        @over  = grep { $_ > $naip->bits } @{$self->valid_masks};
        @under = grep { $_ < $naip->masklen } @{$self->valid_masks};
    }
    elsif( defined $self->parent && $self->subdivide ) {
        @over  = grep { $_ > $naip->bits } @{$self->valid_masks};
        @under = grep { $_ <= $naip->masklen } @{$self->valid_masks};
    }

    if( @over or @under ) {
        return 0;
    }
    else { return 1 }
}

=head2 net_addr_ip

net_addr_ip returns a NetAddr::IP::Lite instance of this network.

=cut

sub net_addr_ip {
    my ($self) = @_;

    return NetAddr::IP::Lite->new($self->address_range);
}

=head2 overlaps

This checks to see of the network overlaps any network with the
same parent.  It returns 1 if it finds an overlapping network,
0 if it doesn't;

=cut

sub overlaps {
    my ($self) = @_;

    if( $self->result_source->resultset->search(
            { address_range => [ {'<<=', $self->address_range},
                                 {'>>',  $self->address_range} ],
              parent        => $self->parent->id
            } )->count ) {

        return 1;
    }
    else { return 0; }
}

=head2 overlaps_any

if the networks overlaps with any other network in the database

=cut

sub overlaps_any {
    my ($self) = @_;

    if( $self->result_source->resultset->search(
            { address_range => [ {'<<=', $self->address_range},
                                 {'>>' , $self->address_range} ]
            } )->count ) {

        return 1;
    }
    else { return 0; }
}

=head2 preceding_addr

Net::Addr::IP of the single IP address preceding this network.
If this is already the first possible network within its parent,
undef is returned.

=cut

sub preceding_addr {
    my ($self) = @_;

    if( ! $self->parent or
        $self->parent->net_addr_ip->addr eq $self->net_addr_ip->addr or
        ! $self->parent->net_addr_ip->contains($self->net_addr_ip) ) {

        return undef; 
    }

    return NetAddr::IP::Lite->new(
               ( NetAddr::IP::Lite->new(
                     $self->net_addr_ip->addr .  '/' .
                     $self->parent->net_addr_ip->mask) - 1
                 )->addr );
};

=head2 smallest_container

smallest_container returns the most logical immediate parent of this
network.

=cut

sub smallest_container {
    my ($self) = @_;
    my $self_netip = NetAddr::IP::Lite->new($self->address_range);
    my $container = $self->result_source->resultset->search(
                    { -and => [
                       address_range => { '>>' => $self->address_range },
                       \['masklen(address_range) < ?', [ value => $self_netip->masklen ]]
                      ]
                    },
                    { '+select' => [{ masklen => 'address_range', -as => 'mask' }],
                       order_by => { -desc => 'mask' }
                    } )->first;

    return $container;
}

1;
