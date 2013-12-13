use lib 'lib';
use 5.010;

use Test::More;
use Test::Deep;

use_ok 'Test::Wing::Client';

{
    my $wing = eval { Test::Wing::Client->new(); };
    isa_ok $wing, 'Test::Wing::Client';
    is $wing->uri, 'http://localhost', 'default hostname for making requests';
}

my $wing = Test::Wing::Client->new(
    uri => 'http://myapp.com',
    ip_address => '192.168.0.2',
);

isa_ok $wing, 'Test::Wing::Client';

can_ok $wing, qw/get put post delete/;
can_ok $wing, qw/last_response cookie_jar/;

is $wing->user_agent, 'Test::Wing::Client', 'default user agent string';
$wing->user_agent('Winging it');

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

$result = $wing->delete('object', { Rita => 'Haworth', });

is $result->{method}, 'DELETE', 'DELETE works';
cmp_deeply
    $result->{params},
    {
        Rita => 'Haworth',
    },
    '.... params passed through as well';

can_ok $wing, qw/has_headers add_header/;

$wing->add_header(ORIGIN => 'http://www.otherdomain.com');
ok $wing->has_headers, 'Got at least one header';
$result = $wing->get('headers');
is $result->{'ORIGIN'}, 'http://www.otherdomain.com', 'ORIGIN passed and received';
ok !$wing->has_headers, 'Extra headers have been removed after the request';

done_testing();
