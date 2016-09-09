#!/usr/bin/perl -w

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTPS;
use Email::MIME::CreateHTML;
use Try::Tiny;

use constant LOGGING_CONFIG => 'logging.cnf';
use constant EXCLUDE_FROM => 'exclude.cnf'; 

use constant MAIL_SUBJ => '';
use constant MAIL_TO => '';
use constant MAIL_FROM => '';
use constant SMTP_HOST => '';
use constant SMTP_PORT => '';
use constant SASL_USER => '';
use constant SASL_PASS => '';

use constant OK => 'OK';
use constant ERROR => 'ERROR';

Log::Log4perl->init(LOGGING_CONFIG);
my $LOG = get_logger();

my $source = shift;
my $dest = shift;
die_usage()
    unless $source and $dest;

my $changelog = generate_changelog($source, $dest);
my $status = sync_folders($source, $dest);
send_changelog($changelog, $status);


sub send_changelog {
    $LOG->info("emailing changelog");
    my $changelog = shift;
    my $status = shift;
    my $message = format_message($changelog, $status);
    my $transport = init_mail_transport();
    try {
        sendmail($message, { transport => $transport });
    } catch {
        $LOG->logdie("Error sending email: $_");
    };
}


sub init_mail_transport {
    return Email::Sender::Transport::SMTPS->new(
        host => SMTP_HOST,
        port => SMTP_PORT,
        ssl  => 'starttls',
        sasl_username => SASL_USER,
        sasl_password => SASL_PASS,
        debug => 0, # or 1
    );    
}


sub format_message {
    my $changelog = shift;
    my $status = shift;
    my $color = status_color($status);
    my $cnt = scalar(@$changelog);
    my $log = join "\n", @$changelog;
    my $body = "<b>Status:</b> [<span style='color: $color'>$status</span>]<br/>\n";
    $body .= "<b>File count:</b> [$cnt]<br/>\n";
    $body .= "<pre>\n$log</pre>\n";    

    return Email::MIME->create_html(
        header => [
            From    => MAIL_FROM,
            To      => MAIL_TO,
            Subject => MAIL_SUBJ,
        ],
        body => $body
    );
}


sub status_color {
    my $s = shift;
    return 'green'
        if $s eq OK;
    return 'red';
}
        

sub generate_changelog {
    my $source = shift;
    my $dest = shift;
    my $cmd = sprintf "rclone check '%s' '%s' --exclude-from %s --quiet 2>&1 1>/dev/null", $source, $dest, EXCLUDE_FROM;
    my @log = `$cmd`;
#    $LOG->logdie("Error when generating changelog: $?")
#    if $?;
    chomp @log;
    return \@log;
}


sub sync_folders {
    my $source = shift;
    my $dest = shift;
    
    my $cmd = sprintf "rclone sync '%s' '%s' --exclude-from %s --quiet 2>&1 1>/dev/null", $source, $dest, EXCLUDE_FROM;
    my @log = `$cmd`;
    if ($?) {
        $LOG->error("Error when sync'ing [$source] to [$dest]: $?");
        return ERROR;
    }
    return OK;
}


sub die_usage {
    my $mesg = "Usage: $0 [source] [destination]\n";
    die $mesg;
}

