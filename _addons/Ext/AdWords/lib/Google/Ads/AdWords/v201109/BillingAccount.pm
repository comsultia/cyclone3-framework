package Google::Ads::AdWords::v201109::BillingAccount;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/billing/v201109' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %name_of :ATTR(:get<name>);
my %currencyCode_of :ATTR(:get<currencyCode>);

__PACKAGE__->_factory(
    [ qw(        id
        name
        currencyCode

    ) ],
    {
        'id' => \%id_of,
        'name' => \%name_of,
        'currencyCode' => \%currencyCode_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'currencyCode' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'id' => 'id',
        'name' => 'name',
        'currencyCode' => 'currencyCode',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::BillingAccount

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
BillingAccount from the namespace https://adwords.google.com/api/adwords/billing/v201109.

Represents an BillingAccount. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * id


=item * name


=item * currencyCode




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::BillingAccount
   id =>  $some_value, # string
   name =>  $some_value, # string
   currencyCode =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

