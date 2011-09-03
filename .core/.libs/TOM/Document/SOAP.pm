package TOM::Document;

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

our @ISA=("TOM::Document::base");

use TOM::Template;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our (
	undef,
	undef,
	undef,
	undef,
	undef,
	$year,
	undef,
	undef,
	undef) = localtime(time);$year+=1900;

our $content_type="text/xml";
our $type='soap';
my $tpl=new TOM::Template(
	'level' => "auto",
	'name' => "default",
	'content-type' => $type
);
our $err_page=$tpl->{'entity'}->{'page.error'};

sub new
{
	my $class=shift;
	my %env=@_;
	my $self={}; 
	%{$self->{ENV}}=%env;
	return bless $self,$class;
}


sub clone
{
	my $class=shift;
	my $self={};
	%{$self->{ENV}}=%{$class->{ENV}};
	%{$self->{OUT}}=%{$class->{OUT}};
	return bless $self;
}



sub prepare
{
	my $self=shift;
	
	$self->{'OUT'}{'HEADER'} = qq{<?xml version="1.0" encoding="<%CODEPAGE%>"?>
<!--
$Net::DOC::base::copyright
-->
<SOAP-ENV:Envelope
	xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
	SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Header>
		<generator>Cyclone3 $TOM::core_version.$TOM::core_build</generator>
		<hostname>$TOM::hostname</hostname>
		<domain>$tom::H</domain>
		<process>$$</process>
		<request_code><\$main::request_code></request_code>
		<request_time><\$main::time_current></request_time>
		<method><\$main::FORM{'type'}></method>
		<TypeID><\$main::FORM{'TID'}></TypeID>
	</SOAP-ENV:Header>
};
	
	$self->{'OUT'}{'HEADER'} .= qq{	<SOAP-ENV:Body>\n};
	
	# body
	$self->{'OUT'}{'BODY'} = qq{<!TMP-OUTPUT!>} unless $self->{'OUT'}{'BODY'};
	
	$self->{'OUT'}{'FOOTER'} = qq{\n</SOAP-ENV:Body>\n};
	$self->{'OUT'}{'FOOTER'} .= qq{</SOAP-ENV:Envelope>\n};
	
	return 1;
}




sub prepare_last
{
	my $self=shift;
	my %env=@_;
	
	# aplikujem title
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-TITLE%>|$self->{env}{DOC_title}|;
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-LNG%>|$tom::lng|g;
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-CODE%>|$main::request_code|;
	
	return 1;
}



1;