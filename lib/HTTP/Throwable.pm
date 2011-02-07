package HTTP::Throwable;
use Moose;

with 'Throwable';

has 'status_code' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'reason' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'message' => ( is => 'ro', isa => 'Str' );

sub content_type { 'text/plain' }

sub build_headers {
    my ($self, $body) = @_;
    [
        'Content-Type'   => $self->content_type,
        'Content-Length' => length $body,
    ]
}

sub as_string {
    my $self = shift;
    my $out  = $self->status_code . " " . $self->reason;
    $out .= " " . $self->message if $self->message;
    $out;
}

sub as_psgi {
    my $self    = shift;
    my $body    = $self->as_string;
    my $headers = $self->build_headers( $body );
    [ $self->status_code, $headers, [ $body ] ];
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

# ABSTRACT: A set of HTTP 1.1 exception objects

=head1 SYNOPSIS

  use HTTP::Throwable;

  # you can use this directly, but ...
  HTTP::Throwable->throw(
      status_code => 500,
      reason      => 'Internal Server Error',
      message     => 'Something has gone very wrong!'
  );

  # ... it is more useful for subclassing
  package InternalServerError;
  use Moose;

  extends 'HTTP::Throwable';
     with 'StackTrace::Auto'; # it is 500 so include the stack trace

  has '+status_code' => ( default => 500 );
  has '+reason'      => ( default => 'Internal Server Error' );

  around 'as_string' => sub {
      my $next = shift;
      my $self = shift;
      $self->$next() . "\n\n" . $self->stack_trace->as_string;
  };

  # and better yet, just use the provided subclasses
  HTTP::Throwable::InternalServerError->throw(
      message => 'Something has gone very wrong!'
  );

=head1 DESCRIPTION

This is the base object for all the HTTP::Throwable subclasses.
While you can easily use this object in your code, you likely want
to use the appropriate subclass for the given error as they will
provide the status-code, reason and enforce any required headers.

NOTE: We have also included some of the documentation from the
HTTP 1.1 spec where appropriate.

=head2 Stack Traces

It should be noted that even though these are all exception objects,
only the 500 Internal Server Error subclass actually includes the
stack trace. This is because more often then not you will not
actually care about the stack trace and therefore do not the extra
overhead. If you do find you want a stack trace though, it is as
simple as subclassing and applying the L<StackTrace::Auto> role.

=head1 ATTRIBUTES

=attr status_code

This is the status code integer as specified in the HTTP spec.

=attr resason

This is the reason phrase as specified in the HTTP spec.

=attr message

This is an additional message string that can be supplied

=head1 METHODS

=method as_string

This returns a string representation of the exception made up
of the status code, the reason and the message.

=method as_psgi

This returns a representation of the exception object as PSGI
response. It will build the content-type and content-length
headers and include the result of C<as_string> in the body.

=head1 SUBCLASSES

Below is a list of the subclasses you will find available in
this distribution. The obvious 4xx and 5xx errors are included
but we also include the 3xx redirection status codes. This is
because, while not really an error, the 3xx status codes do
represent an exceptional control flow.

=head2 Redirection 3xx

This class of status code indicates that further action needs to
be taken by the user agent in order to fulfill the request. The
action required MAY be carried out by the user agent without
interaction with the user if and only if the method used in the
second request is GET or HEAD.

=over 4

=item 300 L<HTTP::Throwable::MultipleChoices>

=item 301 L<HTTP::Throwable::MovedPermanently>

=item 302 L<HTTP::Throwable::Found>

=item 303 L<HTTP::Throwable::SeeOther>

=item 304 L<HTTP::Throwable::NotModified>

=item 305 L<HTTP::Throwable::UseProxy>

=item 307 L<HTTP::Throwable::TemporaryRedirect>

=back

=head2 Client Error 4xx

The 4xx class of status code is intended for cases in which
the client seems to have erred. Except when responding to a
HEAD request, the server SHOULD include an entity containing an
explanation of the error situation, and whether it is a temporary
or permanent condition. These status codes are applicable to any
request method. User agents SHOULD display any included entity
to the user.

=over 4

=item 400 L<HTTP::Throwable::BadRequest>

=item 401 L<HTTP::Throwable::Unauthorized>

=item 403 L<HTTP::Throwable::Forbidden>

=item 404 L<HTTP::Throwable::NotFound>

=item 405 L<HTTP::Throwable::MethodNotAllowed>

=item 406 L<HTTP::Throwable::NotAcceptable>

=item 407 L<HTTP::Throwable::ProxyAuthenticationRequired>

=item 408 L<HTTP::Throwable::RequestTimeout>

=item 409 L<HTTP::Throwable::Conflict>

=item 410 L<HTTP::Throwable::Gone>

=item 411 L<HTTP::Throwable::LengthRequired>

=item 412 L<HTTP::Throwable::PreconditionFailed>

=item 413 L<HTTP::Throwable::RequestEntityToLarge>

=item 414 L<HTTP::Throwable::RequestURITooLong>

=item 415 L<HTTP::Throwable::UnsupportedMediaType>

=item 416 L<HTTP::Throwable::RequestedRangeNotSatisfiable>

=item 417 L<HTTP::Throwable::ExpectationFailed>

=back

=head2 Server Error 5xx

Response status codes beginning with the digit "5" indicate
cases in which the server is aware that it has erred or is
incapable of performing the request. Except when responding to
a HEAD request, the server SHOULD include an entity containing
an explanation of the error situation, and whether it is a
temporary or permanent condition. User agents SHOULD display
any included entity to the user. These response codes are applicable
to any request method.

=over 4

=item 500 L<HTTP::Throwable::InternalServerError>

=item 501 L<HTTP::Throwable::NotImplemented>

=item 502 L<HTTP::Throwable::BadGateway>

=item 503 L<HTTP::Throwable::ServiceUnavailable>

=item 504 L<HTTP::Throwable::GatewayTimeout>

=item 505 L<HTTP::Throwable::HTTPVersionNotSupported>

=back

=head1 SEE ALSO

L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html>





