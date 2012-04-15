use strict;
use warnings;
use Test::More;


use Catalyst::Test 'PieNg';
use PieNg::Controller::Networks;

ok( request('/networks')->is_success, 'Request should succeed' );
done_testing();
