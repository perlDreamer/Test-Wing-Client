package DumbDancerBasedApp;

use Dancer;
set serializer => 'JSON';

get '/' => sub {
    {
        result => {
            method => 'GET',
            uri    => 'slash',
        },
    }
};

get '/api' => sub {
    {
        result => {
            method => 'GET',
            uri    => 'slash-api',
        },
    }
};

get '/api/got' => sub {
    {
        result => {
            method => 'GET',
            uri    => 'slash-api-got',
        },
    }
};

1;
