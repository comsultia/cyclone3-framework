#!/bin/perl
package App::020::SQL::functions::tree;

=head1 NAME

App::020::SQL::functions::tree

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


use TOM::Net::URI::rewrite;
use App::020::functions::charindex;

=head1 FUNCTIONS

=head2 new()

Vytvori novy zaznam v tabulke

=cut

sub new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::new()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# automaticka zamena name na name_url
	if (!$env{'columns'}{'name_url'})
	{
		$env{'columns'}{'name'}=~s|^'||;
		$env{'columns'}{'name'}=~s|'$||;
		$env{'columns'}{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'columns'}{'name'})."'";
		$env{'columns'}{'name'}="'".$env{'columns'}{'name'}."'";
		main::_log("create 'columns'->'name_url'='$env{'columns'}{'name_url'}'");
	}
	
	# najdem volny ID_charindex
	my $level=0; # default
	my $parent_ID_charindex;
	
	# pozriem sa na parent_ID
	if ($env{'parent_ID'})
	{
		my %data=App::020::SQL::functions::get_ID(
			'ID' => $env{'parent_ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'columns' =>
			{
				'ID_charindex' => 1
			}
		);
		if ($data{'ID'})
		{
			$parent_ID_charindex=$data{'ID_charindex'};
			main::_log("parent_ID_charindex='$parent_ID_charindex'");
		}
		else
		{
			main::_log("can't find parent ID='$env{'parent_ID'}'",1);
			$t->close();
			return undef;
		}
	}
	
	my $ID_charindex_new=find_new_child(
		$parent_ID_charindex,
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
	);
	
	$env{'columns'}{'ID_charindex'}="'".$ID_charindex_new."'";
	my $ID=App::020::SQL::functions::new(%env);
	
	$t->close();
	return $ID;
}


=head2 move_up()

Posunie záznam o položku vyššie. V preklade to znamená že nájde položku predchádzajúci a switchne sa s ňou.

=cut

sub move_up
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::move_up()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# vyberiem si tento zaznam z databazy
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {'ID_charindex'=>1}
	);
	if (!$data{'ID'})
	{
		$t->close();
		return undef;
	}
	
	if (not $data{'status'} =~ /^[YN]$/)
	{
		main::_log("only ID with status 'Y' or 'N' can be moved in tree, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	main::_log("ID='$env{'ID'}' has ID_charindex='$data{'ID_charindex'}'");
	
	my $ID_charindex=$data{'ID_charindex'};
	my $ID_charindex_=$data{'ID_charindex'};
	$ID_charindex_=~s|^(.*)...$|\1|;
	
	# najdem predchadzajucu polozku
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM `$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex < '$data{'ID_charindex'}'
			AND ID_charindex LIKE '$ID_charindex_\___'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_charindex DESC
		LIMIT 1
	};
	
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>0,'quiet'=>1);
	if ($sth0{'rows'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("higher ID='$db0_line{'ID'}' ID_charindex='$db0_line{'ID_charindex'}'");
			
			swap(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID1' => $env{'ID'},
				'ID2' => $db0_line{'ID'},
				'-journalize' => $env{'-journalize'},
			);
			
		}
	}
	else
	{
		main::_log("this ID='$env{ID}' is at top");
	}
	
	$t->close();
}


=head2 move_down()

Posunie záznam o položku nižšie. V preklade to znamená že nájde položku nižsiu a switchne sa s ňou.

=cut

sub move_down
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::move_down()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# vyberiem si tento zaznam z databazy
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {'ID_charindex'=>1}
	);
	if (!$data{'ID'})
	{
		$t->close();
		return undef;
	}
	
	if (not $data{'status'} =~ /^[YN]$/)
	{
		main::_log("only ID with status 'Y' or 'N' can be moved in tree, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	main::_log("ID='$env{'ID'}' has ID_charindex='$data{'ID_charindex'}'");
	
	my $ID_charindex=$data{'ID_charindex'};
	my $ID_charindex_=$data{'ID_charindex'};
	$ID_charindex_=~s|^(.*)...$|\1|;
	
	# najdem predchadzajucu polozku
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM `$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex > '$data{'ID_charindex'}'
			AND ID_charindex LIKE '$ID_charindex_\___'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_charindex ASC
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'log'=>0,'quiet'=>1);
	if ($sth0{'rows'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("lower ID='$db0_line{'ID'}' ID_charindex='$db0_line{'ID_charindex'}'");
			
			swap(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID1' => $env{'ID'},
				'ID2' => $db0_line{'ID'},
				'-journalize' => $env{'-journalize'},
			);
			
		}
	}
	else
	{
		main::_log("this ID='$env{ID}' is at bottom");
	}
	
	$t->close();
}



