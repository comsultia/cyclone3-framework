package TOM::Database::connect;

=head1 NAME

TOM::Database::connect

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

=over

=item *

DBI

=item *

Mysql

=item *

L<TOM::Database:SQL|source-doc/".core/.libs/TOM/Database/SQL.pm">

=back

=cut

use DBI;
use Mysql;
use TOM::Database::SQL;

sub all
{
	my @databases=@_;
	$TOM::DB{main}{name}=$TOM::DB_name unless $TOM::DB{main}{name};
	
	main::_log("request to connect handler 'main'");
	
	main::_log("connecting 'main' ($TOM::DB{main}{host} $TOM::DB{main}{name} $TOM::DB{main}{user})");
	
	$main::DB{'main'} = Mysql->Connect
	(
		$TOM::DB{main}{host},
		$TOM::DB{main}{name},
		$TOM::DB{main}{user},
		$TOM::DB{main}{pass}
	);
	
	if (!$main::DB{'main'})
	{
		die "Connection to MySQL database not established: ".Mysql->errmsg()."\n";
	}
	
	$main::DB{'main'}->{'dbh'}->{'mysql_auto_reconnect'}=$TOM::DB_mysql_auto_reconnect;
	$main::DB{'main'}->{'dbh'}->{'mysql_enable_utf8'} = 1;
	#$self->{_dbh}->{mysql_enable_utf8} = 1;
	
	foreach my $sql(@{$TOM::DB{'main'}{'sql'}})
	{
		main::_log("sql='$sql'");
		my $sth=$main::DB{'main'}->{'dbh'}->prepare($sql);$sth->execute();
#		TOM::Database::SQL::execute($sql,'db_h'=>'main','quiet'=>1);
	}
	
	TOM::Database::connect::multi(@databases);
	# spetna kompatiblita
	# TODO: [Aben] Vyhodit spetnu kompatibilitu na $main::DBH
	$main::DBH=$main::DB{'main'};
	return 1;
}



