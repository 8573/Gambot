use Encode;

## `janebot: memo <addressee> <text>` — Record a memorandum.
if ($message =~ /^${sl}${cm}memo\s+(\S+)\s+(.+)$/i) {
  ## Memoranda are serialized for storage as space-separated lists of
  ## `key:value` pairs.
  ##
  ## The presently defined keys are as follows:
  ##  - `in`, whose value is the channel in which the memorandum was recorded;
  ##  - `to`, whose value is the nick to which the memorandum is addressed;
  ##  - `from`, whose value is the nick of the author of the memorandum; and
  ##  - `text`, whose value is the text of the memorandum.
  ##
  ## Note that `text` should come last, because its value may contain spaces.
  my $memo = "in:$target to:$1 from:$sender text:$2";

  ## Check that the length in octets of the memorandum as it will be delivered
  ## does not exceed the maximum.
  ##
  ## IETF RFC 2812 §2.3 specifies the maximum length of an IRC message as 512
  ## “characters”; given the age of the protocol and the language used in the
  ## specification, I assume that by “characters” it means “octets”.
  ##
  ## Compute the length in octets of the serialized memorandum, plus the
  ## length in octets of the name of the channel in which the memorandum is to
  ## be delivered:
  my $memoLength = length(Encode::encode_utf8($memo . $target))
    ## The length in octets of the serialized memorandum includes the length
    ## of the field keys and other serialization format cruft, which will not
    ## be included in the memorandum when it is delivered.
    ##
    ## Accordingly, subtract the length of this serialization format cruft
    ## from the length in octets of the concatenation of the serialized
    ## memorandum and the name of the channel in which the memorandum is to be
    ## delivered.
    ##
    ## All keys that are presently defined for memorandum serializations (see
    ## above) should be included here, terminated by colons *and* separated by
    ## spaces:
    - length('in: to: from: text:');
  ## Compute the maximum length in octets for the concatenation of the
  ## serialized memorandum (sans format cruft) and the name of the channel in
  ## which the memorandum is to be delivered.
  ##
  ## This is the maximum length in octets of an IRC message per IETF RFC 2812
  ## §2.3 (see above), minus the quantity of octets rendered unavailable for
  ## fitting the memorandum and target channel name into by the IRC message
  ## format and the memorandum delivery formatting:
  my $maxLength = 512 - length("PRIVMSG  :: <> \015\012");
  ## If the memorandum is not too long, add it to a list of memoranda to be
  ## delivered in the future:
  if ($memoLength <= $maxLength) {
    ## This script uses one persistent variable, `memoranda>memos`, which is a
    ## newline-separated list of currently undelivered memoranda.
    my $memos = $core->value_get('memoranda', 'memos');

    ## Append this memorandum to the list of undelivered memoranda:
    $core->value_set('memoranda', 'memos', "$memos\n$memo");

    ## Notify the author of the memorandum that the memorandum has been
    ## recorded:
    actOut('MESSAGE', $target, "$sender: Memorandum for $1 saved.");
  }
  ## If the memorandum is too long, then…
  else {
    my $n = $memoLength - $maxLength;
    my $s = $n > 1 ? 's' : '';
    ## …notify the author of the memorandum that the memorandum was not
    ## recorded due to being overly long:
    actOut('MESSAGE', $target,
      "$sender: I can’t handle that memorandum, it’s $n byte$s too long!");
  }
}

## When someone speaks, deliver all memoranda from the channel in which the
## person spoke that are addressed to that person’s nick.

## Going through the list of all undelivered memoranda…
my @memos = map {
  ## …if a memorandum therein is both from this channel and addressed to the
  ## nick of the person who just spoke (with both the channel name and the
  ## addressee nick being case-insensitive)…
  $_ =~ /^in:$target to:$sender from:$validNick text:(.*)/i
    ## …then add that memorandum to a list of memoranda to be delivered now,
    ## formatted as:
    ##    addressee: <author> text
    ## (With the angle-brackets being literal.)
    ? "$sender: <$1> $2"
    ## If a memorandum in the list of all undelivered memoranda is not both
    ## from this channel and addressed to the person who just spoke, then do
    ## not add that memorandum to the list of memoranda to be delivered now.
    : ()
} split("\n", $core->value_get('memoranda', 'memos'));

## Deliver the memoranda that are to be delivered now, if any.
if (@memos) {
  actOut('MESSAGE', $target, "$sender, you have memoranda:");
  foreach my $memo (@memos) {
    actOut('MESSAGE', $target, $memo);
  }
}

# vim: tabstop=2:shiftwidth=2:expandtab:
