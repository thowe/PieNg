#!/usr/bin/perl
#
# Launch like so:
# perl -Ilib script/set_admin_password.pl --user admin --pass MyPass

use strict;
use warnings;
use 5.010;
use Getopt::Long;
use Config::Any;

use PieDB::Schema;

my ($admin_pass, $admin_user);

GetOptions( 'pass=s' => \$admin_pass,
            'user=s' => \$admin_user, );

if( !defined $admin_pass or !defined $admin_user ) {
    say "Usaage: perl -Ilib script/set_admin_password.pl --user admin --pass MyPass" .
    exit;
}

my $cfg = Config::Any->load_files( { files => [ 'pieng.conf' ],
                                     use_ext => 1 } );
my $conn = $cfg->[0]->{'pieng.conf'}->{
                         'Model::PieDB'}->{
                           'connect_info'};

my $schema = PieDB::Schema->connect(  $conn->{'dsn'},
                                      $conn->{'user'},
                                      $conn->{'password'},
                                      { 'AutoCommit' => $conn->{'AutoCommit'},
                                      'quote_names' => $conn->{'quote_names'} } );

my $admin = $schema->resultset('User')->find({
                username => $admin_user });

if (defined $admin) {
    $admin->update({ password => $admin_pass });
}
else {
    $admin = $schema->resultset('User')->create({
                username => $admin_user,
                password => $admin_pass });
    my $role = $schema->resultset('Role')->find(
                   { name => 'administrator' });
    $admin->user_roles->create({ role => $role->id });
}
