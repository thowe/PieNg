use strict;
use warnings;
use Test::More;


use Catalyst::Test 'PieNg';
use PieNg::Controller::Hosts;

ok( request('/hosts')->is_success, 'Request should succeed' );
done_testing();
