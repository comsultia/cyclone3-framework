#!/bin/perl
package App::210::SQL;

=head1 NAME

App::210::SQL

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

 App::210

=cut

use App::210::_init;

=head1 FUNCTIONS

=head2 page_set_as_default

Nastavi stranku ako defaultnu

=cut

sub page_set_as_default
{
	my $ID=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::page_set_as_default()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$App::210::db_name unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# zistim najprv informacie o tomto ID
	my %data=App::020::SQL::functions::get_ID(
		'ID' => $ID,
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => "a210_page",
		'columns' =>
		{
			'lng' => 1,
			'is_default' => 1
		}
	);
	
	# zistim ci mozem vobec nastavovat toto ID
	if (!$data{'ID'})
	{
		main::_log("ID='$ID' not exists",1);
		$t->close();
		return undef;
	}
	
	if (not $data{'status'}=~/^[YN]$/)
	{
		main::_log("only ID with status='Y/N' can be set as default",1);
		$t->close();
		return undef;
	}
	
	if ($data{'is_default'} eq "Y")
	{
		main::_log("this ID is default");
		$t->close();
		return 1;
	}
	
	# start transakcie
	my $tr=new TOM::Database::SQL::transaction('db_h'=>$env{'db_h'});
	
	# najdem polozky ktora su momentalne ako default
	# zrusenia starej ako default
	my $sql=qq{
	SELECT
		ID
	FROM
		`$env{'db_name'}`.`a210_page`
	WHERE
		lng='$data{'lng'}'
		AND is_default='Y'
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'});
	if (!$sth0{'sth'})
	{
		main::_log("error",1);
		$tr->rollback();
		$t->close();
		return undef;
	}
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("default ID='$db0_line{'ID'}'");
		App::020::SQL::functions::update(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => "a210_page",
			'ID'      => $db0_line{'ID'},
			'columns' =>
			{
				'is_default' => "'N'",
			},
			'-journalize' => 1
		);
	}
	# update novej polozky na default
	App::020::SQL::functions::update(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => "a210_page",
		'ID'      => $ID,
		'columns' =>
		{
			'is_default' => "'Y'",
		},
		'-journalize' => 1
	);
	
	# stop transakcie
	$tr->close();
	
	
	
	$t->close();
	return 1;
}


=head2 page_get_default_ID



=cut

sub page_get_default_ID
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::page_get_default_ID()");
	
	my $where;
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	$env{'tb_name'}='a210_page';
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$App::210::db_name unless $env{'db_name'};
	
	$where.="AND status='Y' ";
	
	# najdem polozku ktora je momentalne ako default
	my $sql=qq{
	SELECT
		ID
	FROM
		`$env{'db_name'}`.`a210_page`
	WHERE
		lng='$env{'lng'}'
		AND is_default='Y'
		$where
	LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,
		'db_h' => $env{'db_h'},
		'quiet' => 1,
		'slave' => 1,
		'-cache' => 3600,
		'-cache_changetime' => App::020::SQL::functions::_get_changetime(\%env),
	);
	if (!$sth0{'sth'})
	{
		main::_log("error",1);
		$t->close();
		return undef;
	}
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		main::_log("return ID='$db0_line{'ID'}'");
		$t->close();
		return $db0_line{'ID'};
	}
	
	$t->close();
	return undef;
}


sub _page_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::210::db_name,'class'=>'indexer'});
	
	my $t=track TOM::Debug(__PACKAGE__."::_page_index()",'timer'=>1);
	
	use Ext::Elastic::_init;
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::210::db_name.a210_page AS page
			WHERE
				page.status IN ('Y','N','L','W') AND
				page.ID=?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (!$sth0{'rows'})
		{
			main::_log("page.ID=$env{'ID'} not found",1);
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::210::db_name,
				'type' => 'a210_page',
				'id' => $env{'ID'}
			))
			{
				main::_log("removing from Elastic",1);
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::210::db_name,
					'type' => 'a210_page',
					'id' => $env{'ID'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %page=$sth0{'sth'}->fetchhash();
		
#		$org{'name_short'}=[$org{'name_short'}]
#			if $org{'name_short'};
		
		foreach (keys %page)
		{
			delete $page{$_} unless $page{$_};
		}
		
		%{$page{'metahash'}}=App::020::functions::metadata::parse($page{'metadata'});
		delete $page{'metadata'};
		
		foreach (grep {not defined $page{$_}} keys %page)
		{
			delete $page{$_};
		}
		
		foreach my $sec(keys %{$page{'metahash'}})
		{
			if ($sec=~/\./)
			{
				my $sec_=$sec;$sec_=~s|\.|-|g;
				$page{'metahash'}{$sec_}=$page{'metahash'}{$sec};
				delete $page{'metahash'}{$sec};
				$sec=$sec_;
			}
			foreach my $var(keys %{$page{'metahash'}{$sec}})
			{
				if ($var=~/\./)
				{
					my $var_=$var;$var_=~s|\.|-|g;
					$page{'metahash'}{$sec}{$var_}=$page{'metahash'}{$sec}{$var};
					delete $page{'metahash'}{$sec}{$var};
					next;
				}
			}
		}
		
		foreach my $sec(keys %{$page{'metahash'}})
		{
			foreach (keys %{$page{'metahash'}{$sec}})
			{
				if (!$page{'metahash'}{$sec}{$_})
				{
					delete $page{'metahash'}{$sec}{$_};
					next
				}
				if ($_=~s/\[\]$//)
				{
					foreach my $val (split(';',$page{'metahash'}{$sec}{$_.'[]'}))
					{
						push @{$page{'metahash'}{$sec}{$_}},$val;
						push @{$page{'metahash'}{$sec}{$_.'_t'}},$val;
						
						if ($val=~/^[0-9]{1,9}$/)
						{
							push @{$page{'metahash'}{$sec}{$_.'_i'}},$val;
						}
						if ($val=~/^[0-9\.]{1,9}$/ && (not $val=~/\..*?\./))
						{
							push @{$page{'metahash'}{$sec}{$_.'_f'}},$val;
						}
						
					}
					#push @{$page->{'metahash_keys'}},$sec.'.'.$_ ;
					delete $page{'metahash'}{$sec}{$_.'[]'};
					next;
				}
				
				if ($page{'metahash'}{$sec}{$_}=~/^[0-9]{1,9}$/)
				{
					$page{'metahash'}{$sec}{$_.'_i'} = $page{'metahash'}{$sec}{$_};
				}
				if ($page{'metahash'}{$sec}{$_}=~/^[0-9\.]{1,9}$/ && (not $page{'metahash'}{$sec}{$_}=~/\..*?\./))
				{
					$page{'metahash'}{$sec}{$_.'_f'} = $page{'metahash'}{$sec}{$_};
				}
			}
		}
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		$Elastic->index(
			'index' => 'cyclone3.'.$App::210::db_name,
			'type' => 'a210_page',
			'id' => $env{'ID'},
			'body' => {
				%page,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
		
	}

	$t->close();
}

1;
