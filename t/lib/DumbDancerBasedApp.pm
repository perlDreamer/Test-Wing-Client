package DumbDancerBasedApp;

use Dancer;
set serializer => 'JSON';

options '**' => sub {
    my %headers = map { $_ => request->headers->header($_) } request->headers->header_field_names;
    {
        result => \%headers,
    };
};

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

get '/api/headers' => sub {
    my %headers = map { $_ => request->headers->header($_) } request->headers->header_field_names;
    {
        result => \%headers,
    };
};

get '/api/object' => sub {
    {
        result => {
            method => 'GET',
            uri    => 'api-object',
            'params' => { params(), },
        },
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
