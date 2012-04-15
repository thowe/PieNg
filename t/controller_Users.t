use strict;
use warnings;
use Test::More;


use Catalyst::Test 'PieNg';
use PieNg::Controller::Users;

ok( request('/users')->is_success, 'Request should succeed' );
done_testing();
