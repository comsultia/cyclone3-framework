#!/bin/perl
package App::910::functions;

=head1 NAME

App::910::functions

=head1 DESCRIPTION



=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::910::_init|app/"910/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::910::_init;
use TOM::Security::form;
use App::160::SQL;
use Ext::Redis::_init;
use Ext::Elastic::_init;
use String::Diff;
use POSIX qw(ceil);

our $debug=0;
our $quiet;$quiet=1 unless $debug;
our $log_changes=$App::910::log_changes || undef;
#our $index_product_ent=$App::910::index_product_ent || undef;

=head2 product_add()

Adds new product to category, or updates old one

Add new product

 product_add
 (
   'product.product_number' => '',
	'product.status' => '', # Y/N/T
   'product_lng.lng' => '',
   'product_lng.name' => '',
	'product_lng.description' => '',
	'product_sym.ID' => '', # product_cat.ID_entity
 );

Change product number (displayed in catalog)

 product_add
 (
   'product.ID' => '',
   'product.product_number' => '',
 );
 
Create new product modification

 product_add
 (
   'product.ID_entity' => '',
   'product_lng.lng' => '',
	'product_lng.description' => '',
	'product_lng.metadata' => '',
 );
 
Create or update language version of product modification

 product_add
 (
   'product.ID' => '',
   'product_lng.lng' => '',
	'product_lng.description' => '',
	'product_lng.metadata' => '',
 );
 
Add new product symlink into category

 product_add
 (
   'product.ID_entity' => '',
   'product_sym.ID' => '', # product_cat.ID_entity
 );

=cut

