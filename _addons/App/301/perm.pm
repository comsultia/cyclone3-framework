#!/bin/perl
package App::301::perm;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;



=head1 NAME

App::301::perm

=head1 DESCRIPTION

Basic permissions storage and management

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=back

=cut

use App::301::_init;


our %groups;
our %roles;
our %ACL_roles;
our %functions;

=head2 FUNCTIONS

=cut


sub register
{
	my %env=@_;
	
	my $t=track TOM::Debug(__PACKAGE__."::register()");
	
	if (!$env{'addon'})
	{
		main::_log("addon not defined",1);
		$t->close();return undef;
	}
	
	main::_log("addon='$env{'addon'}'");
	
	if ($env{'functions'})
	{
		foreach (sort keys %{$env{'functions'}})
		{
			main::_log("FNC_$env{'addon'}.$_");
			$functions{$env{'addon'}.'.'.$_}=$env{'functions'}->{$_};
		}
	}
	
	if ($env{'roles'})
	{
		foreach my $role(sort keys %{$env{'roles'}})
		{
			main::_log("RL_$env{'addon'}.$role");
			if (!$roles{$env{'addon'}.'.'.$role})
			{
				$roles{$env{'addon'}.'.'.$role}={};
			}
			foreach my $fnc(@{$env{'roles'}->{$role}})
			{
				# register function to role
				main::_log("->FNC_$env{'addon'}.$fnc");
				$roles{$env{'addon'}.'.'.$role}{$env{'addon'}.'.'.$fnc}=1;
			}
		}
	}
	
	if ($env{'groups'})
	{
		foreach my $group(sort keys %{$env{'groups'}})
		{
			main::_log("group '$group'");
			if (!$groups{$group})
			{
				$groups{$group}={};
			}
			
			foreach my $role(keys %{$env{'groups'}->{$group}})
			{
				# register role to groups
				my $perm=$env{'groups'}->{$group}{$role};
				my $perm_;
				
#				if (!$groups{$group}{$env{'addon'}.'.'.$role})
#				{
#					$perm_=$perm;
					$groups{$group}{$env{'addon'}.'.'.$role}=$perm;
#				}
#				else
#				{
					# setup the highest permissions
#					main::_log("exists");
#					my @perms=split('',$perm,3);
#					my @perms_=split('',$env{groups}{$env{'addon'}.'.'.$role},3);
#				}
				
				main::_log("->RL_$env{'addon'}.$role '$perm'");
#				$roles{$env{'addon'}.'.'.$role}{$env{'addon'}.'.'.$_}=1;
			}
			
		}
	}
	
	
	if ($env{'ACL_roles'})
	{
		foreach my $ACL_role(sort keys %{$env{'ACL_roles'}})
		{
			main::_log("ACL_role '$ACL_role'");
			if (!$ACL_roles{$ACL_role})
			{
				$ACL_roles{$ACL_role}={};
			}
			
			foreach my $role(keys %{$env{'ACL_roles'}->{$ACL_role}})
			{
				# register role to ACL_roles
				my $perm=$env{'ACL_roles'}->{$ACL_role}{$role};
				my $perm_;
				
				$ACL_roles{$ACL_role}{$env{'addon'}.'.'.$role}=$perm;
				
				main::_log("->RL_$env{'addon'}.$role '$perm'");
			}
			
		}
	}
	
	
	$t->close();
	return 1;
};



