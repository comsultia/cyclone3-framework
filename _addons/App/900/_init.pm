#!/bin/perl
package App::900;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;


BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='1';


use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::900::a020;
use App::900::a160;
use App::900::a301;
use App::900::functions;

our $db_name=$App::900::db_name || $TOM::DB{'main'}{'name'};


1;
