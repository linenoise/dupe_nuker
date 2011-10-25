#!/usr/bin/perl -w
use strict;

=head1 NAME

dupe_nuker -- Systematically removes duplicate files from a directory

=head1 SYNOPSIS

Usage: dupe_nuker <directory>

=head1 DESCRIPTION

This script walks a directory path (breadth-first) and unceremoniously removes duplicate files.  It does this by calculating and maintaining a cache of MD5sums for each file using SQLite.  Only the first instance of any given file is preserved: all successive hits on that md5sum are removed.

=head1 PROCEDURE

=over 12

=item 0. Load prerequisites

This script requires the L<Digest::MD5>, L<File::DirWalk>, and L<DBD::SQLite> modules.

Also, this enables buffer auto-flushing so we can see progress without having to wait for a buffer.

=cut

use Digest::MD5 qw/md5_base64/;
use File::DirWalk;
use DBI;

$| = 1; ### Buffer auto-flushing++;


=item 1. Make sure the user gave us a directory

Grab the directory to clean from ARGV.  If it's not there, print usage information and exit.

=cut

my $directory = $ARGV[0] || print("Usage: $0 <directory>\n") && exit 1;


=item 2. Connect the database handle

Using the data file '.dupe_nuker.sqlite', we bind a DBI::SQLite handle so we can cache MD5 hits.  This file is removed if it exists, and the script exits if it can't connect a database handle to this file.

=cut

my $data_file = '.dupe_nuker.sqlite';
unlink($data_file);	

my $dbh = DBI->connect("dbi:SQLite:dbname=$data_file","","");
my %sth;



=item 3. Create the database table

This script uses a simple database table:

	Checksums (table)
		- file (text)                ### Stores the filename
		- checksum (varchar(255))    ### Stores the md5sum of that file

=cut

$sth{create_checksums} = $dbh->prepare('create table checksums(file text, checksum varchar(255))');
unless ($sth{create_checksums}->execute()) {
	print "Couldn't create checksums table.  Exiting\n";
	exit 1;
}


=item 4. Create and bind a file walk procedure

Create the L<File::DirWalk> object and bind a file walk procedure consisting of:

=over 12

=cut

### Spin through every file in the  folder, calculate MD5 (if not on file) and store
my $walker = new File::DirWalk;
$walker->onFile(sub {
	my ($file) = @_;


=item 4.0 Create and cache statement handles

create and cache useful statement handles for checking files and checksums in the cache, and for creating new cache entries.

=cut

	$sth{file_check}     ||= $dbh->prepare('select checksum from checksums where file = ?');
	$sth{checksum_check} ||= $dbh->prepare('select file from checksums where checksum = ?');
	$sth{new_checksum}   ||= $dbh->prepare('insert into checksums (file, checksum) values (?,?)');

=item 4.1. Skip dotfiles -- we don't care if .DS_Store is identical

=cut

	### Skip dotfiles
	my @paths = split /\//, $file;
	if ($paths[-1] =~ /^\./) {
		return File::DirWalk::SUCCESS;		
	}

=item 4.2 - Calculate the MD5 of that file (open, read, checksum, and close)

=cut

	open('FILE', '<', $file) || print("Couldn't open $file for read.\nExiting.\n") && exit 1;
	my $data = join('',<FILE>);
	close('FILE');
	my $md5 = md5_base64($data);
	
	### Determine whether this is unique
	if ($sth{checksum_check}->execute($md5)) {
		my $row = $sth{checksum_check}->fetchrow_hashref();
		if ($row->{file}) {
		
		
=item 4.3 - If the file is a duplicate (i.e. already has an entry in the checksum cache), unlink it.

=cut

			### It's a dupe.  Nuke it.
			unlink($file);
			print 'X';
			
		} else {
			
			
=item 4.3 - If the file is unique, write it to the checksum cache and continue.

=cut
			### It unique.  Log it.
			my $safe_filename = $file;
			$safe_filename =~ s/\'/\\\'/g;
			unless ($sth{new_checksum}->execute($safe_filename, $md5)) {
				print "Couldn't store checksum $md5 for file '$file'\nExiting.\n";
				exit 1;
			}
			print '+';

		}
		
	} else {
		print "Couldn't compare checksum $md5 for file '$file'\nExiting.\n";
		exit 1;
	}

	return File::DirWalk::SUCCESS;
});

=back

=cut


=item 5. Bind a directory walk procedure

This procedure just prints the name of the current directory so we know where we're at during execution.

=cut

$walker->onDirEnter(sub {
	my ($directory) = @_;
	print "\n\nIn $directory:\n";
	return File::DirWalk::SUCCESS;
});


=item 6. Walk the folder and run the file and directory procedures for each

Iterate through each file and subdirectory in the provided directory and execute the bound file and directory routines on each.

=cut

$walker->walk($directory);


=item 7. Remove the cache data file

=cut

unlink($data_file);


=back

=head1 AUTHORS

This script written by Dann Stayskal <dann@stayskal.com>.

=head1 COPYRIGHT

This script is Copyright (c) 2010 by Dann Stayskal and available under the same license as perl itself.

=cut