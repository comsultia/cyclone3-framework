#!/bin/perl
package App::940::a020;

=head1 NAME

App::940::a020

=cut
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=1;
our $quiet;$quiet=1 unless $debug;

our $VERSION='1';

=head1 DESCRIPTION

a020 low api functions specific to a940

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut


1;