sub product_add
{
	my %env=@_;
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::910::db_name});
	}
	my $t=track TOM::Debug(__PACKAGE__."::product_add()");
	
	$env{'product_sym.ID'} = $env{'product_cat.ID_entity'} if $env{'product_cat.ID_entity'};
	
	# PRODUCT AND PRODUCT MODIFICATION
	
	my %product;
	my $content_reindex;
	my $ent_reindex;
	
	if ($env{'product.ID'})
	{
		$env{'product.ID'}=$env{'product.ID'}+0;
		
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding product.ID_entity by product.ID='$env{'product.ID'}'");
		%product=App::020::SQL::functions::get_ID(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'*'=>1}
		);
		if ($product{'ID'})
		{
			main::_log("found product.ID_entity='$product{'ID_entity'}'");
			
			if ($env{'product.ID_entity'} && ($env{'product.ID_entity'} ne $product{'ID_entity'}))
			{
				main::_log("requested change ID_entity to '$env{'product.ID_entity'}'");
				
				App::020::SQL::functions::update(
					'ID' => $env{'product.ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product",
					'columns' => {'ID_entity' => $env{'product.ID_entity'}},
					'-posix' => 1,
				);
				# reindex old ID_entity
				_product_ent_index('ID_entity'=>$product{'ID_entity'}, 'commit' => $env{'commit'}, '-jobify' => 0)
					if $App::910::index_product_ent;
				
				%product=App::020::SQL::functions::get_ID(
					'ID' => $env{'product.ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product",
					'columns' => {'*'=>1}
				);
				
				$content_reindex=1;
				
#				return 1;
			}
			
			$env{'product.ID_entity'}=$product{'ID_entity'};
			$env{'product.product_number'}=$product{'product_number'}
				unless $env{'product.product_number'};
			
		}
		else
		{
			undef $env{'product.ID_entity'}; # ID_entity has lower priority as ID
			
			main::_log("not found product.ID, undef",1);
#			exit;
			#undef $env{'product.ID'};
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product",
				'columns' => {
					'ID' => $env{'product.ID'},
					'product_number' => "'".TOM::Security::form::sql_escape($env{'product.product_number'})."'", # if defined
					'datetime_publish_start' => 'NOW()'
				},
				'-journalize' => 1,
			);
			%product=App::020::SQL::functions::get_ID(
				'ID' => $env{'product.ID'},
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product",
				'columns' => {'*'=>1}
			);
			$env{'product.ID_entity'}=$product{'ID_entity'};
		}
	}
	
	# find product by product_number
	if (!$env{'product.ID'} && ($env{'product.product_number'} && !$env{'product.product_number.dontcheck'}))
	{
#		exit;
		# check if this product_number not already used by another product
		my $sql=qq{
			SELECT
				ID,
				ID_entity
			FROM
				`$App::910::db_name`.a910_product
			WHERE
				product_number='$env{'product.product_number'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %db0_line=$sth0{'sth'}->fetchhash();
		$env{'product.ID'} = $db0_line{'ID'} if $db0_line{'ID'};
		$env{'product.ID_entity'} = $db0_line{'ID_entity'} if $db0_line{'ID_entity'};
		%product=App::020::SQL::functions::get_ID(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'*'=>1}
		);
		main::_log("found product.ID='$env{'product.ID'}'");
	}
	
	if (!$env{'product.ID'}) # if modification not defined, create a new
	{
		main::_log("!product.ID, create product.ID (product.ID_entity='$env{'product.ID_entity'}')");
#		exit;
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID_entity'} if $env{'product.ID_entity'};
		$env{'product.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {%columns,'datetime_publish_start' => 'NOW()'},
			'-journalize' => 1,
		);
		App::020::SQL::functions::update(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'product_number'=>"'N".$env{'product.ID'}."'"},
			'-posix' => 1,
		);
		%product=App::020::SQL::functions::get_ID(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {'*'=>1}
		);
		$env{'product.ID'}=$product{'ID'};
		$env{'product.ID_entity'}=$product{'ID_entity'};
		$content_reindex=1;
	}
	
	main::_log("product.ID='$product{'ID'}' product.ID_entity='$product{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	# EAN
	$columns{'EAN'}="'".TOM::Security::form::sql_escape($env{'product.EAN'})."'"
		if (exists $env{'product.EAN'} && ($env{'product.EAN'} ne $product{'EAN'}));
	# product_number
	$columns{'product_number'}="'".TOM::Security::form::sql_escape($env{'product.product_number'})."'"
		if ($env{'product.product_number'} && ($env{'product.product_number'} ne $product{'product_number'}));
	# ref_ID
	$columns{'ref_ID'}="'".TOM::Security::form::sql_escape($env{'product.ref_ID'})."'"
		if (exists $env{'product.ref_ID'} && ($env{'product.ref_ID'} ne $product{'ref_ID'}));
	# amount
	$columns{'amount'}="'".TOM::Security::form::sql_escape($env{'product.amount'})."'"
		if (exists $env{'product.amount'} && ($env{'product.amount'} ne $product{'amount'}));
	# amount_unit
	$columns{'amount_unit'}="'".TOM::Security::form::sql_escape($env{'product.amount_unit'})."'"
		if (exists $env{'product.amount_unit'} && ($env{'product.amount_unit'} ne $product{'amount_unit'}));
	# amount_availability
	$columns{'amount_availability'}="'".TOM::Security::form::sql_escape($env{'product.amount_availability'})."'"
		if (exists $env{'product.amount_availability'} && ($env{'product.amount_availability'} ne $product{'amount_availability'}));
	# amount_limit
	$columns{'amount_limit'}="'".TOM::Security::form::sql_escape($env{'product.amount_limit'})."'"
		if (exists $env{'product.amount_limit'} && ($env{'product.amount_limit'} ne $product{'amount_limit'}));
	# amount_order_min
	$columns{'amount_order_min'}="'".TOM::Security::form::sql_escape($env{'product.amount_order_min'})."'"
		if ($env{'product.amount_order_min'} && ($env{'product.amount_order_min'} ne $product{'amount_order_min'}));
	# amount_order_max
	$columns{'amount_order_max'}="'".TOM::Security::form::sql_escape($env{'product.amount_order_max'})."'"
		if (exists $env{'product.amount_order_max'} && ($env{'product.amount_order_max'} ne $product{'amount_order_max'}));
	# amount_order_div
	$columns{'amount_order_div'}="'".TOM::Security::form::sql_escape($env{'product.amount_order_div'})."'"
		if (exists $env{'product.amount_order_div'} && ($env{'product.amount_order_div'} ne $product{'amount_order_div'}));
	# price
	$env{'product.price'}=sprintf("%.3f",$env{'product.price'}) if $env{'product.price'};
	$env{'product.price'}='' if $env{'product.price'} eq "0.000";
	$columns{'price'}="'".TOM::Security::form::sql_escape($env{'product.price'})."'"
		if (exists $env{'product.price'} && ($env{'product.price'} ne $product{'price'}));
	$columns{'price'}='NULL' if $columns{'price'} eq "''";
	# price_previous
	$env{'product.price_previous'}=sprintf("%.3f",$env{'product.price_previous'}) if exists $env{'product.price_previous'};
	$env{'product.price_previous'}='' if $env{'product.price_previous'} eq "0.000";
	$columns{'price_previous'}="'".TOM::Security::form::sql_escape($env{'product.price_previous'})."'"
		if (exists $env{'product.price_previous'} && ($env{'product.price_previous'} ne $product{'price_previous'}));
	$columns{'price_previous'}='NULL' if $columns{'price_previous'} eq "''";
	# price_max
	$env{'product.price_max'}='' if $env{'product.price_max'} eq "0.000";
	$columns{'price_max'}="'".TOM::Security::form::sql_escape($env{'product.price_max'})."'"
		if (exists $env{'product.price_max'} && ($env{'product.price_max'} ne $product{'price_max'}));
	$columns{'price_max'}='NULL' if $columns{'price_max'} eq "''";
	# price_currency
	$columns{'price_currency'}="'".TOM::Security::form::sql_escape($env{'product.price_currency'})."'"
		if ($env{'product.price_currency'} && ($env{'product.price_currency'} ne $product{'price_currency'}));
	# datetime_process
	$columns{'datetime_process'}="'".TOM::Security::form::sql_escape($env{'product.datetime_process'})."'"
		if ($env{'product.datetime_process'} && ($env{'product.datetime_process'} ne $product{'datetime_process'}));
	$columns{'datetime_process'}="NULL" if $env{'product.datetime_process'} eq "NULL";
	# datetime_next_index
	$columns{'datetime_next_index'}="'".TOM::Security::form::sql_escape($env{'product.datetime_next_index'})."'"
		if (exists $env{'product.datetime_next_index'} && ($env{'product.datetime_next_index'} ne $product{'datetime_next_index'}));
	$columns{'datetime_next_index'}="NULL" if $columns{'datetime_next_index'} eq "''";
	# datetime_publish_start
	$columns{'datetime_publish_start'}="'".TOM::Security::form::sql_escape($env{'product.datetime_publish_start'})."'"
		if ($env{'product.datetime_publish_start'} && ($env{'product.datetime_publish_start'} ne $product{'datetime_publish_start'}));
	# datetime_publish_stop
	if ($env{'product.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'}="'".TOM::Security::form::sql_escape($env{'product.datetime_publish_stop'})."'"
			if ($env{'product.datetime_publish_stop'} && ($env{'product.datetime_publish_stop'} ne $product{'datetime_publish_stop'}));
	}
	elsif (exists $env{'product.datetime_publish_stop'})
	{
		$columns{'datetime_publish_stop'} = "NULL"
			if ($env{'product.datetime_publish_stop'} ne $product{'datetime_publish_stop'});
	}

	# supplier_org
	$columns{'supplier_org'}="'".TOM::Security::form::sql_escape($env{'product.supplier_org'})."'"
		if (exists $env{'product.supplier_org'} && ($env{'product.supplier_org'} ne $product{'supplier_org'}));
	$columns{'supplier_org'}='NULL' if $columns{'supplier_org'} eq "''";

	# supplier_person
	$columns{'supplier_person'}="'".TOM::Security::form::sql_escape($env{'product.supplier_person'})."'"
		if (exists $env{'product.supplier_person'} && ($env{'product.supplier_person'} ne $product{'supplier_person'}));
	
	# metadata
	my %metadata=App::020::functions::metadata::parse($product{'metadata'});
	
	foreach my $section(split(';',$env{'product.metadata.override_sections'}))
	{
		delete $metadata{$section};
	}
	
	if ($env{'product.metadata.replace'})
	{
		if (!ref($env{'product.metadata'}) && $env{'product.metadata'})
		{
			%metadata=App::020::functions::metadata::parse($env{'product.metadata'});
		}
		if (ref($env{'product.metadata'}) eq "HASH")
		{
			%metadata=%{$env{'product.metadata'}};
		}
	}
	else
	{
		if (!ref($env{'product.metadata'}) && $env{'product.metadata'})
		{
			# when metadata send as <metatree></metatree> then always replace
			%metadata=App::020::functions::metadata::parse($env{'product.metadata'});
#			my %metadata_=App::020::functions::metadata::parse($env{'product.metadata'});
#			delete $env{'product.metadata'};
#			%{$env{'product.metadata'}}=%metadata_;
		}
		if (ref($env{'product.metadata'}) eq "HASH")
		{
			# metadata overrride
			foreach my $section(keys %{$env{'product.metadata'}})
			{
				foreach my $variable(keys %{$env{'product.metadata'}{$section}})
				{
					$metadata{$section}{$variable}=$env{'product.metadata'}{$section}{$variable};
				}
			}
		}
	}
	
	$columns{'src_data'}="'".TOM::Security::form::sql_escape($env{'product.src_data'})."'"
		if (exists $env{'product.src_data'} && ($env{'product.src_data'} ne $product{'src_data'}));
	
#	use Data::Dumper;print Dumper(\%metadata);
	
	$env{'product.metadata'}=App::020::functions::metadata::serialize(%metadata);
#	print $env{'product.metadata'};
	if (exists $env{'product.metadata'} && ($env{'product.metadata'} ne $product{'metadata'}))
	{
		$columns{'metadata'}="'".TOM::Security::form::sql_escape($env{'product.metadata'})."'"
	}
	
#	if (exists $env{'product.metadata'} && ($env{'product.metadata'} ne $product{'metadata'}))
#	{
#		my $diff = String::Diff::diff_merge($product{'metadata'}, $env{'product.metadata'},
#			remove_open => '<del>',
#			remove_close => '</del>',
#			append_open => '<ins>',
#			append_close => '</ins>',
#		);
#		print $diff;
#		print $env{'product.metadata'}."\n\n";
#		print $product{'metadata'}."\n";
#	}
	
#	print "metadata=".$columns{'metadata'};
	
	if ($columns{'metadata'} && $App::910::metaindex eq 'Y')
	{
		App::020::functions::metadata::metaindex_set(
			'db_h' => 'main',
			'db_name' => $App::910::db_name,
			'tb_name' => 'a910_product',
			'ID' => $env{'product.ID'},
			'metadata' => {%metadata}
		);
	}
	# status_new
	$columns{'status_new'}="'".TOM::Security::form::sql_escape($env{'product.status_new'})."'"
		if ($env{'product.status_new'} && ($env{'product.status_new'} ne $product{'status_new'}));
	# status_sale
	$columns{'status_sale'}="'".TOM::Security::form::sql_escape($env{'product.status_sale'})."'"
		if ($env{'product.status_sale'} && ($env{'product.status_sale'} ne $product{'status_sale'}));
	# status_special
	$columns{'status_special'}="'".TOM::Security::form::sql_escape($env{'product.status_special'})."'"
		if ($env{'product.status_special'} && ($env{'product.status_special'} ne $product{'status_special'}));
	# status_recommended
	$columns{'status_recommended'}="'".TOM::Security::form::sql_escape($env{'product.status_recommended'})."'"
		if ($env{'product.status_recommended'} && ($env{'product.status_recommended'} ne $product{'status_recommended'}));
	# status_main
	$columns{'status_main'}="'".TOM::Security::form::sql_escape($env{'product.status_main'})."'"
		if ($env{'product.status_main'} && ($env{'product.status_main'} ne $product{'status_main'}));
	
	# status
	$columns{'status'}="'".TOM::Security::form::sql_escape($env{'product.status'})."'"
		if ($env{'product.status'} && ($env{'product.status'} ne $product{'status'}));
	
	# sellscore
	$columns{'sellscore'}="'".TOM::Security::form::sql_escape($env{'product.sellscore'})."'"
		if ($env{'product.sellscore'} && ($env{'product.sellscore'} ne $product{'sellscore'}));
		
	if ($env{'product.product_number'} && ($env{'product.product_number'} ne $product{'product_number'}))
	{
		# check if this product_number not already used by another product
		my $sql=qq{
			SELECT
				ID
			FROM
				`$App::910::db_name`.a910_product
			WHERE
				product_number=?
--				AND status IN ('X')
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'bind'=>[$env{'product.product_number'}],'quiet'=>1);
		$columns{'product_number'}="'".TOM::Security::form::sql_escape($env{'product.product_number'})."'" unless $sth0{'rows'};
	}
	
	if (keys %columns)
	{
		main::_log(" a910_product '$env{'product.ID'}' update ".(join ",",keys %columns),3,$App::910::log_changes,2)
			if $App::910::log_changes;
		if ($columns{'amount'})
		{
			main::_log(" update amount from '$product{'amount'}' to '$columns{'amount'}'");
		}
		App::020::SQL::functions::update(
			'ID' => $env{'product.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product",
			'columns' => {%columns},
			'-posix' => 1,
			'-journalize' => 1
		);
		$content_reindex=1;
	}
	
	
	
	# PRODUCT_ENT
	
	my %product_ent;
	my $product_ent_=(App::020::SQL::functions::get_ID_entity
	(
		'ID_entity' => $env{'product.ID_entity'},
		'db_h' => 'main',
		'db_name' => $App::910::db_name,
		'tb_name' => 'a910_product_ent',
		'columns' => {'*'=>1}
	))[0];
	%product_ent=%{$product_ent_} if $product_ent_->{'ID'}; # convert hash_ref to hash
	$env{'product_ent.ID'}=$product_ent{'ID'};
	
	if (!$env{'product_ent.ID'}) # if product_ent not defined, create a new
	{
		main::_log("!product_ent.ID, create product_ent.ID (product_ent.ID_entity='$env{'product.ID_entity'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID_entity'};
		$env{'product_ent.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_ent",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%product_ent=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_ent.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_ent",
			'columns' => {'*'=>1}
		);
		$env{'product_ent.ID'}=$product_ent{'ID'};
		$env{'product_ent.ID_entity'}=$product_ent{'ID_entity'};
		$content_reindex=1;
		$ent_reindex=1;
	}
	
	main::_log("product_ent.ID='$product_ent{'ID'}' product_ent.ID_entity='$product_ent{'ID_entity'}'");
	
	if (!$product_ent{'posix_owner'} && !$env{'product_ent.posix_owner'})
	{
		$env{'product_ent.posix_owner'}=$main::USRM{'ID_user'};
	}
	
	# update only if necessary
	my %columns;
	# brand
	if ($env{'product_brand.code'})
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID,ID_entity,status
			FROM
				`$App::910::db_name`.a910_product_brand
			WHERE
				code=?
		},'quiet'=>1,'bind'=>[$env{'product_brand.code'}]);
		my %product_brand=$sth0{'sth'}->fetchhash();
		$env{'product_brand.ID'} = $product_brand{'ID'} if $product_brand{'ID'};
	}
	if ($env{'product_brand.name'} && !$env{'product_brand.ID'})
	{
		my $sql=qq{
			SELECT
				ID,ID_entity,status
			FROM
				`$App::910::db_name`.a910_product_brand
			WHERE
				name=?
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1,'bind'=>[$env{'product_brand.name'}]);
		my %product_brand=$sth0{'sth'}->fetchhash();
		$env{'product_brand.ID'}=$product_brand{'ID'};
		if (!$product_brand{'ID'})
		{
			$env{'product_brand.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_brand",
#				'columns' => {
#					'status' => "'Y'"
#				},
				'data' => {
					'name' => $env{'product_brand.name'},
					'name_url' => TOM::Net::URI::rewrite::convert($env{'product_brand.name'})
				},
				'-journalize' => 1,
			);
			product_brand_add('product_brand.ID' => $env{'product_brand.ID'},'status' => 'Y');
			$content_reindex=1;
		}
		elsif ($product_brand{'status'} eq "T")
		{
			product_brand_add('product_brand.ID' => $product_brand{'ID'},'status' => 'Y');
		}
	}
	$columns{'ID_brand'}="'".TOM::Security::form::sql_escape($env{'product_brand.ID'})."'"
		if (exists $env{'product_brand.ID'} && ($env{'product_brand.ID'} ne $product_ent{'ID_brand'}));
	# family
	if ($env{'product_family.name'})
	{
		my $sql=qq{
			SELECT
				ID,ID_entity
			FROM
				`$App::910::db_name`.a910_product_family
			WHERE
				name='$env{'product_family.name'}'
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		my %product_family=$sth0{'sth'}->fetchhash();
		$env{'product_family.ID'}=$product_family{'ID'};
		if (!$product_family{'ID'})
		{
			$env{'product_family.ID'}=App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_family",
				'columns' => {
				},
				'data' => {
					'name' => $env{'product_family.name'},
					'name_url' => TOM::Net::URI::rewrite::convert($env{'product_family.name'})
				},
				'-journalize' => 1,
			);
			$content_reindex=1;
		}
	}
	elsif (exists $env{'product_family.name'}) # reset
	{
		$env{'product_family.ID'}='';
	}
	$columns{'ID_family'}="'".TOM::Security::form::sql_escape($env{'product_family.ID'})."'"
		if (exists $env{'product_family.ID'} && ($env{'product_family.ID'} ne $product_ent{'ID_family'}));
	# posix_owner
	$columns{'posix_owner'}="'".TOM::Security::form::sql_escape($env{'product_ent.posix_owner'})."'"
		if (exists $env{'product_ent.posix_owner'} && ($env{'product_ent.posix_owner'} ne $product_ent{'posix_owner'}));
	# VAT
	$columns{'VAT'}="'".TOM::Security::form::sql_escape($env{'product_ent.VAT'})."'"
		if (exists $env{'product_ent.VAT'} && ($env{'product_ent.VAT'} ne $product_ent{'VAT'}));
	# priority_A
	$columns{'priority_A'}="'".TOM::Security::form::sql_escape($env{'product_ent.priority_A'})."'"
		if (exists $env{'product_ent.priority_A'} && ($env{'product_ent.priority_A'} ne $product_ent{'priority_A'}));
		$columns{'priority_A'}='NULL' if $columns{'priority_A'} eq "''";
	# priority_B
	$columns{'priority_B'}="'".TOM::Security::form::sql_escape($env{'product_ent.priority_B'})."'"
		if (exists $env{'product_ent.priority_B'} && ($env{'product_ent.priority_B'} ne $product_ent{'priority_B'}));
		$columns{'priority_B'}='NULL' if $columns{'priority_B'} eq "''";
	# priority_C
	$columns{'priority_C'}="'".TOM::Security::form::sql_escape($env{'product_ent.priority_C'})."'"
		if (exists $env{'product_ent.priority_C'} && ($env{'product_ent.priority_C'} ne $product_ent{'priority_C'}));
		$columns{'priority_C'}='NULL' if $columns{'priority_C'} eq "''";

	# product_type
	$columns{'product_type'}="'".TOM::Security::form::sql_escape($env{'product_ent.product_type'})."'"
		if (exists $env{'product_ent.product_type'} && ($env{'product_ent.product_type'} ne $product_ent{'product_type'}));
	
	if (keys %columns)
	{
		main::_log(" a910_product_ent '$env{'product_ent.ID'}' update ".(join ",",keys %columns),3,$App::910::log_changes,2)
			if $App::910::log_changes;
		App::020::SQL::functions::update(
			'ID' => $env{'product_ent.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_ent",
			'columns' => {%columns},
			'-journalize' => 1
		);
		$content_reindex=1;
		$ent_reindex=1;
	}
	
	
	
	# LNG DETECTION
	
	# check symlink
	my %product_sym;
	my %product_cat;
	if (!$env{'product_lng.lng'} && $env{'product_sym.ID'})
	{
		my $sym_ID;
		if (ref($env{'product_sym.ID'}) eq "ARRAY")
		{
			$sym_ID=$env{'product_sym.ID'}[0];
		}
		else
		{
			$sym_ID=$env{'product_sym.ID'};
		}
		
		%product_cat=App::020::SQL::functions::get_ID(
			'ID' => $sym_ID,
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_cat",
			'columns' => {'*'=>1}
		);
		$env{'product_lng.lng'}=$product_cat{'lng'} if $product_cat{'ID'};
		main::_log("setting lng='$env{'product_lng.lng'}' from product_sym.ID='$sym_ID'");
	}
	# check lng_param
	$env{'product_lng.lng'}=$tom::lng unless $env{'product_lng.lng'};
	main::_log("lng='$env{'product_lng.lng'}'");
	
	
	# PRODUCT_LNG
	
	my %product_lng;
	if (!$env{'product_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_lng`
			WHERE
				ID_entity=$env{'product.ID'} AND
				lng='$env{'product_lng.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%product_lng=$sth0{'sth'}->fetchhash();
		$env{'product_lng.ID'}=$product_lng{'ID'} if $product_lng{'ID'};
	}
	
	if (!$env{'product_lng.ID'}) # if product_lng not defined, create a new
	{
		main::_log("!product_lng.ID, create product_lng.ID (product_lng.lng='$env{'product_lng.lng'}')");
		my %columns;
		$columns{'ID_entity'}=$env{'product.ID'};
		$columns{'lng'}="'".$env{'product_lng.lng'}."'";
		$env{'product_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_lng",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%product_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_lng",
			'columns' => {'*'=>1}
		);
		$env{'product_lng.ID'}=$product_lng{'ID'};
		$env{'product_lng.ID_entity'}=$product_lng{'ID_entity'};
		$content_reindex=1;
	}
	
	main::_log("product_lng.ID='$product_lng{'ID'}' product_lng.ID_entity='$product_lng{'ID_entity'}'");
	
	# generate keywords
	if ($env{'product_lng.keywords'})
	{
		my @ref=split(' # ',$product_lng{'keywords'});
		$ref[1]=$env{'product_lng.keywords'};
		$env{'product_lng.keywords'}=$ref[0].' # '.$ref[1];
	}
	else {$env{'product_lng.keywords'}=$product_lng{'keywords'};}
	if ( $env{'product_lng.description_short'} || $env{'product_lng.description'})
	{
		my @ref=split(' # ',$env{'product_lng.keywords'});
		$ref[0]='';
		my %keywords=App::401::keywords::html_extract($env{'product_lng.description_short'}.' '.$env{'product_lng.description'});
		foreach (keys %keywords)
		{$ref[0].=", ".$_;}
		$ref[0]=~s|^, ||;
		$env{'product_lng.keywords'}=$ref[0].' # '.$ref[1];
	}
	$env{'product_lng.keywords'}='' if ($env{'product_lng.keywords'} eq ' # ');
	
	# update only if necessary
	my %columns;
	my %data;
	# name
	$data{'name'}=$env{'product_lng.name'}
		if ($env{'product_lng.name'} && ($env{'product_lng.name'} ne $product_lng{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'product_lng.name'})
		if ($env{'product_lng.name'} && (TOM::Net::URI::rewrite::convert($env{'product_lng.name'}) ne $product_lng{'name_url'}));
	# name_long
	$columns{'name_long'}="'".TOM::Security::form::sql_escape($env{'product_lng.name_long'})."'"
		if ($env{'product_lng.name_long'} && ($env{'product_lng.name_long'} ne $product_lng{'name_long'}));
	# name_label
	$columns{'name_label'}="'".TOM::Security::form::sql_escape($env{'product_lng.name_label'})."'"
		if (exists $env{'product_lng.name_label'} && ($env{'product_lng.name_label'} ne $product_lng{'name_label'}));
	# description_short
	if ($env{'product_lng.description_short'} && TOM::Text::format::xml2text($env{'product_lng.description_short'}) eq "")
	{
		undef $env{'product_lng.description_short'};
	}
	$columns{'description_short'}="'".TOM::Security::form::sql_escape($env{'product_lng.description_short'})."'"
		if (exists $env{'product_lng.description_short'} && ($env{'product_lng.description_short'} ne $product_lng{'description_short'}));
	# description
	if ($env{'product_lng.description'} && TOM::Text::format::xml2text($env{'product_lng.description'}) eq "")
	{
		undef $env{'product_lng.description'};
	}
	$columns{'description'}="'".TOM::Security::form::sql_escape($env{'product_lng.description'})."'"
		if (exists $env{'product_lng.description'} && ($env{'product_lng.description'} ne $product_lng{'description'}));
	# keywords
	$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'product_lng.keywords'})."'"
		if ($env{'product_lng.keywords'} && ($env{'product_lng.keywords'} ne $product_lng{'keywords'}));
	
	if (keys %columns || keys %data)
	{
#		main::_log(" a910_product_lng '$env{'product_lng.ID'}' update ".(join ",",keys %columns));
		main::_log(" a910_product_lng '$env{'product_lng.ID'}' update ".(join ",",keys %columns),3,$App::910::log_changes,2)
			if $App::910::log_changes;
		App::020::SQL::functions::update(
			'ID' => $env{'product_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_lng",
			'columns' => {%columns},
			'data' => {%data},
			'-journalize' => 1,
			'-posix' => 1,
		);
		$content_reindex=1;
	}
	
	
	# lngs?
	if ($env{'lngs'} && keys %{$env{'lngs'}})
	{
		foreach my $lng (sort keys %{$env{'lngs'}})
		{
			main::_log("update lng '$lng'");
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_lng`
				WHERE
					ID_entity=$env{'product.ID'} AND
					lng=?
				LIMIT 1
			},'bind'=>[$lng],'quiet'=>1);
			my %product_lng=$sth0{'sth'}->fetchhash();
			
			if (!$product_lng{'ID'}) # if product_lng not defined, create a new
			{
				my %columns;
				$columns{'ID_entity'}=$env{'product.ID'};
				$columns{'lng'}="'".$lng."'";
				my $ID=App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_lng",
					'columns' => {%columns},
					'-journalize' => 1,
				);
				%product_lng=App::020::SQL::functions::get_ID(
					'ID' => $ID,
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_lng",
					'columns' => {'*'=>1}
				);
				$content_reindex=1;
			}
			
#			main::_log("product_lng.ID='$product_lng{'ID'}' product_lng.ID_entity='$product_lng{'ID_entity'}'");
			
#			# generate keywords
#			if ($env{'product_lng.keywords'})
#			{
#				my @ref=split(' # ',$product_lng{'keywords'});
#				$ref[1]=$env{'product_lng.keywords'};
#				$env{'product_lng.keywords'}=$ref[0].' # '.$ref[1];
#			}
#			else {$env{'product_lng.keywords'}=$product_lng{'keywords'};}
#			if ($lngs{$lng}{'description_short'} || $lngs{$lng}{'description'})
#			{
#				my @ref=split(' # ',$lngs{$lng}{'keywords'});
#				$ref[0]='';
#				my %keywords=App::401::keywords::html_extract($env{'product_lng.description_short'}.' '.$env{'product_lng.description'});
#				foreach (keys %keywords)
#				{$ref[0].=", ".$_;}
#				$ref[0]=~s|^, ||;
#				$env{'product_lng.keywords'}=$ref[0].' # '.$ref[1];
#			}
#			$env{'product_lng.keywords'}='' if ($env{'product_lng.keywords'} eq ' # ');
			
			# update only if necessary
			my %columns;
			my %data;
			# name
			$data{'name'}=$env{'lngs'}{$lng}{'name'}
				if ($env{'lngs'}{$lng}{'name'} && ($env{'lngs'}{$lng}{'name'} ne $product_lng{'name'}));
			$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'lngs'}{$lng}{'name'})
				if ($env{'lngs'}{$lng}{'name'} && (TOM::Net::URI::rewrite::convert($env{'lngs'}{$lng}{'name'}) ne $product_lng{'name_url'}));
			# name_long
			$columns{'name_long'}="'".TOM::Security::form::sql_escape($env{'lngs'}{$lng}{'name_long'})."'"
				if ($env{'lngs'}{$lng}{'name_long'} && ($env{'lngs'}{$lng}{'name_long'} ne $product_lng{'name_long'}));
			# name_label
			$columns{'name_label'}="'".TOM::Security::form::sql_escape($env{'lngs'}{$lng}{'name_label'})."'"
				if (exists $env{'lngs'}{$lng}{'name_label'} && ($env{'lngs'}{$lng}{'name_label'} ne $product_lng{'name_label'}));
			# description_short
			if ($env{'lngs'}{$lng}{'description_short'} && TOM::Text::format::xml2text($env{'lngs'}{$lng}{'description_short'}) eq "")
			{
				undef $env{'lngs'}{$lng}{'description_short'};
			}
			$columns{'description_short'}="'".TOM::Security::form::sql_escape($env{'lngs'}{$lng}{'description_short'})."'"
				if (exists $env{'lngs'}{$lng}{'description_short'} && ($env{'lngs'}{$lng}{'description_short'} ne $product_lng{'description_short'}));
			# description
			if ($env{'lngs'}{$lng}{'description'} && TOM::Text::format::xml2text($env{'lngs'}{$lng}{'description'}) eq "")
			{
				undef $env{'lngs'}{$lng}{'description'};
			}
			$columns{'description'}="'".TOM::Security::form::sql_escape($env{'lngs'}{$lng}{'description'})."'"
				if (exists $env{'lngs'}{$lng}{'description'} && ($env{'lngs'}{$lng}{'description'} ne $product_lng{'description'}));
			# keywords
			$columns{'keywords'}="'".TOM::Security::form::sql_escape($env{'lngs'}{$lng}{'keywords'})."'"
				if ($env{'lngs'}{$lng}{'keywords'} && ($env{'lngs'}{$lng}{'keywords'} ne $product_lng{'keywords'}));
			
			if (keys %columns || keys %data)
			{
				main::_log(" a910_product_lng '$lng' '$product_lng{'ID'}' update ".(join ",",keys %columns),3,$App::910::log_changes,2)
					if $App::910::log_changes;
				App::020::SQL::functions::update(
					'ID' => $product_lng{'ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_lng",
					'columns' => {%columns},
					'data' => {%data},
					'-journalize' => 1,
					'-posix' => 1,
				);
				$content_reindex=1;
			}
			
		}
	}
	
	# PRODUCT_SYM
	
	if ($env{'product_sym.ID'} && ref($env{'product_sym.ID'}) eq "ARRAY")
	{
		my @sym_IDs;
		foreach my $sym_ID (@{$env{'product_sym.ID'}})
		{
			$sym_ID+=0;
			next unless $sym_ID;
			push @sym_IDs,$sym_ID;
			
			main::_log("checking \@sym.ID $sym_ID");
			
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_sym`
				WHERE
					ID_entity=? AND
					ID=?
				LIMIT 1
			},'quiet'=>1,'bind'=>[
				$env{'product.ID_entity'},
				$sym_ID
			]);
			if (!$sth0{'rows'})
			{
				TOM::Database::SQL::execute(qq{
					INSERT INTO
						`$App::910::db_name`.a910_product_sym
					SET
						ID_entity=?,
						ID=?,
						datetime_create=NOW(),
						status='Y'
				},'bind'=>[
					$env{'product.ID_entity'},
					$sym_ID
				],'quiet'=>1);
#				$env{'product_sym.ID'}=App::020::SQL::functions::new(
#					'db_h' => "main",
#					'db_name' => $App::910::db_name,
#					'tb_name' => "a910_product_sym",
#					'columns' =>
#					{
#						'ID_entity' => $env{'product.ID_entity'},
#						'ID' => $sym_ID
#					},
#					'-journalize' => 1,
#				);
				$content_reindex=1;
				$ent_reindex=1;
			}
			
		}
		
		if ($env{'product_sym.replace'})
		{
			my $sql_sym = join ',',@sym_IDs;
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_sym`
				WHERE
					ID_entity=$env{'product.ID_entity'} AND
					ID NOT IN ($sql_sym)
			},'quiet'=>1);
			while (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				main::_log("delete $db0_line{'ID'}");
				TOM::Database::SQL::execute(qq{
					DELETE FROM
						`$App::910::db_name`.a910_product_sym
					WHERE
						ID_entity=? AND
						ID=?
					LIMIT 1;
				},'bind'=>[
					$db0_line{'ID_entity'},
					$db0_line{'ID'}
				],'quiet'=>1);
				$content_reindex=1;
				$ent_reindex=1;
			}
		}
		
	}
	elsif ($env{'product_sym.ID'})
	{
		$env{'product_sym.ID'}+=0;
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_sym`
			WHERE
				ID_entity=$env{'product.ID_entity'} AND
				ID=$env{'product_sym.ID'}
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		if (!$sth0{'rows'})
		{
			TOM::Database::SQL::execute(qq{
				INSERT INTO
					`$App::910::db_name`.a910_product_sym
				SET
					ID_entity=?,
					ID=?,
					datetime_create=NOW(),
					status='Y'
			},'bind'=>[
				$env{'product.ID_entity'},
				$env{'product_sym.ID'}
			],'quiet'=>1);
			$content_reindex=1;
			$ent_reindex=1;
#			$env{'product_sym.ID'}=App::020::SQL::functions::new(
#				'db_h' => "main",
#				'db_name' => $App::910::db_name,
#				'tb_name' => "a910_product_sym",
#				'columns' =>
#				{
#					'ID' => $env{'product_sym.ID'},
#					'ID_entity' => $env{'product.ID_entity'},
#				},
#				'-journalize' => 1,
#			);
		}
		
		if ($env{'product_sym.replace'})
		{
			my $sql=qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_sym`
				WHERE
					ID_entity=$env{'product.ID_entity'} AND
					ID != $env{'product_sym.ID'}
				LIMIT 1
			};
			my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
			while (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				TOM::Database::SQL::execute(qq{
					DELETE FROM
						`$App::910::db_name`.a910_product_sym
					WHERE
						ID_entity=? AND
						ID=?
					LIMIT 1;
				},'bind'=>[
					$db0_line{'ID_entity'},
					$db0_line{'ID'}
				],'quiet'=>1);
				$content_reindex=1;
				$ent_reindex=1;
			}
			
		}
		
	}
	
#	main::_log("product_sym.ID='$env{'product_sym.ID'}'");
	
	if ($env{'prices'})
	{
		foreach my $price_level_name_code (keys %{$env{'prices'}})
		{
			# hladam cenovu hladinu
			my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_price_level` WHERE name_code=? LIMIT 1},
				'bind'=>[$price_level_name_code],'quiet'=>1);
			my %price_level=$sth0{'sth'}->fetchhash();
			# nieje, vytvaram
			if (!$sth0{'rows'})
			{
				App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_price_level",
					'columns' =>
					{
						'name_code' => "'".TOM::Security::form::sql_escape($price_level_name_code)."'",
						'status' => "'Y'",
					},
					'-journalize' => 1,
				);
				my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_price_level` WHERE name_code=? LIMIT 1},
				'bind'=>[$price_level_name_code],'quiet'=>1);
				%price_level=$sth0{'sth'}->fetchhash();
			}
			# ???
			next unless $price_level{'ID_entity'};
			# hladam cenu
			my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_product_price` WHERE ID_price=? AND ID_entity=? LIMIT 1},
				'bind'=>[$price_level{'ID_entity'},$product{'ID'}],'quiet'=>1);
			my %price=$sth0{'sth'}->fetchhash();
			
			if (ref($env{'prices'}{$price_level_name_code}) eq "HASH")
			{
				$env{'prices'}{$price_level_name_code}{'price'}=sprintf("%.3f",$env{'prices'}{$price_level_name_code}{'price'});
				$env{'prices'}{$price_level_name_code}{'price_full'}=sprintf("%.3f",$env{'prices'}{$price_level_name_code}{'price_full'});
#					if $env{'prices'}{$price_level_name_code}{'price_full'};
				$env{'prices'}{$price_level_name_code}{'price_previous'}=sprintf("%.3f",$env{'prices'}{$price_level_name_code}{'price_previous'})
					if defined $env{'prices'}{$price_level_name_code}{'price_previous'};
				$env{'prices'}{$price_level_name_code}{'price_previous_full'}=sprintf("%.3f",$env{'prices'}{$price_level_name_code}{'price_previous_full'})
					if defined $env{'prices'}{$price_level_name_code}{'price_previous_full'};
			}
			else
			{
				my $price=sprintf("%0.3f",$env{'prices'}{$price_level_name_code});
#				$env{'prices'}{$price_level_name_code}=sprintf("%0.3f",$env{'prices'}{$price_level_name_code});
				delete $env{'prices'}{$price_level_name_code};
				$env{'prices'}{$price_level_name_code}{'price'}=$price;
				$env{'prices'}{$price_level_name_code}{'price_full'}=$price;
			}
			
			if (!$sth0{'rows'})
			{
				my %data;
				$data{'src_data'} = $env{'prices'}{$price_level_name_code}{'src_data'}
					if defined $env{'prices'}{$price_level_name_code}{'src_data'};
				App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_price",
					'columns' =>
					{
						'ID_entity' => $product{'ID'},
						'ID_price' => $price_level{'ID_entity'},
						'price' => $env{'prices'}{$price_level_name_code}{'price'},
						'price_full' => $env{'prices'}{$price_level_name_code}{'price_full'},
						'price_previous' => ($env{'prices'}{$price_level_name_code}{'price_previous'} || 'NULL'),
						'price_previous_full' => ($env{'prices'}{$price_level_name_code}{'price_previous_full'} || 'NULL'),
						'datetime_next_index' => ($env{'prices'}{$price_level_name_code}{'datetime_next_index'} || 'NULL'),
						'status' => "'Y'",
					},
					'data' => {
						%data
					},
					'-journalize' => 1,
					'-posix' => 1
				);
				$content_reindex=1;
			}
			elsif (
				$price{'price'} ne $env{'prices'}{$price_level_name_code}{'price'} ||
				$price{'price_full'} ne $env{'prices'}{$price_level_name_code}{'price_full'} ||
				(
					exists $env{'prices'}{$price_level_name_code}{'price_previous'}
					&& $price{'price_previous'} ne $env{'prices'}{$price_level_name_code}{'price_previous'} 
				) ||
				(
					defined $env{'prices'}{$price_level_name_code}{'src_data'}
					&& $price{'src_data'} ne $env{'prices'}{$price_level_name_code}{'src_data'}
				) ||
				$price{'datetime_next_index'} ne $env{'prices'}{$price_level_name_code}{'datetime_next_index'}
			)
			{
				my %data;
				$data{'src_data'} = $env{'prices'}{$price_level_name_code}{'src_data'}
					if defined $env{'prices'}{$price_level_name_code}{'src_data'};
				
				main::_log("price $price{'price'}<>$env{'prices'}{$price_level_name_code}{'price'}")
					if $price{'price'} ne $env{'prices'}{$price_level_name_code}{'price'};
				main::_log("price_full $price{'price_full'}<>$env{'prices'}{$price_level_name_code}{'price_full'}")
					if $price{'price_full'} ne $env{'prices'}{$price_level_name_code}{'price_full'};
				main::_log("price_previous $price{'price_previous'}<>$env{'prices'}{$price_level_name_code}{'price_previous'}")
					if (exists $env{'prices'}{$price_level_name_code}{'price_previous'} && $price{'price_previous'} ne $env{'prices'}{$price_level_name_code}{'price_previous'});
				main::_log("src_data modified '$price{'src_data'}'<>'$env{'prices'}{$price_level_name_code}{'src_data'}'")
					if (defined $env{'prices'}{$price_level_name_code}{'src_data'} && $price{'src_data'} ne $env{'prices'}{$price_level_name_code}{'src_data'});
				main::_log("datetime_next_index $price{'datetime_next_index'}<>$env{'prices'}{$price_level_name_code}{'datetime_next_index'}")
					if $price{'datetime_next_index'} ne $env{'prices'}{$price_level_name_code}{'datetime_next_index'};
				
				$env{'prices'}{$price_level_name_code}{'datetime_next_index'}="'".$env{'prices'}{$price_level_name_code}{'datetime_next_index'}."'"
					if $env{'prices'}{$price_level_name_code}{'datetime_next_index'};
				
				App::020::SQL::functions::update(
					'ID' => $price{'ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_price",
					'columns' => {
						'price' => $env{'prices'}{$price_level_name_code}{'price'},
						'price_full' => $env{'prices'}{$price_level_name_code}{'price_full'},
						'price_previous' => ($env{'prices'}{$price_level_name_code}{'price_previous'} || 'NULL'),
						'price_previous_full' => ($env{'prices'}{$price_level_name_code}{'price_previous_full'} || 'NULL'),
						'datetime_next_index' => ($env{'prices'}{$price_level_name_code}{'datetime_next_index'} || 'NULL')
					},
					'data' => {
						%data
					},
					'-journalize' => 1,
					'-posix' => 1
				);
				$content_reindex=1;
			}
		}
	}
	
	
	if ($env{'legal'})
	{
		foreach my $country_code (keys %{$env{'legal'}})
		{
#			main::_log("legal = $country_code");
			# hladam legal
			my %sth0=TOM::Database::SQL::execute(qq{SELECT * FROM `$App::910::db_name`.`a910_product_legal` WHERE ID_entity=? AND country_code=? LIMIT 1},
				'bind'=>[$product{'ID'},$country_code],'quiet'=>1);
			my %legal=$sth0{'sth'}->fetchhash();
			
			if (ref($env{'legal'}{$country_code}) eq "HASH")
			{
				
			}
			
			if (!$sth0{'rows'})
			{
				App::020::SQL::functions::new(
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_legal",
					'columns' =>
					{
						'ID_entity' => $product{'ID'},
						'status' => "'Y'",
					},
					'data' => {
						'country_code' => $country_code,
						'VAT' => $env{'legal'}{$country_code}{'VAT'},
					},
					'-journalize' => 1,
#					'-posix' => 1
				);
				$content_reindex=1;
			}
			elsif (
				$legal{'VAT'} ne $env{'legal'}{$country_code}{'VAT'}
			)
			{
#				main::_log("$price{'price'}<>$env{'prices'}{$price_level_name_code}{'price'}");
				App::020::SQL::functions::update(
					'ID' => $legal{'ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_legal",
					'columns' => {
#						'price' => $env{'prices'}{$price_level_name_code}{'price'},
#						'price_full' => $env{'prices'}{$price_level_name_code}{'price_full'},
#						'price_previous' => ($env{'prices'}{$price_level_name_code}{'price_previous'} || 'NULL'),
#						'price_previous_full' => ($env{'prices'}{$price_level_name_code}{'price_previous_full'} || 'NULL'),
					},
					'data' => {
						'VAT' => $env{'legal'}{$country_code}{'VAT'}
#						'src_data' => $env{'prices'}{$price_level_name_code}{'src_data'}
					},
					'-journalize' => 1,
#					'-posix' => 1
				);
				$content_reindex=1;
			}
		}
	}
	
	# THUMBNAIL
	
	if ($env{'thumbnail'} && -e $env{'thumbnail'} && not -d $env{'thumbnail'})
	{
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $env{'product.ID'},
			'rel_type' => 'thumbnail',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			
			my %image=App::501::functions::image_add(
				'image.ID_entity' => $relation->{'r_ID_entity'},
				'image_attrs.name' => $env{'product.product_number'} || $env{'product.ID'} || $env{'thumbnail'},
				'image_attrs.ID_category' => $App::910::thumbnail_cat_ID_entity,
				'check_duplicity' => 'Y',
				'file' => $env{'thumbnail'}
			);
			
			if ($image{'image.ID'})
			{
#				App::501::functions::image_regenerate(
#					'image.ID' => $image{'image.ID'}
#				);
			}
			
		}
		else
		{
			
			my %image=App::501::functions::image_add(
				'image_attrs.name' => $env{'product.product_number'} || $env{'product.ID'} || $env{'thumbnail'},
				'image_attrs.ID_category' => $App::910::thumbnail_cat_ID_entity,
				'check_duplicity' => 'Y',
				'image_attrs.status' => 'Y',
				'file' => $env{'thumbnail'}
			);
			
			if ($image{'image.ID'})
			{
				
#				App::501::functions::image_regenerate(
#					'image.ID' => $image{'image.ID'}
#				);
				
				my ($ID_entity,$ID)=App::160::SQL::new_relation(
					'l_prefix' => 'a910',
					'l_table' => 'product',
					'l_ID_entity' => $env{'product.ID'},
					'rel_type' => 'thumbnail',
					'r_db_name' => $App::501::db_name,
					'r_prefix' => 'a501',
					'r_table' => 'image',
					'r_ID_entity' => $image{'image.ID_entity'},
					'status' => 'Y',
				);
				
			}
			
		}
		
	}
	
	$env{'reindex'}=$content_reindex;
	
	if ($ent_reindex)
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID
			FROM
				$App::910::db_name.a910_product
			WHERE
				ID_entity = ?
		},'quiet'=>1,'bind'=>[$env{'product.ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log(" index product '$db0_line{'ID'}'",3,$App::910::log_changes,2)
				if $App::910::log_changes;
			App::020::SQL::functions::_save_changetime({
				'db_h'=>'main',
				'db_name'=>$App::910::db_name,
				'tb_name'=>'a910_product',
				'ID_entity'=>$db0_line{'ID'}}
			);
			# reindex this product
			if (not exists $env{'index'} || $env{'index'})
			{
				_product_index('ID'=>$db0_line{'ID'}, 'commit' => $env{'commit'}, '-jobify' => 0);
			}
		}
		_product_ent_index('ID_entity'=>$env{'product.ID_entity'}, 'commit' => $env{'commit'}, '-jobify' => 0)
			if $App::910::index_product_ent;
	}
	elsif ($content_reindex)
	{
		main::_log(" index product '$env{'product.ID'}'",3,$App::910::log_changes,2)
			if $App::910::log_changes;
		App::020::SQL::functions::_save_changetime({
			'db_h'=>'main',
			'db_name'=>$App::910::db_name,
			'tb_name'=>'a910_product',
			'ID_entity'=>$env{'product.ID'}}
		);
		# reindex this product
		if (not exists $env{'index'} || $env{'index'})
		{
			_product_index('ID'=>$env{'product.ID'}, 'commit' => $env{'commit'}, '-jobify' => 0);
			_product_ent_index('ID_entity'=>$env{'product.ID_entity'}, 'commit' => $env{'commit'}, '-jobify' => 0)
				if $App::910::index_product_ent;
		}
	}
	
	$t->close();
	return %env;
}


