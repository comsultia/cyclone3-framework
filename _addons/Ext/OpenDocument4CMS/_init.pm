#!/bin/perl
package Ext::OpenDocument4CMS;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension OpenDocument4CMS

=head1 DESCRIPTION

Extension that supports OpenDocument standard in CMS

=cut

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
}

=head1 DEPENDS

=over

=item *

XML::Sablotron

=item *

File::Copy

=item *

File::Path

=item *

Archive::Zip

=item *

L<TOM::Utils::vars|source-doc/".core/.libs/TOM/Utils/vars.pm">

=back

=cut

use XML::Sablotron;
use File::Copy;
use File::Path;
use Archive::Zip;
use TOM::Utils::vars;

our $DIR=(__FILE__=~/^(.*)\//)[0];


sub sab_MHMakeCode
{
	my ($self, $processor, $severity, $facility, $code)=@_;
	return $code; # I can deal with internal numbers
}

sub sab_MHLog
{
	my ($self, $processor, $code, $level, @fields)=@_;
	main::_log("[Sablot:$code][$level]\n" . (join "\n", @fields, ""));
}

sub sab_MHError
{
	sab_MHLog(@_);
	main::_log("Dying from Sablotron errors, see log",1);
	return undef;
	#die "Dying from Sablotron errors, see log\n";
}



=head1 FUNCTIONS

=head2 odf2xml()

Converts zipped opendocument file into one big xml file

 my $xml=odf2xml('file:/');

 odf2xml('file:/','file:/'); - not supported

=cut

sub odf2xml
{
	my $file=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::odf2xml()");
	main::_log("input file='$file'");
	
	my $odf=Ext::OpenDocument4CMS->extract($file);
	
	my $pwd_old=$main::ENV{'PWD'};
	chdir $odf->{'tmpdir'};
	
	# copy catenate.xsl driver file
	###############################################
	File::Copy::copy($DIR.'/xsl/catenate.xsl',$odf->{'tmpdir'}.'/catenate.xsl');
	
	# converting into one big XML
	###############################################
	my $sab = new XML::Sablotron();
	my $situa = new XML::Sablotron::Situation();
	$sab->RegHandler(0,
		{
			MHMakeCode => \&sab_MHMakeCode,
			MHLog => \&sab_MHLog,
			MHError => \&sab_MHError
		}
	);
	$sab->process($situa, $odf->{'tmpdir'}.'/catenate.xsl', 'content.xml', 'arg:/output');
	my $output=$sab->getResultArg('arg:/output');
	main::_log("output=length(".(length($output)).")");
	
	$odf->close();
	
	chdir $pwd_old;
	
	$t->close();
	return $output;
}



=head2 extract('file:/')

 my $obj=Ext::OpenDocument4CMS->extract('/home/user/test.odt');
 main::_log("tmpdir='".$obj->{'tmpdir'}."'");
 $obj->close();

=cut

sub extract
{
	my $class=shift;
	my $file=shift;
	my %env=@_;
	my $self={};
	my $t=track TOM::Debug(__PACKAGE__."->extract()");
	
	main::_log("input file='$file'");
	
	# open zip
	###############################################
	my $zip = Archive::Zip->new();
	my $status = $zip->read($file);
	if ($status != Archive::Zip::AZ_OK)
	{
		main::_log("Opening zip archive $file failed (is this zip archive?)",1);
		$t->close();
		return undef;
	}
	
	# create temporary directory
	###############################################
	my $hash=TOM::Utils::vars::genhash(32);
	$self->{'tmpdir'}=$TOM::P.'/_temp/'.$hash;
	main::_log("output tmpdir='".$self->{'tmpdir'}."'");
	mkdir $self->{'tmpdir'};
	
	# extract into
	###############################################
	if (!$env{'extract'})
	{
		# extract only important files
		main::_log("extract 'content.xml','styles.xml','meta.xml'");
		$zip->extractMember('content.xml',$self->{'tmpdir'}.'/content.xml');
		$zip->extractMember('styles.xml',$self->{'tmpdir'}.'/styles.xml');
		$zip->extractMember('meta.xml',$self->{'tmpdir'}.'/meta.xml');
	}
	elsif ($env{'extract'} eq "*")
	{
		# extract all files
		main::_log("extract full tree");
		$zip->extractTree(undef,$self->{'tmpdir'}.'/');
	}
	else
	{
		# extract only selected files
		foreach my $exfile(@{$env{'extract'}})
		{
			main::_log("extract '$exfile'");
			$zip->extractMember($exfile,$self->{'tmpdir'}.'/'.$exfile);
		}
	}
	
	$t->close();
	return bless $self,$class;
}



=head2 save_as('file:/')

 $obj->save_as('/home/user/test2.odt');

=cut

sub save_as
{
	my $self=shift;
	my $file=shift;
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."->save_as()");
	
	my $zip = Archive::Zip->new();
	$zip->addTree($self->{'tmpdir'});
	$zip->writeToFileNamed($file);
	
	$t->close();
	return 1;
}



