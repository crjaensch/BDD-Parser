use v6.d;
use Grammar::Tracer;

grammar GherkinParser {
    # Utility tokens for whitespace handling
    token ws { \h* }  # Horizontal whitespace only
    token eol { \n \h* }  # End of line with optional whitespace
    token blank-line { \h* \n }  # Empty line

    # Main structure
    rule TOP { 
        <.blank-line>*
        <feature>
        \s*  # Allow any whitespace at end of file
    }
    
    rule feature {
        'Feature:' <feature-name> <.eol>
        <.blank-line>*
        <scenario>+
    }

    token feature-name {
        \N+
    }

    rule scenario {
        <.blank-line>*
        'Scenario:' <scenario-name> <.eol>
        <.blank-line>*
        <step>+
        \n*  # Allow trailing newlines after steps
    }

    token scenario-name {
        \N+
    }

    rule step {
        <step-keyword> <step-text> <.eol>
    }

    token step-keyword {
        'Given' | 'When' | 'Then' | 'And' | 'But'
    }

    token step-text {
        \N+
    }
}

class GherkinActions {
    has %.elements;  # Store all parsed elements
    has $.current-feature-id;
    has $.current-scenario-id;
    has $.step-counter = 0;
    
    submethod BUILD() {
        %!elements = (
            features => {},    # Indexed by feature-id
            scenarios => {},   # Indexed by scenario-id
            steps => {},      # Indexed by step-id
        );
    }
    
    method generate-id(Str $prefix) {
        state %counters;
        %counters{$prefix}++;
        return "{$prefix}-{%counters{$prefix}}";
    }

    method TOP($/) {
        # Return both the traditional structure and our indexed hash
        make {
            tree => $<feature>.made,
            elements => %!elements,
        }
    }
    
    method feature($/) {
        my $feature-id = self.generate-id('feature');
        $!current-feature-id = $feature-id;
        
        # First collect scenario results
        my @scenario-results = $<scenario>.map(*.made);
        my @scenario-ids = @scenario-results.map(*<id>);
        
        my $feature = {
            id => $feature-id,
            name => $<feature-name>.trim.Str,
            scenarios => @scenario-ids,
        };
        
        # Store in our elements hash
        %!elements<features>{$feature-id} = $feature;
        
        # Return both ID and traditional structure
        make {
            id => $feature-id,
            name => $feature<name>,
            scenarios => @scenario-results.map(*<tree>),
        }
    }

    method scenario($/) {
        my $scenario-id = self.generate-id('scenario');
        $!current-scenario-id = $scenario-id;
        
        # First collect step results
        my @step-results = $<step>.map(*.made);
        my @step-ids = @step-results.map(*<id>);
        
        my $scenario = {
            id => $scenario-id,
            feature-id => $!current-feature-id,
            name => $<scenario-name>.trim.Str,
            steps => @step-ids,
        };
        
        # Store in our elements hash
        %!elements<scenarios>{$scenario-id} = $scenario;
        
        # Return both ID and traditional structure
        make {
            id => $scenario-id,
            tree => {
                name => $scenario<name>,
                steps => @step-results.map(*<tree>),
            }
        }
    }

    method step($/) {
        my $step-id = self.generate-id('step');
        $!step-counter++;
        
        my $step = {
            id => $step-id,
            scenario-id => $!current-scenario-id,
            keyword => ~$<step-keyword>,
            text => $<step-text>.trim.Str,
            order => $!step-counter,
        };
        
        # Store in our elements hash
        %!elements<steps>{$step-id} = $step;
        
        # Return both ID and traditional structure
        make {
            id => $step-id,
            tree => {
                keyword => $step<keyword>,
                text => $step<text>,
            }
        }
    }
}

sub MAIN(
    Str $filename = './scenario1.feature',
    Bool :$debug = True
) {
    my $content = slurp $filename;
    say "Content:\n$content" if $debug;
    
    my $actions = GherkinActions.new;
    my $match = GherkinParser.parse($content, :$actions);
    
    if $match {
        say "Parsing successful!";
        say "\nTree structure:";
        say $match.made<tree>.raku;
        say "\nIndexed elements:";
        say $match.made<elements>.raku;
    } else {
        say "Parsing failed";
        say "Debug trace:";
        GherkinParser.parse($content, :$actions, :debug);
    }
}