sub _product_index
{
	my %env=@_;
#	return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::910::db_name,'class'=>'indexer'})
#		unless $env{'-jobify'}; # do it in background
	
	if ($env{'-jobify'})
	{
#		main::_log("try jobify");
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::910::db_name,'class'=>'indexer','deduplication'=>1});
	}
	
	return undef unless $env{'ID'}; # product.ID
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_index($env{'ID'})",'timer'=>1);
	
	
	if ($Ext::Solr && ($env{'solr'} || not exists $env{'solr'}))
	{
		# remove this obsolete... 
		_product_index_solr('ID'=>$env{'ID'},'commit'=>1,'-jobify'=>1);
	}
	
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{
#		my $status_string = $App::910::solr_status_index;
#		$status_string =~ s/(\w)/\'$1\',/g; $status_string =~ s/,$//;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				product.ID,
				product.ID_entity,
				product_ent.ID_brand,
				product_ent.ID_family,
				product_ent.VAT,
				product_ent.rating_score,
				product_ent.rating_votes,
				product_ent.rating,
				product_ent.priority_A,
				product_ent.priority_B,
				product_ent.priority_C,
				product_ent.product_type
			FROM
				$App::910::db_name.a910_product AS product
			INNER JOIN $App::910::db_name.a910_product_ent AS product_ent ON
			(
				product.ID_entity = product_ent.ID_entity
			)
			LEFT JOIN $App::910::db_name.a910_product_brand AS product_brand ON
			(
				product_brand.ID_entity = product_ent.ID_brand
			)
			LEFT JOIN $App::910::db_name.a910_product_family AS product_family ON
			(
				product_family.ID_entity = product_ent.ID_family
			)
			WHERE
				product.status IN ('Y','N','L','W') AND
				product.ID = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (!$sth0{'rows'})
		{
			main::_log("product.ID=$env{'ID'} not found as valid item");
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::910::index_name,
				'type' => 'a910_product',
				'id' => $env{'ID'}
			))
			{
				main::_log("removing from Elastic");
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::910::index_name,
					'type' => 'a910_product',
					'id' => $env{'ID'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %product=_product_hash('ID'=>$env{'ID'});
		if (my %prod=$sth0{'sth'}->fetchhash())
		{
			foreach (keys %prod)
			{
				next unless $prod{$_};
				$product{$_}=$prod{$_};
			}
		}
		
		delete $product{'datetime_publish_start'}
			if $product{'datetime_publish_start'}=~/^0/;
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		
		main::_log("index",{
			'facility' => 'elastic',
			'severity' => 3,
			'data' => {
				'action' => 'index',
	#			'hostname' => $self->{'host_name'},
				'index_s' => 'cyclone3.'.$App::910::index_name,
				'type_s' => 'a910_product',
				'ID_s' => $env{'ID'}
			}
		});
		
		delete $product{'metahash'} unless keys %{$product{'metahash'}};
		delete $product{'relations'} unless keys %{$product{'relations'}};
		
		my $datetime_index=$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
			.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z';
		$Elastic->index(
			'index' => 'cyclone3.'.$App::910::index_name,
			'type' => 'a910_product',
			'id' => $env{'ID'},
			'body' => {
				%product,
				'_datetime_index' => $datetime_index
			}
		);
		
		# check
		my $check=$Elastic->get(
			'index' => 'cyclone3.'.$App::910::index_name,
			'type' => 'a910_product',
			'id' => $env{'ID'}
		);
		main::_log("received datetime current='".$datetime_index."' index='".$check->{'_source'}->{'_datetime_index'}."'");
		if ($datetime_index ne $check->{'_source'}->{'_datetime_index'})
		{
			main::_log("not succesfully indexed?",1);
		}
#		main::_log("/index ID=$product{'ID'}",3,"elastic");
		
	}
	
	
	if ($Redis)
	{
		$Redis->incr($App::910::db_name.".a910_product.indexed",sub{});
	}
	
	# when product indexed, it's like changed
	App::020::SQL::functions::_save_changetime({
		'db_h'=>'main',
		'db_name'=>$App::910::index_name,
		'tb_name'=>'a910_product',
		'ID_entity'=>$env{'ID'}}
	);
	
	$t->close();
	
}


