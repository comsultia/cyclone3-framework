#!/bin/perl
package App::210;

=head1 NAME

App::210

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use App::020; # data standard 0
use App::210::SQL;

1;
