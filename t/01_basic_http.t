use lib 'lib';
use 5.010;

use Test::More;
use Test::Deep;

use_ok 'Test::Wing::Client';

my $wing = Test::Wing::Client->new(
    uri => 'http://myapp.com',
    ip_address => '192.168.0.1',
    user_agent => 'Winging it',
);

isa_ok $wing, 'Test::Wing::Client';

can_ok $wing, qw/get put post delete/;

use lib 't/lib';
use_ok 'DumbDancerBasedApp';

my $result;

$result = $wing->get('/api');
is $result->{method}, 'GET', 'used GET';
is $result->{uri}, 'slash-api', 'api prefix added to URI';

done_testing();