sub multi
{
	my $t=track TOM::Debug(__PACKAGE__."::multi()");
	
	my @databases=@_;
	
	foreach my $handler (@databases)
	{
		main::_log("request to connect handler '$handler'");
		
		if ($main::DB{$handler})
		{
			main::_log("this handler already connected");
			next;
		}
		
		foreach (keys %TOM::DB)
		{
			#main::_log("control handler '$_'");
			if
			(
				($main::DB{$_})
				&&
				(
					($TOM::DB{$_}{'host'} eq $TOM::DB{$handler}{'host'})
					&&($TOM::DB{$_}{'user'} eq $TOM::DB{$handler}{'user'})
					&&($TOM::DB{$_}{'user'} eq $TOM::DB{$handler}{'user'})
					&&($TOM::DB{$_}{'uri'} eq $TOM::DB{$handler}{'uri'})
				)
			)
			{
				main::_log("is same as handler '$_'");
				$main::DB{$handler}=$main::DB{$_};last;
			}
		}
		
		if ($main::DB{$handler})
		{
			main::_log("this handler is connected");
			next;
		}
		
		# idem connectovat
		
		if ($TOM::DB{$handler}{'type'} eq "DBI")
		{
			if  ($TOM::DB{$handler}{uri} =~ /dbi:ODBC:driver=\{SQL Native Client/i)
			{
				$TOM::DB{$handler}{'subtype'} = 'mssql';
			}
			
			main::_log("DBI connecting '$handler' ('$TOM::DB{$handler}{uri}' '$TOM::DB{$handler}{user}' '****')");
			
#			main::_log("DBI connecting '$handler' ('$TOM::DB{$handler}{uri}' '$TOM::DB{$handler}{user}' '****')",3,"sql.err");
			
			if ($TOM::DB{$handler}{'timeouted'} >= 2)
			{
				main::_log("can't connect '$handler', already timeouted",1);
				$t->close();
				return undef;
			}
			
			eval {
				local $SIG{'ALRM'} = sub {
					$TOM::DB{$handler}{'timeouted'}+=1;
					main::_log("SIG{ALRM} Timed out database connection",1);
					die "Timed out database connection";
				}; # NB: \n required
				alarm(5);
				$main::DB{$handler} = DBI->connect
				(
					$TOM::DB{$handler}{'uri'},
					$TOM::DB{$handler}{'user'},
					$TOM::DB{$handler}{'pass'},
					{
						'PrintError' => 0,
						'RaiseError' => 0,
	#					'LongReadLen' => 6000000,
	#					'syb_enable_utf8' => 1
#						syb_err_handler => \&err_handler
					}
				);
			};
			alarm 0;
			
			if (!$main::DB{$handler})
			{
				main::_log("can't connect '$handler' error='$DBI::err $DBI::errstr' '$@' '$!'",1);
				$t->close();
				return undef;
			}
			
			if ($TOM::DB{$handler}{'uri'}=~/^dbi:Sybase:/)
			{
				$main::DB{$handler}->do("set textsize = 512000");
				$main::DB{$handler}->do("SET DATEFORMAT 'yyyy-MM-dd hh:mm:ss'");
#				$main::DB{$handler}->syb_enable_utf8(1);
			}
			else
			{
				# don't sty readlen by this way for MSSQL
				$main::DB{$handler}->{'LongReadLen'}  = 512000;
			}
			
			#$dbh->{AutoCommit}    = 1;
			#$main::DB{$handler}->{RaiseError}    = 1;
			
			$main::DB{$handler}->{'ora_check_sql'} = 0;
			$main::DB{$handler}->{'RowCacheSize'}  = 32;
			
			foreach my $sql(@{$TOM::DB{$handler}{'sql'}})
			{
				if (ref($sql) eq "CODE")
				{
					main::_log("code call");
					&$sql;
				}
				else
				{
					main::_log("sql='$sql'");
#					TOM::Database::SQL::execute($sql, 'db_h'=>$handler, 'quiet'=>1);
					my $sth=$main::DB{$handler}->{'dbh'}->prepare($sql);$sth->execute();
				}
#				
			}
			
		}
		else
		{
			$TOM::DB{$handler}{'name'}=$TOM::DB{'main'}{'name'} unless $TOM::DB{$handler}{'name'};
			
			main::_log("MySQL connecting '$handler' ('$TOM::DB{$handler}{host}' '$TOM::DB{$handler}{name}' '$TOM::DB{$handler}{user}' '****')");
			
#			main::_log("MySQL connecting '$handler' ('$TOM::DB{$handler}{host}' '$TOM::DB{$handler}{name}' '$TOM::DB{$handler}{user}' '****')",3,"sql.err");
			
			$main::DB{$handler} = Mysql->Connect
			(
				$TOM::DB{$handler}{'host'},
				$TOM::DB{$handler}{'name'} || 'TOM',
				$TOM::DB{$handler}{'user'},
				$TOM::DB{$handler}{'pass'},
			);
			
			if (!$main::DB{$handler} && $handler=~/:\d+$/)
			{
				main::_log("can't connect slave handler '$handler', removing from pool",1);
				undef $TOM::DB{$handler};
				$t->close();
				return undef;
			}
			elsif (!$main::DB{$handler})
			{
				die "Connection to MySQL database not established: ".Mysql->errmsg()."\n";
			}
			
			$main::DB{$handler}->{'dbh'}->{'mysql_auto_reconnect'}=$TOM::DB_mysql_auto_reconnect;
			$main::DB{$handler}->{'dbh'}->{'mysql_enable_utf8'} = 1;
			
			foreach my $sql(@{$TOM::DB{$handler}{'sql'}})
			{
				main::_log("sql='$sql'");
#				TOM::Database::SQL::execute($sql, 'db_h'=>$handler, 'quiet'=>1);
				my $sth=$main::DB{$handler}->{'dbh'}->prepare($sql);$sth->execute();
			}
			
		}
		
	}
	
	$t->close();
	return 1;
}


sub disconnect
{
	my $db_h=shift;
	return undef unless $db_h;
	return undef unless $main::DB{$db_h};
	
	foreach (keys %main::DB)
	{
		next if $_ eq $db_h;
		undef $main::DB{$_} if $main::DB{$_} eq $main::DB{$db_h};
	}
	undef $main::DB{$db_h};
	
	return 1;
}

1;
