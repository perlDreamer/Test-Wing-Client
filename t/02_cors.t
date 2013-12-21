use lib 'lib';
use 5.010;

use Test::More;
use Test::Deep;
use lib 't/lib';

use_ok 'Test::Wing::Client';
use_ok 'DumbDancerBasedApp';

my $wing = Test::Wing::Client->new(
    uri => 'http://myapp.com',
    ip_address => '192.168.0.2',
);

can_ok $wing, qw/options/;

my $result;

$result = $wing->options('/api');
is $result->{Host}, 'myapp.com', 'Received host header';

$result = $wing->options('/api', [
    'Access-Control-Request-Method' => 'POST',
    'Origin' => 'http://www.example.com',
]);
is $result->{ORIGIN}, 'http://www.example.com', 'cycled Origin header';
is $result->{'ACCESS-CONTROL-REQUEST-METHOD'}, 'POST', 'cycled Request-Method header';

done_testing();
