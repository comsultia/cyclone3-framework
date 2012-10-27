package Google::Ads::AdWords::v201206::TargetingIdeaPage;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/o/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %totalNumEntries_of :ATTR(:get<totalNumEntries>);
my %entries_of :ATTR(:get<entries>);

__PACKAGE__->_factory(
    [ qw(        totalNumEntries
        entries

    ) ],
    {
        'totalNumEntries' => \%totalNumEntries_of,
        'entries' => \%entries_of,
    },
    {
        'totalNumEntries' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'entries' => 'Google::Ads::AdWords::v201206::TargetingIdea',
    },
    {

        'totalNumEntries' => 'totalNumEntries',
        'entries' => 'entries',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::TargetingIdeaPage

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
TargetingIdeaPage from the namespace https://adwords.google.com/api/adwords/o/v201206.

Contains a subset of {@link TargetingIdea}s from the search criteria specified by a {@link TargetingIdeaSelector}. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * totalNumEntries


=item * entries




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::TargetingIdeaPage
   totalNumEntries =>  $some_value, # int
   entries =>  $a_reference_to, # see Google::Ads::AdWords::v201206::TargetingIdea
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

