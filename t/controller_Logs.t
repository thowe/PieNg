use strict;
use warnings;
use Test::More;


use Catalyst::Test 'PieNg';
use PieNg::Controller::Logs;

ok( request('/logs')->is_success, 'Request should succeed' );
done_testing();
