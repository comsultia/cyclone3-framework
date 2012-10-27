package Google::Ads::AdWords::v201206::ManagedCustomerLink;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/mcm/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %managerCustomerId_of :ATTR(:get<managerCustomerId>);
my %clientCustomerId_of :ATTR(:get<clientCustomerId>);

__PACKAGE__->_factory(
    [ qw(        managerCustomerId
        clientCustomerId

    ) ],
    {
        'managerCustomerId' => \%managerCustomerId_of,
        'clientCustomerId' => \%clientCustomerId_of,
    },
    {
        'managerCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'clientCustomerId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
    },
    {

        'managerCustomerId' => 'managerCustomerId',
        'clientCustomerId' => 'clientCustomerId',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::ManagedCustomerLink

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ManagedCustomerLink from the namespace https://adwords.google.com/api/adwords/mcm/v201206.

Represents an AdWords manager-client link. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * managerCustomerId


=item * clientCustomerId




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::ManagedCustomerLink
   managerCustomerId =>  $some_value, # long
   clientCustomerId =>  $some_value, # long
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

