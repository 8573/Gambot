if ($message =~ /^${sl}${cm}ftc (-?[0-9]*.*[0-9]*)$/i) {
  my $answer = sprintf("%.2f",(5/9) * ($1 - 32));
  actOut('MESSAGE',$target,"$receiver: $answer°C");
}

if ($message =~ /^${sl}${cm}ctf (-?[0-9]*.*[0-9]*)$/i) {
  my $answer = sprintf("%.2f",(9/5) * $1 + 32);
  actOut('MESSAGE',$target,"$receiver: $answer°F");
}
