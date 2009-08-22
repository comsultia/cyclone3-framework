#!/bin/perl
package App::730::a301;

=head1 NAME

App::730::a301

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a730

=cut

=head1 DEPENDS

=over

=item *

L<App::730::_init|app/"730/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::730::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='$Rev$';


# addon functions
our %functions=(
	# article data
#	'data.article.visits' => 1,
#	'data.article.title' => 1,
#	'data.article.datetime_start' => 1,
#	'data.article.datetime_stop' => 1,
#	'data.article.priority_A' => 1,
#	'data.article.priority_B' => 1,
#	'data.article.priority_C' => 1,
#	'data.article.editor' => 1,
#	'data.article.subtitle' => 1,
#	'data.article.content' => 1,
	
	# actions
#	'action.article.enable' => 1,
);


# addon roles
our %roles=(
#	'article.content' => [
#		'data.article.title',
#		'data.article.subtitle',
#		'data.article.content',
#	],
#	'article.planning' => [
#		'data.article.datetime_start',
#		'data.article.datetime_stop',
#		'data.article.priority_A',
#		'data.article.priority_B',
#		'data.article.priority_C'
#	],
#	'article.publishing' => [
#		'action.article.enable'
#	],
);


# default groups related to addon roles with defined permissions
our %groups=(
#	'world' => {
#		'article.content' => 'r  '
#	},
#	'editor' => {
#		'article.content' => 'rwx',
#		'article.planning' => 'rwx',
#		'article.publishing' => 'rwx'
#	}
);


# ACL role override
our %ACL_roles=(
#	'owner' => {
#		'article.content' => 'rwx',
#		'article.planning' => 'rwx',
#	},
#	'manager' => {
#		'article.planning' => 'r x',
#	},
);


# register this definition

App::301::perm::register(
	'addon' => 'a730',
	'functions' => \%functions,
	'roles' => \%roles,
	'ACL_roles' => \%ACL_roles,
	'groups' => \%groups
);



sub get_owner
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_owner()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	if ($env{'r_table'} eq "event")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::730::db_name`.a730_event
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close();
		return $db0_line{'posix_owner'};
	}
	
	$t->close();
	return undef;
}


sub set_owner
{
	shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::set_owner()");
	
	foreach (sort keys %env) {main::_log("input '$_'='$env{$_}'") if defined $env{$_}};
	
	if ($env{'r_table'} eq "event")
	{
		my @IDs=App::020::SQL::functions::get_ID_entity
		(
			'ID_entity' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::730::db_name,
			'tb_name' => 'a730_event',
		);
		if ($IDs[0]->{'ID'})
		{
			App::020::SQL::functions::update(
				'ID' => $IDs[0]->{'ID'},
				'db_h' => 'main',
				'db_name' => $App::730::db_name,
				'tb_name' => 'a730_event',
				'columns' =>
				{
					'posix_owner' => "'".$env{'posix_owner'}."'"
				},
				'-journalize' => 1,
				'-posix' => 1
			);
			$t->close();
			return 1;
		}
	}
	
	$t->close();
	return undef;
}



1;