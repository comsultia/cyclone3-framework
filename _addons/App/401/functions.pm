#!/bin/perl
package App::401::functions;

=head1 NAME

App::401::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::401::_init|app/"401/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::401::_init;
use TOM::Security::form;
use Time::HiRes qw(usleep);

our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head2 article_add()

Adds new article to category, or updates old article

Add new article (uploading new content)

 article_add
 (
   'article.ID' => '',
   'article.ID_entity' => '',
   'article_ent.ID_author' => '',
   'article_attrs.ID_category' => '',
   'article_attrs.name' => '',
   'article_attrs.lng' => '',
   'article_content.ID_editor' => '',
   'article_content.subtitle' => '',
   'article_content.mimetype' => '',
   'article_content.abstract' => '',
   'article_content.body' => '',
   #'article_content.keywords' => '',
   'article_content.lng' => '',
 );

Add new symlink to article in another directory (or the same with another name)

 article_add
 (
   'article.ID_entity' => '',
   'article_attrs.ID_category' => '',
 );

Move article to another directory (new ID of category for symlink defined)

 article_add
 (
   'article.ID' => '',
   'article_attrs.ID_category' => '',
 );

=cut

sub article_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::article_add()",'timer'=>1);
	
	$env{'article_content.mimetype'}="text/html" unless $env{'article_content.mimetype'};
	
	my $content_updated=0; # boolean if important content attributes was updated
	
	# detect language
	my %article_cat;
	if ($env{'article_attrs.ID_category'})
	{
		# detect language
		%article_cat=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_attrs.ID_category'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_cat",
			'columns' => {'*'=>1}
		);
		$env{'article_attrs.lng'}=$article_cat{'lng'};
		main::_log("setting lng='$env{'article_attrs.lng'}' from article_attrs.ID_category='$env{'article_attrs.ID_category'}'");
	}
	
	$env{'article_attrs.lng'}=$tom::lng unless $env{'article_attrs.lng'};
	main::_log("lng='$env{'article_attrs.lng'}'");
	
	# ARTICLE
	
	my %article;
	if ($env{'article.ID'})
	{
		# detect language
		%article=App::020::SQL::functions::get_ID(
			'ID' => $env{'article.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article",
			'columns' => {'*'=>1}
		);
		$env{'article.ID_entity'}=$article{'ID_entity'} if $article{'ID_entity'};
	}
	
#	if (!$env{'article.ID'})
#	{
#		$env{'article.ID'}=$article{'ID'} if $article{'ID'};
#	}
	
	
	# check if this symlink with same ID_category not exists
	# and article.ID is unknown
	if ($env{'article_attrs.ID_category'} && !$env{'article.ID'} && $env{'article.ID_entity'} && !$env{'forcesymlink'})
	{
		main::_log("\$env{'article_attrs.ID_category'} && !\$env{'article.ID'} && \$env{'article.ID_entity'} -> search for article.ID");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::401::db_name`.`a401_article_view`
			WHERE
				ID_entity_article=$env{'article.ID_entity'} AND
				( ID_category = $env{'article_attrs.ID_category'} OR ID_category IS NULL ) AND
				status IN ('Y','N','L')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		if ($db0_line{'ID'})
		{
			$env{'article.ID'}=$db0_line{'ID_article'};
			$env{'article_attrs.ID'}=$db0_line{'ID_attrs'};
			main::_log("setup article.ID='$db0_line{'ID_article'}'");
		}
	}
	
	if (!$article{'ID'} && $env{'article.ID_entity'})
	{
		# check if this article exists
		# - not necessary :)
	}
	
	main::_log("status article.ID='$env{'article.ID'}' article.ID_entity='$env{'article.ID_entity'}'");
	
	
	if (!$env{'article.ID'})
	{
		# generating new article!
		main::_log("adding new regular article");
		
		my %columns;
		$columns{'ID_entity'}=$env{'article.ID_entity'} if $env{'article.ID_entity'};
		
		$env{'article.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article",
			'columns' =>
			{
				%columns,
			},
			'-journalize' => 1,
		);
		
		main::_log("generated article ID='$env{'article.ID'}'");
		$content_updated=1;
	}
	
	
	if (!$env{'article.ID_entity'})
	{
		if ($article{'ID_entity'})
		{
			$env{'article.ID_entity'}=$article{'ID_entity'};
		}
		elsif ($env{'article.ID'})
		{
			%article=App::020::SQL::functions::get_ID(
				'ID' => $env{'article.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article",
				'columns' => {'*'=>1}
			);
			$env{'article.ID_entity'}=$article{'ID_entity'};
		}
		else
		{
			die "ufff\n";
		}
	}
	
	if (!$env{'article.ID_entity'})
	{
		die "ufff, missing article.ID_entity\n";
	}
	
	
	# ARTICLE_ATTRS
	
	my %article_attrs;
	if (!$env{'article_attrs.ID'})
	{
		main::_log("!\$env{'article_attrs.ID'} -> SELECT");
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::401::db_name`.`a401_article_attrs`
			WHERE
				ID_entity='$env{'article.ID'}' AND
				lng='$env{'article_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_attrs=$sth0{'sth'}->fetchhash();
		$env{'article_attrs.ID'}=$article_attrs{'ID'};
	}
	if (!$env{'article_attrs.ID'})
	{
		main::_log("!\$env{'article_attrs.ID'} -> new()");
		# create one language representation of article in content structure
		my %columns;
		$columns{'ID_category'}=$env{'article_attrs.ID_category'} if $env{'article_attrs.ID_category'};
		$columns{'datetime_start'}="'".$env{'article_attrs.datetime_start'}."'" if $env{'article_attrs.datetime_start'};
		$columns{'datetime_start'}="NOW()" unless $columns{'datetime_start'};
		
		$env{'article_attrs.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_attrs",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID'},
#				'order_id' => $order_id,
				'lng' => "'$env{'article_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
	}
	if ($env{'article_attrs.ID'} && !$article_attrs{'ID_category'})
	{
		main::_log("\$env{'article_attrs.ID'} && !\$article_attrs{'ID_category'} -> get_ID()");
		%article_attrs=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_attrs.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_attrs",
			'columns' => {'*'=>1}
		);
	}
	
	main::_log("$env{'article_attrs.ID'} ($env{'article_attrs.status'} && ($env{'article_attrs.status'} ne $article_attrs{'status'}))");
	
	# update if necessary
	if ($env{'article_attrs.ID'})
	{
		my %columns;
		# name
		$columns{'name'}="'".TOM::Security::form::sql_escape($env{'article_attrs.name'})."'"
			if ($env{'article_attrs.name'} && ($env{'article_attrs.name'} ne $article_attrs{'name'}));
		# name_url
		$columns{'name_url'}="'".TOM::Security::form::sql_escape(TOM::Net::URI::rewrite::convert($env{'article_attrs.name'}))."'"
			if ($env{'article_attrs.name'} && ($env{'article_attrs.name'} ne $article_attrs{'name'}));
		# ID_category
		$columns{'ID_category'}=$env{'article_attrs.ID_category'}
			if ($env{'article_attrs.ID_category'} && ($env{'article_attrs.ID_category'} ne $article_attrs{'ID_category'}));
		# datetime_start
		$columns{'datetime_start'}="'".$env{'article_attrs.datetime_start'}."'"
			if ($env{'article_attrs.datetime_start'} && ($env{'article_attrs.datetime_start'} ne $article_attrs{'datetime_start'}));
		# datetime_stop
		if (exists $env{'article_attrs.datetime_stop'} && ($env{'article_attrs.datetime_stop'} ne $article_attrs{'datetime_stop'}))
		{
			if (!$env{'article_attrs.datetime_stop'})
			{
				$columns{'datetime_stop'}="NULL";
			}
			else
			{
				$columns{'datetime_stop'}="'".$env{'article_attrs.datetime_stop'}."'";
			}
		}
		# status
		$columns{'status'}="'".TOM::Security::form::sql_escape($env{'article_attrs.status'})."'"
			if ($env{'article_attrs.status'} && ($env{'article_attrs.status'} ne $article_attrs{'status'}));
		# priority_A
		$columns{'priority_A'}="'".$env{'article_attrs.priority_A'}."'"
			if (exists $env{'article_attrs.priority_A'} && ($env{'article_attrs.priority_A'} ne $article_attrs{'priority_A'}));
		$columns{'priority_A'}="NULL" if $columns{'priority_A'} eq "''";
		# priority_B
		$columns{'priority_B'}="'".$env{'article_attrs.priority_B'}."'"
			if (exists $env{'article_attrs.priority_B'} && ($env{'article_attrs.priority_B'} ne $article_attrs{'priority_B'}));
		$columns{'priority_B'}="NULL" if $columns{'priority_B'} eq "''";
		
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'article_attrs.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_attrs",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
	}
	
	# ARTICLE_CONTENT
	
	my %article_content;
	if (!$env{'article_content.ID'})
	{
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::401::db_name`.`a401_article_content`
			WHERE
				ID_entity='$env{'article.ID_entity'}' AND
				lng='$env{'article_attrs.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_content=$sth0{'sth'}->fetchhash();
		$env{'article_content.ID'}=$article_content{'ID'};
	}
	if (!$env{'article_content.ID'})
	{
		# create one language representation of article
		my %columns;
		
		$env{'article_content.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_content",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID_entity'},
				'lng' => "'$env{'article_attrs.lng'}'",
			},
			'-journalize' => 1,
		);
		$content_updated=1;
	}
	
	# get article_content
	if ($env{'article_content.ID'} && !$article_content{'body'})
	{
		%article_content=App::020::SQL::functions::get_ID(
			'ID' => $env{'article_content.ID'},
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_content",
			'columns' => {'*'=>1}
		);
	}
	
	# generate keywords
	$env{'article_content.keywords'}=(split('#',$env{'article_content.keywords'}))[1] if ($env{'article_content.keywords'}=~/#/);
	
	if (exists $env{'article_content.keywords'})
	{
		my @ref=split('#',$article_content{'keywords'});
		$ref[1]=$env{'article_content.keywords'};
		1 while ($ref[0]=~s|^ ||);1 while ($ref[1]=~s|^ ||);
		1 while ($ref[0]=~s| $||);1 while ($ref[1]=~s| $||);
		$env{'article_content.keywords'}=$ref[0].' # '.$ref[1];
	}
	else {$env{'article_content.keywords'}=$article_content{'keywords'};}
	if ( $env{'article_content.abstract'} || $env{'article_content.body'})
	{
		my @ref=split('#',$env{'article_content.keywords'});
		$ref[0]='';
		my %keywords=article_content_extract_keywords(%env);
		foreach (keys %keywords)
		{$ref[0].=", ".$_;}
		$ref[0]=~s|^, ||;
		1 while ($ref[0]=~s|^ ||);1 while ($ref[1]=~s|^ ||);
		1 while ($ref[0]=~s| $||);1 while ($ref[1]=~s| $||);
		$env{'article_content.keywords'}=$ref[0].' # '.$ref[1];
	}
	$env{'article_content.keywords'}='' if ($env{'article_content.keywords'} eq ' # ');
	$env{'article_content.keywords'}=~s|^[ ]?#[ ]?||;
	
	# update if necessary
	if ($env{'article_content.ID'})
	{
		my %columns;
		$columns{'subtitle'}="'".TOM::Security::form::sql_escape($env{'article_content.subtitle'})."'"
			if (exists $env{'article_content.subtitle'} && ($env{'article_content.subtitle'} ne $article_content{'subtitle'}));
		$columns{'mimetype'}="'".TOM::Security::form::sql_escape($env{'article_content.mimetype'})."'"
			if ($env{'article_content.mimetype'} && ($env{'article_content.mimetype'} ne $article_content{'mimetype'}));
		$columns{'abstract'}="'".TOM::Security::form::sql_escape($env{'article_content.abstract'})."'"
			if ($env{'article_content.abstract'} && ($env{'article_content.abstract'} ne $article_content{'abstract'}));
		$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'article_content.keywords'})."'"
			if (exists $env{'article_content.keywords'} && ($env{'article_content.keywords'} ne $article_content{'keywords'}));
		$columns{'body'}="'".TOM::Security::form::sql_escape($env{'article_content.body'})."'"
			if ($env{'article_content.body'} && ($env{'article_content.body'} ne $article_content{'body'}));
			
		if (keys %columns)
		{
			$env{'article_content.ID_editor'}=$main::USRM{'ID_user'} unless $env{'article_content.ID_editor'};
			$columns{'ID_editor'}="'".$env{'article_content.ID_editor'}."'";
			App::020::SQL::functions::update(
				'ID' => $env{'article_content.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_content",
				'columns' => {%columns},
				'-journalize' => 1
			);
			$content_updated=1;
		}
	}
	
	# ARTICLE_ENT
	
	my %article_ent;
	if (!$env{'article_ent.ID_entity'})
	{
		#main::_log("!\$env{'article_ent.ID_entity'}, loading article_ent");
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::401::db_name`.`a401_article_ent`
			WHERE
				ID_entity='$env{'article.ID_entity'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%article_ent=$sth0{'sth'}->fetchhash();
		$env{'article_ent.ID_entity'}=$article_ent{'ID_entity'};
		$env{'article_ent.ID'}=$article_ent{'ID'};
	}
	if (!$env{'article_ent.ID_entity'})
	{
		# create one entity representation of article
		my %columns;
		#main::_log("!\$env{'article_ent.ID_entity'}, creating article_ent");
		$env{'article_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::401::db_name,
			'tb_name' => "a401_article_ent",
			'columns' =>
			{
				%columns,
				'ID_entity' => $env{'article.ID_entity'},
			},
			'-journalize' => 1,
		);
	}
	
	#main::_log("\$env{'article_ent.ID_entity'}=$env{'article_ent.ID_entity'} \$env{'article_ent.posix_owner'}=$env{'article_ent.posix_owner'}");
	if (!$article_ent{'posix_owner'} && !$env{'article_ent.posix_owner'})
	{
		$env{'article_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update if necessary
	if ($env{'article_ent.ID'})
	{
		my %columns;
		$columns{'ID_author'}="'".$env{'article_ent.ID_author'}."'"
			if ($env{'article_ent.ID_author'} && ($env{'article_ent.ID_author'} ne $article_ent{'ID_author'}));
		$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'article_ent.posix_owner'})."'"
			if ($env{'article_ent.posix_owner'} && ($env{'article_ent.posix_owner'} ne $article_ent{'posix_owner'}));
		$columns{'sources'}="'".TOM::Security::form::sql_escape($env{'article_ent.sources'})."'"
			if (exists $env{'article_ent.sources'} && ($env{'article_ent.sources'} ne $article_ent{'sources'}));
		$columns{'visits'}="'".TOM::Security::form::sql_escape($env{'article_ent.visits'})."'"
			if (exists $env{'article_ent.visits'} && ($env{'article_ent.visits'} ne $article_ent{'visits'}));
		$columns{'rating_score'}="'".TOM::Security::form::sql_escape($env{'article_ent.rating_score'})."'"
			if (exists $env{'article_ent.rating_score'} && ($env{'article_ent.rating_score'} ne $article_ent{'rating_score'}));
		$columns{'rating_votes'}="'".TOM::Security::form::sql_escape($env{'article_ent.rating_votes'})."'"
			if (exists $env{'article_ent.rating_votes'} && ($env{'article_ent.rating_votes'} ne $article_ent{'rating_votes'}));
		$columns{'rating'}="'".TOM::Security::form::sql_escape($env{'article_ent.rating'})."'"
			if (exists $env{'article_ent.rating'} && ($env{'article_ent.rating'} ne $article_ent{'rating'}));
		if (keys %columns)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'article_ent.ID'},
				'db_h' => "main",
				'db_name' => $App::401::db_name,
				'tb_name' => "a401_article_ent",
				'columns' => {%columns},
				'-journalize' => 1
			);
		}
	}
	
	if ($content_updated)
	{
		App::020::SQL::functions::_save_changetime({'db_h'=>'main','db_name'=>$App::401::db_name,'tb_name'=>'a401_article','ID_entity'=>$env{'article.ID_entity'}});
	}
	
	$t->close();
	return %env;
}



