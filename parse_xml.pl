use XML::Simple;
use POSIX;
require 'note.pm';
$outfile = "midi.txt";
$p1 = XML::Simple->new();
$data=$p1->XMLin('xml_test.xml');

print "$data->{'part'}\n";
if(ref($data->{'part'}) eq 'ARRAY')
{
   @parts = @{$data->{'part'}};
}
else
{
   @parts = ($data->{'part'});
}

open $fh, ">$outfile" || die "Unable to open file for writing: $!";
if(defined($data->{'part'}{'id'})) #un solo instrumento
{
   process_part(0,$data->{'part'},$fh);
}
else
{
   my $i = 0;
   foreach my $key (keys %{$data->{'part'}})
   {
      process_part($i,$data->{'part'}{$key},$fh);
	  $i++;
   }   
}
close $fh;