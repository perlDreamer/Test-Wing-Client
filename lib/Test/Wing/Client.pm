use strict;
use warnings;
package Test::Wing::Client;

use Moo;

extends 'Wing::Client';

use Dancer ();
use Dancer::Request;
use URI;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use HTTP::CookieJar::LWP;

=head1 NAME

Test::Wing::Client - A simple test client to Wing's REST services.

=head1 SYNOPSIS

 use Test::Wing::Client;
 use My::Wing::App;

 my $wing = Test::Wing::Client->new(uri => 'https://www.thegamecrafter.com');

 my $game = $wing->get('game/528F18A2-F2C4-11E1-991D-40A48889CD00');
 
 my $session = $wing->post('session', { username => 'me', password => '123qwe', api_key_id => 'abcdefghijklmnopqrztuz' });

 $game = $wing->put('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id}, name => 'Lacuna Expanse' });

 my $status = $wing->delete('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id} });

=head1 DESCRIPTION

A light-weight wrapper for Wing's (L<https://github.com/plainblack/Wing>) RESTful API (an example of which can be found at: L<https://www.thegamecrafter.com/developer/>) for testing. It basically hides the request cycle from you so that you can get down to the business of testing the API. It doesn't attempt to manage the data structures or objects the web service interfaces with.

This class extends L<Wing::Client> with the following changes:

=over

=item *

Added the ip_address, user_agent and session_id properties

=item *

The uri property is optional, and defaults to 'http://localhost'.  Since an HTTP request isn't really being made, setting the uri (HTTP_HOST) is really only needed for tenant sites in Wing and a few other minor purposes.

=item *

Overriding the guts of the module that actually makes calls over HTTP, and outright ignoring the persistent L<HTTP::Thin> user agent.

=item *

Cookies that are passed back in responses are stored locally and automatically put into outgoing requests.

=back

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

=item session_id

A Wing session_id.  If set, this is automatically added to all requests because I'm lazy.  If you don't
want a session_id for a while, set the C<no_session_id> flag on the object.

=item no_session_id

If set to true, prevents adding the session_id to the request.

=back

=item extra_headers

An array ref of extra HTTP headers.  These headers are cleared out immediately
after the request is made.

=item add_header

Push a list of headers on the C<extra_headers> array.

=item has_headers

Returns true if there are headers to add.  Should almost always be true since we add
a User-Agent headers to the request by default.

=item clear_headers

Clear all internal headers.  You should not need to call this.

=back

=cut

has '+uri' => (
    required => 0,
    default  => sub { 'http://localhost' },
);

has [qw/ip_address session_id no_session_id/] => (
    is          => 'rw',
    required    => 0,
);

has user_agent => (
    is          => 'rw',
    required    => 0,
    default     => sub { "Test::Wing::Client" },
);

has extra_headers => (
    is          => 'rw',
    required    => 0,
    default     => sub { [] },
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

sub _add_session_id {
    my $orig   = shift;
    my $self   = shift;
    my $uri    = shift;
    my $params = shift || {};
    if ($self->session_id && ! $self->no_session_id && ! exists $params->{session_id}) {
        $params->{session_id} = $self->session_id;
    }
    return $self->$orig($uri, $params, @_);
}

around get => \&_add_session_id;
around post => \&_add_session_id;
around put => \&_add_session_id;
around delete => \&_add_session_id;

sub add_header {
    my $self = shift;
    push @{ $self->extra_headers }, @_
}

sub has_headers {
    return scalar @{ $_[0]->extra_headers };
}

sub _add_headers_to_request {
    my ($self, $request) = @_;
    ##Okay, we add a header but we check anyway since I may change this later
    return unless $self->has_headers;
    $request->header(@{ $self->extra_headers });
}

sub clear_headers {
    my $self = shift;
    $self->extra_headers([]);
}

sub _process_request {
    my $self = shift;
    my $request = shift;
    $self->last_response('');
    $self->add_header('User-Agent' => $self->user_agent);
    $self->_add_headers_to_request($request);
    $self->cookie_jar->add_cookie_header($request);
    my $env = $request->to_psgi;
    if ($self->ip_address) {
        $env->{REMOTE_ADDR} = $self->ip_address;
    }
    if ($env->{REQUEST_METHOD} eq 'POST' and exists $env->{'HTTP_X_HTTP_METHOD'}) {
        $env->{REQUEST_METHOD} = $env->{'HTTP_X_HTTP_METHOD'};
    }
    my $dancer_request = Dancer::Request->new( env => $env);
    Dancer::set logger => 'console';
    Dancer::set log => 'debug';
    my $dancer_response = Dancer->dance( $dancer_request );
    my $response = HTTP::Response->from_psgi( $dancer_response );
    $response->request($request);
    $self->cookie_jar->extract_cookies($response);
    $self->last_response($response);
    $self->clear_headers;
    return $self->_process_response($response);
}

=head2 options(path, headers)

Performs an C<OPTIONs> request, which is used for CrossOrigin verification

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item headers

An array reference of headers to send with the request.

=back

=cut

sub options {
    my ($self, $path, $headers) = @_;
    $headers //= [];
    my $uri = $self->_create_uri($path);
    my $request = HTTP::Request->new('OPTIONS', $uri->as_string, $headers);
    return $self->_process_request( $request );
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
