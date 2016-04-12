#!/bin/perl
package App::520::a301;

=head1 NAME

App::520::a301

=cut
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DESCRIPTION

a301 enhancement to a520

=cut

=head1 DEPENDS

=over

=item *

L<App::520::_init|app/"520/_init.pm">

=item *

L<App::301::perm|app/"301/perm.pm">

=item *

L<App::020::_init|app/"020/_init.pm">

=back

=cut

use App::520::_init;
use App::301::perm;
use App::020::_init;


our $VERSION='1';


# addon functions
our %functions=(
	'addon' => 1,
);


# addon roles
our %roles=(
	'addon' => [
		'addon'
	],
);


# default groups related to addon roles with defined permissions
our %groups=(
	'world' => {
#		'poll' => 'r  '
	},
	'editor' => {
		'addon' => 'rwx',
	}
);


# ACL role override
our %ACL_roles=(
	'owner' => {
#		'poll' => 'rwx',
	},
);


# register this definition

App::301::perm::register(
	'addon' => 'a520',
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
	
	if ($env{'r_table'} eq "audio")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::510::db_name`.a520_audio_ent
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1,'-slave'=>0);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$t->close();
		return $db0_line{'posix_owner'};
	}
	elsif ($env{'r_table'} eq "audio_cat")
	{
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$App::520::db_name`.a520_audio_cat
			WHERE
				ID='$env{'r_ID_entity'}'
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
	
	if ($env{'r_table'} eq "audio_cat")
	{
		App::020::SQL::functions::update(
			'ID' => $env{'r_ID_entity'},
			'db_h' => 'main',
			'db_name' => $App::510::db_name,
			'tb_name' => 'a520_audio_cat',
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
	elsif ($env{'r_table'} eq "video")
	 {
		  my @IDs=App::020::SQL::functions::get_ID_entity
		  (
				'ID_entity' => $env{'r_ID_entity'},
				'db_h' => 'main',
				'db_name' => $App::510::db_name,
				'tb_name' => 'a520_audio_ent',
		  );
		  if ($IDs[0]->{'ID'})
		  {
				App::020::SQL::functions::update(
					'ID' => $IDs[0]->{'ID'},
					'db_h' => 'main',
					'db_name' => $App::520::db_name,
					'tb_name' => 'a520_audio_ent',
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
