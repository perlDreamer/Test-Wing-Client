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
is $result->{REMOTE_ADDR}, '192.168.0.2', 'User Agent passed through to request';

done_testing();
