package JavaScript::JSLint::V8;

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

    $self->{ctx} = JavaScript::V8::Context->new();
    $self->{ctx}->eval( $jslint_source );

    $self->{errors} = [];
    $self->{ctx}->bind_function( push_error => sub {
        my ( $line, $character, $reason, $evidence ) = @_;
        push( @{$self->{errors}}, {
            line => $line,
            character => $character,
            reason => $reason,
            evidence => $evidence,
        } );
    } );
}

sub lint {
    my ( $self, $js_source, %opt ) = @_;
    
    $self->{errors} = [];
    
    # Convert JS source to a JS string. This means that we have to escape
    # backslashes and double-quotes. We then also need to split it into an
    # array of lines and format it as a JavaScript array string because that's
    # what JSLINT expects to be passed.
    $js_source =~ s/\\/\\\\/g;
    $js_source =~ s/"/\\"/g;
    my @js_lines = split(/\r\n|\r|\n/, $js_source);
    my $js_str = '["' . join('","', @js_lines) . '"]';

    # Need to build an option string in the same vein
    my $opt_str = to_json( \%opt );
    warn( $opt_str );

    # Invoke JSLint. We need to eval and use the push_error function registered
    # earlier to ge tthe errors out as JavaScript::V8 doesn't provide a call()
    # method or similar. Evaling the call to JSLINT and then evaling 
    # JSLint.errors on its own /should/ be good enough, but for some reason it
    # doesn't work.
    my $result = $self->{ctx}->eval( qq/
        (function(){
            if ( JSLINT( $js_str, $opt_str ) ) {
                return true;
            }
            var i;
            for ( i = 0; i < JSLINT.errors.length; i++) {
                push_error( JSLINT.errors[i].line, JSLINT.errors[i].character, JSLINT.errors[i].reason, JSLINT.errors[i].evidence );
            }
            return false;
        })();
    / );

    return @{$self->{errors}};
}