sub get_roles
{
	my %env=@_;
	my %roles;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_roles()");
	
	main::_log("ID_user='$env{'ID_user'}' ID_group='$env{'ID_group'}'");
	
	my $status="'Y','L'";
	if (!$env{'ID_user'})
	{
		$status="'Y','L','N'";
	}
	
	my %user;
	if ($env{'ID_user'})
	{
		%user=App::301::functions::user_get($env{'ID_user'});
	}
	
	# world group (generic)
	if ($env{'ID_group'} eq "0" || $env{'ID_group'} eq "*")
	{
		main::_log("group 'world' permissions");
		foreach my $role(sort keys %{$App::301::perm::groups{'world'}})
		{
			main::_log("RL_$role '$App::301::perm::groups{'world'}{$role}'");
			$roles{$role}=$App::301::perm::groups{'world'}{$role};
		}
	}
	
	
	# get group(s)
	my %groups;
	if ($env{'ID_group'} && $env{'ID_group'} ne "*" && $env{'ID_group'} ne $env{'ID_user'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				TOM.a301_user_group AS `group`
			WHERE
				`group`.ID = $env{'ID_group'} AND
				`group`.status IN ($status)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$groups{$env{'ID_group'}}=$db0_line{'name'};
		}
	}
	if ($env{'ID_user'} && $env{'ID_group'} eq "*" && $env{'ID_group'} ne $env{'ID_user'})
	{
		my $sql=qq{
			SELECT
				`group`.*
			FROM
				TOM.a301_user_rel_group AS rel,
				TOM.a301_user_group AS `group`
			WHERE
				rel.ID_user='$env{'ID_user'}' AND
				rel.ID_group = `group`.ID AND
				`group`.status IN ($status)
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$groups{$db0_line{'ID'}}=$db0_line{'name'};
		}
	}
	
	# check 'admin' group at first
	foreach (keys %groups)
	{
		if ($groups{$_} eq "admin")
		{
			main::_log("group 'admin' permissions");
			main::_log("RL_unlimited 'rwx'");
			$roles{'unlimited'}='rwx';
			delete $groups{$_};
		}
	}
	
	# check 'editor' group as second
	foreach (keys %groups)
	{
		if ($groups{$_} eq "editor")
		{
			main::_log("group 'editor' permissions");
			my %roles_local;
			foreach my $role(sort keys %{$App::301::perm::groups{'editor'}})
			{
#				my $perm=perm_inc($roles{$role},$App::301::perm::groups{'editor'}{$role});
#				main::_log("RL_$role '$roles{$role}'+'$App::301::perm::groups{'editor'}{$role}'='$perm'");
#				$roles{$role}=$perm;
				main::_log(" RL_$role '$App::301::perm::groups{'editor'}{$role}'");
				$roles_local{$role}=$App::301::perm::groups{'editor'}{$role};
			}
			my $sql=qq{
				SELECT *
				FROM TOM.a301_user_group
				WHERE ID=$_ AND status IN ($status)
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			if (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				main::_log("group 'editor' permissions overrides");
				foreach my $role(split('\n',$db0_line{'perm_roles_override'}))
				{
					my @role_def=split(':',$role,2);
					my $perm=perm_sum($roles_local{$role_def[0]},$role_def[1]);
					main::_log(" RL_$role_def[0] '$roles_local{$role_def[0]}'*'$role_def[1]'='$perm'");
					$roles_local{$role_def[0]}=$perm;
				}
			}
			
			main::_log("group 'editor' overrides");
			foreach my $role(keys %roles_local)
			{
				my $perm=perm_inc($roles{$role},$roles_local{$role});
				main::_log(" RL_$role '$roles{$role}'+'$roles_local{$role}'='$perm'");
				$roles{$role}=$perm;
			}
			
			main::_log(" RL_login '--x'");
			$roles{'login'}='--x';
			
			delete $groups{$_};
		}
	}
	
	# check other groups
	foreach my $group(keys %groups)
	{
		my $sql=qq{
			SELECT *
			FROM TOM.a301_user_group
			WHERE ID=$group AND status IN ($status)
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("group '$db0_line{'name'}' permissions");
			foreach my $role(split('\n',$db0_line{'perm_roles_override'}))
			{
				my @role_def=split(':',$role,2);
				my $perm=perm_inc($roles{$role_def[0]},$role_def[1]);
				main::_log("RL_$role_def[0] '$roles{$role_def[0]}'+'$role_def[1]'='$perm'");
				$roles{$role_def[0]}=$perm;
			}
		}
	}
	
	
	# user overrides
	if ($env{'ID_group'} eq $env{'ID_user'} || $env{'ID_group'} eq "*")
	{
		main::_log("user overrides");
		foreach my $role(split('\n',$user{'perm_roles_override'}))
		{
			my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
			my $perm=perm_sum($roles{$role_def[0]},$role_def[1]);
			my @perm_=split('',$perm);
			$perm_[0]=' ' unless $perm_[0];
			$perm_[1]=' ' unless $perm_[1];
			$perm_[2]=' ' unless $perm_[2];
			$perm=join '',@perm_;
			main::_log("RL_$role_def[0] '$roles{$role_def[0]}'*'$role_def[1]'='$perm'");
			$roles{$role_def[0]}=$perm;
		}
	}
	
	if ($roles{'unlimited'})
	{
		%roles=('unlimited'=>'rwx','login'=>'--x');
	}
	
	main::_log("send to output:");
	foreach (sort keys %roles)
	{
		my @perm=split('',$roles{$_});
		$perm[0]='-' if (!$perm[0] || $perm[0] eq ' ');
		$perm[1]='-' if (!$perm[1] || $perm[1] eq ' ');
		$perm[2]='-' if (!$perm[2] || $perm[2] eq ' ');
		$roles{$_}=join '',@perm;
		main::_log(" RL_$_ '$roles{$_}'");
	}
	
	$t->close();
	return %roles;
}


=head2 get_ACL_roles

Get list of roles from ACL and ACL_role

=cut

sub get_ACL_roles
{
	my %env=@_;
	my %roles;
	my $permstrip;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_ACL_roles()");
	
	main::_log("ID_user='$env{'ID_user'}' ID_group='$env{'ID_group'}' r_prefix='$env{'r_prefix'}' r_table='$env{'r_table'}' r_prefix='$env{'r_ID_entity'}'");
	
	# get full ACL from this entity and filter it after
	my @ACL=get_ACL(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'},
	);

	foreach my $ACL_item(@ACL)
	{
		if (($env{'ID_user'} && !$ACL_item->{'folder'} && $ACL_item->{'ID'} eq $env{'ID_user'}) ||
		($env{'ID_group'} && $ACL_item->{'folder'} && $ACL_item->{'ID'} eq $env{'ID_group'}))
		{
			main::_log("override by ACL_role roles");
			my %my_roles;
			foreach my $ACL_role(split(',',$ACL_item->{'roles'}))
			{
				main::_log("ACL_role '$ACL_role'");
				foreach my $role(keys %{$App::301::perm::ACL_roles{$ACL_role}})
				{
					my $perm=perm_inc($my_roles{$role},$App::301::perm::ACL_roles{$ACL_role}{$role});
					main::_log(" RL_$role '$my_roles{$role}'+'$App::301::perm::ACL_roles{$ACL_role}{$role}'='$perm'");
					$my_roles{$role}=$perm;
				}
			}
			main::_log("override by ACL_role roles (apply)");
			foreach my $role(keys %my_roles)
			{
				my $perm=perm_sum($roles{$role},$my_roles{$role});
				main::_log(" RL_$role '$roles{$role}'*'$my_roles{$role}'='$perm'");
				$roles{$role}=$perm;
			}
			
			main::_log("override by group/user override def");
			foreach my $role(split('\n',$ACL_item->{'override'}))
			{
				my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
				my $perm=perm_sum($roles{$role_def[0]},$role_def[1]);
				main::_log(" RL_$role_def[0] '$roles{$role_def[0]}'*'$role_def[1]'='$perm'");
				$roles{$role_def[0]}=$perm;
			}
			
			# strip
			main::_log("strip by '$ACL_item->{'perm_R'}$ACL_item->{'perm_W'}$ACL_item->{'perm_X'}'");
			$permstrip=$ACL_item->{'perm_R'}.$ACL_item->{'perm_W'}.$ACL_item->{'perm_X'};
#			$permstrip=~tr/RWXrwx_/      -/;
#			main::_log("strip string '$permstrip'");
#			foreach my $role(keys %roles)
#			{
#				my $perm=perm_sum($roles{$role},$permstrip);
#				main::_log(" RL_$role '$roles{$role}'*'$permstrip'='$perm'");
#				$roles{$role}=$perm;
#			}
			
			last;
		}
	}
	
#	main::_log("permstrip=$permstrip");
	$t->close();
	return ({%roles},$permstrip);
}




=head2 get_entity_roles

Get list of roles in one entity for user and groups

=cut

sub get_entity_roles
{
	my %env=@_;
	my %roles;
	my $permstrip;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_entity_roles()");
	
	main::_log("r_prefix='$env{'r_prefix'}' r_table='$env{'r_table'}' r_prefix='$env{'r_ID_entity'}'");
	
	my @ACL=get_ACL
	(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'}
	);
	
	my %grp;
	foreach (@{$env{'groups'}}){$grp{$_}++;}
	
	main::_log("get permissions from groups");
	my %groups_roles;
	my %strip_perms;
	foreach my $ACL_item(@ACL)
	{
		if ($ACL_item->{'folder'} && $grp{$ACL_item->{'ID'}}) # this is group
		{
			main::_log("I'm in this group $ACL_item->{'ID'}");
			
			# get basic group roles
			main::_log("load basic group roles");
			my %local_roles=get_roles(
				'ID_group' => "$ACL_item->{'ID'}"
			);
			
			# override it byt ACL_roles
			main::_log("override by ACL_role roles");
			my %my_roles;
			foreach my $ACL_role(split(',',$ACL_item->{'roles'}))
			{
				main::_log("ACL_role '$ACL_role'");
				foreach my $role(keys %{$App::301::perm::ACL_roles{$ACL_role}})
				{
					my $perm=perm_inc($my_roles{$role},$App::301::perm::ACL_roles{$ACL_role}{$role});
					main::_log(" RL_$role '$my_roles{$role}'+'$App::301::perm::ACL_roles{$ACL_role}{$role}'='$perm'");
					$my_roles{$role}=$perm;
				}
			}
			main::_log("override by ACL_role roles (apply)");
			foreach my $role(keys %my_roles)
			{
				my $perm=perm_sum($local_roles{$role},$my_roles{$role});
				main::_log(" RL_$role '$local_roles{$role}'*'$my_roles{$role}'='$perm'");
				$local_roles{$role}=$perm;
			}
			
			main::_log("override by group/user override def");
			foreach my $role(split('\n',$ACL_item->{'override'}))
			{
				my @role_def=split(':',$role,2);$role_def[1]=~tr/rwx\-/RWX_/;
				my $perm=perm_sum($local_roles{$role_def[0]},$role_def[1]);
				main::_log(" RL_$role_def[0] '$local_roles{$role_def[0]}'*'$role_def[1]'='$perm'");
				$local_roles{$role_def[0]}=$perm;
			}
			
			# strip
			main::_log("strip by '$ACL_item->{'perm_R'}$ACL_item->{'perm_W'}$ACL_item->{'perm_X'}'");
			my $permstrip=$ACL_item->{'perm_R'}.$ACL_item->{'perm_W'}.$ACL_item->{'perm_X'};
			$strip_perms{'perm_R'}=$ACL_item->{'perm_R'} if $ACL_item->{'perm_R'} ne ' ';
			$strip_perms{'perm_W'}=$ACL_item->{'perm_W'} if $ACL_item->{'perm_W'} ne ' ';
			$strip_perms{'perm_X'}=$ACL_item->{'perm_X'} if $ACL_item->{'perm_X'} ne ' ';
			$permstrip=~tr/RWXrwx_/      -/;
			main::_log("strip string '$permstrip'");
			foreach my $role(keys %local_roles)
			{
				my $perm=perm_sum($local_roles{$role},$permstrip);
				main::_log(" RL_$role '$local_roles{$role}'*'$permstrip'='$perm'");
				$local_roles{$role}=$perm;
			}
			
			
			# compare %local_roles to %groups_roles
			main::_log("group '$ACL_item->{'ID'}' roles (apply)");
			foreach my $role(keys %local_roles)
			{
				my $perm=perm_inc($groups_roles{$role},$local_roles{$role});
				main::_log(" RL_$role '$groups_roles{$role}'+'$local_roles{$role}'='$perm'");
				$groups_roles{$role}=$perm;
			}
			
			
		}
		
		
		
	}
	
	# strip
	main::_log("strip all by '$strip_perms{'perm_R'}$strip_perms{'perm_W'}$strip_perms{'perm_X'}'");
	
	
	$t->close();
	return ({%roles},$permstrip);
}


=head2 get_entity_sum_roles

Get list of roles in entity and depends for user

=cut

sub get_entity_sum_roles
{
	my %env=@_;
	my %roles;
	
	my $t=track TOM::Debug(__PACKAGE__."::get_entity_sum_roles()");
	
	main::_log("ID_user='$env{'ID_user'}' r_prefix='$env{'r_prefix'}' r_table='$env{'r_table'}' r_prefix='$env{'r_ID_entity'}'");
	
	# get ID_user global roles (defined by groups and ID_user)
	my %roles_global=get_roles(
		'ID_user'=>$env{'ID_user'},
		'ID_group'=>'*'
	);
	
	my @groups=(0);
	my %grp=App::301::functions::user_groups($env{'ID_user'});
	foreach (keys %grp){push @groups, $grp{$_}{'ID'};}
	
	# get list of this entity parents
	
	
	# get special roles of this entity
	my $roles_entity=get_entity_roles(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'},
		'ID_user' => $env{'ID_user'},
		'groups' => [@groups]
	);
	
	# and combine this all :)
	
	$t->close();
	return undef;
}



sub get_owner
{
	my $t=track TOM::Debug(__PACKAGE__."::get_owner()");
	my %env=@_;
	my $owner;
	
	# at first check if this addon is available
	my $r_prefix=$env{'r_prefix'};
		$r_prefix=~s|^a|App::|;
		$r_prefix=~s|^e|Ext::|;
	eval "use $r_prefix".'::a301;' unless $r_prefix->VERSION;
	
	# check if a301 enhancement of this application is available
	my $pckg=$r_prefix."::a301";
	if ($pckg->VERSION)
	{
		main::_log("trying get_owner() from package '$pckg'");
		$owner=$pckg->get_owner(
			'r_table' => $env{'r_table'},
			'r_ID_entity' => $env{'r_ID_entity'}
		);
		main::_log("owner='$owner'");
		$t->close();
		return $owner;
	}
	else
	{
		main::_log("blind get_owner()");
		my $db_name=App::160::SQL::_detect_db_name($env{'r_prefix'});
		
		my $sql=qq{
			SELECT
				posix_owner
			FROM
				`$db_name`.$env{'r_prefix'}_$env{'r_table'}
			WHERE
				ID_entity='$env{'r_ID_entity'}'
			LIMIT 1;
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$owner=$db0_line{'posix_owner'};
	}
	
	main::_log("owner='$owner'");
	$t->close();
	return $owner;
};


sub set_owner
{
	my $t=track TOM::Debug(__PACKAGE__."::set_owner()");
	my %env=@_;
	
	# at first check if this addon is available
	my $r_prefix=$env{'r_prefix'};
		$r_prefix=~s|^a|App::|;
		$r_prefix=~s|^e|Ext::|;
	eval "use $r_prefix".'::a301;' unless $r_prefix->VERSION;
	
	# check if a301 enhancement of this application is available
	my $pckg=$r_prefix."::a301";
	if ($pckg->VERSION)
	{
		main::_log("trying set_owner() from package '$pckg'");
		my $out=$pckg->set_owner(
			'r_table' => $env{'r_table'},
			'r_ID_entity' => $env{'r_ID_entity'},
			'posix_owner' => $env{'posix_owner'}
		);
		$t->close();
		return $out;
	}
	else
	{
		$t->close();
		return undef;
	}
	
	$t->close();
	return undef;
};




sub get_ACL
{
	my $t=track TOM::Debug(__PACKAGE__."::get_ACL()");
	my %env=@_;
	my @ACL;
	
   my $db_name=App::160::SQL::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
   
	
	my $world;
	my $sql=qq{
	SELECT
		acl.*,
		grp.name
	FROM
		`$db_name`.a301_ACL_user_group AS acl,
		`TOM`.a301_user_group AS grp
	WHERE
		acl.r_prefix='$env{'r_prefix'}' AND
		acl.r_table='$env{'r_table'}' AND
		acl.r_ID_entity='$env{'r_ID_entity'}' AND
		acl.ID_entity = grp.ID_entity
	ORDER BY
		acl.ID_entity ASC
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my %item;
		
		if ($db0_line{'ID_entity'} ne "0" && !$world) # world override not available
		{
			$world=1;
			my %item;
			main::_log("->{world} 'r--'");
			$item{'ID'}='0';
			$item{'folder'}='Y';
			$item{'roles'}='';
			$item{'perm_R'}='r';
			$item{'perm_W'}='-';
			$item{'perm_X'}='-';
			$item{'status'}='L';
			$item{'name'}='world';
			push @ACL, {%item};
		}
		
		$db0_line{'perm_R'}=~tr/YN/R_/;
		$db0_line{'perm_W'}=~tr/YN/W_/;
		$db0_line{'perm_X'}=~tr/YN/X_/;
		
		main::_log("->{user_group} ID='$db0_line{'ID_entity'}' name='$db0_line{'name'}' roles='$db0_line{'roles'}' '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'");
		$item{'ID'}=$db0_line{'ID_entity'};
		$item{'folder'}='Y';
		$item{'roles'}=$db0_line{'roles'};
		$item{'perm_R'}=$db0_line{'perm_R'};
		$item{'perm_W'}=$db0_line{'perm_W'};
		$item{'perm_X'}=$db0_line{'perm_X'};
		$item{'status'}=$db0_line{'status'};
		$item{'override'}=$db0_line{'perm_roles_override'};
		$item{'name'}=$db0_line{'name'};
		
		push @ACL, {%item};
	}
	
	
	if (!$world) # world override not available
	{
		$world=1;
		my %item;
		main::_log("->{world} 'r--'");
		$item{'ID'}='0';
		$item{'folder'}='Y';
		$item{'roles'}='';
		$item{'perm_R'}='r';
		$item{'perm_W'}='-';
		$item{'perm_X'}='-';
		$item{'status'}='L';
		$item{'name'}='world';
		push @ACL, {%item};
	}
	
   # get owner
   my $owner=App::301::perm::get_owner(
		'r_prefix' => $env{'r_prefix'},
		'r_table' => $env{'r_table'},
		'r_ID_entity' => $env{'r_ID_entity'}
	);
   if ($owner)
	{
		my %item;
		
		my %author=App::301::authors::get_author($owner);
		
		main::_log("->{owner} ID='$owner' name='$author{'login'}' 'rwx'");
		$item{'ID'}=$owner;
		$item{'folder'}='';
		$item{'roles'}='owner';
		$item{'perm_R'}='r';
		$item{'perm_W'}='w';
		$item{'perm_X'}='x';
		$item{'status'}='L';
		$item{'name'}=$author{'login'};
		
		push @ACL, {%item};
   }
   
	my $sql=qq{
	SELECT
		acl.*,
		usr.login AS name,
		usr.login
	FROM
		`$db_name`.a301_ACL_user AS acl,
		`TOM`.a301_user AS usr
	WHERE
		acl.r_prefix='$env{'r_prefix'}' AND
		acl.r_table='$env{'r_table'}' AND
		acl.r_ID_entity='$env{'r_ID_entity'}' AND
		acl.ID_entity = usr.ID_user
	ORDER BY
		acl.ID_entity ASC
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my %item;
		
		$db0_line{'perm_R'}=~tr/YN/R_/;
		$db0_line{'perm_W'}=~tr/YN/W_/;
		$db0_line{'perm_X'}=~tr/YN/X_/;
		
		if ($db0_line{'ID_entity'} eq $owner)
		{
			main::_log("->{owner/user} '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'");
			$ACL[0]{'perm_R'}=$db0_line{'perm_R'};
			$ACL[0]{'perm_W'}=$db0_line{'perm_W'};
			$ACL[0]{'perm_X'}=$db0_line{'perm_X'};
			next;
		}
		
		main::_log("->{user} ID='$db0_line{'ID_entity'}' name='$db0_line{'login'}' roles='$db0_line{'roles'}' '$db0_line{'perm_R'}$db0_line{'perm_W'}$db0_line{'perm_X'}'");
		$item{'ID'}=$db0_line{'ID_entity'};
		$item{'folder'}='';
		$item{'roles'}=$db0_line{'roles'};
		$item{'perm_R'}=$db0_line{'perm_R'};
		$item{'perm_W'}=$db0_line{'perm_W'};
		$item{'perm_X'}=$db0_line{'perm_X'};
		$item{'status'}=$db0_line{'status'};
		$item{'override'}=$db0_line{'perm_roles_override'};
		$item{'name'}=$db0_line{'login'};
		
		push @ACL, {%item};
	}
	
	$t->close();
	return @ACL;
}



sub ACL_user_group_update
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_group_update()");
	my %env=@_;
	
   my $db_name=App::160::SQL::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	if ($env{'roles'})
	{
		$env{'roles'}=~s|owner||g;
		my @roles=split('[,;]',$env{'roles'});
		$env{'roles'}=join ",", @roles;
		1 while ($env{'roles'}=~s|,,|,|g);
		$env{'roles'}=~s|^,||;
		$env{'roles'}=~s|,$||;
	}
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user_group
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		my %columns;
		$columns{'perm_R'} = "'".$env{'perm_R'}."'" if $env{'perm_R'};
		$columns{'perm_W'} = "'".$env{'perm_W'}."'" if $env{'perm_W'};
		$columns{'perm_X'} = "'".$env{'perm_X'}."'" if $env{'perm_X'};
		$columns{'roles'} = "'".$env{'roles'}."'" if $env{'roles'};
		App::020::SQL::functions::update(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user_group',
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	else
	{
		App::020::SQL::functions::new(
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user_group',
			'columns' =>
			{
				'ID_entity' => "'".$env{'ID'}."'",
				'r_prefix' => "'".$env{'r_prefix'}."'",
				'r_table' => "'".$env{'r_table'}."'",
				'r_ID_entity' => "'".$env{'r_ID_entity'}."'",
				'perm_R' => "'Y'",
				'perm_W' => "'Y'",
				'perm_X' => "'Y'",
				'roles' => "'".$env{'roles'}."'"
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}


sub ACL_user_group_remove
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_group_remove()");
	my %env=@_;
	
   my $db_name=App::160::SQL::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user_group
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		App::020::SQL::functions::delete(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user_group',
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}


sub ACL_user_update
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_update()");
	my %env=@_;
	
   my $db_name=App::160::SQL::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	if ($env{'roles'})
	{
		$env{'roles'}=~s|owner||g;
		my @roles=split('[,;]',$env{'roles'});
		$env{'roles'}=join ",", @roles;
		1 while ($env{'roles'}=~s|,,|,|g);
		$env{'roles'}=~s|^,||;
		$env{'roles'}=~s|,$||;
	}
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		my %columns;
		$columns{'perm_R'} = "'".$env{'perm_R'}."'" if $env{'perm_R'};
		$columns{'perm_W'} = "'".$env{'perm_W'}."'" if $env{'perm_W'};
		$columns{'perm_X'} = "'".$env{'perm_X'}."'" if $env{'perm_X'};
		$columns{'roles'} = "'".$env{'roles'}."'" if $env{'roles'};
		App::020::SQL::functions::update(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user',
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	else
	{
		App::020::SQL::functions::new(
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user',
			'columns' =>
			{
				'ID_entity' => "'".$env{'ID'}."'",
				'r_prefix' => "'".$env{'r_prefix'}."'",
				'r_table' => "'".$env{'r_table'}."'",
				'r_ID_entity' => "'".$env{'r_ID_entity'}."'",
				'perm_R' => "'Y'",
				'perm_W' => "'Y'",
				'perm_X' => "'Y'",
				'roles' => "'".$env{'roles'}."'"
			},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}


sub ACL_user_remove
{
	my $t=track TOM::Debug(__PACKAGE__."::ACL_user_remove()");
	my %env=@_;
	
   my $db_name=App::160::SQL::_detect_db_name($env{'r_prefix'}) || $TOM::DB{'main'}{'name'};
	
	my $sql=qq{
		SELECT
			ID,
			ID_entity
		FROM
			`$db_name`.a301_ACL_user
		WHERE
			ID_entity='$env{'ID'}' AND
			r_prefix='$env{'r_prefix'}' AND
			r_table='$env{'r_table'}' AND
			r_ID_entity='$env{'r_ID_entity'}'
		LIMIT 1;
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	
	if ($sth0{'rows'})
	{
		my %db0_line=$sth0{'sth'}->fetchhash();
		App::020::SQL::functions::delete(
			'ID' => $db0_line{'ID'},
			'db_h' => 'main',
			'db_name' => $db_name,
			'tb_name' => 'a301_ACL_user',
			'-journalize' => 1,
			'-posix' => 1,
		);
		$t->close();
		return 1;
	}
	
	$t->close();
	return undef;
}



sub perm_inc # only accept higher permissions '-w-'+'r-x'='rwx'
{
	my $from=shift;
	my $to=shift;
	my @from_=split('',$from);
	$from_[0]=' ' unless $from_[0];
	$from_[1]=' ' unless $from_[1];
	$from_[2]=' ' unless $from_[2];
	my @to_=split('',$to);
	$to_[0]=' ' unless $to_[0];
	$to_[1]=' ' unless $to_[1];
	$to_[2]=' ' unless $to_[2];
	$to_[0]=$from_[0] if (!$to_[0] || $to_[0] eq '-' || $to_[0] eq '_' || $to_[0] eq ' ');
	$to_[1]=$from_[1] if (!$to_[1] || $to_[1] eq '-' || $to_[0] eq '_' || $to_[1] eq ' ');
	$to_[2]=$from_[2] if (!$to_[2] || $to_[2] eq '-' || $to_[0] eq '_' || $to_[2] eq ' ');
	$to=join '',@to_;
	return $to;
}

sub perm_sum # accept every permission (higher or lower) 'rw-'*' -x'='r-x'
{
	my $from=shift;
	my $to=shift;
	my @from_=split('',$from);
	$from_[0]=' ' unless $from_[0];
	$from_[1]=' ' unless $from_[1];
	$from_[2]=' ' unless $from_[2];
	my @to_=split('',$to);
	$to_[0]=' ' unless $to_[0];
	$to_[1]=' ' unless $to_[1];
	$to_[2]=' ' unless $to_[2];
	$to_[0]=$from_[0] if ($to_[0] eq ' ');
	$to_[1]=$from_[1] if ($to_[1] eq ' ');
	$to_[2]=$from_[2] if ($to_[2] eq ' ');
	$to=join '',@to_;
	return $to;
}


=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
