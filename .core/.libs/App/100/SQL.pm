#!/bin/perl
package App::100::SQL;

=head1 NAME

App::100::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 DEPENDS

 App::100

=cut

use App::100;

=head1 FUNCTIONS

=head2 ticket_event_new

Vloží nový záznam

=head2 ticket_close

Uzavrie ticket

=cut

our $debug=0;

sub ticket_event_new
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::ticket_event_new()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};
	
	foreach (keys %env)
	{
		main::_log("input '$_'='$env{$_}'");
	}

	my $ID_ticket;

	# Ak existuje tiket z danym nazvom, tak
	my $sql = qq/
	SELECT
		ID, emails, status
	FROM
		TOM.a100_ticket
	WHERE
		domain='$env{'domain'}' AND
		name='$env{'name'}'
	/;
	my %sth0 = TOM::Database::SQL::execute( $sql, 'db_h'=>$env{'db_h'}, 'log'=>$debug);
	
	if ( !$sth0{'rows'} )
	{
		# Este taky ticket nemam, musim ho vytvorit
		$ID_ticket = App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => "TOM",
			'tb_name' => "a100_ticket",
			'columns' => {
				'domain' => "'$env{'domain'}'",
				'name' => "'$env{'name'}'",
				'emails' => "'$env{'emails'}'",
				'status' => "'Y'",
			},
			'-journalize' => 1
		);
	}
	else
	{
		my %ticket = $sth0{'sth'}->fetchhash;
		$ID_ticket = $ticket{'ID'};
		my $journalize;
		$journalize=1 if $ticket{'status'} ne 'Y';
		App::020::SQL::functions::update(
			'db_h' => "main",
			'db_name' => "TOM",
			'tb_name' => "a100_ticket",
			'ID' => $ticket{'ID'},
			'columns' =>
			{
				'status' => "'Y'",
				'emails' => "'$env{'emails'}'",
			},
			'-journalize' => $journalize
		);
	}

	return 0 unless $ID_ticket;

	$env{'cvml'} =~ s|'|\\'|g;

	# Vytvaram ticket event
	my $ID_ticket_event = App::020::SQL::functions::new(
		'db_h' => "main",
		'db_name' => "TOM",
		'tb_name' => "a100_ticket_event",
		'columns' => {
			'ID_ticket' => $ID_ticket,
			'cvml' => "'$env{'cvml'}'",
			'status' => "'Y'",
		},
	);
	
	return 0 unless $ID_ticket_event;
	$t->close();
	return 1;
}

sub ticket_close
{
	my %env=@_;
	my $t=track TOM::Debug(__PACKAGE__."::ticket_close()");
	
	$env{'db_h'}='main' unless $env{'db_h'};
	$env{'db_name'}=$TOM::DB{$env{'db_h'}}{'name'} unless $env{'db_name'};

	return 0 unless $env{'ID'};

	App::020::SQL::functions::update(
		'db_h' => 'main',
		'db_name' => 'TOM',
		'tb_name' => 'a100_ticket',
		'ID' => $env{'ID'},
		'columns' =>
		{
			'status' => "'N'",
		},
		'-journalize' => 1
	);

	App::020::SQL::functions::update(
		'db_h' => 'main',
		'db_name' => 'TOM',
		'tb_name' => 'a100_ticket_event',
		'ID_ticket' => $env{'ID'},
		'columns' =>
		{
			'status' => "'N'",
		}
	);

	$t->close();
	return 1;
}


1;
