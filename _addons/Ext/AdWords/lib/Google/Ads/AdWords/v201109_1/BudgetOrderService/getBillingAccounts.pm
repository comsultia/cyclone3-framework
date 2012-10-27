
package Google::Ads::AdWords::v201109_1::BudgetOrderService::getBillingAccounts;
use strict;
use warnings;

{ # BLOCK to scope variables

sub get_xmlns { 'https://adwords.google.com/api/adwords/billing/v201109_1' }

__PACKAGE__->__set_name('getBillingAccounts');
__PACKAGE__->__set_nillable();
__PACKAGE__->__set_minOccurs();
__PACKAGE__->__set_maxOccurs();
__PACKAGE__->__set_ref();

use base qw(
    SOAP::WSDL::XSD::Typelib::Element
    SOAP::WSDL::XSD::Typelib::ComplexType
);

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables


__PACKAGE__->_factory(
    [ qw(
    ) ],
    {
    },
    {
    },
    {

    }
);

} # end BLOCK






} # end of BLOCK



1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::BudgetOrderService::getBillingAccounts

=head1 DESCRIPTION

Perl data type class for the XML Schema defined element
getBillingAccounts from the namespace https://adwords.google.com/api/adwords/billing/v201109_1.

Returns all the open/active BillingAccounts associated with the current manager. @return A list of {@link BillingAccount}s. @throws ApiException 





=head1 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over


=back


=head1 METHODS

=head2 new

 my $element = Google::Ads::AdWords::v201109_1::BudgetOrderService::getBillingAccounts->new($data);

Constructor. The following data structure may be passed to new():

 {
 },

=head1 AUTHOR

Generated by SOAP::WSDL

=cut

