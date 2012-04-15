package PieDB::Schema::Result::Host;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 NAME

PieDB::Schema::Result::Host

=cut

__PACKAGE__->table("hosts");

=head1 ACCESSORS

=head2 address

  data_type: 'inet'
  is_nullable: 0

=head2 network

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "address",
  { data_type => "inet", is_nullable => 0 },
  "network",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("address");

=head1 RELATIONS

=head2 network

Type: belongs_to

Related object: L<PieDB::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "PieDB::Schema::Result::Network",
  { id => "network" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-30 23:41:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e6QaEm7TDKI4dHkqpU6CEg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
