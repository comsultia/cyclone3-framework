#!/bin/perl
package App::900::a020;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=1;
our $quiet;$quiet=1 unless $debug;

our $VERSION='1';

1;
