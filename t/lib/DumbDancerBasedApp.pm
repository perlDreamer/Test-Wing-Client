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
    my $environ = request->env;
    {
        result => $environ,
    };
};

post '/api/object' => sub {
    {
        result => {
            method => 'POST',
            uri    => 'api-object',
            'params' => { params(), },
        },
    };
};

put '/api/object' => sub {
    {
        result => {
            method => 'PUT',
            uri    => 'api-object',
            'params' => { params(), },
        },
    };
};

del '/api/object' => sub {
    {
        result => {
            method => 'DELETE',
            uri    => 'api-object',
            'params' => { params(), },
        },
    };
};

1;