=head2 article_content_extract_keywords()

Extracts keywords from article_content.abstract/body

 article_content_extract_keywords
 (
   'article_content.mimetype' => '',
   'article_content.abstract' => '',
   'article_content.body' => '',
 );

=cut

sub article_content_extract_keywords
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::article_content_extract_keywords()") if $debug;
	$env{'article_content.mimetype'}="text/html" unless $env{'article_content.mimetype'};
	
	my %keywords;
	
	if ($env{'article_content.mimetype'}="text/html")
	{
		%keywords=App::401::keywords::html_extract($env{'article_content.abstract'}.' '.$env{'article_content.body'});
	}
	
	
	foreach (keys %keywords)
	{
		#main::_log("key $_");
	}
	
	
	$t->close() if $debug;
	return %keywords;
}


sub article_item_info
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::article_item_info()");
	
	my $sql_where;
	if ($env{'article_attrs.ID_category'} eq 'NULL'){$sql_where='ID_category IS NULL';}
	else {$sql_where="ID_category = $env{'article_attrs.ID_category'}";}
	my $sql=qq{
		SELECT
			view.*,
			IF
			(
				(SELECT COUNT(*) FROM `$App::401::db_name`.a401_article_view WHERE ID_entity_article=view.ID_entity_article AND status IN ('Y','N')) > 1,
				'Y','N'
			) AS symlink,
			IF
			(
				(
					status LIKE 'Y' AND
					NOW() >= datetime_start AND
					(datetime_stop IS NULL OR NOW() <= datetime_stop)
				),
			 	'Y', 'N'
			) AS datetime_status
		FROM
			`$App::401::db_name`.a401_article_view AS view
		WHERE
			ID_article = '$env{'article.ID'}' AND
			$sql_where
		LIMIT
			1
	};
	
	my %data;
	
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>1);
	if ($sth0{'sth'})
	{
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			
			foreach (keys %db0_line){$data{'db_'.$_}=$db0_line{$_};}
			
			$data{'ID'}=$db0_line{'ID_article'};
			$data{'ID_entity'}=$db0_line{'ID_entity_article'};
			
			my %author=App::301::authors::get_author($db0_line{'posix_author'});
			($author{'fullname'},$author{'shortname'})=App::301::authors::get_fullname(%author);
			foreach (keys %author){$data{'author_'.$_}=$author{$_};}
			
			my %editor=App::301::authors::get_author($db0_line{'posix_editor'});
			($editor{'fullname'},$editor{'shortname'})=App::301::authors::get_fullname(%editor);
			foreach (keys %editor){$data{'editor_'.$_}=$editor{$_};}
			
			# check relations
			foreach my $relation (App::160::SQL::get_relations(
				'db_name' => $App::401::db_name,
				'l_prefix' => 'a401',
				'l_table' => 'article',
				'l_ID_entity' => $db0_line{'ID_entity_article'},
#				'rel_type' => $env{'rel_type'},
#				'r_prefix' => "a501",
#				'r_table' => "image",
				'status' => "Y"
			))
			{
				if ($relation->{'r_prefix'} eq "a542" && $relation->{'r_table'} eq "file" && $relation->{'rel_type'} eq "attachment")
				{$data{'attachment_status'}='Y';next};
				if ($relation->{'r_prefix'} eq "a821" && $relation->{'r_table'} eq "discussion" && $relation->{'rel_type'} eq "discussion")
				{$data{'discussion_status'}='Y';next};
				$data{'relation_status'}='Y';
			}
			
			# check relations
			if ($db0_line{'keywords'}){$data{'keywords_status'}='Y';}
			
			$data{'size'}=TOM::Text::format::bytes(length($db0_line{'abstract'}.$db0_line{'body'}));
			
		}
		
	}
	else
	{
		main::_log("can't select",1);
	}
	
	$t->close();
	return %data;
}


