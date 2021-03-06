#! /usr/bin/env perl
# Copyright 2018 The OpenSSL Project Authors. All Rights Reserved.
#
# Licensed under the OpenSSL license (the "License").  You may not use
# this file except in compliance with the License.  You can obtain a copy
# in the file LICENSE in the source distribution or at
# https://www.openssl.org/source/license.html

use strict;
no strict 'refs';               # To be able to use strings as function refs
use OpenSSL::Test;
use Errno qw(:POSIX);
use POSIX qw(strerror);

# We actually have space for up to 4095 error messages,
# numerically speaking...  but we're currently only using
# numbers 1 through 127.
# This constant should correspond to the same constant
# defined in crypto/err/err.c, or at least must not be
# assigned a greater number.
use constant NUM_SYS_STR_REASONS => 127;

setup('test_errstr');

# These are POSIX error names, which Errno implements as functions
# (this is documented)
my @posix_errors = @{$Errno::EXPORT_TAGS{POSIX}};

plan tests => scalar @posix_errors
    +1                          # Checking that error 128 gives 'reason(128)'
    +1                          # Checking that error 0 gives the library name
    ;

foreach my $errname (@posix_errors) {
    my $errnum = "Errno::$errname"->();

 SKIP: {
        skip "Error $errname ($errnum) isn't within our range", 1
            if $errnum > NUM_SYS_STR_REASONS;

        my $perr = eval {
            # Set $! to the error number...
            local $! = $errnum;
            # ... and $! will give you the error string back
            $!
        };

        # We know that the system reasons are in OpenSSL error library 2
        my @oerr = run(app([ qw(openssl errstr), sprintf("2%06x", $errnum) ]),
                       capture => 1);
        $oerr[0] =~ s|\R$||;
        $oerr[0] =~ s|.*system library:||g; # The actual message is last

        ok($oerr[0] eq $perr, "($errnum) '$oerr[0]' == '$perr'");
    }
}

my @after = run(app([ qw(openssl errstr 2000080) ]), capture => 1);
$after[0] =~ s|\R$||;
$after[0] =~ s|.*system library:||g;
ok($after[0] eq "reason(128)", "(128) '$after[0]' == 'reason(128)'");

my @zero = run(app([ qw(openssl errstr 2000000) ]), capture => 1);
$zero[0] =~ s|\R$||;
$zero[0] =~ s|.*system library:||g;
ok($zero[0] eq "system library", "(0) '$zero[0]' == 'system library'");
