package Test::Output;

use warnings;
use strict;

use Test::Builder;
use Test::Output::Tie;
require Exporter;

our @ISA=qw(Exporter);
our @EXPORT=qw(output_is output_isnt output_like output_unlike
               stderr_is stderr_isnt stderr_like stderr_unlike
               stdout_is stdout_isnt stdout_like stdout_unlike
             );

our @EXPORT_OK=qw(output_from stderr_from stdout_from);

my $Test = Test::Builder->new;

=head1 NAME

Test::Output - Utilities to test STDOUT and STDERR messages.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Test::More tests => 4;
    use Test::Output;

    sub writer {
      print "Write out.\n";
      print STDERR "Error out.\n";
    }

    stdout_is(\&writer,"Write out.\n",'Test STDOUT');

    stderr_isnt(\&writer,"No error out.\n",'Test STDERR');

    output_is(
              \&writer,
              "Write out.\n",
              "Error out.\n",
              'Test STDOUT & STDERR'
            );

    # Use bare blocks.

   stdout_is { print "test" } "test" "Test STDOUT";
   stderr_isnt { print "bad test" } "test" "Test STDERR";
   output_is { print 'STDOUT'; print STDERR 'STDERR' }
     "STDOUT", "STDERR", "Test output";

=head1 DESCRIPTION

Test::Output provides a simple interface for testing output sent to STDOUT
or STDERR. A number of different utilies are included to try and be as
flexible as possible to the tester.

While Test::Output requires Test::Tester during installation, this
requirement is only for its own tests, not for what it's testing. One of
the main ideas behind Test::Output is to make it as self contained as
possible so it can be included with other's modules. As of this release
the only requirement is to include Test::Output::Tie along with it.

Test::Output ties STDOUT and STDERR using Test::Output::Tie.

All functions are exported.

=cut

=head1 TESTS

=head2 STDOUT

=over 4

=item B<stdout_is>

=item B<stdout_isnt>

   stdout_is  ( $coderef, $expected, 'description' );
   stdout_is    { ... } $expected, 'description';
   stdout_isnt( $coderef, $expected, 'description' );
   stdout_isnt  { ... } $expected, 'description';

stdout_is() captures output sent to STDOUT from $coderef and compares
it against $expected. The test passes if equal.

stdout_isnt() passes if STDOUT is not equal to $expected.

=cut

sub stdout_is (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my $stdout=stdout_from($test);

  my $ok=($stdout eq $expected);

  $Test->ok( $ok, $description ) ||
   $Test->diag( "STDOUT is:\n$stdout\nnot:\n$expected\nas expected" );

  return $ok;
}

