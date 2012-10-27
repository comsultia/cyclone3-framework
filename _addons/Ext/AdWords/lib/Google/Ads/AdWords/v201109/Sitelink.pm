package Google::Ads::AdWords::v201109::Sitelink;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %displayText_of :ATTR(:get<displayText>);
my %destinationUrl_of :ATTR(:get<destinationUrl>);

__PACKAGE__->_factory(
    [ qw(        displayText
        destinationUrl

    ) ],
    {
        'displayText' => \%displayText_of,
        'destinationUrl' => \%destinationUrl_of,
    },
    {
        'displayText' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'destinationUrl' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'displayText' => 'displayText',
        'destinationUrl' => 'destinationUrl',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::Sitelink

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Sitelink from the namespace https://adwords.google.com/api/adwords/cm/v201109.

Class to represent a single sitelink 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * displayText


=item * destinationUrl




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::Sitelink
   displayText =>  $some_value, # string
   destinationUrl =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

