package Mersenne;

use strict;
use warnings;

use HTML::TokeParser;
use HTML::Entities;
use YAML;

my $current_link;

my $dispatch =
  {
   '/p' =>
   { markdown => sub { "\n\n" } },
   'h\d' =>
   { markdown => sub { my $t=shift; $t->[1] =~ /(\d)/; ('#' x $1) . ' ' } },
   'li' =>
   { markdown => sub { '  * ' } },
   '/li' =>
   { markdown => sub { "\n" } },
   'a' =>
   { markdown => sub { my $t=shift; $current_link = $t->[2]->{href}; ($current_link) ? '[' : '' } },
   '/a' =>
   { markdown => sub { my $l = $current_link; undef $current_link; ($l) ? '](' . $l . ')' : '' } },
  };

sub new {
  my ( $class, $file ) = @_;
  die "$file not found/n" unless -f $file;
  my $p = HTML::TokeParser->new($file) ||
     die "Can't open: $!";
  $p->empty_element_tags(1);
  $p->unbroken_text(1);
  my $self = {};
  $self->{parser} = $p;
  bless $self, $class;
  return $self;
}

sub parser {
  my $self = shift;
  return $self->{parser};
}

sub transform {
  my ( $self, $format ) = @_;
  $format ||= 'markdown';
  my $p = $self->parser;
  $p->get_tag( 'title' );
  my $title = $p->get_token->[1];
  $p->get_tag('body');
  my $text;
  while ( my $tok = $p->get_token ) {
    my $type = $tok->[0];
    if ($type eq 'S' and $tok->[1] eq 'a' and $tok->[2]->{href} =~ /^\#cmnt_ref/ ) {
      last;
    } elsif ( $type eq 'T') {
      $text .= $tok->[1];
    } elsif ( $type eq 'E' or $type eq 'S' ) {
      my $tag = $tok->[1];
      $tag = '/' . $tag if $type eq 'E';
      foreach my $key ( keys %$dispatch ) {
        if ( $tag =~ m!^(:?$key)$!i ) {
          my $action = $dispatch->{$key}->{$format};
          $text .= $action->($tok);
          last;
        }
      }
    }
  }
  my $content =  decode_entities( $text ) . "\n";
  my $head = Dump { title => $title, author => 'John Doe', date => "14/07/2011", layout => 'post' };
  my $post = join("---\n", $head, $content);
  print $post;
}

1;
