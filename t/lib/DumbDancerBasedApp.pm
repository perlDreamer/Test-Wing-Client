package DumbDancerBasedApp;

use Dancer;
set serializer => 'JSON';

get '/api' => sub {
    {
        result => {
            method => 'GET',
            uri    => 'slash-api',
        },
    };
};

get '/api/env' => sub {
    my %environ = map { $_ => request->env->{$_} }
        qw/SERVER_NAME PATH_INFO HTTP_USER_AGENT HTTP_COOKIE REMOTE_ADDR REQUEST_URI HTTP_HOST/;
    {
        result => \%environ,
    };
};

1;
