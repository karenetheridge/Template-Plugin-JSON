use 5.006;

package Template::Plugin::JSON;
# ABSTRACT: Adds a .json vmethod for all TT values.

use Moose;

use JSON ();

use Carp qw/croak/;

extends qw(Moose::Object Template::Plugin);

our $VERSION = "0.08";


has context => (
	isa => "Object",
	is  => "ro",
	weak_ref => 1,
);

has json_converter => (
	isa => "Object",
	is  => "ro",
	lazy_build => 1,
);

has json_args => (
	isa => "HashRef",
	is  => "ro",
	default => sub { {} },
);

sub BUILDARGS {
    my ( $class, $c, @args ) = @_;

	my $args;

	if ( @args == 1 and not ref $args[0] ) {
		warn "Single argument form is deprecated, this module always uses JSON/JSON::XS now";
	}

	$args = ref $args[0] ? $args[0] : {};

	return { %$args, context => $c, json_args => $args };
}

sub _build_json_converter {
	my $self = shift;

	my $json = JSON->new->allow_nonref(1);

	my $args = $self->json_args;

	for my $method (keys %$args) {
		if ( $json->can($method) ) {
			$json->$method( $args->{$method} );
		}
	}

	return $json;
}

sub json {
	my ( $self, $value ) = @_;

	$self->json_converter->encode($value);
}

sub json_decode {
	my ( $self, $value ) = @_;

	$self->json_converter->decode($value);
}

sub BUILD {
	my $self = shift;
	$self->context->define_vmethod( $_ => json => sub { $self->json(@_) } ) for qw(hash list scalar);
}

__PACKAGE__;

__END__

=pod

=head1 SYNOPSIS

	[% USE JSON ( pretty => 1 ) %];

	<script type="text/javascript">

		var foo = [% foo.json %];

	</script>

	or read in JSON

	[% USE JSON %]
	[% data = JSON.json_decode(json) %]
	[% data.thing %]

=head1 DESCRIPTION

This plugin provides a C<.json> vmethod to all value types when loaded. You
can also decode a json string back to a data structure.

It will load the L<JSON> module (you probably want L<JSON::XS> installed for
automatic speed ups).

Any options on the USE line are passed through to the JSON object, much like L<JSON/to_json>.

=head1 SEE ALSO

L<JSON>, L<Template::Plugin>

=cut