=head2 ->get_images

Function return list of hashes with informations about included images

 @images=$obj->get_images();
 main::_log("first image source='".$images[0]{'src'}."'");

=cut

sub get_images
{
	my $self=shift;
	
	my $sab = new XML::Sablotron();
	my $situa = new XML::Sablotron::Situation();
	$sab->RegHandler(0,
		{
			MHMakeCode => \&sab_MHMakeCode,
			MHLog => \&sab_MHLog,
			MHError => \&sab_MHError
		}
	);
	
	my $output;
	
	if (-e $self->{'tmpdir'}.'/styles.xml')
	{
		$sab->process($situa, $DIR.'/xsl/get_images.xsl', $self->{'tmpdir'}.'/styles.xml', 'arg:/output');
		$output.=$sab->getResultArg('arg:/output');
	}
	
	if (-e $self->{'tmpdir'}.'/content.xml')
	{
		$sab->process($situa, $DIR.'/xsl/get_images.xsl', $self->{'tmpdir'}.'/content.xml', 'arg:/output');
		$output.=$sab->getResultArg('arg:/output');
	}
	
	main::_log("output=length(".(length($output)).")");
	
	my @images;
	
	while ($output=~s|<image>(.*?)</image>||)
	{
		my $image=$1;
		my %hash;
		while ($image=~s|<([\w]+)>(.*?)</\1>||)
		{
			my $var=$1;
			my $val=$2;
			$hash{$1}=$2;
		}
		push @images, {%hash};
	}
	
	return @images;
}




=head2 ->to_xhtml

Function converts content into simple XHTML

 my $xhtml=$obj->to_xhtml();

=cut

sub to_xhtml
{
	my $self=shift;
	
	my $sab = new XML::Sablotron();
	my $situa = new XML::Sablotron::Situation();
	$sab->RegHandler(0,
		{
			MHMakeCode => \&sab_MHMakeCode,
			MHLog => \&sab_MHLog,
			MHError => \&sab_MHError
		}
	);
	
	my $output;
	
	if (-e $self->{'tmpdir'}.'/content.xml')
	{
		$sab->process($situa, $DIR.'/xsl/to_xhtml.xsl', $self->{'tmpdir'}.'/content.xml', 'arg:/output');
		$output=$sab->getResultArg('arg:/output');
	}
	
	main::_log("output=length(".(length($output)).")");
	
	return $output;
}


sub close
{
	my $self=shift;
	# cleaning
	rmtree $self->{'tmpdir'};
}

sub DESTROY
{
	my $self=shift;
	# cleaning
	rmtree $self->{'tmpdir'};
}


=head1 AUTHORS

Roman Fordinal (roman.fordinal@comsultia.com)

=cut


1;
