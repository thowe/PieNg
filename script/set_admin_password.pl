#!/usr/bin/perl
#
# Launch like so:
# perl -Ilib script/set_admin_password.pl

use strict;
use warnings;
use 5.010;

use PieDB::Schema;

my $db_driver = 'Pg';
my $db_name   = 'pieng';
my $db_host   = 'localhost';
my $db_user   = 'pieng';
my $db_pass   = 'piepass';

# What password do you want?
my $admin_pass = 'mypass';

my $schema = PieDB::Schema->connect("DBI:$db_driver:dbname=$db_name;host=$db_host",
                                     $db_user,$db_pass, { quote_names => 1 });

my $admin = $schema->resultset('User')->find({
                username => 'admin' });

if (defined $admin) {
    $admin->update({ password => $admin_pass });
}
else {
    $admin = $schema->resultset('User')->create({
                username => 'admin',
                password => $admin_pass });
    my $role = $schema->resultset('Role')->find(
                   { name => 'administrator' });
    say $role->name;
    $admin->user_roles->create({ role => $role->id });
}
