package Google::Ads::AdWords::v201109_1::LocationCriterion;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109_1' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %location_of :ATTR(:get<location>);
my %canonicalName_of :ATTR(:get<canonicalName>);
my %reach_of :ATTR(:get<reach>);
my %locale_of :ATTR(:get<locale>);
my %searchTerm_of :ATTR(:get<searchTerm>);

__PACKAGE__->_factory(
    [ qw(        location
        canonicalName
        reach
        locale
        searchTerm

    ) ],
    {
        'location' => \%location_of,
        'canonicalName' => \%canonicalName_of,
        'reach' => \%reach_of,
        'locale' => \%locale_of,
        'searchTerm' => \%searchTerm_of,
    },
    {
        'location' => 'Google::Ads::AdWords::v201109_1::Location',
        'canonicalName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'reach' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'locale' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'searchTerm' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'location' => 'location',
        'canonicalName' => 'canonicalName',
        'reach' => 'reach',
        'locale' => 'locale',
        'searchTerm' => 'searchTerm',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::LocationCriterion

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
LocationCriterion from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

Represents data that encapsulates a location criterion. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * location


=item * canonicalName


=item * reach


=item * locale


=item * searchTerm




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::LocationCriterion
   location =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Location
   canonicalName =>  $some_value, # string
   reach =>  $some_value, # long
   locale =>  $some_value, # string
   searchTerm =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

