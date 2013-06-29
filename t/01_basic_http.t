use lib 'lib';
use 5.010;

use Test::More;
use Test::Deep;

use_ok 'Test::Wing::Client';

my $wing = Test::Wing::Client->new(
    uri => 'http://myapp.com',
    ip_address => '192.168.0.2',
);

is $wing->user_agent, 'Test::Wing::Client', 'default user agent string';
$wing->user_agent('Winging it');

isa_ok $wing, 'Test::Wing::Client';

can_ok $wing, qw/get put post delete/;
can_ok $wing, qw/last_response cookie_jar/;

use lib 't/lib';
use_ok 'DumbDancerBasedApp';

my $result;

$result = $wing->get('/api');
is $result->{method}, 'GET', 'used GET';
is $result->{uri}, 'slash-api', 'manual fetch of /api URL';

$result = $wing->get('env');

is $result->{HTTP_USER_AGENT}, 'Winging it', 'User Agent passed through to request';
is $result->{REMOTE_ADDR}, '192.168.0.2', 'remote IP address set';

$result = $wing->post('object', { andy => 'dufresne', red => 'redding'});

is $result->{method}, 'POST', 'POST works';
cmp_deeply
    $result->{params},
    {
        andy => 'dufresne',
        red  => 'redding',
    },
    '.... params passed through as well';

$result = $wing->put('object', { Brooks => 'Hatlen', jake => 'the crow'});

is $result->{method}, 'PUT', 'PUT works';
cmp_deeply
    $result->{params},
    {
        Brooks => 'Hatlen',
        jake   => 'the crow',
    },
    '.... params passed through as well';

done_testing();
