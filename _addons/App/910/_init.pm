#!/bin/perl
package App::910;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;


=head1 NAME

Application 910 - Products catalog

=head1 DESCRIPTION

Application which manages products catalag

=cut

BEGIN {main::_log("<={LIB} ".__PACKAGE__);}

our $VERSION='$Rev$';


=head1 SYNOPSIS

 use App::910::_init;

=cut

=head1 DEPENDS

=over

=item *

L<App::020::_init|app/"020/_init.pm">

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::401::mimetypes|app/"401/mimetypes.pm">

=item *

L<App::910::a160|app/"910/a160.pm">

=item *

L<App::910::a301|app/"910/a301.pm">

=item *

L<App::910::functions|app/"910/functions.pm">

=back

=cut

use TOM::Template;
use TOM::Utils::currency;
use App::020::_init; # data standard 0
use App::301::_init;
use App::401::mimetypes;
use App::910::a160;
use App::910::a301;
use App::910::functions;



=head1 CONFIGURATION

 $db_name
 $currency='EUR'

=cut

our $currency=$App::910::currency || 'EUR';
our $db_name=$App::401::db_name || $TOM::DB{'main'}{'name'};



# check relation to a501
use App::501::_init;
our $thumbnail_cat_ID_entity;
our %thumbnail_cat;

# find any category;
my $sql="
	SELECT
		ID, ID_entity
	FROM
		`$App::501::db_name`.`a501_image_cat`
	WHERE
		name='product thumbnails' AND
		lng IN ('".(join "','",@TOM::LNG_accept)."')
	LIMIT 1
";
my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
if (my %db0_line=$sth0{'sth'}->fetchhash())
{
	$thumbnail_cat_ID_entity=$db0_line{'ID_entity'} unless $thumbnail_cat_ID_entity;
}
else
{
	$thumbnail_cat_ID_entity=App::020::SQL::functions::tree::new(
		'db_h' => "main",
		'db_name' => $App::501::db_name,
		'tb_name' => "a501_image_cat",
		'columns' => {
			'name' => "'product thumbnails'",
			'lng' => "'$tom::LNG'",
			'status' => "'L'"
		},
		'-journalize' => 1
	);
}

foreach my $lng(@TOM::LNG_accept)
{
	#main::_log("check related category $lng");
	my $sql=qq{
		SELECT
			ID, ID_entity
		FROM
			`$App::501::db_name`.`a501_image_cat`
		WHERE
			ID_entity=$thumbnail_cat_ID_entity AND
			lng='$lng'
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'quiet'=>1);
	if (my %db0_line=$sth0{'sth'}->fetchhash())
	{
		$thumbnail_cat{$lng}=$db0_line{'ID'};
	}
	else
	{
		#main::_log("creating related category");
		$thumbnail_cat{$lng}=App::020::SQL::functions::tree::new(
			'db_h' => "main",
			'db_name' => $App::501::db_name,
			'tb_name' => "a501_image_cat",
			'columns' => {
				'ID_entity' => $thumbnail_cat_ID_entity,
				'name' => "'product thumbnails'",
				'lng' => "'$lng'",
				'status' => "'L'"
			},
			'-journalize' => 1
		);
	}
}



=head1 AUTHOR

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
