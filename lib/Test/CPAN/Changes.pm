package Test::CPAN::Changes;

use strict;
use warnings;

use CPAN::Changes;
use Test::Builder;

my $Test       = Test::Builder->new;
my $version_re = '^[._\-[:alnum:]]+$';    # "Looks like" a version

sub import {
    my $self = shift;

    my $caller = caller;
    no strict 'refs';
    *{ $caller . '::changes_ok' }      = \&changes_ok;
    *{ $caller . '::changes_file_ok' } = \&changes_file_ok;

    $Test->exported_to( $caller );
    $Test->plan( @_ );
}

sub changes_ok {
    $Test->plan( tests => 4 );
    return changes_file_ok( undef, @_ );
}

sub changes_file_ok {
    my ( $file, $arg ) = @_;
    $file ||= 'Changes';
    $arg ||= {};

    my $changes = eval { CPAN::Changes->load( $file ) };

    if ( $@ ) {
        $Test->ok( 0, "Unable to parse $file" );
        $Test->diag( "  ERR: $@" );
        return;
    }

    $Test->ok( 1, "$file is loadable" );

    my @releases = $changes->releases;

    if ( !@releases ) {
        $Test->ok( 0, "$file does not contain any releases" );
        return;
    }

    $Test->ok( 1, "$file contains at least one release" );

    for ( @releases ) {
        if ( $_->date !~ m[^${CPAN::Changes::W3CDTF_REGEX}\s*$] ) {
            $Test->ok( 0, "$file contains an invalid release date" );
            $Test->diag( '  ERR: ' . $_->date );
            return;
        }
        if ( $_->version !~ m{$version_re} ) {
            $Test->ok( 0, "$file contains an invalid version number" );
            $Test->diag( '  ERR: ' . $_->version );
            return;
        }
    }

    $Test->ok( 1, "$file contains valid release dates" );
    $Test->ok( 1, "$file contains valid version numbers" );

    if ( defined $arg->{version} ) {
        my $v = $arg->{version};

        if ( my $release = $changes->release( $v ) ) {
            $Test->ok( 1, "$file has an entry for the current version, $v" );
            my $changes = $release->changes;

            if ( $changes and grep { @$_ > 0 } values %$changes ) {
              $Test->ok( 1, "entry for the current version, $v, has content" );
            } else {
              $Test->ok( 0, "entry for the current version, $v, no content" );
            }
        } else {
            # Twice so that we have a fixed number of tests to plan.
            # -- rjbs, 2011-05-02
            $Test->ok( 0, "$file has no entry for the current version, $v" );
            $Test->ok( 0, "$file has no entry for the current version, $v" );
        }
    }

    return $changes;
}

1;

__END__

=head1 NAME

Test::CPAN::Changes - Validation of the Changes file in a CPAN distribution

=head1 SYNOPSIS

    use Test::More;
    eval 'use Test::CPAN::Changes';
    plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
    changes_ok();

=head1 DESCRIPTION

This module allows CPAN authors to write automated tests to ensure their 
changelogs match the specification.

=head1 METHODS

=head2 changes_ok( )

Simple wrapper around C<changes_file_ok>. Declares a four test plan, and 
uses the default filename of C<Changes>.

=head2 changes_file_ok( $filename, \%arg )

Checks the contents of the changes file against the specification. No plan 
is declared and if ithe filename is undefined, C<Changes> is used.

C<%arg> may include a I<version> entry, in which case the entry for that
version must exist and have content.  This is useful to ensure that the version
currently being released has documented changes.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Spec>

=item * L<CPAN::Changes>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