sub stdout_isnt (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my $stdout=stdout_from($test);

  my $ok=($stdout ne $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDOUT:\n$stdout\nmatching:\n$expected\nnot expected" );

  return $ok;
}

=item B<stdout_like>

=item B<stdout_unlike>

   stdout_like  ( $coderef, qr/$expected/, 'description' );
   stdout_like    { ... } qr/$expected/, 'description';
   stdout_unlike( $coderef, qr/$expected/, 'description' );
   stdout_unlike  { ... } qr/$expected/, 'description';

stdout_like() captures the output sent to STDOUT from $coderef and compares
it to the regex in $expected. The test passes if the regex matches.

stdout_unlike() passes if STDOUT does not match the regex.

=back

=cut

sub stdout_like (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  unless(my $regextest=_chkregex('stdout_like' => $expected)) {
    return $regextest;
  }

  my $stdout=stdout_from($test);

  my $ok=($stdout =~ $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDOUT:\n$stdout\ndoesn't match:\n$expected\nas expected" );

  return $ok;
}

sub stdout_unlike (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  unless(my $regextest=_chkregex('stdout_unlike' => $expected)) {
    return $regextest;
  }

  my $stdout=stdout_from($test);

  my $ok=($stdout !~ $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDOUT:\n$stdout\nmatches:\n$expected\nnot expected" );


  return $ok;
}

=head2 STDERR

=over 4

=item B<stderr_is>

=item B<stderr_isnt>

   stderr_is  ( $coderef, $expected, 'description' );
   stderr_is    {... } $expected, 'description';
   stderr_isnt( $coderef, $expected, 'description' );
   stderr_isnt  {... } $expected, 'description';

stderr_is() is similar to stdout_is, except that it captures STDERR. The
test passes if STDERR from $coderef equals $expected.

stderr_isnt() passes if STDERR is not equal to $expected.

=cut

sub stderr_is (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my $stderr=stderr_from($test);

  my $ok=($stderr eq $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDERR is:\n$stderr\nnot:\n$expected\nas expected" );

  return $ok;
}

sub stderr_isnt (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my $stderr=stderr_from($test);

  my $ok=($stderr ne $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDERR:\n$stderr\nmatches:\n$expected\nnot expected" );

  return $ok;
}

=item B<stderr_like>

=item B<stderr_unlike>

   stderr_like  ( $coderef, qr/$expected/, 'description' );
   stderr_like   { ...} qr/$expected/, 'description';
   stderr_unlike( $coderef, qr/$expected/, 'description' );
   stderr_unlike  { ...} qr/$expected/, 'description';

stderr_like() is similar to stdout_like() except that it compares the regex
$expected to STDERR captured from $codref. The test passes if the regex
matches.

stderr_unlike() passes if STDERR does not match the regex.

=back

=cut

sub stderr_like (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  unless(my $regextest=_chkregex('stderr_like' => $expected)) {
    return $regextest;
  }

  my $stderr=stderr_from($test);

  my $ok=($stderr =~ $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDERR:\n$stderr\ndoesn't match:\n$expected\nas expected" );

  return $ok;
}

sub stderr_unlike (&$;$$) {
  my $test=shift;
  my $expected=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  unless(my $regextest=_chkregex('stderr_unlike' => $expected)) {
    return $regextest;
  }

  my $stderr=stderr_from($test);

  my $ok=($stderr !~ $expected);

  $Test->ok( $ok, $description ) ||
    $Test->diag( "STDERR:\n$stderr\nmatches:\n$expected\nnot expected" );

  return $ok;
}

=head2 OUTPUT

=over 4

=item B<output_is>

=item B<output_isnt>

   output_is  ( $coderef, $expected_stdout, $expected_stderr, 'description' );
   output_is    {... } $expected_stdout, $expected_stderr, 'description';
   output_isnt( $coderef, $expected_stdout, $expected_stderr, 'description' );
   output_isnt  {... } $expected_stdout, $expected_stderr, 'description';

The output_is() function is a combination of the stdout_is() and stderr_is()
functions. For example:

  output_is(sub {print "foo"; print STDERR "bar";},'foo','bar');

is functionally equivalent to

  stdout_is(sub {print "foo";},'foo') 
    && stderr_is(sub {print STDERR "bar";'bar');

except that $coderef is only executed once.

Unlike, stdout_is() and stderr_is() which ignore STDERR and STDOUT
repectively, output_is() requires both STDOUT and STDERR to match in order
to pass. Setting either $expected_stdout or $expected_stderr to C<undef>
ignores STDOUT or STDERR respectively.

  output_is(sub {print "foo"; print STDERR "bar";},'foo',undef);

is the same as

  stdout_is(sub {print "foo";},'foo') 

output_isnt() provides the opposite function of output_is(). It is a 
combination of stdout_isnt() and stderr_isnt().

  output_isnt(sub {print "foo"; print STDERR "bar";},'bar','foo');

is functionally equivalent to

  stdout_is(sub {print "foo";},'bar') 
    && stderr_is(sub {print STDERR "bar";'foo');

As with output_is(), setting either $expected_stdout or $expected_stderr to
C<undef> ignores the output to that facility.

  output_isnt(sub {print "foo"; print STDERR "bar";},undef,'foo');

is the same as

  stderr_is(sub {print STDERR "bar";},'foo') 

=cut

sub output_is (&$$;$$) {
  my $test=shift;
  my $expout=shift;
  my $experr=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my($stdout,$stderr)=output_from($test);

  my $ok=1;
  my $diag;

  if(defined($experr) && defined($expout)) {
    unless($stdout eq $expout) {
      $ok=0;
      $diag.="STDOUT is:\n$stdout\nnot:\n$expout\nas expected";
    }
    unless($stderr eq $experr) {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR is:\n$stderr\nnot:\n$experr\nas expected";
    }
  } elsif(defined($expout)) {
    $ok=($stdout eq $expout);
    $diag.="STDOUT is:\n$stdout\nnot:\n$expout\nas expected";
  } elsif(defined($experr)) {
    $ok=($stderr eq $experr);
    $diag.="STDERR is:\n$stderr\nnot:\n$experr\nas expected";
  } else {
    unless($stdout eq '') {
      $ok=0;
      $diag.="STDOUT is:\n$stdout\nnot:\n\nas expected";
    }
    unless($stderr eq '') {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR is:\n$stderr\nnot:\n\nas expected";
    }
  }

  $Test->ok( $ok, $description ) || $Test->diag($diag);

  return $ok;
}

sub output_isnt (&$$;$$) {
  my $test=shift;
  my $expout=shift;
  my $experr=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my($stdout,$stderr)=output_from($test);

  my $ok=1;
  my $diag;

  if(defined($experr) && defined($expout)) {
    if($stdout eq $expout) {
      $ok=0;
      $diag.="STDOUT:\n$stdout\nmatching:\n$expout\nnot expected";
    }
    if($stderr eq $experr) {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR:\n$stderr\nmatching:\n$experr\nnot expected";
    }
  } elsif(defined($expout)) {
    $ok=($stdout ne $expout);
    $diag="STDOUT:\n$stdout\nmatching:\n$expout\nnot expected";
  } elsif(defined($experr)) {
    $ok=($stderr ne $experr);
    $diag="STDERR:\n$stderr\nmatching:\n$experr\nnot expected";
  } else {
    if($stdout eq '') {
      $ok=0;
      $diag="STDOUT:\n$stdout\nmatching:\n\nnot expected";
    }
    if($stderr eq '') {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR:\n$stderr\nmatching:\n\nnot expected";
    }
  }

  $Test->ok( $ok, $description ) || $Test->diag($diag);

  return $ok;
}

=item B<output_like>

=item B<output_unlike>

  output_like  ( $coderef, $regex_stdout, $regex_stderr, 'description' );
  output_like     ... } $regex_stdout, $regex_stderr, 'description';
  output_unlike( $coderef, $regex_stdout, $regex_stderr, 'description' );
  output_unlike  { ... } $regex_stdout, $regex_stderr, 'description';

output_like() and output_unlike() follow the same principles as output_is()
and output_isnt() except they use a regular expression for matching.

output_like() attempts to match $regex_stdout and $regex_stderr against
STDOUT and STDERR produced by $coderef. The test passes if both match.

  output_like(sub {print "foo"; print STDERR "bar";},qr/foo/,qr/bar/);

The above test is successful.

Like output_is(), setting either $regex_stdout or $regex_stderr to
C<undef> ignores the output to that facility.

  output_like(sub {print "foo"; print STDERR "bar";},qr/foo/,undef);

is the same as

  stdout_like(sub {print "foo"; print STDERR "bar";},qr/foo/);

output_unlike() test pass if output from $coderef doesn't match 
$regex_stdout and $regex_stderr.

=back

=cut

sub output_like (&$$;$$) {
  my $test=shift;
  my $expout=shift;
  my $experr=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my($stdout,$stderr)=output_from($test);

  my $ok=1;

  unless(my $regextest=_chkregex( 'output_like_STDERR' => $experr, 
                                  'output_like_STDOUT' => $expout)) {
    return $regextest;
  }

  my $diag;
  if(defined($experr) && defined($expout)) {
    unless($stdout =~ $expout) {
      $ok=0;
      $diag.="STDOUT:\n$stdout\ndoesn't match:\n$expout\nas expected";
    }
    unless($stderr =~ $experr) {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR:\n$stderr\ndoesn't match:\n$experr\nas expected";
    }
  } elsif(defined($expout)) {
    $ok=($stdout =~ $expout);
    $diag.="STDOUT:\n$stdout\ndoesn't match:\n$expout\nas expected";
  } elsif(defined($experr)) {
    $ok=($stderr =~ $experr);
    $diag.="STDERR:\n$stderr\ndoesn't match:\n$experr\nas expected";
  } else {
    unless($stdout eq '') {
      $ok=0;
      $diag.="STDOUT is:\n$stdout\nnot:\n\nas expected";
    }
    unless($stderr eq '') {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR is:\n$stderr\nnot:\n\nas expected";
    }
  }

  $Test->ok( $ok, $description ) || $Test->diag( $diag );

  return $ok;
}

sub output_unlike (&$$;$$) {
  my $test=shift;
  my $expout=shift;
  my $experr=shift;
  my $options=shift if(ref($_[0]));
  my $description=shift;

  my($stdout,$stderr)=output_from($test);

  my $ok=1;

  unless(my $regextest=_chkregex( 'output_unlike_STDERR' => $experr, 
                                  'output_unlike_STDOUT' => $expout)) {
    return $regextest;
  }

  my $diag;
  if(defined($experr) && defined($expout)) {
    if($stdout =~ $expout) {
      $ok=0;
      $diag.="STDOUT:\n$stdout\nmatches:\n$expout\nnot expected";
    }
    if($stderr =~ $experr) {
      $diag.="\n" unless($ok);
      $ok=0;
      $diag.="STDERR:\n$stderr\nmatches:\n$experr\nnot expected";
    }
  } elsif(defined($expout)) {
    $ok=($stdout !~ $expout);
    $diag.="STDOUT:\n$stdout\nmatches:\n$expout\nnot expected";
  } elsif(defined($experr)) {
    $ok=($stderr !~ $experr);
    $diag.="STDERR:\n$stderr\nmatches:\n$experr\nnot expected";
  }

  $Test->ok( $ok, $description ) || $Test->diag( $diag );

  return $ok;
}

=head1 FUNCTIONS

=cut

=head2 stdout_from

  my $stdout = stdout_from($coderef)
  my $stdout = stdout_from { ... };

stdout_from() executes $coderef and captures STDOUT.

=cut

sub stdout_from (&) {
  my $test=shift;

  select((select(STDOUT), $|=1)[0]);
  my $out=tie *STDOUT, 'Test::Output::Tie';

  &$test;
  my $stdout=$out->read;

  undef $out;
  untie *STDOUT;

  return $stdout;
}

=head2 stderr_from

  my $stderr = stderr_from($coderef)
  my $stderr = stderr_from { ... };

stderr_from() executes $coderef and captures STDERR.

=cut

sub stderr_from (&) {
  my $test=shift;

  select((select(STDERR), $|=1)[0]);
  my $err=tie *STDERR, 'Test::Output::Tie';

  &$test;
  my $stderr=$err->read;

  undef $err;
  untie *STDERR;

  return $stderr;
}

=head2 output_from

  my ($stdout, $stderr) = output_from($coderef)
  my ($stdout, $stderr) = output_from {...};

output_from() executes $coderef one time capturing both STDOUT and STDERR.

=cut

sub output_from (&) {
  my $test=shift;

  select((select(STDOUT), $|=1)[0]);
  select((select(STDERR), $|=1)[0]);
  my $out=tie *STDOUT, 'Test::Output::Tie';
  my $err=tie *STDERR, 'Test::Output::Tie';

  &$test;
  my $stdout=$out->read;
  my $stderr=$err->read;

  undef $out;
  undef $err;
  untie *STDOUT;
  untie *STDERR;

  return ($stdout,$stderr);
}

sub _chkregex {
  my %regexs=@_;

  foreach my $test (keys(%regexs)) {
    next unless(defined($regexs{$test}));

    my $usable_regex=$Test->maybe_regex( $regexs{$test} );
    unless(defined( $usable_regex )) {
      my $ok = $Test->ok( 0, $test );

      $Test->diag("'$regexs{$test}' doesn't look much like a regex to me.");
#       unless $ok;

      return $ok;
    }
  }
  return 1;
}

=head1 AUTHOR

Shawn Sorichetti, C<< <ssoriche@coloredblocks.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-output@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to chromatic whose TieOut.pm was the basis for capturing output.

Also thanks to rjbs for his help cleaning the documention

Thanks to David Wheeler for providing code block support and tests.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shawn Sorichetti, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::Output