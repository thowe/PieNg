#!/usr/bin/perl
#
# Launch like so:
# perl -Ilib script/set_admin_password.pl --adminpass thepasswordIwant \
# --dbuser piedbuser --dbpass piedbpass


use strict;
use warnings;
use 5.010;
use Getopt::Long;

use PieDB::Schema;

my $db_driver = 'Pg';
my $db_name   = 'pieng';
my $db_host   = 'localhost';
my $dbuser;
my $dbpass;

my $admin_pass;

GetOptions( 'adminpass=s' => \$admin_pass,
            'dbuser=s'    => \$dbuser,
            'dbpass=s'    => \$dbpass );

if( !defined $admin_pass or !defined $dbuser or !defined $dbpass ) {
    say "Usaage: perl -Ilib script/set_admin_password.pl --dbuser piedbuser \\\n" .
        "        --dbpass piedbpass --adminpass thepasswordIwant";
    exit;
}

my $schema = PieDB::Schema->connect("DBI:$db_driver:dbname=$db_name;host=$db_host",
                                     $dbuser,$dbpass, { quote_names => 1 });

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
    $admin->user_roles->create({ role => $role->id });
}