sub _product_ent_index
{
	my %env=@_;
	
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::910::db_name,'class'=>'indexer','deduplication'=>1});
	}
	
	return undef unless $env{'ID_entity'};
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_ent_index($env{'ID_entity'})",'timer'=>1);
	
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{	
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				product_ent.ID_brand,
				product_ent.ID_family,
				product_ent.VAT,
				product_ent.rating_score,
				product_ent.rating_votes,
				product_ent.rating,
				product_ent.priority_A,
				product_ent.priority_B,
				product_ent.priority_C,
				product_ent.product_type,
				
				product_brand.name AS brand_name,
				product_brand.alias_name AS brand_alias_name,
				product_brand.name_url AS brand_name_url,
				
				product_family.name AS family_name,
				product_family.name_url AS family_name_url
				
			FROM
				$App::910::db_name.a910_product AS product
			INNER JOIN $App::910::db_name.a910_product_ent AS product_ent ON
			(
				product.ID_entity = product_ent.ID_entity
			)
			LEFT JOIN $App::910::db_name.a910_product_brand AS product_brand ON
			(
				product_brand.ID_entity = product_ent.ID_brand
			)
			LEFT JOIN $App::910::db_name.a910_product_family AS product_family ON
			(
				product_family.ID_entity = product_ent.ID_family
			)
			WHERE
				product_ent.status IN ('Y','N','L','W') AND
				product.ID_entity=?
		},'quiet'=>1,'bind'=>[$env{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("product.ID_entity=$env{'ID_entity'} not found as valid item");
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::910::index_name,
				'type' => 'a910_product_ent',
				'id' => $env{'ID_entity'}
			))
			{
				main::_log("removing from Elastic");
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::910::index_name,
					'type' => 'a910_product_ent',
					'id' => $env{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %product=$sth0{'sth'}->fetchhash();
			foreach (keys %product){delete $product{$_} unless $product{$_}};
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				product.ID
			FROM
				$App::910::db_name.a910_product AS product
			WHERE
				product.ID_entity = ?
				AND product.status IN ('Y','N','L','W')
		},'bind'=>[$env{'ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			my %prod=_product_hash('ID'=>$db0_line{'ID'});
			if ($prod{'ID'})
			{
				push @{$product{'product'}}, \%prod;
			}
		}
		
#		print Dumper(\%product);
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		
		main::_log("index",{
			'facility' => 'elastic',
			'severity' => 3,
			'data' => {
				'action' => 'index',
	#			'hostname' => $self->{'host_name'},
				'index_s' => 'cyclone3.'.$App::910::index_name,
				'type_s' => 'a910_product_ent',
				'ID_s' => $env{'ID_entity'}
			}
		});
		
		my $datetime_index=$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
			.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z';
		$Elastic->index(
			'index' => 'cyclone3.'.$App::910::index_name,
			'type' => 'a910_product_ent',
			'id' => $env{'ID_entity'},
			'body' => {
				%product,
				'_datetime_index' => $datetime_index
			}
		);
		
		# check
		my $check=$Elastic->get(
			'index' => 'cyclone3.'.$App::910::index_name,
			'type' => 'a910_product_ent',
			'id' => $env{'ID_entity'}
		);
		main::_log("received datetime current='".$datetime_index."' index='".$check->{'_source'}->{'_datetime_index'}."'");
		if ($datetime_index ne $check->{'_source'}->{'_datetime_index'})
		{
			main::_log("not succesfully indexed?",1);
		}
		
	}
	
	$t->close();
}


sub _product_hash
{
	my %env=@_;
	
	return undef unless $env{'ID'}; # product.ID
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			product.ID,
			product.ID_entity,
			product.ref_ID,
			product.product_number,
			product.EAN,
			product.datetime_publish_start,
			product.datetime_publish_stop,
			product.amount,
			product.amount_unit,
			product.amount_availability,
			product.amount_limit,
			product.amount_order_min,
			product.amount_order_max,
			product.amount_order_div,
			product.price,
			product.price_previous,
			product.price_max,
			product.price_currency,
			product.price_EUR,
			product.metadata,
			product.supplier_org,
			product.supplier_person,
			product.status_new,
			product.status_recommended,
			product.status_sale,
			product.status_special,
			product.status_main,
			product.status,
			product.sellscore,
			
			product_brand.name AS brand_name,
			product_brand.alias_name AS brand_alias_name,
			product_brand.name_url AS brand_name_url,
			
			product_family.name AS family_name,
			product_family.name_url AS family_name_url
			
		FROM
			$App::910::db_name.a910_product AS product
		INNER JOIN $App::910::db_name.a910_product_ent AS product_ent ON
		(
			product.ID_entity = product_ent.ID_entity
		)
		LEFT JOIN $App::910::db_name.a910_product_brand AS product_brand ON
		(
			product_brand.ID_entity = product_ent.ID_brand
		)
		LEFT JOIN $App::910::db_name.a910_product_family AS product_family ON
		(
			product_family.ID_entity = product_ent.ID_family
		)
		WHERE
			product.status IN ('Y','N','L','W') AND
			product.ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (!$sth0{'rows'})
	{
		return undef;
	}
	
	my %product=$sth0{'sth'}->fetchhash();
		foreach (keys %product){delete $product{$_} unless $product{$_} || $_ eq 'amount'};
	
	%{$product{'metahash'}}=App::020::functions::metadata::parse($product{'metadata'});
	delete $product{'metadata'};
	
	use App::910::metadata;	
	App::910::metadata::preprocess(\%{$product{'metahash'}});
	
	foreach my $sec(keys %{$product{'metahash'}})
	{
		foreach (keys %{$product{'metahash'}{$sec}})
		{
			if (!$product{'metahash'}{$sec}{$_})
			{
				delete $product{'metahash'}{$sec}{$_};
				next
			}
			if ($_=~s/\[\]$//)
			{
				foreach my $val (split(';',$product{'metahash'}{$sec}{$_.'[]'}))
				{
					push @{$product{'metahash'}{$sec}{$_}},$val;
				}
				#push @{$product->{'metahash_keys'}},$sec.'.'.$_ ;
				next;
			}
			
			if ($product{'metahash'}{$sec}{$_}=~/^\d\d\d\d\-\d\d\-\d\d$/)
			{
				$product{'metahash'}{$sec}{$_.'_d'} = $product{'metahash'}{$sec}{$_};
			}
			if ($product{'metahash'}{$sec}{$_}=~/^[0-9]{1,9}$/)
			{
				$product{'metahash'}{$sec}{$_.'_i'} = $product{'metahash'}{$sec}{$_};
			}
			if ($product{'metahash'}{$sec}{$_}=~/^[0-9\.]{1,9}$/ && (not $product{'metahash'}{$sec}{$_}=~/\..*?\./))
			{
				$product{'metahash'}{$sec}{$_.'_f'} = $product{'metahash'}{$sec}{$_};
			}
			
			# list of used metadata fields
#				push @{$product{'metahash_keys'}}, $sec.'.'.$_;
			push @{$product{'metahash_keys'}{$sec}}, $_;
		}
	}
	
	# product_lng
	my %used;
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			name,
			name_url,
			name_long,
			name_label,
			description_short,
			description,
			keywords,
			lng
		FROM
			$App::910::db_name.a910_product_lng
		WHERE
			status='Y'
			AND ID_entity=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		next unless $db0_line{'name'};
		push @{$product{'name'}},$db0_line{'name'}
			unless $used{$db0_line{'name'}};
		push @{$product{'full_name'}},$product{'brand_name'}.' '.$db0_line{'name'}
			unless $used{$db0_line{'name'}};
		
		foreach (keys %db0_line){delete $db0_line{$_} unless $db0_line{$_}};
		
		$used{$db0_line{'name'}}++;
		%{$product{'locale'}{$db0_line{'lng'}}}=%db0_line;
	}
	
	# categories
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			a910_product_sym.ID,
			a910_product_cat.ID_charindex,
			a910_product_cat.ID AS cat_ID,
			a910_product_cat.ID_entity AS cat_ID_entity,
			a910_product_cat.name,
			a910_product_cat.lng,
			a910_product_cat.alias_name
		FROM
			$App::910::db_name.a910_product_sym
		INNER JOIN $App::910::db_name.a910_product_cat ON
		(
			a910_product_sym.ID = a910_product_cat.ID_entity
		)
		WHERE
			a910_product_sym.status='Y'
			AND a910_product_sym.ID_entity=?
	},'quiet'=>1,'bind'=>[$product{'ID_entity'}]);
	my %used;
	my %used2;
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		push @{$product{'cat'}},$db0_line{'cat_ID_entity'}
			unless $used{$db0_line{'cat_ID_entity'}};
		
		push @{$product{'cat_charindex'}},$db0_line{'ID_charindex'}
			unless $used{$db0_line{'ID_charindex'}};
		
		push @{$product{'cat_name'}},$db0_line{'name'}
			unless $used{$db0_line{'name'}};
			
		push @{$product{'cat_alias_name'}},$db0_line{'alias_name'}
			if (!$used{$db0_line{'alias_name'}} && $db0_line{'alias_name'});
		
		push @{$product{'locale'}{$db0_line{'lng'}}{'cat_name'}}, $db0_line{'name'};
#				unless $used{$db0_line{'name'}};
		push @{$product{'locale'}{$db0_line{'lng'}}{'cat_alias_name'}}, $db0_line{'alias_name'}
			if $db0_line{'alias_name'};
