package TOM::Engine::job::module;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM;
use Cwd 'abs_path';

sub new
{
	my $class=shift;
	my $conf=shift;
	my $env=shift;
	
	if ($conf->{'name'})
	{
		# try to find file by name
		
		unless ($conf->{'name'}=~s/^([ae])(.*?)\-//)
		{
			main::_log("unknown type of addon",1);
			return undef;
		}
		
		my $addon_type=$1;
		my $addon_name=$2;
		my $addon_path=$addon_type;
			if ($addon_path=~s/^a/App\/$addon_name/)
			{
			}
			elsif ($addon_path=~s/^e/Ext\/$addon_name/)
			{
			}
		
		my $file=$addon_type.$addon_name.'-'.$conf->{'name'}.'.job';
		
		if ($tom::P ne $TOM::P)
		{
			if (-e $tom::P.'/_addons/'.$addon_path.'/_mdl/'.$file)
			{
				$conf->{'file'} = $tom::P.'/_addons/'.$addon_path.'/_mdl/'.$file;
			}
			elsif (-e $tom::P.'/_mdl/'.$file)
			{
				$conf->{'file'} = $tom::P.'/_mdl/'.$file;
			}
		}
		
		foreach my $dir_item (@TOM::Overlays::item)
		{
			if (-e $TOM::P.'/_overlays/'.$dir_item.'/_addons/'.$addon_path.'/_mdl/'.$file)
			{
				$conf->{'file'} = $TOM::P.'/_overlays/'.$dir_item.'/_addons/'.$addon_path.'/_mdl/'.$file;
			}
			elsif (-e $TOM::P.'/_overlays/'.$dir_item.'/_mdl/'.$file)
			{
				$conf->{'file'} = $TOM::P.'/_overlays/'.$dir_item.'/_mdl/'.$file;
			}
		}
		
		if (!$conf->{'file'})
		{
			if (-e $TOM::P.'/_addons/'.$addon_path.'/_mdl/'.$file)
			{
				$conf->{'file'} = $TOM::P.'/_addons/'.$addon_path.'/_mdl/'.$file;
			}
			elsif (-e $TOM::P.'/_mdl/'.$file)
			{
				$conf->{'file'} = $TOM::P.'/_mdl/'.$file;
			}
		}
		
		delete $conf->{'name'};
	}
	
	if ($conf->{'file'})
	{
		my $abs_path=$conf->{'file'}=abs_path($conf->{'file'});
		
		if (!-e $conf->{'file'})
		{
			main::_log("file '$conf->{'file'}' not found",1);
			return undef;
		}
		
		my $m_time=(stat($conf->{'file'}))[9];
		my $extra_name=TOM::Digest::hash($conf->{'file'});
		my $job_class='Cyclone3::job::'.$extra_name;
		
		if (!$job_class->VERSION() || ($job_class->VERSION() < $m_time))
		{
			# reload this class source
			my $job_data;
			do {
				open (JOBHND,'<'.$conf->{'file'}) || do {
					main::_log($!,1);
					return undef;
				};
				local $/;
				$job_data=<JOBHND>;
				close JOBHND;
			};
			
			$job_data=~s|^(#!/usr/bin/env.*?)(package Cyclone3::job);|$1package Cyclone3::job::$extra_name;\nour \$VERSION=$m_time;|ms || do {
				main::_log("can't load job module file",1);
				return undef;
			};
			
			eval $job_data;
			if ($@)
			{
				main::_log($@,1);
				return undef;
			}
		}
	
		delete $conf->{'name'};
		delete $conf->{'file'};
		
		my $job=new $job_class($conf,$env);
			$job->{'file'}=$abs_path;
		return $job;
	}
	
	my $obj=bless {}, $class;
	
	$obj->{'env'}=$env;
	
	return $obj;
#	return $obj->prepare;
}

sub env {return shift->{'env'}}

#sub job
#{
#	my $class=shift;
#	my %env=@_;
#	
#	my $obj=bless {}, $class;
#	
#	main::_log("calling create via job and execute"); # we are creating new 
#	
#	return $obj->execute;
#}


sub execute
{
	my $self=shift;
	
	main::_log("executing dummy execute",1);
	
	return $self;
}



package TOM::Engine;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use JSON;
use Ext::RabbitMQ::_init;


sub jobify # prepare function call to background
{
	my $env=$_[1];
	if ($main::nojobify)
	{
		undef $main::nojobify;
		return undef;
	}
	return undef unless $RabbitMQ;
	my (undef,undef,undef,$function)=caller 1;
	$RabbitMQ->publish(
		'exchange'=>'cyclone3.job',
		'routing_key' => ($env->{'routing_key'} || $tom::H_orig || 'job'),
		'body' => to_json({'function' => $function,'args' => $_[0]})
	);
	return 1;
}

1;
