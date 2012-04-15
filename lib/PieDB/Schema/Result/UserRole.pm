package PieDB::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 NAME

PieDB::Schema::Result::UserRole

=cut

__PACKAGE__->table("user_roles");

=head1 ACCESSORS

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("user", "role");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<PieDB::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "PieDB::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 role

Type: belongs_to

Related object: L<PieDB::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "PieDB::Schema::Result::Role",
  { id => "role" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-06-30 23:41:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4LcpdzGIoFfXkttp4jekaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
