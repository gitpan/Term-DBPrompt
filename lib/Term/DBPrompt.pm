package Term::DBPrompt;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.04';

our @EXPORT = qw( get_cmd_line page_open   page_close     set_prompt
                  set_banner   set_command get_candidates set_opt
                  init_pipe    fh);

use base qw(Exporter);
use File::Spec;

use Text::Balanced qw(extract_delimited);

my @pipe;

my $opt_file;
my $opt_argv;
my $opt_interact;
my $opt_prompt;
my $opt_quiet;

my $tty_in;
my $tty_out;

my $inp_prv = '';
my $inp_fin;
my $inp_dat;
my $inp_ctr;
my $inp_tok;
my $inp_typ;
my $inp_fhd;
my $inp_eof = 0;

my @commands;

sub set_opt {
    while (my ($k, $v) = each %{$_[0]}) {
        given ($k) {
            when ('file')    { $opt_file     = $v; }
            when ('argv')    { $opt_argv     = $v; }
            when ('inter')   { $opt_interact = $v; }
            when ('prompt')  { $opt_prompt   = $v; }
            when ('quiet')   { $opt_quiet    = $v; }
            when ('tty_in')  { $tty_in       = $v; }
            when ('tty_out') { $tty_out      = $v; }
            default {
                die "Error: in subroutine set_opt(), found invalid key {$k => '$v'} (not 'file', 'argv', 'inter', 'prompt', 'quiet', 'tty_in' or 'tty_out')";
            }
        }
    }
}

sub init_pipe {
    @pipe = ();
    if (defined $opt_file) {
        push @pipe, ['f', $opt_file]; # first read from a file (if any)
    }
    if (defined $opt_argv and $opt_argv =~ m{\S}xms) {
        push @pipe, ['a', $opt_argv]; # then execute from the commandline
    }
    if (!@pipe or $opt_interact) { # if pipe is empty, or interactive has been forced...
        push @pipe, ['i']; # ...then read from STDIN
    }

    $inp_prv = '';
    $inp_fin = undef;
    $inp_dat = undef;
    $inp_ctr = undef;
    $inp_tok = undef;
    $inp_typ = undef;
    $inp_fhd = undef;
    $inp_eof = 0;

    @commands = ();
}

# set up some parameters:

my $prompt = '?> ';

my $banner =
  qq{\n}.
  qq{**********\n}.
  qq{** Test **\n}.
  qq{**********\n}.
  qq{\n};

my @cmd_available = qw( exit help );

# some setters and getters:

sub set_banner {
    $banner = shift;
}

sub set_prompt {
    $prompt = shift;
}

sub set_command {
    @cmd_available = ();
    for (@_) {
        push @cmd_available, lc;
    }
}

