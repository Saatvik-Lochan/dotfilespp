#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Basename qw(basename);
use JSON::PP qw(decode_json);
use Time::HiRes qw(time);

$| = 1;

my $KITTY_ICON = '';
my $TMUX_CLIENTS_CACHE = '';
my $TMUX_CLIENTS_CACHE_AT = 0;

binmode STDIN, ':raw';
binmode STDOUT, ':encoding(UTF-8)';

sub run_cmd {
    my (@cmd) = @_;

    open my $fh, '-|', @cmd or return '';
    local $/;
    my $output = <$fh>;
    close $fh;

    return '' unless defined $output;

    $output =~ s/\s+\z//;
    return $output;
}

sub process_firefox {
    my ($data) = @_;

    my @site_handlers = (
        {
            match => qr/\[PDF\] Online LaTeX Editor Overleaf/,
            label => 'overleaf:pdf',
        },
        {
            match  => qr/Online LaTeX Editor Overleaf/,
            label => 'overleaf:editor',
        },
        {
            match => qr/ChatGPT/,
            label => 'gpt',
        },
    );

    my $title = $data->{title} // '';

    for my $site_handler (@site_handlers) {
        next unless $title =~ $site_handler->{match};

        return " " . $site_handler->{label};
    }

    return "" . "firefox";
}

sub process_zathura {
    my ($data) = @_;

    my $title = $data->{title} // '';
    my $name = basename($title);
    $name =~ s/\.[^.]+$//;

    return " $name";
}

sub process_emacs {
    my ($data) = @_;

    my $title = $data->{title} // '';

    if ($title =~ m{([^/]+\.[^/\s]+)}) {
        return " $1";
    }

    return ' emacs';
}

sub process_spotify {
    my ($data) = @_;

    return '󰎆 spotify';
}

sub process_kitty {
    my ($data) = @_;

    my $kitty_pid = $data->{pid};
    return "$KITTY_ICON kitty" unless defined $kitty_pid;

    my $children = run_cmd('ps', '-o', 'pid=,comm=', '--ppid', $kitty_pid);
    my ($terminal_pid, $terminal_comm);

    for my $line (split /\n/, $children) {
        next unless $line =~ /^\s*(\d+)\s+(.*)$/;
        my ($child_pid, $child_comm) = ($1, $2);
        next if $child_comm eq 'kitten';

        $terminal_pid = $child_pid;
        $terminal_comm = $child_comm;
        last;
    }

    return "$KITTY_ICON kitty" unless $terminal_pid;

    my $session = '';
    my $session_target = '';
    my $program = '';

    if ($terminal_comm =~ /^tmux:/) {
        if (time() - $TMUX_CLIENTS_CACHE_AT > 0.2) {
            $TMUX_CLIENTS_CACHE = run_cmd('tmux', 'list-clients', '-F', '#{client_pid}' . "\t" . '#{session_name}');
            $TMUX_CLIENTS_CACHE_AT = time();
        }

        for my $line (split /\n/, $TMUX_CLIENTS_CACHE) {
            my ($client_pid, $client_session) = split /\t/, $line, 2;
            next unless defined $client_pid && $client_pid == $terminal_pid;

            $session_target = $client_session // '';
            $session = $session_target;
            $session = lc $session;
            $session =~ s/\+\d+\z//;
            last;
        }

        if ($session_target) {
            $program = run_cmd('tmux', 'display-message', '-p', '-t', $session_target, '#{pane_current_command}');
        }
    }

    if (!$program) {
        my ($child_pid) = split /\n/, run_cmd('pgrep', '-P', $terminal_pid);
        my $program_pid = $child_pid || $terminal_pid;
        $program = run_cmd('ps', '-o', 'comm=', '-p', $program_pid);
    }

    return "$KITTY_ICON $session:$program" if $session && $program;
    return "$KITTY_ICON $program" if $program;

    return "$KITTY_ICON kitty";
}

sub process_json {
    my ($data) = @_;

    die "expected JSON object\n" unless ref($data) eq 'HASH';

    my %handlers = (
        Emacs              => \&process_emacs,
        firefox            => \&process_firefox,
        kitty              => \&process_kitty,
        Spotify            => \&process_spotify,
        'org.pwmt.zathura' => \&process_zathura,
    );

    my $app_id = $data->{app_id} // '';
    my $handler = $handlers{$app_id};

    return $handler->($data) if defined $handler;

    return lc $app_id;
}

while (my $input = <STDIN>) {
    next unless $input =~ /\S/;

    my $data = eval { decode_json($input) };
    die "invalid JSON: $@" if $@;

    print process_json($data), "\n";
}
