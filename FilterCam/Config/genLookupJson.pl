#!/usr/bin/perl

use strict;
#use warnings;
use feature qw(switch say);
use List::Util qw[min max];

# generates partial JSON for setting up lookup filters, for use in FilterConfig.json

my @fileList = ();



# assume files are in ../Images/Lookup/, check that it's there

my $rootdir = '../../../SampleImages/Lookup';

if (-e $rootdir and -d $rootdir) {
    print "\n\nChecking directory: $rootdir\n";
} else {
    die "directory not found: $rootdir";
}


# find all .jpg, .JPG, .png and .PNG files
processDir($rootdir);




# generate Lookup list and keys
my $count = @fileList;

if ($count == 0) {
    print "No files found\n\n";
    exit;
}

#print "IMAGES: @fileList\n"; # DEBUG

print "\"lookup\": [ \n";

my $key = "";
for my $i (0 .. ($count-2))
{
    $key = substr(@fileList[$i], 0, 6);
    print "               { \"key\": \"$key\", \"image\": \"$fileList[$i]\" },\n" ;
}
$key = substr(@fileList[$count-1], 0, 6);
print "               { \"key\": \"$key\", \"image\": \"$fileList[$count-1]\" }\n" ;





# generate template for category assignments

print "\n\n               {\"category\": \"???\",\n";
print "                   \"filters\": [\n";


my $k = 0;
$key = "";
my $oldkey = "";
my $p1 = "";
my $p2 = "";
my $rem = 0;
my $j = 0;

while ($k < $count){
    $rem = min(10, ($count-$k));
    print "                           ";
    $j = 0;
    while ($j < $rem){
        $key = substr(@fileList[$k], 0, 6);
        $p1 = substr($key, 0, 2);
        $p2 = substr($oldkey, 0, 2);
        $oldkey = $key;
        $k = $k + 1;
        if ($p1 ne $p2) {
            print "\n                           ";  # changed category, start new line
            $j = 0;
            $rem = min(9, ($count-$k));
        } else {
            $j = $j + 1;
        }
        print "\"$key\", ";
    }
    print "\n";
}

print "                   ]\n";
print "               },\n\n";





# subroutine to process a directory
sub processDir{
    my ($d) = @_;
    print "Processing: \"$d\"\n";
    
    opendir my($rootdirhandle), $d;
    my @files = readdir($rootdirhandle);
    closedir($rootdirhandle);
    
    foreach my $file (@files)
    {
        # skip . and ..
        next if($file =~ /^\.$/);
        next if($file =~ /^\.\.$/);
        next if ($file =~ /^\./);
        
        # skip lookup.jpg and lookup.png (template files)
        next if($file =~ /^lookup.jpg$/);
        next if($file =~ /^lookup.png$/);
        
        #print "\"$file\"\n"; # debug
        
        # directory?
        my $path = $d . "/" . $file;
        if (-d $path) {
            #print "Dir: $path\n";
            processDir($path);
        }
        
        
        # valid file types
        
        if ($file =~ /\.jpg$/i) { push @fileList, $file };
        
        #if ($file =~ /\.JPG$/i){ push @fileList, $file };
        
        if ($file =~ /\.png$/i){ push @fileList, $file };
        
        #if ($file =~ /\.PNG$/i){ push @fileList, $file };
    }
}
