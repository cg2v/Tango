#!/usr/bin/perl
# can't use IO::Dir, File::Copy, or User::pwent if in perl-base environment
use strict;
use File::Spec;
use IO::File;

# assumes both src and dst are paths of files (dst may or may not exist)
sub copyfile {
 my ($src, $dst)=@_;
 my ($s, $d);
 my ($len, $buf);

 $s=new IO::File "<$src" or die "open $src: $!\n";
 $d=new IO::File ">$dst" or die "open $dst: $!\n";

 do {
   $len=$s->sysread($buf, 10240);
   die "read $src: $!\n" if (!defined($len));
   $d->syswrite($buf, $len);
 } while ($len > 0);
 $s->close;
 $d->close;
}


opendir DIR, "mount" or die "Cannot open 'mount': $!\n";
foreach my $fn (readdir DIR) {
  my $src=File::Spec->catfile("mount", $fn);
  my $dst=File::Spec->catfile("autolab", $fn);
  if (-f $src) {
    copyfile($src, $dst);
  }
}
closedir DIR;

my @userinfo=getpwnam("autolab");
die "Cannot get info for user 'autolab': $!\n" unless (scalar @userinfo > 2 && $userinfo[2] > 0);

my $pid=fork;

die "Cannot fork: $!\n" unless defined($pid);

if ($pid == 0) {
   my $grpstring=sprintf("%d %d", $userinfo[3], $userinfo[$3]);
   $! = 0;
   $) = $grpstring;
   die "initgroups: $!\n" if ($!);
   $( = $userinfo[3];
   die "setgid: $!\n" if ($!);
   $> = $userinfo[2];
   die "seteuid: $!\n" if ($!);
   $< = $userinfo[2];
   die "setuid: $!\n" if ($!);
   my $logfile = new IO::File ">output/feedback" or die "Cannot open 'output/feedback': $!\n";
   my @newargs;
   push @newargs, "autodriver";
   push @newargs, @ARGV;
   push @newargs, "autolab";
   #print $logfile "Executing ",  join(" ", @newargs), "\n";
   open STDOUT, ">&", $logfile or die "Redirect stdout: $!\n";
   open STDERR, ">&", $logfile or die "Redirect stderr: $!\n";
   close($logfile);
   exec @newargs;
   exit(-1);
}

my ($wpid, $status);
do { $wpid = waitpid($pid, 0); } while ($wpid > 0 && $wpid != $pid);
if ($? & 0xff) {
  $status=-1;
} else {
  $status = $? >> 8;
}
copyfile("output/feedback", "mount/feedback");
exit($status);