#				if (!$used{$db0_line{'alias_name'}} && $db0_line{'alias_name'});
		
		my %sql_def=('db_h' => "main",'db_name' => $App::910::db_name,'tb_name' => "a910_product_cat");
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$db0_line{'cat_ID'},
				%sql_def,
				'-cache' => 86400*7
			)
		)
		{
			push @{$product{'cat_path'}},$p->{'ID_entity'}
				unless $used2{$p->{'ID_entity'}};
			push @{$product{'cat_path_name'}},$p->{'name'}
				unless $used2{$p->{'ID_entity'}};
			$used2{$p->{'ID_entity'}}++;
		}
		
		$used{$db0_line{'ID_charindex'}}++;
		$used{$db0_line{'cat_ID_entity'}}++;
		$used{$db0_line{'name'}}++;
		$used{$db0_line{'alias_name'}}++;
	}
	
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			rating.datetime_rating
		FROM
			$App::910::db_name.a910_product_rating AS rating
		WHERE
			rating.status='Y'
			AND length(rating.description) >= 10
			AND rating.ID_product = ?
		ORDER BY
			rating.datetime_rating DESC
		LIMIT 1
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	my %db1_line=$sth1{'sth'}->fetchhash();
	if ($db1_line{'datetime_rating'})
	{
		$product{'ratings'}{'datetime_last'} = $db1_line{'datetime_rating'};
	}
	
	# rating_variable
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			a910_product_rating_variable.score_variable AS var,
			AVG(a910_product_rating_variable.score_value) AS val,
			COUNT(DISTINCT(a910_product_rating.ID_entity)) AS cnt
		FROM
			$App::910::db_name.a910_product_rating_variable
		INNER JOIN a910_product_rating ON
		(
			a910_product_rating.ID_entity = a910_product_rating_variable.ID_entity
		)
		WHERE
			a910_product_rating.score_basic IS NULL AND
			a910_product_rating.status='Y' AND
			a910_product_rating.ID_product = ?
		GROUP BY
			a910_product_rating_variable.score_variable
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	my $i_count;
	my $i_sum;
	my $i_avg;
	while (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		main::_log("rating variable '$db1_line{'var'}' cnt='$db1_line{'cnt'}'");
		my $var=$db1_line{'var'};
		$var=lc(Int::charsets::encode::UTF8_ASCII($var));
		$var=~s|[^\w]||g;
		$i_count++;
		$i_sum+=$db1_line{'val'};
#			main::_log("var=$var val=$db1_line{'val'}");
#			print Dumper($product{'rating'});use Data::Dumper;
		$product{'ratings'}{'variable'}{$var} = ceil($db1_line{'val'}+0);
	}
	
	# vahovany rating
	my $helpful_initial=2;
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT (
			SUM(
				IF (rating.score_basic, rating.score_basic,
					(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity))
				* COALESCE((
					SELECT IF (rating_weight,rating_weight,0.01)
					FROM TOM.a301_user_profile
					WHERE ID_entity = rating.posix_owner
					LIMIT 1
				),0.5) * ((rating.helpful_Y+$helpful_initial) / (rating.helpful_Y+$helpful_initial + rating.helpful_N+$helpful_initial))
			) / SUM( COALESCE((
					SELECT IF (rating_weight,rating_weight,0.01)
					FROM TOM.a301_user_profile
					WHERE ID_entity = rating.posix_owner
					LIMIT 1
				),0.5) * ((rating.helpful_Y+$helpful_initial) / (rating.helpful_Y+$helpful_initial + rating.helpful_N+$helpful_initial))
			)
		) AS score,
			COUNT(rating.ID) AS ratings,
			MAX(rating.datetime_rating) AS datetime_rating
		FROM
			$App::910::db_name.a910_product_rating AS rating
		WHERE
			rating.status='Y'
			AND (rating.score_basic IS NOT NULL
				OR (
					SELECT COUNT(rating_variable.score_value) FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity
				) > 0
			)
			AND rating.ID_product = ?
		GROUP BY
			rating.ID_product
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	my %db1_line=$sth1{'sth'}->fetchhash();
	
	if ($db1_line{'ratings'})
	{
		$db1_line{'score'} = 0 unless $db1_line{'score'};
		main::_log("ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
		
		$product{'ratings'}->{'variable'}->{'count'} = ceil($db1_line{'ratings'});
		$product{'ratings'}->{'variable'}->{'avg'} = $db1_line{'score'};
	}
	
	
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			a910_product_price.*,
			a910_price_level.name_code
		FROM
			$App::910::db_name.a910_product_price
		INNER JOIN $App::910::db_name.a910_price_level ON
		(
			a910_product_price.ID_price = a910_price_level.ID_entity
		)
		WHERE
			a910_product_price.ID_entity = ?
			AND a910_product_price.status = 'Y'
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	while (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		$db1_line{'price'}+=0;
		$db1_line{'price_full'}+=0;
		$db1_line{'price_previous'}+=0;
		$db1_line{'price_previous_full'}+=0;
		$product{'prices'}{$db1_line{'name_code'}}{'price'} = $db1_line{'price'}+0
			if $db1_line{'price'};
		$product{'prices'}{$db1_line{'name_code'}}{'price_full'} = $db1_line{'price_full'}+0
			if $db1_line{'price_full'};
		$product{'prices'}{$db1_line{'name_code'}}{'price_previous'} = $db1_line{'price_previous'}+0
			if $db1_line{'price_previous'};
		$product{'prices'}{$db1_line{'name_code'}}{'price_previous_full'} = $db1_line{'price_previous_full'}+0
			if $db1_line{'price_previous_full'};
	}
	
	# product_set
	$product{'relations'}={} unless $product{'relations'};
	
	foreach my $relation (App::160::SQL::get_relations(
		'db_name' => $App::910::db_name,
		'l_prefix' => 'a910',
		'l_table' => 'product',
		'r_ID_entity' => $product{'ID'},
		'r_prefix' => "a910",
		'r_table' => "product",
		'rel_type' => "product_set",
		'status' => "Y",
		'limit' => 1000
	))
	{
		push @{$product{'relations'}{'in_product_set'}}, {
			'ID' => $relation->{'l_ID_entity'},
			'quantifier' => $relation->{'quantifier'}
		};
	}
	
	foreach my $relation (App::160::SQL::get_relations(
		'db_name' => $App::910::db_name,
		'l_prefix' => 'a910',
		'l_table' => 'product',
		'l_ID_entity' => $product{'ID'},
		'r_prefix' => "a910",
		'r_table' => "product",
#			'rel_type' => "product_set",
		'status' => "Y",
		'limit' => 1000
	))
	{
		push @{$product{'relations'}{$relation->{'rel_type'} || 'others'}}, {
			'ID' => $relation->{'r_ID_entity'},
			'priority' => $relation->{'priority'},
			'quantifier' => $relation->{'quantifier'}
		};
	}
	
	# hits
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			COUNT(*) AS cnt
		FROM
			$App::910::db_name.a910_product_hit
		WHERE
			ID_product = ?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		$product{'hits'}{'all'} = $db1_line{'cnt'};
	}
	
	# hits 7days
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			COUNT(*) AS cnt
		FROM
			$App::910::db_name.a910_product_hit
		WHERE
			ID_product = ?
			AND datetime_event >= DATE_SUB(NOW(),INTERVAL 7 DAY)
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		$product{'hits'}{'7d'} = $db1_line{'cnt'};
	}
	
	# hits 24hr
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			COUNT(*) AS cnt
		FROM
			$App::910::db_name.a910_product_hit
		WHERE
			ID_product = ?
			AND datetime_event >= DATE_SUB(NOW(),INTERVAL 24 HOUR)
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		$product{'hits'}{'24h'} = $db1_line{'cnt'};
	}
	
	
	# rating_variable
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			a910_product_rating_variable.score_variable AS var,
			AVG(a910_product_rating_variable.score_value) AS val,
			COUNT(DISTINCT(a910_product_rating.ID_entity)) AS cnt
		FROM
			$App::910::db_name.a910_product_rating_variable
		INNER JOIN a910_product_rating ON
		(
			a910_product_rating.ID_entity = a910_product_rating_variable.ID_entity
		)
		WHERE
			a910_product_rating.score_basic IS NULL AND
			a910_product_rating.status='Y' AND
			a910_product_rating.ID_product = ?
		GROUP BY
			a910_product_rating_variable.score_variable
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	my $i_count;
	my $i_sum;
	my $i_avg;
	while (my %db1_line=$sth1{'sth'}->fetchhash())
	{
		main::_log("rating variable '$db1_line{'var'}' cnt='$db1_line{'cnt'}'");
		my $var=$db1_line{'var'};
		$var=lc(Int::charsets::encode::UTF8_ASCII($var));
		$var=~s|[^\w]||g;
		$i_count++;
		$i_sum+=$db1_line{'val'};
		
		$product{'ratings'}{'variable'}{$var} = $db1_line{'val'};
		
#			push @content_ent,WebService::Solr::Field->new( 'Rating_variable.'.$var.'_i' =>  ceil($db1_line{'val'}+0) );
	}
	
	# vahovany rating
	my $helpful_initial=2;
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT (
			SUM(
				IF (rating.score_basic, rating.score_basic,
					(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity))
				* COALESCE((
					SELECT IF (rating_weight,rating_weight,0.01)
					FROM TOM.a301_user_profile
					WHERE ID_entity = rating.posix_owner
					LIMIT 1
				),0.5) * ((rating.helpful_Y+$helpful_initial) / (rating.helpful_Y+$helpful_initial + rating.helpful_N+$helpful_initial))
			) / SUM( COALESCE((
					SELECT IF (rating_weight,rating_weight,0.01)
					FROM TOM.a301_user_profile
					WHERE ID_entity = rating.posix_owner
					LIMIT 1
				),0.5) * ((rating.helpful_Y+$helpful_initial) / (rating.helpful_Y+$helpful_initial + rating.helpful_N+$helpful_initial))
			)
		) AS score,
			COUNT(rating.ID) AS ratings,
			MAX(rating.datetime_rating) AS datetime_rating
		FROM
			$App::910::db_name.a910_product_rating AS rating
		WHERE
			rating.status='Y'
