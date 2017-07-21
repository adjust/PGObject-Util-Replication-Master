package PGObject::Util::Replication::Master;

use 5.006;
use strict;
use warnings;

use Moo;

extends 'PGObject::Util::Replication::SMO';

=head1 NAME

PGObject::Util::Replication::Master - Manage Database Masters

=head1 VERSION

Version 0.01

=cut

our $VERSION = 'v0.02';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use PGObject::Util::Replication::Master;

    my $masterdb = PGObject::Util::Replication::Master->new(
                     host => 'localhost',
                     port => 5432,
   );

   # also slot management
   $master->slots();
   $master->addslot('slotname');
   $master->removeslot('slotname');

   
=head1 SERVER PROPERTIES

All are inherited from PGObject::Util::Replication::SMO.

=head1 METHDOS

=head2 ping_wal()

connects to the db and asks for the current wal log series
number (lsn) and related information.  Is intended to be 
used for monitoring and to deliver telemtry data.

Returned hashref includes:

=over

=item snapshot_lsn

The curret query log sequence number at the time of snapshot epoch

=item snapshpt_epoch

The current epoch at time of snapshot (technically small variance
is possible here).

=item delta_bytes

Number of bytes sent to the WAL since last time this was called
(if known).  Will be undef on first run after loading module.

=item delta_secs

Number of seconds (including fractional seconds) since last run
if known.  Will be undef on first run after loading module.

=item bytes_per_sec

Number of bytes per sec on average since last run.  Will be undef
on first run.

=back

On the first run, we will get the lsn and the epoch of the
current snapshot but no deltas because we lack a comparison.
On subsequent runs we get telemetry.

=cut

{
 my $last = {
    snapshot_lsn => undef,
    snapshot_epoch => undef,
    delta_bytes => undef,
    delta_secs => undef,
    bytes_per_sec => undef,
 };
 sub ping_wal {
    my ($self) = @_; 
    my $dbh = $self->connect;
    my $sth = $dbh->prepare("
       WITH snapshot AS (
            SELECT pg_current_xlog_location() AS snapshot_lsn,
                   EXTRACT(EPOCH FROM clock_timestamp()) AS snapshot_epoch
       ), old AS (select ?::pg_lsn as last_lsn, ?::numeric last_epoch)
       SELECT snapshot.*, snapshot_lsn - last_lsn AS delta_bytes,
             snapshot_epoch - last_epoch as delta_secs,
             (snapshot_lsn - last_lsn) / (snapshot_epoch - last_epoch) AS bytes_per_sec
        FROM snapshot cross join old;
    ");
    $sth->execute($last->{snapshot_lsn}, $last->{snapshot_epoch});
    my $current = $sth->fetchrow_hashref('NAME_lc');
    $last = $current;
    return $current;
 }
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at adjust.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-replication-master at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-Replication-Master>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::Replication::Master


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-Replication-Master>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-Replication-Master>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-Replication-Master>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-Replication-Master/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Adjust.com
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Util::Replication::Master
