package JavaScript::JSLint::SpiderMonkey;

use strict;
use warnings;

use Carp;
use JSON qw(to_json);
use JavaScript::V8;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = {};

    bless( $self, $class );
 
    $self->_init( $_[0] );
    
    return $self;
}

sub _init {
    my ( $self, $jslint_source ) = @_;
    $self->{ctx} = JavaScript::Runtime->new()->create_context();
    $self->{ctx}->eval( $jslint_source );
}

sub lint {
    my ( $self, $js_source, %opt ) = @_;

    my $result = $ctx->call( 'JSLINT', $js_source, \%opt ) );
    
    return $result ? () : @{ $ctx->eval( "JSLINT.errors" ) };
}

1;