sub swap
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::swap()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my %data1=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID1'},
		'columns' => {'ID_charindex'=>1}
	);
	my %data2=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID2'},
		'columns' => {'ID_charindex'=>1}
	);
	if (!$data1{'ID'} || !$data2{'ID'})
	{
		main::_log("ID1 or ID2 can't be found in table",1);
		$t->close();
		return undef;
	}
	
	main::_log("swap ID='$data1{ID}' ID_charindex='$data1{'ID_charindex'}' => ID='$data2{ID}' ID_category='$data2{'ID_charindex'}'");
	
	my $ID_charindex=$data1{'ID_charindex'};
	$ID_charindex=~s|^(.*)...|\1\.\.\.|;
	main::_log("middle ID_charindex='$ID_charindex'");
	
	# ziskam zoznam vsetkych poloziek pod ID_charindex a zacnem ich menit na medziID_charindex '...'
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$data1{ID_charindex}%'
		ORDER BY
			ID_entity
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_c=$db1_line{'ID_charindex'};
			$ID_charindex_c=~s|^$data1{ID_charindex}|$ID_charindex|;
			
			main::_log("sub of ID_charindex='$data1{ID_charindex}' is ID='$db1_line{'ID'}' ID_charindex='$db1_line{'ID_charindex'}'=>'$ID_charindex_c'");
			
			App::020::SQL::functions::update(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $db1_line{'ID'},
#				'-journalize' => $env{'-journalize'},
				'columns' => {
					'ID_charindex' => "'$ID_charindex_c'"
				}
			);
		}
	}
	
	# zistam zoznam vsetkych poloziek pod $IDcharindex2
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$data2{ID_charindex}%'
		ORDER BY
			ID_entity
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_c=$db1_line{'ID_charindex'};
			$ID_charindex_c=~s|^$data2{ID_charindex}|$data1{ID_charindex}|;
			
			main::_log("sub of ID_charindex='$data2{ID_charindex}' is ID='$db1_line{'ID'}' ID_charindex='$db1_line{'ID_charindex'}'=>'$ID_charindex_c'");
			
			App::020::SQL::functions::update(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $db1_line{'ID'},
				'-journalize' => $env{'-journalize'},
				'columns' => {
					'ID_charindex' => "'$ID_charindex_c'"
				}
			);
		}
	}
	
	# zistam zoznam vsetkych poloziek pod $IDcharindex3
	my $SQL=qq{
		SELECT
			ID,
			ID_entity,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$ID_charindex%'
		ORDER BY
			ID_entity
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_c=$db1_line{'ID_charindex'};
			$ID_charindex_c=~s|^$ID_charindex|$data2{ID_charindex}|;
			
			main::_log("sub of ID_charindex='$ID_charindex' is ID='$db1_line{'ID'}' ID_charindex='$db1_line{'ID_charindex'}'=>'$ID_charindex_c'");
			
			App::020::SQL::functions::update(
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'ID' => $db1_line{'ID'},
				'-journalize' => $env{'-journalize'},
				'columns' => {
					'ID_charindex' => "'$ID_charindex_c'"
				}
			);
		}
	}
	
	$t->close();
	return 1;
}


=head2 move_to()

Presunie záznam pod inú položku.

=cut