=head2 article_visit()

Increase number of article visits

=cut

sub article_visit
{
	my $ID_entity=shift;
	
	# check if this visit is in article
	my $cache={};
	$cache=$Ext::CacheMemcache::cache->get(
		'namespace' => $App::401::db_name.".a401_article_ent.visit",
		'key' => $ID_entity
	) if $TOM::CACHE_memcached;
	if (!$cache->{'time'} && $TOM::CACHE_memcached)# try again when memcached sends empty key (bug)
	{
		usleep(3000); # 3 miliseconds
		$cache=$Ext::CacheMemcache::cache->get(
			'namespace' => $App::401::db_name.".a401_article_ent.visit",
			'key' => $ID_entity
		);
	}
	
	if (!$cache->{'time'})
	{
		$cache->{'visits'}=1;
		$Ext::CacheMemcache::cache->set
		(
			'namespace' => $App::401::db_name.".a401_article_ent.visit",
			'key' => $ID_entity,
			'value' =>
			{
				'time' => time(),
				'visits' => $cache->{'visits'}
			},
			'expiration' => "24H"
		) if $TOM::CACHE_memcached;
		# update SQL
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::401::db_name`.a401_article_ent
			SET visits=visits+1
			WHERE ID_entity=$ID_entity
			LIMIT 1
		},'quiet'=>1) unless $TOM::CACHE_memcached;
		return 1;
	}
	
	# return unless memcached available
	return 1 unless $TOM::CACHE_memcached;
	
	$cache->{'visits'}++;
	
	my $old=time()-$cache->{'time'};
	
	if ($old > (60*10))
	{
		# update database
		TOM::Database::SQL::execute(qq{
			UPDATE `$App::401::db_name`.a401_article_ent
			SET visits=visits+$cache->{'visits'}
			WHERE ID_entity=$ID_entity
			LIMIT 1
		},'quiet'=>1);
		$cache->{'visits'}=0;
		$cache->{'time'}=time();
	}
	
	$Ext::CacheMemcache::cache->set
	(
		'namespace' => $App::401::db_name.".a401_article_ent.visit",
		'key' => $ID_entity,
		'value' =>
		{
			'time' => $cache->{'time'},
			'visits' => $cache->{'visits'}
		},
		'expiration' => "24H"
	) if $TOM::CACHE_memcached;
	
	return 1;
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