--				AND (
--					SELECT ID
--					FROM TOM.a301_user_profile
--					WHERE ID_entity = rating.posix_owner
--					LIMIT 1
--				) IS NOT NULL
			AND (rating.score_basic IS NOT NULL
				OR (
					SELECT COUNT(rating_variable.score_value) FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity
				) > 0
			)
			AND rating.ID_product = ?
		GROUP BY
			rating.ID_product
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	my %db1_line=$sth1{'sth'}->fetchhash();
	
	if ($db1_line{'ratings'})
	{
		$db1_line{'score'} = 0 unless $db1_line{'score'};
		main::_log("ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
		
		$product{'ratings'}->{'weighted'}->{'count'} = ceil($db1_line{'ratings'});
		$product{'ratings'}->{'weighted'}->{'avg'} = $db1_line{'score'};
	}
	
	# rating in last 6months (not weighted)
	if ($db1_line{'ratings'})
	{
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				AVG(IF (rating.score_basic, rating.score_basic,
					(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity)))
					AS score,
				COUNT(rating.ID) AS ratings
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
				AND rating.datetime_rating >= DATE_SUB(NOW(),INTERVAL 6 MONTH)
				AND rating.ID_product = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		if ($db1_line{'ratings'})
		{
			main::_log("6mo ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
			$db1_line{'score'} = 0 unless $db1_line{'score'};
			
			$product{'ratings'}->{'6m'}->{'count'} = $db1_line{'ratings'};
			$product{'ratings'}->{'6m'}->{'avg'} = $db1_line{'score'};
		}
	}
	
	my %sth1=TOM::Database::SQL::execute(qq{
		SELECT
			COUNT(rating.ID) AS ratings
		FROM
			$App::910::db_name.a910_product_rating AS rating
		WHERE
			rating.status='Y'
			AND rating.posix_owner != ''
			AND rating.description IS NOT NULL
			AND rating.status_publish='Y'
			AND rating.ID_product = ?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	my %db1_line=$sth1{'sth'}->fetchhash();
	if ($db1_line{'ratings'})
	{
		$product{'ratings'}{'count_public'} = $db1_line{'ratings'};
#			push @content_ent,WebService::Solr::Field->new( 'Rating_public_count_i' =>  int($db1_line{'ratings'}));
	}
	
	delete $product{'datetime_publish_start'}
		if $product{'datetime_publish_start'}=~/^0/;
	
#		main::_log("index ID=$product{'ID'}",3,"elastic");
	my %log_date=main::ctogmdatetime(time(),format=>1);
	
	delete $product{'metahash'} unless keys %{$product{'metahash'}};
	delete $product{'relations'} unless keys %{$product{'relations'}};
	
	return %product;		
}


sub _product_index_solr
{
	my %env=@_;
	
	if ($env{'-jobify'})
	{
		return 1 if TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::910::db_name,'class'=>'fifo','deduplication'=>1});
	}
	
	return undef unless $env{'ID'}; # product.ID
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_index_solr($env{'ID'})",'timer'=>1);
	
	my @content_ent;
	my @content_id;
	
	my $status_string = $App::910::solr_status_index;
	
	$status_string =~ s/(\w)/\'$1\',/g; $status_string =~ s/,$//;
	
#		main::_log(" status=$status_string");
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::910::db_name.a910_product
		WHERE
			status IN ( $status_string ) AND
			ID=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$env{'ID_entity'}=$db0_line{'ID_entity'};
		main::_log(" ID_entity=$db0_line{'ID_entity'}");
		
		push @content_ent,WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} )
			if $db0_line{'ID_entity'};
		
		push @content_ent,WebService::Solr::Field->new( 'product_number_s' => $db0_line{'product_number'} )
			if $db0_line{'product_number'};
		push @content_ent,WebService::Solr::Field->new( 'product_number_t' => $db0_line{'product_number'} )
			if $db0_line{'product_number'};
		
		push @content_ent,WebService::Solr::Field->new( 'amount_f' => $db0_line{'amount'} )
			if $db0_line{'amount'};
		
		push @content_ent,WebService::Solr::Field->new( 'status_new_s' => $db0_line{'status_new'} )
			if $db0_line{'status_new'};
		push @content_ent,WebService::Solr::Field->new( 'status_sale_s' => $db0_line{'status_sale'} )
			if $db0_line{'status_sale'};
		push @content_ent,WebService::Solr::Field->new( 'status_special_s' => $db0_line{'status_special'} )
			if $db0_line{'status_special'};
		push @content_ent,WebService::Solr::Field->new( 'status_recommended_s' => $db0_line{'status_recommended'} )
			if $db0_line{'status_recommended'};
		push @content_id,WebService::Solr::Field->new( 'status_main_s' => $db0_line{'status_main'} )
			if $db0_line{'status_main'};
		push @content_id,WebService::Solr::Field->new( 'status_s' => $db0_line{'status'} )
			if $db0_line{'status'};
		
		push @content_id,WebService::Solr::Field->new( 'price_f' => $db0_line{'price'} )
			if $db0_line{'price'};
			
		push @content_id,WebService::Solr::Field->new( 'price_full_f' => $db0_line{'price_full'} )
			if $db0_line{'price_full'};
		
		push @content_id,WebService::Solr::Field->new( 'sellscore_f' => $db0_line{'sellscore'} )
			if $db0_line{'sellscore'};
		
		if ($db0_line{'datetime_next_index'} && not $db0_line{'datetime_publish_start'} =~/^0000/)
		{
			$db0_line{'datetime_next_index'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_next_index'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'next_index_tdt' => $db0_line{'datetime_next_index'} );
		}
		
		if ($db0_line{'datetime_publish_start'} && not $db0_line{'datetime_publish_start'} =~/^0000/)
		{
			$db0_line{'datetime_publish_start'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_publish_start'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'datetime_publish_start_tdt' => $db0_line{'datetime_publish_start'} );
		}
		
		if ($db0_line{'datetime_publish_stop'} && not $db0_line{'datetime_publish_stop'} =~/^0000/)
		{
			$db0_line{'datetime_publish_stop'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_publish_stop'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'datetime_publish_stop_tdt' => $db0_line{'datetime_publish_stop'} );
		}
		
		my %metadata=App::020::functions::metadata::parse($db0_line{'metadata'});
#			use Data::Dumper;print Dumper(\%metadata);
		foreach my $sec(keys %metadata)
		{
			foreach (keys %{$metadata{$sec}})
			{
				next unless $metadata{$sec}{$_};
				if ($_=~s/\[\]$//)
				{
#						print "$sec\n";
					# this is comma separated array
					foreach my $val (split(';',$metadata{$sec}{$_.'[]'}))
					{push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_sm' => $val)}
					push @content_ent,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_);
					next;
				}
				
				push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_s' => "$metadata{$sec}{$_}" );
				if ($metadata{$sec}{$_}=~/^[0-9]{1,9}0*?$/ && $metadata{$sec}{$_} < 2147483647)
				{
					push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_i' => "$metadata{$sec}{$_}" );
				}
				if ($metadata{$sec}{$_}=~/^[0-9\.]{1,9}0*?$/ && (not $metadata{$sec}{$_}=~/\..*?\./))
				{
					push @content_ent,WebService::Solr::Field->new( $sec.'.'.$_.'_f' => "$metadata{$sec}{$_}" );
				}
				
				# list of used metadata fields
				push @content_ent,WebService::Solr::Field->new( 'metadata_used_sm' => $sec.'.'.$_ );
			}
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::910::db_name.a910_product_ent
			WHERE
				ID_entity=?
		},'quiet'=>1,'bind'=>[$db0_line{'ID_entity'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			push @content_ent,WebService::Solr::Field->new( 'product_type_s' => $db1_line{'product_type'} );
			push @content_ent,WebService::Solr::Field->new( 'posix_owner_s' => $db1_line{'posix_owner'} );
			
			my %sth2=TOM::Database::SQL::execute(qq{
				SELECT
					name
				FROM
					`$App::910::db_name`.a910_product_brand
				WHERE
					ID=?
			},'quiet'=>1,'bind'=>[$db1_line{'ID_brand'}]);
			if (my %db2_line=$sth2{'sth'}->fetchhash())
			{
				push @content_ent,WebService::Solr::Field->new( 'brand_f' =>  $db1_line{'ID_brand'});
				push @content_ent,WebService::Solr::Field->new( 'brand_name_s' =>  $db2_line{'name'});
				push @content_ent,WebService::Solr::Field->new( 'brand_name_t' =>  $db2_line{'name'});
			}
		}
		
		# hits
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(*) AS cnt
			FROM
				$App::910::db_name.a910_product_hit
			WHERE
				ID_product = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{push @content_ent,WebService::Solr::Field->new( 'hits_i' =>  $db1_line{'cnt'});}
		
		# hits 7days
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(*) AS cnt
			FROM
				$App::910::db_name.a910_product_hit
			WHERE
				ID_product = ?
				AND datetime_event >= DATE_SUB(NOW(),INTERVAL 7 DAY)
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{push @content_ent,WebService::Solr::Field->new( 'hits_7dy_i' =>  $db1_line{'cnt'})}
		
		# hits 24hr
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(*) AS cnt
			FROM
				$App::910::db_name.a910_product_hit
			WHERE
				ID_product = ?
				AND datetime_event >= DATE_SUB(NOW(),INTERVAL 24 HOUR)
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db1_line=$sth1{'sth'}->fetchhash())
		{push @content_ent,WebService::Solr::Field->new( 'hits_24hr_i' =>  $db1_line{'cnt'})}
		
		# rating_variable
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_rating_variable.score_variable AS var,
				AVG(a910_product_rating_variable.score_value) AS val,
				COUNT(DISTINCT(a910_product_rating.ID_entity)) AS cnt
			FROM
				$App::910::db_name.a910_product_rating_variable
			INNER JOIN a910_product_rating ON
			(
				a910_product_rating.ID_entity = a910_product_rating_variable.ID_entity
			)
			WHERE
				a910_product_rating.score_basic IS NULL AND
				a910_product_rating.status='Y' AND
				a910_product_rating.ID_product = ?
			GROUP BY
				a910_product_rating_variable.score_variable
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my $i_count;
		my $i_sum;
		my $i_avg;
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			main::_log("rating variable '$db1_line{'var'}' cnt='$db1_line{'cnt'}'");
			my $var=$db1_line{'var'};
			$var=lc(Int::charsets::encode::UTF8_ASCII($var));
			$var=~s|[^\w]||g;
			$i_count++;
			$i_sum+=$db1_line{'val'};
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable.'.$var.'_i' =>  ceil($db1_line{'val'}+0));
		}
		
		# vahovany rating
		my $helpful_initial=2;
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT (
				SUM(
					IF (rating.score_basic, rating.score_basic,
						(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity))
					* COALESCE((
						SELECT IF (rating_weight,rating_weight,0.01)
						FROM TOM.a301_user_profile
						WHERE ID_entity = rating.posix_owner
						LIMIT 1
					),0.5) * ((rating.helpful_Y+$helpful_initial) / (rating.helpful_Y+$helpful_initial + rating.helpful_N+$helpful_initial))
				) / SUM( COALESCE((
						SELECT IF (rating_weight,rating_weight,0.01)
						FROM TOM.a301_user_profile
						WHERE ID_entity = rating.posix_owner
						LIMIT 1
					),0.5) * ((rating.helpful_Y+$helpful_initial) / (rating.helpful_Y+$helpful_initial + rating.helpful_N+$helpful_initial))
				)
			) AS score,
				COUNT(rating.ID) AS ratings,
				MAX(rating.datetime_rating) AS datetime_rating
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
--				AND (
--					SELECT ID
--					FROM TOM.a301_user_profile
--					WHERE ID_entity = rating.posix_owner
--					LIMIT 1
--				) IS NOT NULL
				AND (rating.score_basic IS NOT NULL
					OR (
						SELECT COUNT(rating_variable.score_value) FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity
					) > 0
				)
				AND rating.ID_product = ?
			GROUP BY
				rating.ID_product
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		
		if ($db1_line{'ratings'})
		{
			$db1_line{'score'} = 0 unless $db1_line{'score'};
			main::_log("ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable_count_i' =>  ceil($db1_line{'ratings'}));
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable_avg_i' =>  ceil($db1_line{'score'}));
			push @content_ent,WebService::Solr::Field->new( 'Rating_variable_avg_f' =>  $db1_line{'score'});
			
#			$db1_line{'datetime_rating'}=~s| (\d\d)|T$1|;
#			$db1_line{'datetime_rating'}.="Z";
#			push @content_id,WebService::Solr::Field->new( 'Rating_datetime_tdt' => $db1_line{'datetime_rating'} );
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				rating.datetime_rating
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
				AND length(rating.description) >= 10
				AND rating.ID_product = ?
			ORDER BY
				rating.datetime_rating DESC
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		if ($db1_line{'datetime_rating'})
		{
			$db1_line{'datetime_rating'}=~s| (\d\d)|T$1|;
			$db1_line{'datetime_rating'}.="Z";
			push @content_id,WebService::Solr::Field->new( 'Rating_datetime_tdt' => $db1_line{'datetime_rating'} );
		}
		
		# rating in last 6months (not weighted)
		if ($db1_line{'ratings'})
		{
			my %sth1=TOM::Database::SQL::execute(qq{
				SELECT
					AVG(IF (rating.score_basic, rating.score_basic,
						(SELECT AVG(rating_variable.score_value) AS val FROM $App::910::db_name.a910_product_rating_variable AS rating_variable WHERE rating.ID_entity = rating_variable.ID_entity)))
						AS score,
					COUNT(rating.ID) AS ratings
				FROM
					$App::910::db_name.a910_product_rating AS rating
				WHERE
					rating.status='Y'
					AND rating.datetime_rating >= DATE_SUB(NOW(),INTERVAL 6 MONTH)
					AND rating.ID_product = ?
			},'quiet'=>1,'bind'=>[$env{'ID'}]);
			my %db1_line=$sth1{'sth'}->fetchhash();
			if ($db1_line{'ratings'})
			{
				main::_log("6mo ratings avg='$db1_line{'score'}' count='$db1_line{'ratings'}'");
				$db1_line{'score'} = 0 unless $db1_line{'score'};
				push @content_ent,WebService::Solr::Field->new( 'Rating_variable_6mo_count_i' =>  ceil($db1_line{'ratings'}));
				push @content_ent,WebService::Solr::Field->new( 'Rating_variable_6mo_avg_i' =>  ceil($db1_line{'score'}));
				push @content_ent,WebService::Solr::Field->new( 'Rating_variable_6mo_avg_f' =>  $db1_line{'score'});
			}
		}
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				COUNT(rating.ID) AS ratings
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
				AND rating.posix_owner != ''
				AND rating.description IS NOT NULL
				AND rating.status_publish='Y'
				AND rating.ID_product = ?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		if ($db1_line{'ratings'})
		{
			push @content_ent,WebService::Solr::Field->new( 'Rating_public_count_i' =>  int($db1_line{'ratings'}));
		}
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $env{'ID'},
			'rel_type' => 'thumbnail',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			push @content_ent,WebService::Solr::Field->new( 'is_thumbnail_i' => 1);
			push @content_ent,WebService::Solr::Field->new( 'is_thumbnail_s' => 'Y');
			push @content_ent,WebService::Solr::Field->new( 'thumbnail_i' => $relation->{'r_ID_entity'});
		}
		
		if (my $relation=(App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $env{'ID'},
			'rel_type' => 'gallery',
			'r_prefix' => "a501",
			'r_table' => "image",
			'status' => "Y",
			'limit' => 1
		))[0])
		{
			push @content_ent,WebService::Solr::Field->new( 'is_gallery_i' => 1);
			push @content_ent,WebService::Solr::Field->new( 'is_gallery_s' => 'Y');
		}
		
		# prices
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_price.*,
				a910_price_level.name_code
			FROM
				$App::910::db_name.a910_product_price
			INNER JOIN $App::910::db_name.a910_price_level ON
			(
				a910_product_price.ID_price = a910_price_level.ID_entity
			)
			WHERE
				a910_product_price.ID_entity = ?
				AND a910_product_price.status = 'Y'
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
			next if $db1_line{'price'} == 0;
			push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_f' =>  $db1_line{'price'});
#			push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_VAT_f' =>  );
			push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_full_f' =>  $db1_line{'price_full'} || $db1_line{'price'});
			
			if ($App::910::solr_price_history)
			{
				foreach my $part ('2:DAY','7:DAY','4:WEEK','6:MONTH','12:MONTH')
				{
					my ($interval,$interval_type)=split(':',$part);
#					my $interval='7';
#					my $interval_type='DAY';
					my $interval_down=$interval+($interval/2);
					my $interval_up=$interval-($interval/2);
					
					# history of prices
					
					# start price
					my %sth2=TOM::Database::SQL::execute(qq{
						SELECT
							a910_product_price_j.*,
							a910_price_level.name_code
						FROM
							$App::910::db_name.a910_product_price_j
						INNER JOIN $App::910::db_name.a910_price_level ON
						(
							a910_product_price_j.ID_price = a910_price_level.ID_entity
						)
						WHERE
							a910_product_price_j.ID_entity = ?
							AND a910_product_price_j.ID = ?
							AND a910_product_price_j.datetime_create < DATE_SUB(NOW(),INTERVAL $interval_down $interval_type)
						ORDER BY
							a910_product_price_j.datetime_create DESC
						LIMIT 1
					},'quiet'=>1,'bind'=>[$env{'ID'},$db1_line{'ID'}]);
					my %db2_line=$sth2{'sth'}->fetchhash();
					
					next unless $db2_line{'datetime_create'};
					
					main::_log("$db1_line{'ID'}: START at '$db2_line{'datetime_create'}' with price '$db2_line{'price'}/$db2_line{'price_full'}'");
	#				main::_log("$db1_line{'ID'}: ending with price '$db1_line{'price'}/$db1_line{'price_full'}'");
					
					my %prices;
					my $i;
					my %sth3=TOM::Database::SQL::execute(qq{
						SELECT
							a910_product_price_j.*,
							TIMESTAMPDIFF(MINUTE,
								COALESCE((
									SELECT
										j2.datetime_create
									FROM
										$App::910::db_name.a910_product_price_j AS j2
									WHERE
										j2.ID_entity = a910_product_price_j.ID_entity
										AND j2.ID = a910_product_price_j.ID
										AND j2.datetime_create < a910_product_price_j.datetime_create
										AND j2.datetime_create > DATE_SUB(NOW(),INTERVAL $interval_down $interval_type)
									ORDER BY
										j2.datetime_create DESC
									LIMIT 1
								),DATE_SUB(NOW(),INTERVAL $interval_down $interval_type)),a910_product_price_j.datetime_create
							) AS date_diff_previous,
							TIMESTAMPDIFF(MINUTE,a910_product_price_j.datetime_create,
								COALESCE((
									SELECT
										j2.datetime_create
									FROM
										$App::910::db_name.a910_product_price_j AS j2
									WHERE
										j2.ID_entity = a910_product_price_j.ID_entity
										AND j2.ID = a910_product_price_j.ID
										AND j2.datetime_create > a910_product_price_j.datetime_create
										AND j2.datetime_create < DATE_SUB(NOW(),INTERVAL $interval_up $interval_type)
									ORDER BY
										j2.datetime_create ASC
									LIMIT 1
								),DATE_SUB(NOW(),INTERVAL $interval_up $interval_type))
							) AS date_diff_to
						FROM
							$App::910::db_name.a910_product_price_j
						WHERE
							a910_product_price_j.ID_entity = ?
							AND a910_product_price_j.ID = ?
							AND a910_product_price_j.datetime_create >= DATE_SUB(NOW(),INTERVAL $interval_down $interval_type)
							AND a910_product_price_j.datetime_create <= DATE_SUB(NOW(),INTERVAL $interval_up $interval_type)
						ORDER BY
							a910_product_price_j.datetime_create
					},'quiet'=>1,'bind'=>[$env{'ID'},$db1_line{'ID'}]);
					while (my %db3_line=$sth3{'sth'}->fetchhash())
					{
						main::_log("$db3_line{'ID'}: CHANG at '$db3_line{'datetime_create'}' to price '$db3_line{'price'}/$db3_line{'price_full'}' (duration=$db3_line{'date_diff_to'} previous=$db3_line{'date_diff_previous'})");
						if (!$i){$prices{$db2_line{'price'}}+=$db3_line{'date_diff_previous'};}
						$prices{$db3_line{'price'}}+=$db3_line{'date_diff_to'};
						$i++;
					}
					
					if (!$i){$prices{$db2_line{'price'}}+=1;}
					
					my $prices_sum;
					my $prices_i;
					foreach (keys %prices){$prices_i+=$prices{$_};$prices_sum+=$_*$prices{$_};}
					
					my $avg=ceil(($prices_sum/$prices_i)*100)/100;
					
					my $code=$interval.do{$interval_type=~/^(.)/;lc($1);};
					
					main::_log("$db1_line{'name_code'}.$code avg=".$avg);
					
					push @content_ent,WebService::Solr::Field->new( 'price.'.$db1_line{'name_code'}.'_'.$code.'_f' =>  $avg);
					
				}
			}
			# end price history
			
#			main::_log("---");
			
		}
		
		# set
		foreach my $relation (App::160::SQL::get_relations(
			'db_name' => $App::910::db_name,
			'l_prefix' => 'a910',
			'l_table' => 'product',
			'l_ID_entity' => $db0_line{'ID'},
			'r_prefix' => "a910",
			'r_table' => "product",
			'rel_type' => "product_set",
			'status' => "Y"
		))
		{
			
			main::_log("product_set relation to ".$relation->{'r_ID_entity'}." ".$relation->{'priority'});
			push @content_id,WebService::Solr::Field->new( 'set_product_sm' =>  $relation->{'r_ID_entity'}.':'.$relation->{'quantifier'});
			
		}
		
	}
	
	my %content;
	
	my %sth0=TOM::Database::SQL::execute(qq{
		SELECT
			*
		FROM
			$App::910::db_name.a910_product_lng
		WHERE
			status='Y'
			AND ID_entity=?
	},'quiet'=>1,'bind'=>[$env{'ID'}]);
	while (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		my $lng=$db0_line{'lng'};
#		main::_log("product_lng ID='$db0_line{'ID'}' lng='$lng'");
		
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				a910_product_sym.ID,
				a910_product_cat.ID_charindex,
				a910_product_cat.ID as cat_ID
			FROM
				$App::910::db_name.a910_product_sym
			INNER JOIN $App::910::db_name.a910_product_cat ON
			(
				a910_product_sym.ID = a910_product_cat.ID_entity
				AND a910_product_cat.lng = ?
			)
			WHERE
				a910_product_sym.status='Y'
				AND a910_product_sym.ID_entity=?
		},'quiet'=>1,'bind'=>[$db0_line{'lng'},$env{'ID_entity'}]);
		while (my %db1_line=$sth1{'sth'}->fetchhash())
		{
#			main::_log("[$lng] cat+ $db1_line{'ID'} $db1_line{'ID_charindex'}");
			push @{$content{$lng}},WebService::Solr::Field->new( 'cat_charindex_sm' =>  $db1_line{'ID_charindex'}); # product_cat.ID_entity
			push @{$content{$lng}},WebService::Solr::Field->new( 'cat' =>  $db1_line{'ID'});
			
			my %sql_def=('db_h' => "main",'db_name' => $App::910::db_name,'tb_name' => "a910_product_cat");
			foreach my $p(
				App::020::SQL::functions::tree::get_path(
					$db1_line{'cat_ID'},
					%sql_def,
					'-cache' => 86400*7
				)
			)
			{
#				main::_log(" cat_sm=".$p->{'ID_entity'});
				push @{$content{$lng}},WebService::Solr::Field->new( 'cat_path_sm' =>  $p->{'ID_entity'});
			}
			
		}
		
		# save original HTML values
		$db0_line{'description_short'}=~s/\|/&#124;/g;
		if ($tom::test && $db0_line{'lng'} eq "pl")
		{
			$db0_line{'description_short'}=~tr/ł/l/;
#				print $db0_line{'description_short'}."\n";
		}
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description_short_orig_pl' => $db0_line{'description_short'} )
			if $db0_line{'description_short'};
		$db0_line{'description'}=~s/\|/&#124;/g;
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description_orig_pl' => $db0_line{'description'} )
			if $db0_line{'description'};
		
		for my $part('description_short', 'description')
		{
			$db0_line{$part}=~s|<.*?>||gms;
			$db0_line{$part}=~s|&nbsp;| |gms;
			$db0_line{$part}=~s|  | |gms;
#			for (0,1,2,4,11,'B','0161','0165')
#			{$db0_line{$part}=~s|\x{$_}||g;}
		}
		
		push @{$content{$lng}},WebService::Solr::Field->new( 'lng_s' => $lng );
		
		push @{$content{$lng}},WebService::Solr::Field->new( 'name' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @{$content{$lng}},WebService::Solr::Field->new( 'title' => $db0_line{'name'} )
			if $db0_line{'name'};
		push @{$content{$lng}},WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} )
			if $db0_line{'name_url'};
		push @{$content{$lng}},WebService::Solr::Field->new( 'subject' => $db0_line{'name_long'} )
			if ($db0_line{'name_long'});
		push @{$content{$lng}},WebService::Solr::Field->new( 'name_label_s' => $db0_line{'name_label'} )
			if $db0_line{'name_label'};
		
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'description' => $db0_line{'description_short'} )
			if $db0_line{'description_short'};
		
#		print $db0_line{'description'}."\n";
#		my $len=9268;
#		print "!".ord(substr($db0_line{'description'},$len-1,1))."!\n";
#		print "!".ord(substr($db0_line{'description'},$len,1))."!\n";
#		print "!".ord(substr($db0_line{'description'},$len+1,1))."!\n";
#		$db0_line{'description'}=substr($db0_line{'description'},0,$len);
		
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'text' => $db0_line{'description'} )
			if $db0_line{'description'};
		push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'keywords' => $db0_line{'keywords'} )
			if $db0_line{'keywords'};
		
		if ($db0_line{'datetime_modified'})
		{
			$db0_line{'datetime_modified'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_modified'}.="Z";
			push @{$content{$lng}},WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_modified'} );
		}
		
		# language rating
		my %sth1=TOM::Database::SQL::execute(qq{
			SELECT
				rating.datetime_rating
			FROM
				$App::910::db_name.a910_product_rating AS rating
			WHERE
				rating.status='Y'
				AND length(rating.description) >= 10
				AND rating.ID_product = ?
				AND rating.lng = ?
			ORDER BY
				rating.datetime_rating DESC
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'ID'},$db0_line{'lng'}]);
		my %db1_line=$sth1{'sth'}->fetchhash();
		if ($db1_line{'datetime_rating'})
		{
			$db1_line{'datetime_rating'}=~s| (\d\d)|T$1|;
			$db1_line{'datetime_rating'}.="Z";
			push @{$content{$db0_line{'lng'}}},WebService::Solr::Field->new( 'Rating_datetime_lng_tdt' => $db1_line{'datetime_rating'} );
		}
		
	}
	
	use Data::Dumper;
