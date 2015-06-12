use MooseX::Declare;
class Note
{
   has part_num =>(is => 'rw', isa =>'Int');
   has number => (is => 'rw',isa =>'Int');   
   has duration =>(is => 'rw');
   has start_tie =>(is => 'rw');
   has stop_tie =>(is => 'rw');   
   
   sub to_string ()
   {
      my $self = shift;
      my $ret = "$self->{'part_num'}";
	  if(-1 == $self->number)
	  {
	     $ret.="S$self->{'duration'}";
	  }
	  else
	  {
	     $ret.="N$self->{'number'}"."D$self->{'duration'}";
	  }
      return $ret;
   }
}

sub process_part()
{
   my %duration=("whole" => 4, "half" => 2, "quarter" => 1,
           "eighth" => 0.5, "16th" => 0.25,
		   "32nd" => 0.125);
   my %note_numbers=("C" => 0, "C#" =>1, "Db"=>1, "D" => 2, "D#"=>3, "Eb" => 3,
              "E" => 4, "F" =>5, "F#" =>6, "Gb" =>6, "G" =>7, "G#" =>8, "Ab" => 8,
			  "A"=>9, "A#"=>10,"Bb"=>10,"B"=>11);	
   my $part_num = shift;			  
   my $part = shift;
   my $file_handle = shift;   
   my %parts = %{$part};
   my $tempo = $parts{'measure'}[0]->{'sound'}->{'tempo'};
   my $numerador = $parts{'measure'}[0]->{'attributes'}->{'time'}->{'beats'} if defined $parts{'measure'}[0]->{'attributes'}->{'time'}->{'beats'};
   my $denominador = $parts{'measure'}[0]->{'attributes'}->{'time'}->{'beat-type'} if defined $parts{'measure'}[0]->{'attributes'}->{'time'}->{'beat-type'};
   my @part_notes = ();
   my @notes = ();
   my $total_time;
   my $rest;
   my $i;
   my $start_tie;
   my $stop_tie;
   my $note_duration;
   my @ties = ();
   my $tie;
   my $note_number;
   my $note;

   foreach my $measure (@{$parts{'measure'}}) #estos son los compases del instrumento en cuestion
   {
      $numerador = $measure->{'attributes'}->{'time'}->{'beats'} if defined $measure->{'attributes'}->{'time'}->{'beats'};
      $denominador = $measure->{'attributes'}->{'time'}->{'beat-type'} if defined $measure->{'attributes'}->{'time'}->{'beat-type'};
      if(defined $measure->{'sound'}->{'tempo'})
      {
	     $tempo = $measure->{'sound'}->{'tempo'};
      }
      $total_time = $numerador / $denominador * 4 * 60 / $tempo * 1000;
      $rest = $total_time;
      if (ref($measure->{'note'}) eq 'ARRAY')
      {
         @notes = @{$measure->{'note'}};
      }	  
      else
      {
         @notes = ($measure->{'note'});
      }  
      for ($i = 0; $i<= $#notes; $i++)
      {
         $start_tie = 0;
	     $stop_tie = 0;
         $note_duration = 1000 * $duration{$notes[$i]->{'type'}} * 60 / $tempo;
	     #trecillos(y otros -illos)
	     if (defined($notes[$i]->{'time-modification'}))
	     {
		    $note_duration *= $notes[$i]->{'time-modification'}->{'normal-notes'} / $notes[$i]->{'time-modification'}->{'actual-notes'};		 
	     }
         #puntillos
	     if(defined($notes[$i]->{'dot'}))
	     {
	        print "puntillo";
	        $note_duration *= 1.5;
	     }
	     $note_duration = floor($note_duration);
	     $rest -= $note_duration;
	     if($i == $#notes)
	     {
	        $note_duration += $rest;
	     }
	     #ligaduras
	     if(defined($notes[$i]->{'tie'}))
	     {
	        if (ref($notes[$i]->{'tie'}) eq 'ARRAY')
		    {
		       @ties = @{$notes[$i]->{'tie'}};
		    }
		    else
		    {
		       @ties = ($notes[$i]->{'tie'});
		    }
	        foreach $tie (@ties)
		    {
			   $start_tie = 1 if ($tie->{'type'} eq 'start');			
			   $stop_tie = 1 if ($tie->{'type'} eq 'stop');						
		    }		 
	     }
	  
	     if (defined($notes[$i]->{'pitch'}{'octave'}))#means we got a note and not a silence
	     {
	        $note_number = 12 * $notes[$i]->{'pitch'}{'octave'} + $note_numbers{$notes[$i]->{'pitch'}{'step'}};		 
		    push(@part_notes, Note->new(part_num => $part_num,number=>$note_number,duration=>$note_duration,
		                             start_tie =>$start_tie,stop_tie=>$stop_tie));
	     }	 
	     else
	     {
		    push(@part_notes, Note->new(part_num=>$part_num,number=>-1,duration=>$note_duration,
		                             start_tie =>$start_tie,stop_tie=>$stop_tie));
	     }
      }
   
   }
   #check ties
   for($i=0;$i<=$#part_notes;$i++)
   {
      #check if the tied notes are the same, and tied correctly
      if($i >0 && $part_notes[$i-1]->{'start_tie'} && $part_notes[$i]->{'stop_tie'}
               && $part_notes[$i-1]->{'number'} == $part_notes[$i]->{'number'})
      {
         #absorb the duration of the next note
         $part_notes[$i-1]->{'duration'} += $part_notes[$i]->{'duration'};
	     #remove the current note, and set the pointer one back, so that it returns to the current note
	     $i-- if splice(@part_notes,$i,1);
      }
   }
   
   foreach $note (@part_notes)
   {
      print $file_handle $note->to_string."\n";
   }
}
1;