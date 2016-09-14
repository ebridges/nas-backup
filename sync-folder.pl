#!/usr/bin/perl -w

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use Config::IniFiles;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTPS;
use Email::MIME::CreateHTML;
use Try::Tiny;

use constant OK => 'OK';
use constant ERROR => 'ERROR';

use constant LOGGING_CONFIG => 'logging.cnf';
use constant EXCLUDE_FROM => 'exclude.cnf';
use constant EMAIL_CONFIG => 'email.cnf';
use constant RCLONE_CONFIG => 'rclone-config.cfg';

Log::Log4perl->init(LOGGING_CONFIG);
my $LOG = get_logger();

my $env = 'DEVELOPMENT';
if (defined $ENV{NASBACKUP_ENV}) {
    $env = $ENV{NASBACKUP_ENV};
}

my $cfg = Config::IniFiles->new( -file => EMAIL_CONFIG );

my $MAIL_SUBJ = $cfg->val( $env, 'mail-subject' );
my $MAIL_TO = $cfg->val( $env, 'mail-to' );
my $MAIL_FROM = $cfg->val( $env, 'mail-from' );
my $SMTP_HOST = $cfg->val( $env, 'smtp-hostname' );
my $SMTP_PORT = $cfg->val( $env, 'smtp-port-num' );
my $SASL_USER = $cfg->val( $env, 'smtp-username' );
my $SASL_PASS = $cfg->val( $env, 'smtp-pasword' );

my $source = shift;
my $dest = shift;
die_usage()
    unless $source and $dest;

my $changelog = generate_changelog($source, $dest);
$LOG->debug("changelog with " . scalar(@$changelog) . " entries.");
my $status = sync_folders($source, $dest);
$LOG->debug("sync completed.");
send_changelog($changelog, $status, $source, $dest);


sub send_changelog {
    $LOG->info("emailing changelog");
    my $changelog = shift;
    my $status = shift;
    my $src = shift;
    my $des = shift;
    my $message = format_message($changelog, $status, $src, $des);
    my $transport = init_mail_transport();
    try {
        sendmail($message, { transport => $transport });
    } catch {
        $LOG->logdie("Error sending email: $_");
    };
    $LOG->trace('changelog emailed.')
}


sub init_mail_transport {
    $LOG->trace("initializing mail transport to <$SMTP_HOST:$SMTP_PORT>");
    return Email::Sender::Transport::SMTPS->new(
        host => $SMTP_HOST,
        port => $SMTP_PORT,
        ssl  => 'starttls',
        sasl_username => $SASL_USER,
        sasl_password => $SASL_PASS,
        debug => 0, # or 1
    );    
}


sub format_message {
    $LOG->trace("formatting message to <$MAIL_TO>");
    my $changelog = shift;
    my $status = shift;
    my $src = shift;
    my $des = shift;
    my $color = status_color($status);
    my $cnt = scalar(@$changelog);
    my $log = join "\n", @$changelog;
    my $body = "<b>Status:</b> [<span style='color: $color'>$status</span>]<br/>\n";
    $body .= "<b>File count:</b> [$cnt]<br/>\n";
    $body .= "<b>Source:</b> [$src]<br/>\n";
    $body .= "<b>Destination:</b> [$des]<br/>\n";
    $body .= "<pre>\n$log</pre>\n";    

    return Email::MIME->create_html(
        header => [
            From    => $MAIL_FROM,
            To      => $MAIL_TO,
            Subject => $MAIL_SUBJ,
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
    $LOG->trace("generating changelog");
    my $source = shift;
    my $dest = shift;
    my $cmd = sprintf "rclone check '%s' '%s' --config %s --exclude-from %s --quiet 2>&1 1>/dev/null", $source, $dest, RCLONE_CONFIG, EXCLUDE_FROM;
    $LOG->trace("check command: [$cmd]");
    my @log = `$cmd`;
    chomp @log;
    return \@log;
}


sub sync_folders {
    my $source = shift;
    my $dest = shift;
    $LOG->trace("sync source: [$source] to [$dest]");
    my $cmd = sprintf "rclone sync '%s' '%s' --config %s --exclude-from %s --verbose 2>&1 1>/dev/null", $source, $dest, RCLONE_CONFIG, EXCLUDE_FROM;
    $LOG->trace("sync command: [$cmd]");
    my @log = `$cmd`;
    if ($?) {
        $LOG->error("Error when syncing [$source] to [$dest]: $?");
        return ERROR;
    }
    return OK;
}


sub die_usage {
    my $mesg = "Usage: $0 [source] [destination]\n";
    die $mesg;
}