#	print Dumper(@content_id);
	
	my $solr = Ext::Solr::service();
	
	# how many products of this type we have indexed?
	my $response = $solr->search( "+id:".$App::910::index_name.".a910_product.* +ID_i:$env{'ID'}" );
	for my $doc ( $response->docs )
	{
		my $lng=$doc->value_for( 'lng_s' );
		if (!$content{$lng} || !$env{'ID_entity'})
		{
			main::_log("remove ".$doc->value_for('id'),1);
			$solr->delete_by_id($doc->value_for('id'));
		}
	}
	
	if ($env{'ID_entity'})
	{
		my $last_indexed=$tom::Fyear."-".$tom::Fmom."-".$tom::Fmday."T".$tom::Fhour.":".$tom::Fmin.":".$tom::Fsec."Z";
		foreach my $lng (keys %content)
		{
			my $id=$App::910::index_name.".a910_product.".$lng.".".$env{'ID'};
			
			my $doc = WebService::Solr::Document->new();
			
			$doc->add_fields((
				WebService::Solr::Field->new( 'id' => $id ),
				@content_ent,
				@content_id,
				@{$content{$lng}},
				WebService::Solr::Field->new( 'db_s' => $App::910::db_name ),
				WebService::Solr::Field->new( 'addon_s' => 'a910_product' ),
				WebService::Solr::Field->new( 'ID_i' => $env{'ID'} ),
				WebService::Solr::Field->new( 'last_indexed_tdt' => $last_indexed )
			));
			
#			print Dumper($doc);
			$solr->add($doc);
		}
	}
	
	if ($env{'commit'})
	{
		$solr->commit();
	}
	
	$t->close();
	
}


sub _product_cat_index
{
	my %env=@_;
	return undef unless $env{'ID'};
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_cat_index()",'timer'=>1);
	
	if ($Ext::Solr && ($env{'solr'} || not exists $env{'solr'}))
	{
		my $solr = Ext::Solr::service();
		
		my %content;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::910::db_name.a910_product_cat
			WHERE
				status IN ('Y','L')
				AND ID=?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("found");
			
			my $id=$App::910::index_name.".a910_product_cat.".$db0_line{'lng'}.".".$db0_line{'ID'};
			main::_log("index id='$id'");
			
			my $doc = WebService::Solr::Document->new();
			
			$db0_line{'description'}=~s|<.*?>||gms;
			$db0_line{'description'}=~s|&nbsp;| |gms;
			$db0_line{'description'}=~s|  | |gms;
			
			$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_create'}.="Z";
			
			
			$doc->add_fields((
				WebService::Solr::Field->new( 'id' => $id ),
				
				WebService::Solr::Field->new( 'name' => $db0_line{'name'} ),
				WebService::Solr::Field->new( 'name_partial' => $db0_line{'name'} ),
				WebService::Solr::Field->new( 'name_t' => $db0_line{'name'} ),
				WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
				WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
				WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
				
				WebService::Solr::Field->new( 'description' => $db0_line{'description'} ),
				
				WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
				
				WebService::Solr::Field->new( 'db_s' => $App::910::db_name ),
				WebService::Solr::Field->new( 'addon_s' => 'a910_product_cat' ),
				WebService::Solr::Field->new( 'lng_s' => $db0_line{'lng'} ),
				WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
				WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
				do {if ($db0_line{'alias_name'}){WebService::Solr::Field->new( 'alias_name_s' => $db0_line{'alias_name'} )}},
			));
			
			$solr->add($doc);
		}
		else
		{
			main::_log("not found active ID",1);
			my $response = $solr->search( "id:".$App::910::index_name.".a910_product_cat.* AND ID_i:$env{'ID'}" );
			for my $doc ( $response->docs )
			{
				$solr->delete_by_id($doc->value_for('id'));
			}
		}
	}
	
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my %product_cat=App::020::SQL::functions::get_ID(
			'ID' => $env{'ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_cat",
			'columns' => {'*'=>1}
		);
		if (!$product_cat{'ID'})
		{
			$t->close();
			return 1;
		}
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID_entity
			FROM
				$App::910::db_name.a910_product_cat AS product_cat
			WHERE
				product_cat.status IN ('Y','N','L','W') AND
				product_cat.ID_entity=?
			LIMIT 1
		},'quiet'=>1,'bind'=>[$product_cat{'ID_entity'}]);
		if (!$sth0{'rows'})
		{
			main::_log("product_cat.ID=$product_cat{'ID_entity'} not found as valid item");
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::910::index_name,
				'type' => 'a910_product_cat',
				'id' => $product_cat{'ID_entity'}
			))
			{
				main::_log("removing from Elastic");
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::910::index_name,
					'type' => 'a910_product_cat',
					'id' => $product_cat{'ID_entity'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %product_cat=$sth0{'sth'}->fetchhash();
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID,
				name,
				alias_name,
				lng
			FROM
				$App::910::db_name.a910_product_cat AS product_cat
			WHERE
				product_cat.status IN ('Y','L') AND
				product_cat.ID_entity=?
		},'quiet'=>1,'bind'=>[$product_cat{'ID_entity'}]);
		while (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			if ($db0_line{'alias_name'})
			{
				$db0_line{'name'}=[
					$db0_line{'name'},
					$db0_line{'alias_name'}
				];
				delete $db0_line{'alias_name'};
			}
			else
			{
				$db0_line{'name'}=[
					$db0_line{'name'}
				];
			}
			
			my %sql_def=('db_h' => "main",'db_name' => $App::910::db_name,'tb_name' => "a910_product_cat");
			foreach my $p(
				App::020::SQL::functions::tree::get_path(
					$db0_line{'ID'},
					%sql_def,
					'-cache' => 86400*7
				)
			)
			{
				push @{$db0_line{'cat_path'}},$p->{'ID_entity'};
			}
			
			$db0_line{'cat_level'} = scalar @{$db0_line{'cat_path'}};
			
			%{$product_cat{'locale'}{$db0_line{'lng'}}}=%db0_line;
		}
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		
		main::_log("index",{
			'facility' => 'elastic',
			'severity' => 3,
			'data' => {
				'action' => 'index',
	#			'hostname' => $self->{'host_name'},
				'index_s' => 'cyclone3.'.$App::910::index_name,
				'type_s' => 'a910_product_cat',
				'ID_entity_s' => $product_cat{'ID_entity'}
			}
		});
		
		$Elastic->index(
			'index' => 'cyclone3.'.$App::910::index_name,
			'type' => 'a910_product_cat',
			'id' => $product_cat{'ID_entity'},
			'body' => {
				%product_cat,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
	}
	
	$t->close();
}



