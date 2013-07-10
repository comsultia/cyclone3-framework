#!/bin/perl
package Ext::Redis;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

Extension Redis

=head1 DESCRIPTION

Library that uses memory daemon to store data between processes

=cut

#use Redis;

our $service;

BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	
	eval {require RedisDB};
	if ($@)
	{
		main::_log("<={LIB} RedisDB",1);
		undef $Ext::Redis::host;
	}
	else
	{
		main::_log("<={LIB} RedisDB");
	}
	
};

if ($Ext::Redis::host)
{
	my $t=track TOM::Debug("connect",'attrs'=>$Ext::Redis::host);
	eval{
		if ($Ext::Redis::host=~/^\//)
		{
			$service = RedisDB->new(
				'path' => $Ext::Redis::host,
				'raise_error' => 0 # not works
			)
		}
		else
		{
			$service = RedisDB->new(
				'host' => (split(':',$Ext::Redis::host))[0],
				'port' => (split(':',$Ext::Redis::host))[1] || 6379,
		#			'connection_name' => 'C3',#.$TOM::Engine.' '.$tom::H_www,
				'raise_error' => 0 # not works
			)
		}
	};
	if ($service && $service->ping)
	{
		my %info=%{$service->info()};
		main::_log("Redis v".$info{'redis_version'}." connected and respondig");
#		if ($info{'redis_version'} < '2.4.15')
		#$service->send_command('CLIENT SETNAME aa');
		
		
		# override memcached
		$TOM::CACHE_memcached=1;
		$Ext::CacheMemcache::cache = new Ext::CacheMemcache::Redir;
		main::_log("overriding \$Ext::CacheMemcache::cache object");
	}
	else
	{
		$t->close();
		undef $service;
		undef $Ext::Redis::host;
	}
	$t->close();
}

package Ext::CacheMemcache::Redir; # buaah
use Storable;

sub new
{
	my $class=shift;
	my $self={};
	
	return bless $self, $class;
}

sub set
{
	my $self=shift;
	my %env=@_;
	
	if (ref $env{'value'})
	{
		$env{'value'}=Storable::nfreeze($env{'value'});
	}
	else
	{
		$env{'value'}=Storable::nfreeze(\$env{'value'});
	}
	
	my $key='memcache|'.$env{'namespace'}.'|'.$env{'key'};
	
	my $expire;
	if ($env{'expiration'}=~/^(\d+)S?$/)
	{
		$expire=$1;
	}
	elsif ($env{'expiration'}=~/^(\d+)D$/)
	{
		$expire=$1*86400;
	}
	elsif ($env{'expiration'}=~/^(\d+)H$/)
	{
		$expire=$1*3600;
	}
	
	$Ext::Redis::service->set(
		$key,
		$env{'value'},
		sub {} # in pipeline
	);
	$Ext::Redis::service->expire(
		$key,
		$expire || 600,
		sub {} # in pipeline
	);
	
	return 1;
}

sub get
{
	my $self=shift;
	my %env=@_;
	my $value=Storable::thaw(
		$Ext::Redis::service->get(
			'memcache|'.$env{'namespace'}.'|'.$env{'key'}
		)
	);
	if (ref $value eq "SCALAR")
	{
		return $$value;
	}
	return $value;
}

sub AUTOLOAD
{
	
}

# for exporting symbols
package Ext::Redis::_init;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
use base 'Exporter';
our @EXPORT = qw($Redis);

our $Redis=$Ext::Redis::service;

1;