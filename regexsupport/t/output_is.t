use Test::More tests => 32;
use Test::Tester;
use Test::Output;

use strict;
use warnings;

check_test( sub {
            output_is(sub {
                        print "TEST OUT\n";
                      },
                      "TEST OUT\n",
                      '',
                      'Testing STDOUT'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT',
            },'STDOUT matches success'
          );

check_test( sub {
            output_is(sub {
                        print STDERR "TEST OUT\n";
                      },
                      '',
                      "TEST OUT\n",
                      'Testing STDERR'
                    )
            },{
              ok => 1,
              name => 'Testing STDERR',
            },'STDERR matches success'
          );

check_test( sub {
            output_is(sub {
                        print "TEST OUT\n"; 
                        print STDERR "TEST ERR\n";
                      },
                      "TEST OUT\n",
                      "TEST ERR\n",
                      'Testing STDOUT & STDERR'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT & STDERR',
            },'STDOUT & STDERR match success'
          );

check_test( sub {
            output_is(sub {
                        printf("TEST OUT - %d\n",25);
                      },
                      "TEST OUT - 25\n",
                      '',
                      'Testing STDOUT printf'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT printf',
            },'STDOUT printf match success'
          );

check_test( sub {
            output_is(sub {
                        print "TEST OUT";
                      },
                      "TEST OUT STDOUT",
                      '',
                      'Testing STDOUT failure'
                    )
            }, {
              ok => 0,
              name => 'Testing STDOUT failure',
              diag => "STDOUT is:\nTEST OUT\nnot:\nTEST OUT STDOUT\nas expected\nSTDERR is:\n\nnot:\n\nas expected\n",
            },'STDOUT not matching failure'
          );

check_test( sub {
            output_is(sub {
                      print STDERR "TEST OUT"},
                      '',
                      "TEST OUT STDERR",
                      'Testing STDERR failure'
                    )
            }, {
              ok => 0,
              name => 'Testing STDERR failure',
              diag => "STDOUT is:\n\nnot:\n\nas expected\nSTDERR is:\nTEST OUT\nnot:\nTEST OUT STDERR\nas expected\n",
            },'STDERR not matching failure'
          );