sub product_brand_add
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::product_brand_add()");
	
	my $content_reindex;
	
	my %product_brand;
	
	if ($env{'product_brand.ID'})
	{
		$env{'product_brand.ID'}=$env{'product_brand.ID'}+0;
		undef $env{'product_brand.ID_entity'}; # ID_entity has lower priority as ID
		# when real ID_entity used, then read it from ID
		# when ID not found, undef ID_entity, because is invalid
		main::_log("finding product_brand.ID_entity by product_brand.ID='$env{'product_brand.ID'}'");
		%product_brand=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_brand.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand",
			'columns' => {'*'=>1}
		);
		if ($product_brand{'ID'})
		{
			$env{'product_brand.ID_entity'}=$product_brand{'ID_entity'};
			main::_log("found product_brand.ID_entity='$env{'product_brand.ID_entity'}'");
		}
		else
		{
			main::_log("not found product_brand.ID, undef",1);
			$content_reindex=1;
			App::020::SQL::functions::new(
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_brand",
				'columns' => {
					'ID' => $env{'product_brand.ID'}
				},
				'-journalize' => 1,
			);
			%product_brand=App::020::SQL::functions::get_ID(
				'ID' => $env{'product_brand.ID'},
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_brand",
				'columns' => {'*'=>1}
			);
			$env{'product_brand.ID_entity'}=$product_brand{'ID_entity'};
		}
	}
	elsif ($env{'product_brand.code'})
	{
		undef $env{'product_brand.ID_entity'};
		undef $env{'product_brand.ID'};
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID,
				ID_entity
			FROM
				`$App::910::db_name`.a910_product_brand
			WHERE
				code = ?
			LIMIT 1
		},'quiet'=>1,'bind'=>[$env{'product_brand.code'}]);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			$env{'product_brand.ID'} = $db0_line{'ID'};
			$env{'product_brand.ID_entity'} = $db0_line{'ID_entity'};
			%product_brand=App::020::SQL::functions::get_ID(
				'ID' => $env{'product_brand.ID'},
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_brand",
				'columns' => {'*'=>1}
			);
		}
		elsif ($env{'product_brand.name'})
		{
			my %sth0=TOM::Database::SQL::execute(qq{
				SELECT
					ID,
					ID_entity
				FROM
					`$App::910::db_name`.a910_product_brand
				WHERE
					name = ?
				LIMIT 1
			},'quiet'=>1,'bind'=>[$env{'product_brand.name'}]);
			if (my %db0_line=$sth0{'sth'}->fetchhash())
			{
				$env{'product_brand.ID'} = $db0_line{'ID'};
				$env{'product_brand.ID_entity'} = $db0_line{'ID_entity'};
				%product_brand=App::020::SQL::functions::get_ID(
					'ID' => $env{'product_brand.ID'},
					'db_h' => "main",
					'db_name' => $App::910::db_name,
					'tb_name' => "a910_product_brand",
					'columns' => {'*'=>1}
				);
			}
		}
		
		main::_log("found? product_brand.ID='$env{'product_brand.ID'}'");
	}
	
	if (!$env{'product_brand.ID'})
	{
		main::_log("!product_brand.ID, create product_brand.ID (product_brand.ID_entity='$env{'product_brand.ID_entity'}')");
		$content_reindex=1;
		my %columns;
		$columns{'ID_entity'}=$env{'product_brand.ID_entity'} if $env{'product_brand.ID_entity'};
		$env{'product_brand.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand",
			'columns' => {%columns},
			'-journalize' => 1,
		);
		%product_brand=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_brand.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand",
			'columns' => {'*'=>1}
		);
		$env{'product_brand.ID'}=$product_brand{'ID'};
		$env{'product_brand.ID_entity'}=$product_brand{'ID_entity'};
	}
	
	main::_log("product_brand.ID='$product_brand{'ID'}' product_brand.ID_entity='$product_brand{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# code
	$data{'code'}=$env{'product_brand.code'}
		if ($env{'product_brand.code'} && ($env{'product_brand.code'} ne $product_brand{'code'}));
	# name
	$data{'name'}=$env{'product_brand.name'}
		if ($env{'product_brand.name'} && ($env{'product_brand.name'} ne $product_brand{'name'}));
	$data{'name_url'}=TOM::Net::URI::rewrite::convert($env{'product_brand.name'})
		if ($env{'product_brand.name'} && ($env{'product_brand.name'} ne $product_brand{'name'}));
	# alias_name
	$data{'alias_name'}=$env{'product_brand.alias_name'}
		if (exists $env{'product_brand.alias_name'} && ($env{'product_brand.alias_name'} ne $product_brand{'alias_name'}));
	# status
	$data{'status'}=$env{'product_brand.status'}
		if ($env{'product_brand.status'} && ($env{'product_brand.status'} ne $product_brand{'status'}));
	# metadata
	$data{'metadata'}=$env{'product_brand.metadata'}
		if ($env{'product_brand.metadata'} && ($env{'product_brand.metadata'} ne $product_brand{'metadata'}));
	
	if (keys %columns || keys %data)
	{
		$content_reindex=1;
		App::020::SQL::functions::update(
			'ID' => $env{'product_brand.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand",
			'columns' => {%columns},
			'data' => {%data},
			'-posix' => 1,
			'-journalize' => 1
		);
	}
	
	# check lng_param
	$env{'product_brand_lng.lng'}=$tom::lng unless $env{'product_brand_lng.lng'};
	main::_log("lng='$env{'product_brand_lng.lng'}'");
	
	# PRODUCT_BRAND_LNG
	
	my %product_brand_lng;
	if (!$env{'product_brand_lng.ID'})
	{
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_brand_lng`
			WHERE
				ID_entity=$env{'product_brand.ID'} AND
				lng='$env{'product_brand_lng.lng'}'
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
		%product_brand_lng=$sth0{'sth'}->fetchhash();
		$env{'product_brand_lng.ID'}=$product_brand_lng{'ID'} if $product_brand_lng{'ID'};
	}
	
	if (!$env{'product_brand_lng.ID'}) # if product_lng not defined, create a new
	{
		main::_log("!product_brand_lng.ID, create product_brand_lng.ID (product_brand_lng.lng='$env{'product_brand_lng.lng'}')");
		$content_reindex=1;
		my %data;
		$data{'ID_entity'}=$env{'product_brand.ID'};
		$data{'lng'}=$env{'product_brand_lng.lng'};
		$env{'product_brand_lng.ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand_lng",
			'data' => {%data},
			'-journalize' => 1,
		);
		%product_brand_lng=App::020::SQL::functions::get_ID(
			'ID' => $env{'product_brand_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand_lng",
			'columns' => {'*'=>1}
		);
		$env{'product_brand_lng.ID'}=$product_brand_lng{'ID'};
		$env{'product_brand_lng.ID_entity'}=$product_brand_lng{'ID_entity'};
	}
	
	main::_log("product_brand_lng.ID='$product_brand_lng{'ID'}' product_brand_lng.ID_entity='$product_brand_lng{'ID_entity'}'");
	
	# update only if necessary
	my %columns;
	my %data;
	# description
	$data{'description'}=$env{'product_brand_lng.description'}
		if ($env{'product_brand_lng.description'} && ($env{'product_brand_lng.description'} ne $product_brand_lng{'description'}));
	
	if (keys %columns || keys %data)
	{
		$content_reindex=1;
		App::020::SQL::functions::update(
			'ID' => $env{'product_brand_lng.ID'},
			'db_h' => "main",
			'db_name' => $App::910::db_name,
			'tb_name' => "a910_product_brand_lng",
			'columns' => {%columns},
			'data' => {%data},
			'-journalize' => 1,
			'-posix' => 1,
		);
	}
	
	if ($content_reindex)
	{
		App::020::SQL::functions::_save_changetime({
			'db_h'=>'main',
			'db_name'=>$App::910::db_name,
			'tb_name'=>'a910_product_brand',
			'ID_entity'=>$env{'product_brand.ID_entity'}}
		);
		# reindex this product_brand
		_product_brand_index('ID'=>$env{'product_brand.ID'});
	}
	
	$t->close();
	return %product_brand;
}



sub _product_brand_index
{
	TOM::Engine::jobify(\@_,{'routing_key' => 'db:'.$App::910::db_name,'class'=>'fifo'});
	my %env=@_;
	return undef unless $env{'ID'};
	
	my $t=track TOM::Debug(__PACKAGE__."::_product_brand_index()",'timer'=>1);
	
	if ($Ext::Solr && ($env{'solr'} || not exists $env{'solr'}))
	{
		my $solr = Ext::Solr::service();
		
		my %content;
		
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				*
			FROM
				$App::910::db_name.a910_product_brand
			WHERE
				status IN ('Y','L')
				AND name != ''
				AND ID=?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (my %db0_line=$sth0{'sth'}->fetchhash())
		{
			main::_log("found '$db0_line{'name'}'");
			
			my $id=$App::910::index_name.".a910_product_brand.en.".$db0_line{'ID'};
			main::_log("index id='$id'");
			
			my $doc = WebService::Solr::Document->new();
			
	#		$db0_line{'description'}=~s|<.*?>||gms;
	#		$db0_line{'description'}=~s|&nbsp;| |gms;
	#		$db0_line{'description'}=~s|  | |gms;
			
			$db0_line{'datetime_create'}=~s| (\d\d)|T$1|;
			$db0_line{'datetime_create'}.="Z";
			
			
			$doc->add_fields((
				WebService::Solr::Field->new( 'id' => $id ),
				
				WebService::Solr::Field->new( 'name' => $db0_line{'name'} ),
				WebService::Solr::Field->new( 'name_t' => $db0_line{'name'} ),
				WebService::Solr::Field->new( 'name_url_s' => $db0_line{'name_url'} || ''),
				WebService::Solr::Field->new( 'title' => $db0_line{'name'} ),
				
	#			WebService::Solr::Field->new( 'description' => $db0_line{'description'} ),
				
				WebService::Solr::Field->new( 'last_modified' => $db0_line{'datetime_create'} ),
				
				WebService::Solr::Field->new( 'db_s' => $App::910::db_name ),
				WebService::Solr::Field->new( 'addon_s' => 'a910_product_brand' ),
				WebService::Solr::Field->new( 'lng_s' => 'en' ),
				WebService::Solr::Field->new( 'ID_i' => $db0_line{'ID'} ),
				WebService::Solr::Field->new( 'ID_entity_i' => $db0_line{'ID_entity'} ),
			));
			
			$solr->add($doc);
		}
		else
		{
			main::_log("not found active ID",1);
			my $response = $solr->search( "id:".$App::910::index_name.".a910_product_brand.* AND ID_i:$env{'ID'}" );
			for my $doc ( $response->docs )
			{
				$solr->delete_by_id($doc->value_for('id'));
			}
		}
	}
	
	$Elastic||=$Ext::Elastic::service;
	if ($Elastic) # the new way in Cyclone3 :)
	{
		my %sth0=TOM::Database::SQL::execute(qq{
			SELECT
				ID,
				ID_entity,
				name,
				status
			FROM
				$App::910::db_name.a910_product_brand AS product_brand
			WHERE
				product_brand.status IN ('Y','N','L','W') AND
				product_brand.name != '' AND
				product_brand.ID=?
		},'quiet'=>1,'bind'=>[$env{'ID'}]);
		if (!$sth0{'rows'})
		{
			main::_log("product_brand.ID=$env{'ID'} not found as valid item");
			if ($Elastic->exists(
				'index' => 'cyclone3.'.$App::910::index_name,
				'type' => 'a910_product_brand',
				'id' => $env{'ID'}
			))
			{
				main::_log("removing from Elastic");
				$Elastic->delete(
					'index' => 'cyclone3.'.$App::910::index_name,
					'type' => 'a910_product_brand',
					'id' => $env{'ID'}
				);
			}
			$t->close();
			return 1;
		}
		
		my %product_brand=$sth0{'sth'}->fetchhash();
		
		my %log_date=main::ctogmdatetime(time(),format=>1);
		
		main::_log("index",{
			'facility' => 'elastic',
			'severity' => 3,
			'data' => {
				'action' => 'index',
	#			'hostname' => $self->{'host_name'},
				'index_s' => 'cyclone3.'.$App::910::index_name,
				'type_s' => 'a910_product_brand',
				'ID_s' => $env{'ID'}
			}
		});
		
		$Elastic->index(
			'index' => 'cyclone3.'.$App::910::index_name,
			'type' => 'a910_product_brand',
			'id' => $env{'ID'},
			'body' => {
				%product_brand,
				'_datetime_index' => 
					$log_date{'year'}.'-'.$log_date{'mom'}.'-'.$log_date{'mday'}
					.'T'.$log_date{'hour'}.":".$log_date{'min'}.":".$log_date{'sec'}.'Z'
			}
		);
	}
	
	
	$t->close();
}


sub _a210_by_cat
{
	my $cats=shift;
	my %env=@_;
	
	$env{'lng'}=$tom::lng unless $env{'lng'};
	my $cache_key=$App::210::db_name.'::'.$env{'lng'}.'::'.join('::',@{$cats});
	
	# changetimes
	my $changetime_a910=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::910::db_name,
		'tb_name' => 'a910_product_cat',
	});
	my $changetime_a210=App::020::SQL::functions::_get_changetime({
		'db_name' => $App::210::db_name,
		'tb_name' => 'a210_page',
	});
	
	if ($TOM::CACHE && $TOM::CACHE_memcached && $main::cache)
	{
#		main::_log("get cached");
		my $cache=$Ext::CacheMemcache::cache->get(
			'namespace' => "fnc_cache",
			'key' => 'App::910::functions::_a210_by_cat::'.$cache_key
		);
		if (($cache->{'time'} > $changetime_a210) && ($cache->{'time'} > $changetime_a910))
		{
#			print "value=$cache->{'value'} time=$cache->{'time'} key=$cache_key\n";
#			main::_log("found, return");
			return $cache->{'value'};
		}
	}
	
	# find path
	my @categories;
	my %sql_def=('db_h' => "main",'db_name' => $App::910::db_name,'tb_name' => "a910_product_cat");
	foreach my $cat(@{$cats})
	{
		main::_log("cat=$cat") if $env{'debug'};
#		print "mam $cat";
		my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::910::db_name.a910_product_cat WHERE ID_entity=? AND lng=? LIMIT 1},
			'bind'=>[$cat,$env{'lng'}],'log'=>0,'quiet'=>1,
			'-cache' => 600,
			'-cache_changetime' => App::020::SQL::functions::_get_changetime({
				'db_name' => $App::910::db_name,
				'tb_name' => 'a910_product_cat',
			})
		);
		next unless $sth0{'rows'};
		my %db0_line=$sth0{'sth'}->fetchhash();
		my $i;
		foreach my $p(
			App::020::SQL::functions::tree::get_path(
				$db0_line{'ID'},
				%sql_def,
				'-slave' => 1,
				'-cache' => 3600
				# autocached by changetime
			)
		)
		{
			push @{$categories[$i]},$p->{'ID_entity'};
			$i++;
		}
		main::_log(" path=@categories") if $env{'debug'};
	}
	
#	print Dumper(\@categories);
	
	my $category;
	for my $i (1 .. @categories)
	{
		foreach my $cat (@{$categories[-$i]})
		{
#			push @{$product->{'log'}},"find $i ".$cat;
#			print "aha $i $cat\n";
			my %db0_line;
			
			my @a210_page_IDs;
			foreach my $relation(App::160::SQL::get_relations(
				'db_name' => $App::210::db_name,
				'l_prefix' => 'a210',
				'l_table' => 'page',
				#'l_ID_entity' = > ???
				'r_prefix' => "a910",
				'r_table' => "product_cat",
				'r_ID_entity' => $cat,
				'rel_type' => "link",
				'status' => "Y"
			))
			{
				push @a210_page_IDs,$relation->{'l_ID_entity'};
#				main::_log(" related from a210_page ID=".$relation->{'l_ID_entity'}) if $env{'debug'};
			}
			next unless @a210_page_IDs;
			
			main::_log("search for valid a210_page's @a210_page_IDs") if $env{'debug'};
			
			# the longer path is better
			my %sth0=TOM::Database::SQL::execute(
			qq{SELECT ID FROM $App::210::db_name.a210_page WHERE ID_entity IN (}
				.(join ',',@a210_page_IDs).
			qq{) AND lng=? AND status IN ('Y','L') ORDER BY length(ID_charindex) DESC},
			'bind'=>[$env{'lng'}],'quiet'=>1,
				'-cache' => 86400*7,
				'-cache_changetime' => App::020::SQL::functions::_get_changetime({
					'db_name' => $App::210::db_name,
					'tb_name' => 'a210_page',
				})
			);
			my %db0_line=$sth0{'sth'}->fetchhash();
			
			next unless $db0_line{'ID'};
			
			$category=$db0_line{'ID'};
			
			last;
		}
		last if $category;
	}
	
	if ($TOM::CACHE && $TOM::CACHE_memcached)
	{
		$Ext::CacheMemcache::cache->set(
			'namespace' => "fnc_cache",
			'key' => 'App::910::functions::_a210_by_cat::'.$cache_key,
			'value' => {
				'time' => time(),
				'value' => $category
			},
			'expiration' => '3600S'
		);
	}
	
	main::_log("found category $category") if $env{'debug'};
	return $category;
}

=head2 product_rating_add()

Adds / updates a product rating


	App::910::functions::product_rating_add(
		'product_rating.ID' => 2,
		'product_rating.description' => 'I have enjoyed this product very much.',
		'product_rating.score_basic' => 5,
		
		'product_rating.variables' =>
		{
			'advanced_rating' => 50,
			'personal_score' => 10
		}
	);

=cut

sub product_rating_add
{
	my %env=@_;
	return undef unless ($env{'product.ID'} || $env{'product_rating.ID'}); # product.ID or rating.ID
	
	my $t=track TOM::Debug(__PACKAGE__."::product_rating_add()");
	
	main::_log('product.ID='.$env{'product.ID'}." product_rating.ID=".$env{'product_rating.ID'}) if $debug;
	
	my %columns;
	
	$columns{'title'} = "'".TOM::Security::form::sql_escape($env{'product_rating.title'})."'" 
		if exists ($env{'product_rating.title'});
	$columns{'description'} = "'".TOM::Security::form::sql_escape($env{'product_rating.description'})."'" 
		if exists ($env{'product_rating.description'});
	$columns{'score_basic'} = "'".TOM::Security::form::sql_escape($env{'product_rating.score_basic'})."'" 
		if exists ($env{'product_rating.score_basic'});
	$columns{'helpful_Y'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_Y'})."'" 
		if exists ($env{'product_rating.helpful_Y'});
	$columns{'helpful_N'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_N'})."'" 
		if exists ($env{'product_rating.helpful_N'});
	$columns{'status_publish'} = "'".TOM::Security::form::sql_escape($env{'product_rating.status_publish'})."'" 
		if exists ($env{'product_rating.status_publish'});
	$columns{'posix_owner'} = "'".TOM::Security::form::sql_escape($env{'product_rating.posix_owner'})."'" 
		if $env{'product_rating.posix_owner'};
	$columns{'posix_owner'} = "'".$main::USRM{'ID_user'}."'" unless $env{'product_rating.posix_owner'};
	$columns{'lng'} = "'".$env{'lng'}."'" if exists $env{'lng'};
	$columns{'lng'} = "'".$env{'product_rating.lng'}."'" if exists $env{'product_rating.lng'};

	if (!$env{'product_rating.ID'})
	{
		# rating doesn't exist, create new
		if ($env{'product.ID'} =~ /^\d+$/)
		{
			$columns{'datetime_rating'}="'".$env{'product_rating.datetime_rating'}."'"
				if $env{'product_rating.datetime_rating'};
			$columns{'datetime_rating'}='NOW()' unless $columns{'datetime_rating'};
			$env{'product_rating.ID'} = App::020::SQL::functions::new(
				'db_h' => 'main',
				'db_name' => $App::910::db_name,
				'tb_name' => 'a910_product_rating',
				'columns' => 
				{
					'ID_product' => $env{'product.ID'},
#					'datetime_rating' => 'NOW()',
					%columns
				},
				'-journalize' => 1,
				'-posix' => 1
			);
		}

		# check if there are additional variables and append them to the existing rating, now that it exists
	
		if ($env{'product_rating.ID'})
		{
			if ($env{'product_rating.variables'})
			{
				my %variables = %{$env{'product_rating.variables'}};
				
				foreach my $variable (keys %variables)
				{
					my $score_variable = "'".TOM::Security::form::sql_escape($variable)."'";
					my $score_value = "'".TOM::Security::form::sql_escape($variables{$variable})."'";
					
					# update this variable
					my $variable_id = App::020::SQL::functions::new(
						'db_h' => 'main',
						'db_name' => $App::910::db_name,
						'tb_name' => 'a910_product_rating_variable',
						'columns' => 
						{
							'ID_entity' => $env{'product_rating.ID'},
							'score_variable' => $score_variable,
							'score_value' => $score_value
						},
						'-journalize' => 1,
						'-replace' => 1
					);
					
				}
			}
		}
	}
	else
	{
		# update an existing rating
		
		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_rating`
			WHERE
				ID = ?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1, 'log'=>0, 'bind' => [$env{'product_rating.ID'}] );
		my %rating = $sth0{'sth'}->fetchhash();
		
		my %columns_update;
		
		$columns_update{'title'} = "'".TOM::Security::form::sql_escape($env{'product_rating.title'})."'" 
			if (exists ($env{'product_rating.title'})) && $env{'product_rating.title'} ne $rating{'title'};
		$columns_update{'description'} = "'".TOM::Security::form::sql_escape($env{'product_rating.description'})."'" 
			if (exists ($env{'product_rating.description'})) && $env{'product_rating.description'} ne $rating{'description'};
		$columns_update{'score_basic'} = "'".TOM::Security::form::sql_escape($env{'product_rating.score_basic'})."'" 
			if (exists ($env{'product_rating.score_basic'})) && $env{'product_rating.score_basic'} ne $rating{'score_basic'};
		
		$columns_update{'helpful_Y'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_Y'})."'" 
			if (exists ($env{'product_rating.helpful_Y'})) && $env{'product_rating.helpful_Y'} ne $rating{'helpful_Y'};
		$columns_update{'helpful_N'} = "'".TOM::Security::form::sql_escape($env{'product_rating.helpful_N'})."'" 
			if (exists ($env{'product_rating.helpful_N'})) && $env{'product_rating.helpful_N'} ne $rating{'helpful_N'};
		
		$columns_update{'status_publish'} = "'".TOM::Security::form::sql_escape($env{'product_rating.status_publish'})."'" 
			if (exists ($env{'product_rating.status_publish'})) && $env{'product_rating.status_publish'} ne $rating{'status_publish'};
		
		if (keys %columns_update)
		{
			App::020::SQL::functions::update(
				'ID' => $env{'product_rating.ID'},
				'db_h' => "main",
				'db_name' => $App::910::db_name,
				'tb_name' => "a910_product_rating",
				'columns' => {%columns_update},
					'-journalize' => 1,
					'-posix' => 1
			);
		}

		# also, if we are updating an existing rating, it's rating variables need to updated or trashed
		# rating_ID (entity): $env{'product_rating.ID'}
		# 
		
		# get a list of rating variables to be updated
		if (ref($env{'product_rating.variables'}) eq 'HASH')
		{
			my %variables = %{$env{'product_rating.variables'}};	
		
			my $sql_rating_vars=qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_rating_variable`
				WHERE
					ID_entity = ?
			};
			my %sth_rating=TOM::Database::SQL::execute($sql_rating_vars,'quiet'=>1, 'log'=>0, 'bind' => [$env{'product_rating.ID'}] );
				
			# trash all rating variables
			while (my %rating_variable = $sth_rating{'sth'}->fetchhash())
			{
				# does the rating variable exist in the new list of variables to be updated?
				if (exists($variables{$rating_variable{'score_variable'}}))
				{
					# update this variable
					App::020::SQL::functions::update(
						'ID' => $rating_variable{'ID'},
						'db_h' => 'main',
						'db_name' => $App::910::db_name,
						'tb_name' => 'a910_product_rating_variable',
						'columns' => {
	
							'score_value' => "'".TOM::Security::form::sql_escape($variables{$rating_variable{'score_variable'}})."'",
							'status' => "'Y'"
						},
						'-journalize' => 0
					);

					delete $variables{$rating_variable{'score_variable'}};
				} else
				{
					# trash this
					App::020::SQL::functions::to_trash(
						'ID' => $rating_variable{'ID'},
						'db_h' => 'main',
						'db_name' => $App::910::db_name,
						'tb_name' => 'a910_product_rating_variable',
						'-journalize' => 0
					);
				}
			}

			# add all detailed variables that are left
			
			foreach my $variable (keys %variables)
			{
				my $score_variable = "'".TOM::Security::form::sql_escape($variable)."'";
				my $score_value = "'".TOM::Security::form::sql_escape($variables{$variable})."'";
				
				# update this variable
				my $variable_id = App::020::SQL::functions::new(
					'db_h' => 'main',
					'db_name' => $App::910::db_name,
					'tb_name' => 'a910_product_rating_variable',
					'columns' => 
					{
						'ID_entity' => $env{'product_rating.ID'},
						'score_variable' => $score_variable,
						'score_value' => $score_value
					},
					'-journalize' => 1,
					'-replace' => 1
				);
				
			}
			

		} else
		{
			# No detailed rating variables to add
		}
	}
	
	
	
	
	
	$t->close();
	
	return $env{'product_rating.ID'};
}

=head2 product_rating_remove()

Removes a product rating and all its variables


	App::910::functions::product_rating_remove(
		'product_rating.ID' => 2
	);

=cut

sub product_rating_remove
{
	# get this rating and get all rating-variables for this rating, then trash them and reindex the product
	my %env = @_;

	if ($env{'product_rating.ID'} =~ /^\d+$/)
	{
		$env{'ID'} = $env{'product_rating.ID'};

		my $sql=qq{
			SELECT
				*
			FROM
				`$App::910::db_name`.`a910_product_rating`
			WHERE
				ID = ?
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1, 'log'=>0, 'bind' => [$env{'ID'}] );

		if (my %rating = $sth0{'sth'}->fetchhash())
		{
			my $sql2=qq{
				SELECT
					*
				FROM
					`$App::910::db_name`.`a910_product_rating_variable`
				WHERE
					ID_entity = ?
			};
			my %sth1=TOM::Database::SQL::execute($sql2,'quiet'=>1, 'log'=>0, 'bind' => [$env{'ID'}] );
			
			# trash all rating variables
			while (my %rating_variable = $sth1{'sth'}->fetchhash())
			{
				main::_log('Vymazavam: '.$rating_variable{'ID'});

				App::020::SQL::functions::to_trash(
					'ID' => $rating_variable{'ID'},
					'db_h' => 'main',
					'db_name' => $App::910::db_name,
					'tb_name' => 'a910_product_rating_variable',
					'-journalize' => 0
				);
				
			}

			# trash the master rating (entity)
			
			App::020::SQL::functions::to_trash(
				'ID' => $env{'ID'},
				'db_h' => 'main',
				'db_name' => $App::910::db_name,
				'tb_name' => 'a910_product_rating',
				'-journalize' => 1,
			);
		}
	}
}

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
