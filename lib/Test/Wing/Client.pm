use strict;
use warnings;
package Test::Wing::Client;

use Moo;

extends 'Wing::Client';

use Wing::Perl;
use Dancer::Request;
use URI;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use HTTP::CookieJar::LWP;

=head1 NAME

Test::Wing::Client - A simple test client to Wing's REST services.

=head1 SYNOPSIS

 use Test::Wing::Client;

 my $wing = Test::Wing::Client->new(uri => 'https://www.thegamecrafter.com');

 my $game = $wing->get('game/528F18A2-F2C4-11E1-991D-40A48889CD00');
 
 my $session = $wing->post('session', { username => 'me', password => '123qwe', api_key_id => 'abcdefghijklmnopqrztuz' });

 $game = $wing->put('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id}, name => 'Lacuna Expanse' });

 my $status = $wing->delete('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id} });

=head1 DESCRIPTION

A light-weight wrapper for Wing's (L<https://github.com/plainblack/Wing>) RESTful API (an example of which can be found at: L<https://www.thegamecrafter.com/developer/>) for testing. This wrapper basically hides the request cycle from you so that you can get down to the business of using the API. It doesn't attempt to manage the data structures or objects the web service interfaces with.

This class extends L<Wing::Client> with the addition of a few properties, overriding the guts of the module that actually makes calls over HTTP, and outright ignoring the persistent L<HTTP::Thin> user agent.

=head1 METHODS

The following methods are available.

=head2 new ( params ) 

Constructor.

=over

=item params

A hash of parameters.

=over

=item ip_address

The IP address used to build the request.

=item user_agent

A User Agent string for the request.

=back

=back

=cut

has ip_address => (
    is          => 'rw',
    required    => 1,
);

has user_agent => (
    is          => 'rw',
    required    => 1,
);

=head2 cookie_jar

This holds a HTTP::CookieJar::LWP object for persistent cookies between requests.

=cut

has cookie_jar => (
    is          => 'ro',
    required    => 0,
    lazy        => 1,
    builder     => '_build_cookie_jar',
);

sub _build_cookie_jar {
    return HTTP::CookieJar::LWP->new();
}

=head2 last_response

The HTTP::Response object from the last request/response cycle that was made.

=cut

has last_response => (
    is       => 'rw',
    required => 0,
);

around _create_uri => sub {
    my $orig = shift;
    my $self = shift;
    my $uri = $self->$orig(@_);
    $uri->scheme('http') unless defined $uri->scheme;
    return $uri;
};

sub _process_request {
    my $self = shift;
    my $request = shift;
    $request->header('User-Agent' => $self->user_agent);
    $self->last_response('');
    $self->cookie_jar->add_cookie_header($request);
    my $env = $request->to_psgi;
    $DB::single=1;
    if ($env->{REQUEST_METHOD} eq 'POST' and exists $env->{'HTTP_X_HTTP_METHOD'}) {
        $env->{REQUEST_METHOD} = $env->{'HTTP_X_HTTP_METHOD'};
    }
    my $dancer_request = Dancer::Request->new( env => $env);
    my $dancer_response = Dancer->dance( $dancer_request );
    my $response = HTTP::Response->from_psgi( $dancer_response );
    $response->request($request);
    $self->cookie_jar->extract_cookies($response);
    $self->last_response($response);
    return $self->_process_response($response);
}

=head1 SUPPORT

=over

=item Repository

L<http://github.com/perldreamer/Test-Wing-Client>

=item Bug Reports

L<http://github.com/perldreamer/Test-Wing-Client/issues>

=back

=head1 AUTHOR

Colin Kuskie <colink_at_plainblack_dot_com>

=head1 LEGAL

This module is Copyright 2013 Plain Black Corporation. It is distributed under the same terms as Perl itself. 

=cut

1;