sub move_to
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::move_to()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# vyberiem si tento zaznam z databazy
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' => {'ID_charindex'=>1}
	);
	if (!$data{'ID'})
	{
		$t->close();
		return undef;
	}
	
	if (not $data{'status'} =~ /^[YN]$/)
	{
		main::_log("only ID with status 'Y' or 'N' can be moved in tree, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	main::_log("ID='$env{'ID'}' has ID_charindex='$data{'ID_charindex'}'");
	
	# nacitanie informacii o novom parente (ak existuje)
	my %data2;
	if ($env{'parent_ID'})
	{
		%data2=App::020::SQL::functions::get_ID(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'ID' => $env{'parent_ID'},
			'columns' => {'ID_charindex'=>1}
		);
		if (!$data2{'ID'})
		{
			$t->close();
			return undef;
		}
		
		if (not $data2{'status'} =~ /^[YN]$/)
		{
			main::_log("only ID with status 'Y' or 'N' can be moved in tree, not status='$data2{'status'}'",1);
			$t->close();
			return undef;
		}
	}
	
	# zistenie ci novy parent nieje nahodou castou stromu sucasneho ID
	# ( zeby som chcel presunut seba pod seba )
	if ($data2{'ID_charindex'})
	{
		# 000:000 - $data->ID_charindex
		# 000:000:000 - $data2->ID_charindex
		if ($data2{'ID_charindex'}=~/^$data{'ID_charindex'}/)
		{
			main::_log("parent_ID is in ID tree !!!",1);
			$t->close();
			return undef;
		}
	}
	
	# najdem volny ID_charindex pod parent_ID	
	my $ID_charindex=find_new_child(
		$data2{'ID_charindex'},
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
	);
	
	main::_log("ID_charindex old='$data{'ID_charindex'}' new='$ID_charindex'");
	
	my $tr=new TOM::Database::SQL::transaction('db_h'=>"main");
	
	# vyhladam vsetky polozky ktore su ako sub stareho ID_charindex a updatnem ich
	# (vsetky = Y,N)
	my $SQL=qq{
		SELECT
			ID,
			ID_charindex
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$data{ID_charindex}%'
			AND (status='Y' OR status='N')
		ORDER BY
			ID_charindex
	};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		while (my %db0_line=$sth1{'sth'}->fetchhash())
		{
			my $ID_charindex_new=$db0_line{'ID_charindex'};
			$ID_charindex_new=~s|^$data{'ID_charindex'}|$ID_charindex|;
			main::_log("ID='$db0_line{'ID'}' ID_charindex='$db0_line{'ID_charindex'}'->'$ID_charindex_new'");
			
			my $out=App::020::SQL::functions::update(
				'ID'	=> $db0_line{'ID'},
				'db_h' => $env{'db_h'},
				'db_name' => $env{'db_name'},
				'tb_name' => $env{'tb_name'},
				'columns' =>
				{
					'ID_charindex' => "'$ID_charindex_new'",
				}
			);
			if (!$out)
			{
				main::_log("can't move",1);
				$tr->rollback();
				$t->close();
				return undef;
			}
			
		}
	}
	
	$tr->close();
	$t->close();
	return 1;
}


=head2 copy_to

Kopirovanie casti stromu do inej casti stromu

=cut

