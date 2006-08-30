package TOM::Warning;
use TOM::Error::design;
use Utils::vars;
use TOM::Utils::datetime;
use TOM::Utils::vars;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



sub module
{
	if ($TOM::engine eq "pub")
	{
		module_pub(@_);
	}
#	else
#	{
#		engine_lite(@_);
#	}
}



sub module_pub
{
	my %env=@_;
	
#	foreach(keys %env)
#	{
#		main::_log("input key '$_'='$env{$_}'");
#	}
	
	$env{'-MODULE'}=$Tomahawk::mdl_C{-category}."-".$Tomahawk::mdl_C{-name}."/".$Tomahawk::mdl_C{-version}."/".$Tomahawk::mdl_C{-global};
	$env{'-ERROR'}=$env{message};
	
	my $env_=$env{'ENV'};
	
=head1
DAVE: ak sú nejasné pravidlá mailovej komunikácie, prosím napíšte mi. môžme 
zopakovať workshop o komunikácii, aby sme odstránili akékoľvek 
nejasnosti. vďaka.
=cut
	
	return undef unless $env{'-MODULE'};
	
	main::_log("[WARN::MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",1,"pub.warn",0); #local
	main::_log("[$tom::H][WARN::MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"pub.warn",1); #global
	main::_log("[$tom::H][WARN::MDL::$env{-MODULE}] $env{-ERROR} $env{-PLUS}",4,"pub.warn",2) if ($tom::H ne $tom::Hm); #master
	
	my $date=TOM::Utils::datetime::mail_current;
	
	# TODO:[fordinal] pridat dalsie emailove adresy
	
	my $email_addr;
	my $email_name;
	
	$env{to}=@TOM::ERROR_email_send unless $env{to};
	
	foreach ("TOM", @{$env{to}})
	{
		$email_addr.=";".$TOM::contact{$_};
		$email_name.=$_."/";
	};$email_name=~s|/$||;$email_name=~s|TOM/TOM|TOM|;
	
	$email_addr=TOM::Utils::vars::unique_split($email_addr);
	
	if (($TOM::ERROR_module_email) && (!$main::IAdm))
	{
		my $email=$module_email;
		
		$email=~s|<%TYPE%>|WARN|;
		$email=~s|<%TYPE_%>|Warning|;
		$email=~s|<%DATE%>|$date|;
		$email=~s|<%SUBJ%>|[$env{-MODULE}]|;
		$email=~s|<%DOMAIN%>|$tom::H|g;
		#$email=~s|<%ERROR%>|$var|;
		$email=~s|<%TO%>|"$email_name" <TOM\@webcom.sk>|;
		$email=~s|<%ERROR%>|$env{-ERROR}|g;
		$email=~s|<%ERROR-PLUS%>|$env{-PLUS}|g;
		
		#$email=~s|<#PROJECT#>|$email_project|;
		$email=~s|<#PROJECT#>|$email_project\n$email_project_pub|;
		
		$email=~s|<#MODULE#>|$email_module|;
		
		$email=~s|<%MODULE%>|$env{-MODULE}|g;
		
		if ($main::IAdm || $main::ITst)
		{
			$email=~s|<%uri-parsed%>|(search do log)|g;
		}
		
		$email=~s|<%uri-parsed%>|$tom::H_www/?$main::ENV{QUERY_STRING_FULL}|g;
		$email=~s|<%uri-orig%>|$tom::H_www$main::ENV{REQUEST_URI}|g;
		$email=~s|<%uri-referer%>|$main::ENV{HTTP_REFERER}|g;
		
		foreach (sort keys %{$env_})
		{
			#main::_log("input '$_'='".$env_->{$_}."'");
			my $val=$env_->{$_};
			my $env=$email_ENV_;
			$env=~s|<%var%>|$_|g;
			$env=~s|<%value%>|$val|g;
			$email=~s|<#ENV#>|$env\n<#ENV#>|;
		}
		
#		return 1;
=head1
		foreach (sort keys %main::ENV)
		{
			my $val=$main::ENV{$_};
			if (($main::IAdm || $main::ITst)&& ($_=~/^(QUERY|HTTP_COOKIE)/))
			{$val="(search do log)";}
			my $env=$email_ENV_;
			$env=~s|<%var%>|$_|g;
			$env=~s|<%value%>|$val|g;
			$email=~s|<#ENV#>|$env\n<#ENV#>|;
		}
=cut
		
		$email=~s|<%to%>|$email_addr;$Tomahawk::module::authors|;
		
		Utils::vars::replace($email);
		$email=~s|<#.*?#>||g;
		$email=~s|<%.*?%>||g;
	
		TOM::Net::email::send(
			'priority'=>9,
			'from'=>"TOM\@$TOM::hostname",
			'to'=>$email_addr.";".$Tomahawk::module::authors,
			'body'=>$email,
		);
	}
	
	#return 1 if $main::H->r_("<!TMP-".$env{-TMP}."!>",$out);
	#return 1 if $main::H->r_("<!TMP-ERROR!>",$out);
	#$main::H->a($out);
	return 1;
}





1;
