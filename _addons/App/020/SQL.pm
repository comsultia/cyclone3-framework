#!/bin/perl
package App::020::SQL;

=head1 NAME

App::020::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/init.pm">

=item *

L<App::020::SQL::functions|app/"020/SQL/functions.pm">

=back

=cut

use App::020::_init;
use App::020::SQL::functions;

1;