sub copy_to
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::copy_to()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# zistim co za polozku idem presunut
	my %data=App::020::SQL::functions::get_ID(
		'ID'	=> $env{'ID'},
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'columns' =>
		{
			'ID_charindex' => 1,
			'lng' => 1
		}
	);
	if (!$data{'ID'})
	{
		main::_log("ID='$env{ID}' not exists",1);
		$t->close();
		return undef;
	}
	
	# pozriem sa kam idem presunut
	my %data2=App::020::SQL::functions::get_ID(
		'ID'	=> $env{'parent_ID'},
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'columns' =>
		{
			'ID_charindex' => 1,
			'lng' => 1
		}
	);
	if ($data2{'ID'})
	{
		# zistim ci sa nepokusam prekopirovat nejaky jazyk do ineho jazyka
		if ($data{'lng'} ne $data2{'lng'})
		{
			main::_log("can't move, in parent_ID is different language",1);
			$t->close();
			return undef;
		}
	}
	
	# zistim ci cielovy ID_charindex nieje sucastou stromu ktory chcem kopirovat
	if ($data2{'ID_charindex'})
	{
		# 000:000 - $data->ID_charindex
		# 000:000:000 - $data2->ID_charindex
		if ($data2{'ID_charindex'}=~/^$data{'ID_charindex'}/)
		{
			main::_log("parent_ID is in ID tree !!!",1);
			$t->close();
			return undef;
		}
	}
	
	# najdem pod parent_ID volny ID_charindex
	my $ID_charindex_new=find_new_child(
		$data2{'ID_charindex'},
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
	);
	if (!$ID_charindex_new)
	{
		main::_log("can't find new ID_charindex");
		$t->close();
		return undef;
	}
	
	main::_log("new ID_charindex='$ID_charindex_new'");
	
	# zmapujem vsetky polozky stromu ID
	my $sql=qq{
		SELECT
			ID,
			ID_charindex
		FROM `$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex LIKE '$data{ID_charindex}%'
			AND lng='$data{'lng'}'
			AND ( status='Y' OR status='N' )
		ORDER BY
			ID_charindex
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'});
	if (!$sth0{'sth'})
	{
		main::_log("can't select ID tree",1);
		return undef;
	}
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $ID_charindex=$db0_line{'ID_charindex'};
		$ID_charindex=~s|^$data{ID_charindex}|$ID_charindex_new|;
		main::_log("ID='$db0_line{'ID'}' copy from ID_charindex='$db0_line{'ID_charindex'}'->'$ID_charindex'");
		
		App::020::SQL::functions::copy(
			'ID' => $db0_line{'ID'},
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'columns' =>
			{
				'ID_charindex' => "'$ID_charindex'",
			},
		);
		
	}
	
	$t->close();
	return 1;
}


=head2 get_path

Vypisanie cesty konkretnej polozky

=cut

sub get_path
{
	my $ID=shift;
	my @path;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::get_path('$ID')");
	
	my %data=App::020::SQL::functions::get_ID(
		'ID'	=> $ID,
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'columns' =>
		{
			'name' => 1,
			'name_url' => 1,
			'ID_charindex' => 1,
			'lng' => 1,
		}
	);
	
	if (!$data{'ID'})
	{
		main::_log("ID='$ID' not exists",1);
		$t->close();
		return undef;
	}
	
	unshift @path, {%data};
	
	my $parent=$data{'ID_charindex'};
	$parent=~s|^(.*)...$|\1|;
	$parent=~s|:$||;
	# hladam nody az po root
	while ($parent)
	{
		main::_log("find parent '$parent'");
		my $sql=qq{
			SELECT
				ID,
				ID_entity,
				ID_charindex,
				name,
				name_url,
				status
			FROM
				`$env{'db_name'}`.`$env{'tb_name'}`
			WHERE
				ID_charindex='$parent'
				AND lng='$data{'lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'quiet'=>1);
		if ($sth0{'rows'})
		{
			my %data2=$sth0{'sth'}->fetchhash();
			unshift @path, {%data2};
			$parent=$data2{'ID_charindex'};
			$parent=~s|^(.*)...$|\1|;
			$parent=~s|:$||;
		}
		else
		{
			last;
		}
	}
	
	$t->close();
	return @path;
}


=head2 find_new_child

Najdenie noveho ID_charindexu pre child

=cut

sub find_new_child
{
	my $ID_charindex=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::find_new_child('$ID_charindex')");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# ID_charindex_ - base pre novy ID_charindex
	my $ID_charindex_= $ID_charindex.':';
	$ID_charindex_=~s|^:||;
	
	# novy ID_charindex
	my $ID_charindex_new=$ID_charindex_;
	
	# hladam posledny child v tomto node podla ID_charindex_
	my $sql=qq{
	SELECT
		ID_charindex
	FROM `$env{'db_name'}`.`$env{'tb_name'}`
	WHERE
		ID_charindex LIKE '$ID_charindex_\___'
	ORDER BY ID_charindex DESC
	LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'quiet'=>1);
	if (!$sth0{'sth'})
	{
		$t->close();
		return undef;
	}
	if ($sth0{'rows'})
	{
		# idem vyratavat novy ID_charindex, pretoze tento nod ma child/y
		my %db0_line=$sth0{'sth'}->fetchhash();
		main::_log("last child of parent ID_charindex='$db0_line{ID_charindex}'");
		$db0_line{'ID_charindex'}=~/(...)$/;
		my $sub=$1;
		main::_log("ID_charindex chunk '$sub'++");
		# ratanie dalsieho ID_charindex
		my $idx=new App::020::functions::charindex('from'=>$sub);
		my $sub_increased=$idx->increase();
		main::_log("ID_charindex chunk '$sub_increased'");
		$ID_charindex_new.=$sub_increased;
	}
	else
	{
		# tento nod nema childy, takze "koncovka" noveho ID_charindex je 000
		$ID_charindex_new.='000';
	}
	$ID_charindex_new=~s|:$||;
	main::_log("new ID_charindex='$ID_charindex_new'");
	
	$t->close();
	return $ID_charindex_new;
}


=head2 find_path_url

Hladanie cesty

=cut

sub find_path_url
{
	my $path=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::find_path_url('$path')");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my @level=split('/',$path);
	my $levels=($path=~s|/|/|g);
	
	main::_log("levels=$levels");
	
	my $ID_charindex= '___:' x ($levels+1);
	$ID_charindex=~s|:$||;
	
	my $i=0;
	my @ID_charindex_find=('');
	foreach my $level_part (@level)
	{
		my $t_level=track TOM::Debug("level-$i");
		main::_log("part='$level_part'");
		
		my $i0=0;
		foreach my $way (@ID_charindex_find)
		{
			my $ID_charindex=$way;
			$ID_charindex.=":" if $ID_charindex;
			if ($way eq "-"){$i0++;next;}
			my $ll=($ID_charindex=~s|:|:|g);
			if ($ll==$i+1){$i0++;next;}
			
			my $t_way=track TOM::Debug("way-$i0");
			main::_log("ID_charindex='$way'");
			
			my $sql=qq{
				SELECT
					ID,
					ID_charindex
				FROM
					`$env{'db_name'}`.`$env{'tb_name'}`
				WHERE
					ID_charindex LIKE '$ID_charindex\___'
					AND name_url='$level[$i]'
					AND lng='$env{'lng'}'
					AND status='Y'
				ORDER BY
					ID_charindex
			};
			my %sth0=TOM::Database::SQL::execute($sql,'db_h'=>$env{'db_h'},'quiet'=>1);
			if (!$sth0{'sth'})
			{
				return undef;
			}
			
			if (!$sth0{'rows'})
			{
				$way="-";
				$t_way->close();
				next;
			}
			
			my $i2=0;
			while (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				if (!$i2)
				{
					$ID_charindex_find[$i0]=$db0_line{'ID_charindex'};
					main::_log("set way='$ID_charindex_find[$i0]'");
				}
				else
				{
					main::_log("new way='$db0_line{'ID_charindex'}'");
					push @ID_charindex_find,$db0_line{'ID_charindex'};
				}
				
				$i2++;
			}
			
			$i0++;
			$t_way->close();
		}
		$i++;
		$t_level->close();
	}
	
	foreach (@ID_charindex_find)
	{
		main::_log("out=$_");
	}
	
	my $SQL=qq{
		SELECT
			*
		FROM
			`$env{'db_name'}`.`$env{'tb_name'}`
		WHERE
			ID_charindex='$ID_charindex_find[0]'
			AND status='Y'
			AND lng='$env{lng}'};
	my %sth1=TOM::Database::SQL::execute($SQL,'db_h'=>$env{'db_h'},'quiet'=>1);
	if ($sth1{'rows'})
	{
		main::_log("only 1 output");
		my %data=$sth1{'sth'}->fetchhash();
		$t->close();
		return %data;
	}
	else
	{
		main::_log("can't be found",1);
		$t->close();
		return undef;
	}
	
	$t->close();
	return undef;
}


=head2 rename()

Premenujem dany zaznam

=cut

sub rename
{
	my $name=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::rename($name)");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	my $name_url=TOM::Net::URI::rewrite::convert($name);
	
	# zistim si nieco o polozke ktoru chcem premenovat
	my %data=App::020::SQL::functions::get_ID(
		'db_h' => $env{'db_h'},
		'db_name' => $env{'db_name'},
		'tb_name' => $env{'tb_name'},
		'ID' => $env{'ID'},
		'columns' =>
		{
			'status' => 1,
		}
	);
	
	if (!$data{ID})
	{
		main::_log("ID='$env{ID}' not exists",1);
		$t->close();
		return undef;
	}
	
	if ($data{status}=~/^[YN]$/)
	{
		# premenovanie
		App::020::SQL::functions::update(
			'db_h' => $env{'db_h'},
			'db_name' => $env{'db_name'},
			'tb_name' => $env{'tb_name'},
			'ID' => $env{'ID'},
			'-journalize' => $env{'-journalize'},
			'columns' => {
				'name'     => "'$name'",
				'name_url' => "'$name_url'"
			}
		);
	}
	else
	{
		main::_log("only ID with status 'Y' or 'N' can be renamed, not status='$data{'status'}'",1);
		$t->close();
		return undef;
	}
	
	# end track
	$t->close();
	return 1;
}


=head2 clone()

Vytvorenie mutacie nodu ( okrem podnodov )

=cut

sub clone
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::clone()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}
	
	# automaticka zamena name na name_url
	if (!$env{'columns'}{'name_url'})
	{
		$env{'columns'}{'name'}=~s|^'||;
		$env{'columns'}{'name'}=~s|'$||;
		$env{'columns'}{'name_url'}="'".TOM::Net::URI::rewrite::convert($env{'columns'}{'name'})."'";
		$env{'columns'}{'name'}="'".$env{'columns'}{'name'}."'";
		main::_log("create 'columns'->'name_url'='$env{'columns'}{'name_url'}'");
	}
	
	my $ID=App::020::SQL::functions::clone(%env);
	
	$t->close();
	return $ID;
}

1;
