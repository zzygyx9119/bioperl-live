# $Id$
#
# BioPerl module for Bio::AnnotatableI
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::AnnotatableI - the base interface an annotatable object must implement

=head1 SYNOPSIS

    use Bio::SeqIO;
    # get an annotatable object somehow: for example, Bio::SeqI objects
    # are annotatable
    my $seqio = Bio::SeqIO->new(-fh => \*STDIN, -format => 'genbank);
    while (my $seq = $seqio->next_seq()) {
        # $seq is-a Bio::AnnotatableI, hence:
        my $ann_coll = $seq->annotation();
        # $ann_coll is-a Bio::AnnotationCollectionI, hence:
        my @all_anns = $ann_coll->get_Annotations();
        # do something with the annotation objects
    }

=head1 DESCRIPTION

This is the base interface that all annotatable objects must implement. A good
example is Bio::Seq which is an AnnotableI object; if you are a little confused
about what this module does, start a Bio::Seq.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR

 Hilmar Lapp E<lt>hlapp@gmx.netE<gt>
 Allen Day E<lt>allenday@ucla.eduE<gt>

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::AnnotatableI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

use Bio::Annotation::Comment;
use Bio::Annotation::DBLink;
#use Bio::Annotation::OntologyTerm;
use Bio::Annotation::Reference;
use Bio::Annotation::SimpleValue;

our %tagclass = (
  comment        => 'Bio::Annotation::Comment',
  dblink         => 'Bio::Annotation::DBLink',
  description    => 'Bio::Annotation::SimpleValue',
  gene_name      => 'Bio::Annotation::SimpleValue',
  ontology_term  => 'Bio::Annotation::OntologyTerm',
  reference      => 'Bio::Annotation::Reference',

  __DEFAULT__    => 'Bio::Annotation::SimpleValue',
);

our %tag2text = (
  'Bio::Annotation::Comment'        => 'text',
  'Bio::Annotation::DBLink'         => 'primary_id',
  'Bio::Annotation::SimpleValue'    => 'value',
  'Bio::Annotation::SimpleValue'    => 'value',
  'Bio::Annotation::OntologyTerm'   => 'name',
  'Bio::Annotation::Reference'      => 'title',

  __DEFAULT__    => 'value',

);

@ISA = qw( Bio::Root::RootI );

=head2 annotation

 Title   : annotation
 Usage   : $obj->annotation($newval)
 Function: Get the annotation collection (see L<Bio::AnnotationCollectionI>)
           for this annotatable object.
 Example : 
 Returns : a Bio::AnnotationCollectionI implementing object, or undef
 Args    : on set, new value (a Bio::AnnotationCollectionI
           implementing object, optional) (an implementation may not
           support changing the annotation collection)


=cut

sub annotation{
  shift->throw_not_implemented();
}


=head1 "*_tag_*" METHODS

The methods below allow mapping of the old "get_tag_values()"-style
annotation access to Bio::AnnotationCollectionI.  These need not be
implemented in a Bio::AnnotationCollectionI compliant class, as they
are built on top of the methods (see above L</ACCESSOR METHODS>).

 B<DEPRECATED>: DO NOT USE THESE FOR FUTURE DEVELOPMENT.

=cut

=head2 has_tag()

 Usage   : $count = $obj->has_tag($tag)
 Function: returns the number of annotations corresponding to $tag
 Returns : an integer
 Args    : tag name
 Note    : B<DEPRECATED>: this method is essentially scalar(L</get_Annotations()>).

=cut

sub has_tag {
  my ($self,$tag) = @_;
  #uncomment in 1.6
  #$self->deprecated('has_tag() is deprecated.  use get_Annotations()');

  return scalar($self->annotation->get_Annotations($tag));
}

=head2 add_tag_value()

 Usage   : See L</add_Annotation()>.
 Function:
 Returns : 
 Args    : B<DEPRECATED>: this method is essentially L</add_Annotation()>.

=cut

sub add_tag_value {
  my ($self,$tag,@vals) = @_;

  #uncomment in 1.6
  #$self->deprecated('add_tag_value() is deprecated.  use add_Annotation()');

  foreach my $val (@vals){
    my $class = $tagclass{$tag}   || $tagclass{__DEFAULT__};
    my $slot  = $tag2text{$class};

    my $a = $class->new();
    $a->$slot($val);

    $self->annotation->add_Annotation($tag,$a);
  }

  return 1;
  #return $self->annotation->add_Annotation(@args);
}

=head2 get_tag_values()

 Usage   : @annotations = $obj->get_tag_values($tag)
 Function: returns annotations corresponding to $tag
 Returns : a list of Bio::AnnotationI objects
 Args    : tag name
 Note    : B<DEPRECATED>: this method is essentially L</get_Annotations()>.

=cut

sub get_tag_values {
  my ($self,$tag) = @_;

  #uncomment in 1.6
  #$self->deprecated('get_tag_values() is deprecated.  use get_Annotations()');

  if(!$tagclass{$tag} && $self->annotation->get_Annotations($tag)){
    #new tag, haven't seen it yet but it exists.  add to registry
    my($proto) = $self->annotation->get_Annotations($tag);
    $tagclass{$tag} = ref($proto);
  }

  my $slot  = $tag2text{ $tagclass{$tag} || $tagclass{__DEFAULT__} };

  return map { $_->$slot } $self->annotation->get_Annotations($tag);
}

=head2 get_tagset_values()

 Usage   : @annotations = $obj->get_tagset_values($tag1,$tag2)
 Function: returns annotations corresponding to a list of tags.
           this is a convenience method equivalent to multiple calls
           to L</get_tag_values> with each tag in the list.
 Returns : a list of Bio::AnnotationI objects.
 Args    : a list of tag names
 Note    : B<DEPRECATED>: this method is essentially multiple calls to
           L</get_Annotations()>.

=cut

sub get_tagset_values {
  my ($self,@tags) = @_;

  #uncomment in 1.6
  #$self->deprecated('get_tagset_values() is deprecated.  use get_Annotations()');

  my @r = ();
  foreach my $tag (@tags){
    my $slot  = $tag2text{ $tagclass{$tag} || $tagclass{__DEFAULT__} };
    push @r, map { $_->$slot } $self->annotation->get_Annotations($tag);
  }
  return @r;
}

=head2 get_all_tags()

 Usage   : @tags = $obj->get_all_tags()
 Function: returns a list of annotation tag names.
 Returns : a list of tag names
 Args    : none
 Note    : B<DEPRECATED>: use L</get_all_annotation_keys()>.

=cut

sub get_all_tags {
  my ($self,@args) = @_;

  #uncomment in 1.6
  #$self->deprecated('get_all_tags() is deprecated.  use get_all_annotation_keys()');

  return $self->annotation->get_all_annotation_keys(@args);
}

=head2 remove_tag()

 Usage   : See L</remove_Annotations()>.
 Function:
 Returns : 
 Args    : B<DEPRECATED>: use L</remove_Annotations()>.
 Note    : Contrary to what the name suggests, this method removes
           B<all> annotations corresponding to $tag, not just a
           single anntoation.

=cut

sub remove_tag {
  my ($self,@args) = @_;

  #uncomment in 1.6
  #$self->deprecated('remove_tag() is deprecated.  use remove_Annotations()');

  return $self->annotation->remove_Annotations(@args);
}


1;
