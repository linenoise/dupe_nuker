Dupe Nuker
==========

Systematically removes duplicate files from a directory

SYNOPSIS
--------

Usage: dupe_nuker <directory>

Description
-----------

This script walks a directory path (breadth-first) and unceremoniously removes duplicate files. It does this by calculating and maintaining a cache of MD5sums for each file using SQLite. Only the first instance of any given file is preserved: all successive hits on that md5sum are removed.

Procedure
---------

0. Load prerequisites

    This script requires the Digest::MD5, File::DirWalk, and DBD::SQLite modules.

    Also, this enables buffer auto-flushing so we can see progress without having to wait for a buffer.

1. Make sure the user gave us a directory

    Grab the directory to clean from ARGV. If it's not there, print usage information and exit.

2. Connect the database handle

    Using the data file '.dupe_nuker.sqlite', we bind a DBI::SQLite handle so we can cache MD5 hits. This file is removed if it exists, and the script exits if it can't connect a database handle to this file.

3. Create the database table
4. Create and bind a file walk procedure

    4.0 Create and cache statement handles
    4.1. Skip dotfile
    4.2 - Calculate the MD5 of a file (open, read, checksum, and close)
    4.3 - If the file is a duplicate (i.e. already has an entry in the checksum cache), unlink it.
    4.3 - If the file is unique, write it to the checksum cache and continue.

5. Bind a directory walk procedure

    This procedure just prints the name of the current directory so we know where we're at during execution.

6. Walk the folder and run the file and directory procedures for each
7. Remove the cache data file

Copyright
---------

This script is Copyright (c) 2010 by Dann Stayskal.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