sub get_cmd_line {
    until ($inp_eof or @commands) {
        getdata();
    }
    unless (@commands) { return; }

    my $cmd = shift @commands;
    my ($open, $close, $line) = @$cmd;

    if ($opt_prompt) {
        unless ($inp_typ eq 'i' and $tty_in) {
            say $prompt, $line;
        }
    }

    my @words;
    while (1) {
        my ($extracted, $new_line, $prefix) = extract_delimited $line, q{'"}, q{[^'"]*};

        unless (defined $extracted) {
            $line =~ s{\A \s+}''xms; # remove leading spaces
            push @words, split(m{\s+}xms, $line) if $line =~ m{\S}xms;
            last;
        }

        $line = $new_line;
        $extracted =~ s{\A ['"]}''xms;
        $extracted =~ s{['"] \z}''xms;
        $prefix    =~ s{\A \s+}''xms; # remove leading spaces
        push @words, split(m{\s+}xms, $prefix) if $prefix =~ m{\S}xms;;
        push @words, $extracted;
    }

    # say "DEBUG words = ('@words') has ", scalar @words, " elements!";

    unless (@words) {
        return 'Empty', $open, $close, '';
    }

    $words[0] = lc $words[0];

    my @candidates = get_candidates($words[0]);

    if (@candidates > 1) {
        return 'Dup', $open, $close, $words[0], @candidates;
    }

    if (@candidates == 1) {
        $words[0] = $candidates[0];
        return 'Found', $open, $close, @words;
    }

    return 'Not', $open, $close, @words;
}

sub getdata {
    while (1) {
        unless (defined $inp_tok) {
            unless ($inp_prv eq '') {
                $inp_dat = $inp_prv;
                $inp_prv = '';
                $inp_fin = 1;
                last;
            }
            unless (@pipe) {
                $inp_eof = 1;
                return;
            }
            $inp_tok = shift @pipe;
            $inp_typ = $inp_tok->[0];
            $inp_ctr = 0;

            if ($inp_typ eq 'f') {
                open $inp_fhd, '<', $inp_tok->[1]
                  or die "Can't open < '".$inp_tok->[1]."' because $!";
            }
        }

        $inp_ctr++;

        if ($inp_ctr == 1 and $inp_typ eq 'i' and $tty_in) {
            say $banner;
        }

        given ($inp_typ) {
            when ('f') {
                $inp_dat = <$inp_fhd>;
                unless (defined $inp_dat) {
                    close $inp_fhd;
                    $inp_tok = undef;
                    next;
                }
                chomp $inp_dat;
                $inp_dat =~ s{\A \s+}''xms;
                $inp_dat =~ s{\s+ \z}''xms;

                unless ($inp_prv eq '') {
                    $inp_dat = $inp_prv.' '.$inp_dat;
                    $inp_prv = '';
                }
                $inp_fin = 0;
                last;
            }
            when ('a') {
                $inp_dat = $inp_tok->[1];
                $inp_tok = undef;
                $inp_fin = 0;
                last;
            }
            when ('i') {
                if ($tty_in and !$tty_out) {
                    die "STDOUT is redirected but STDIN is not";
                }
                if ($tty_in) {
                    print $prompt;
                }
                $inp_dat = <STDIN>;
                unless (defined $inp_dat) {
                    $inp_tok = undef;
                    next;
                }
                chomp $inp_dat;

                if (!$tty_in and $opt_prompt) {
                    say $prompt, $inp_dat;
                }

                unless ($inp_prv eq '') {
                    $inp_dat = $inp_prv.' '.$inp_dat;
                    $inp_prv = '';
                }

                $inp_fin = 0;
                last;
            }
            default {
                die "Internal error: type = '$inp_typ' (not 'f', 'a' or 'i')";
            }
        }
    }

    unless ($inp_dat =~ m{\S}xms) {
        push @commands, [1, 1, '']; # generate an empty line
        return;
    }

    # here we translate 'any occurrence of ';' or '#' inside quotes into dummy characters
    # in fact, inside quotes character ';' becomes \x{01}, character '#' becomes \x{02}

    my $line = '';

    while (1) {
        my ($extracted, $new_dat, $prefix) = extract_delimited $inp_dat, q{'"}, q{[^'"]*};

        unless (defined $extracted) {
            $line .= $inp_dat;
            last;
        }

        $inp_dat = $new_dat;
        $extracted =~ tr{;\#}{\x{01}\x{02}}; # inside quotes: convert ';' into \x{01} and '#' into \x{02}
        $line .= $prefix.$extracted;
    }

    if ($line =~ m{\A ([^\#]*) \#}xms) { $line = $1; } # remove comments

    $line =~ s{\s+ \z}''xms; # remove trailing spaces

    # here we find out if there is a trailing, half open command:
    unless ($inp_fin) {
        if ($inp_typ eq 'f' or ($inp_typ eq 'i' and !$tty_in)) {
            my $rest;
            if ($line =~ s{; ([^;]*) \z}';'xms) {
                $rest = $1;
            }
            else {
                $rest = $line; $line = '';
            }
            $rest =~ s{\A \s+}''xms;
            $rest =~ s{\s+ \z}''xms;
            $inp_prv = $rest;
        }
    }

    # split up $line by ';' into @dat
    my @dat;
    for (split m{;}xms, $line) {
        s{\A \s+}''xms;
        tr{\x{01}\x{02}}{;\#}; # re-convert the dummy characters back into ';' and '#'
        push @dat, $_ if m{\S}xms;
    }

    my $last = $#dat;
    for my $i (0..$last) {
        my $open  = $i == 0     ? 1 : 0;
        my $close = $i == $last ? 1 : 0;

        push @commands, [$open, $close, $dat[$i]];
    }
}

sub get_candidates {
    my $word = lc $_[0];

    return $word if grep {$_ eq $word} @cmd_available;

    my $len  = length $word;

    my @cdt;

    for my $c (@cmd_available) {
        if (substr($c, 0, $len) eq $word) {
            push @cdt, $c;
        }
    }

    return @cdt;
}

my $temp_dir = $^O eq 'MSWin32' ? $ENV{TMP} || $ENV{TEMP} : $^O eq 'linux' ? '/tmp' : undef;

unless (defined $temp_dir) {
    die "Error: Can't find tempdir, OS = '$^O'";
}

my $temp_name = File::Spec->catfile($temp_dir, 'DBPrompt.txt');

my $page_fh;

sub fh { $page_fh; }

sub page_open {
    open $page_fh, '>', $temp_name or die "Error: can't open > '$temp_name' because $!";
}

sub page_close {
    close $page_fh;

    if ($inp_typ eq 'i' and $tty_in) {
        if ($^O eq 'MSWin32') {
            system qq{more < "$temp_name"};
        }
        else {
            system qq{more < '$temp_name'};
        }
    }
    elsif (!$opt_quiet) {
        if ($^O eq 'MSWin32') {
            system qq{type "$temp_name"};
        }
        else {
            system qq{cat '$temp_name'};
        }
    }
}

1;

__END__

=head1 NAME

Term::DBPrompt - Commandline prompt for a database application

=head1 NEW INTERFACE

Version 0.03 of Term::DBPrompt has introduced incompatible changes that break the interface. The
changes are:

=head2 Subroutines page_say and page_print

Subroutines page_say() and page_print() have been removed from version 0.03. Instead, a new function
fh() is introduced that returns a filhandle that can be printed to. The replacement is therefore
to use that filehandle as follows: say {fh()} ... or print {fh()} ...

=head2 Getopt::Std

The use of Getopt::Std, Commandline parameters and STDIN/STDOUT handling has been removed from version
0.03. Consequently, those actions must be performed in the calling program and passed on to Term::DBPrompt
with the new methods set_opt() and init_pipe(). (the subroutine init_pipe() must be called after set_opt(),
but before get_cmd_line()).

Here is a sample piece of code:

  use Term::DBPrompt;

  use Getopt::Std;
  getopts('f:ipq', \my %opts);
  set_opt({ file     => $opts{f},
            argv     => "@ARGV",
            inter    => $opts{i},
            prompt   => $opts{p},
            quiet    => $opts{q},
            tty_in   => -t STDIN,
            tty_out  => -t STDOUT,
          });

  init_pipe;

  while (my ($rc, $open, $close, $cmd, @params) = get_cmd_line)

=head2 Other changes

Subroutines page_msg_say() and page_msg_print() have been removed from version 0.03, the
replacement is to use a simple say {fh()} ... or print {fh()} ... as described above. Consequently,
there is no equivalent for option "-s" anymore, this case is now covered by option "-q".

=head1 SYNOPSIS

  use strict;
  use warnings;
  use 5.010;

  use Term::DBPrompt;

  use Getopt::Std;
  getopts('f:ipq', \my %opts);
  set_opt({ file     => $opts{f},
            argv     => "@ARGV",
            inter    => $opts{i},
            prompt   => $opts{p},
            quiet    => $opts{q},
            tty_in   => -t STDIN,
            tty_out  => -t STDOUT,
          });

  set_prompt 'dbx> ';

  set_banner qq{\n}.
    qq{*******************************************\n}.
    qq{**   The Database Application Ver 0.12   **\n}.
    qq{*******************************************\n}.
    qq{*                                         *\n}.
    qq{* to get a help screen,    enter "h(elp)" *\n}.
    qq{* to exit the application, enter "e(xit)" *\n}.
    qq{*                                         *\n}.
    qq{*******************************************\n};

  set_command qw(exit help list);

  init_pipe;

  while (my ($rc, $open, $close, $cmd, @params) = get_cmd_line) {

      next if $rc eq 'Empty';

      page_open if $open;

      if ($rc eq 'Dup') {
          local $" = "', '";
          say {fh()} "-- Command '$cmd' can not be uniquely identified";
          say {fh()} "-- Possibilities are ('@params')";
          say {fh()} "-- type 'h' for help or 'e' to exit";
      }
      elsif ($rc eq 'Multi') {
          say {fh()} "-- Multiple commands can not be issued in interactive mode";
          say {fh()} "-- type 'h' for help or 'e' to exit";
      }
      else {
          given ($cmd) {
              when ('exit') { last; }
              when ('help') { do_help(@params); }
              when ('list') { do_list(@params); }
              default {
                  local $" = "', '";
                  if ($rc eq 'Not') {
                      say {fh()} "-- Invalid command '$cmd' ('@params')";
                      say {fh()} "-- type 'h' for help or 'e' to exit";
                  }
                  else {
                      say {fh()} "-- Function not implemented '$cmd' ('@params')";
                      say {fh()} "-- type 'h' for help or 'e' to exit";
                  }
              }
          }
      }

      page_close if $close;
  }

  sub do_help {
      say {fh()} 'DBX - Database Application';
      say {fh()} '';
      say {fh()} 'Commands:';
      say {fh()} '';
      say {fh()} '  h(elp)   -- shows this screen';
      say {fh()} '  l(ist)   -- list parameters';
      say {fh()} '  e(xit)   -- exit the application';
  }

  sub do_list {
      say {fh()} '*****************';
      say {fh()} '**  Parameters **';
      say {fh()} '*****************';
      say {fh()} '';

      for (1..100) {
          printf {fh()} "Parameter #%03d...: ZZZ\n", $_;
      }

      say {fh()} '';
      say {fh()} '*****************';
  }

=head1 DESCRIPTION

=head2 Interactive mode

We save the example program from the synopsis in dbx.pl and we run it with a simple 'perl dbx.pl',
which creates the following output:

  C:\>perl dbx.pl

  *******************************************
  **   The Database Application Ver 0.12   **
  *******************************************
  *                                         *
  * to get a help screen,    enter "h(elp)" *
  * to exit the application, enter "e(xit)" *
  *                                         *
  *******************************************

  dbx>

As you can see, we are greeted by a banner (as defined by the set_banner command in the dbx.pl program)
and a command prompt 'dbx>'.

Now we can enter our first interactive command, the 'help' command:

  dbx> help

  DBX - Database Application

  Commands:

    h(elp)   -- shows this screen
    l(ist)   -- list parameters
    e(xit)   -- exit the application


  dbx>

Now we can issue another command, the 'list' command. We don't need to spell out the whole command,
the first characters that make that command unique is enough, in this case a simple 'l' suffices.
(The list of available commands is defined by the 'set_command(...)' instruction).

  dbx> l
  *****************
  **  Parameters **
  *****************

  Parameter #001...: ZZZ
  Parameter #002...: ZZZ
  ...
  Parameter #049...: ZZZ
  Parameter #050...: ZZZ
  -- Next  --
  ...
  Parameter #099...: ZZZ
  Parameter #100...: ZZZ

  *****************

  dbx>

You will notice that the output waits for a keypress (see the '-- Next  --' line) after a page is
complete (i.e. it is piped through 'more').

To exit the application, you can either hit the EOF character (that is Ctrl-Z on Windows or Ctrl-D
on Linux) or you can enter the exit command.

=head2 Batch mode

There are 3 different ways to feed commands in batch mode: as a parameter on the commandline, as
a file specified via option '-f' or as a file redirected into STDIN, all of these 3 possibilities
can be combined. Multiple commands can be issued on a single line by separating them with a ';'
character. You can also use the '#' character to write comments.

=over

=item Commandline

Here is an example that uses a parameter on the command line to issue the help command:

  C:\>perl dbx.pl help

In order to issue multiple commands, you need to enclose the parameter with double quotes (on Windows)
or single quotes (on Linux). Here is a Windows example:

  C:\>perl dbx.pl "help; list;"

=item option -f

Here is an example that uses option '-f' to feed a file into dbx.pl. Suppose we have a file 'cmd.txt' that
contains many commands. We could feed this file into dbx.pl like so:

  C:\>perl dbx.pl -f cmd.txt

=item Redirection

We can also feed a file into dbx.pl by redirecting STDIN:

  C:\>perl dbx.pl < cmd.txt

=back

=head2 Commandline interface

Here is an overview of the commandline interface:

  perl dbx.pl [-q] [-p] [-f file] [-i] "cmd1; cmd2; ..."

=over

=item option -q

Option '-q' stands for quiet mode. This option supresses normal output in batch mode (it does not have
any effect in interactive mode).

=item option -p

Option '-p' stands for show prompt. This option shows a prompt and the commands in batch mode. It does
not have any effect in interactive mode where the prompt is shown anyway.

=item option -f

As already described above, we can use option '-f' to feed a file into dbx.pl:

  C:\>perl dbx.pl -f cmd.txt

=item option -i

Option '-i' forces interactive mode where the command would otherwise run in batch mode. Consider the
above example "perl dbx.pl -f cmd.txt" which runs in batch mode, i.e. it terminates after the last command
in cmd.txt. If, however, you wish to continue in interactive mode after the commands in cmd.txt have been
processed, you can use the -i option:

  C:\>perl dbx.pl -i -f cmd.txt

=back

=head1 EXPORTED FUNCTIONS

The following functions are exported by default:

=over

=item set_opt

This function sets one (or more) options (which usually have been read in by "Getopt::Std").
The syntax is: set_opt({ opt1 => "val1", opt2 => "val2", ...), where opt1, opt2 can be any of
the following: ('file', 'argv', 'inter', prompt' or 'quiet').

set_opt() is usually called like this:

  use Term::DBPrompt;

  use Getopt::Std;
  getopts('f:ipq', \my %opts);

  set_opt({ file     => $opts{f},
            argv     => "@ARGV",
            inter    => $opts{i},
            prompt   => $opts{p},
            quiet    => $opts{q},
            tty_in   => -t STDIN,
            tty_out  => -t STDOUT,
          });

=item init_pipe

This function must be called before the first use of get_cmd_line(). It resets its internal counters
to start a new session of commands to be processed.

=item set_prompt

This functions sets the prompt. Here is an example to set the prompt to 'abc> ':

  set_prompt 'abc> ';

The default is '?> '.

=item set_banner

The banner is one big string which is displayed at the beginning of each interactive session. You can
set the banner with the set_banner function:

  set_banner qq{\n}.
    qq{*******************************************\n}.
    qq{**   The Database Application Ver 0.12   **\n}.
    qq{*******************************************\n}.
    qq{*                                         *\n}.
    qq{* to get a help screen,    enter "h(elp)" *\n}.
    qq{* to exit the application, enter "e(xit)" *\n}.
    qq{*                                         *\n}.
    qq{*******************************************\n};

=item set_command

The function set_command is used to register all possible identifiers that can be used to trigger an action.
Two common identifiers are 'help' and 'exit', but there can be many more, depending on the particular
application, such as 'add', 'remove', 'list', etc. The reason why these identifiers have to be registered is that
long commands can be shortened to a prefix, if that prefix is unique. With the help of the function set_command,
the program can then automatically compute the smallest prefix which is still unique to identify an action.

To give a concrete example, suppose we have the following list of commands:

  set_command qw(help exit init input list);

If we issued a command 'h', the system would automatically choose the identifier 'help' because there is only
one identifier that begins with 'h'. However, if we issued a command 'i', the system would not be able to decide
if we wanted the identifier 'init' or 'input'. In order to be valid, we would have to enter at least 3 characters
(either 'ini' or 'inp').

=item get_cmd_line

This is the main function to obtain one line from the input (either from STDIN, from a file or from the commandline).
The function takes no parameter, but returns 5 elements:

  my ($rc, $open, $close, $cmd, @params) = get_cmd_line;

The first parameter is a return code. It can have 4 values: 'Found', 'Not', 'Empty' or 'Dup'.

=over

=item $rc == 'Found'

indicates that the prefix that has been entered corresponds exactly to one identifier. $cmd contains that
identifier in full and @param contains all parameters.

=item $rc == 'Not'

indicates that the prefix that has been entered does not correspond to any identifier.
$cmd contains the prefix and @param contains all parameters.

=item $rc == 'Empty'

indicates that an empty line has been entered.

=item $rc == 'Dup'

indicates that the prefix which has been entered corresponds to more than one identifier. In that case
$cmd contains the prefix and @param contains all the possible identifiers that match the prefix.

=back

The value $open can be either 0 or 1. It indicates whether or not the page_open() function should be
called before the command is executed.

The value $close can be either 0 or 1. It indicates whether or not the page_close() function should be
called after the command is executed.

=item get_candidates

This functions returns all possible candidates for a given word where the prefix of the commands registered in the
set_command function matches that word. The returned list can have 0, 1 or more than 1 element.

=item page_open

This functions opens a temp file to which you can print via the fh() handle.

=item page_close

This functions closes the temp file and displays its content on the screen. (for interactive session, its content
will be piped through "more")

=back

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Klaus Eichner. All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
