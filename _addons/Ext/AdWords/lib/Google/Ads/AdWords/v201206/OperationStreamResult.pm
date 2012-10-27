package Google::Ads::AdWords::v201206::OperationStreamResult;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %operationResults_of :ATTR(:get<operationResults>);

__PACKAGE__->_factory(
    [ qw(        operationResults

    ) ],
    {
        'operationResults' => \%operationResults_of,
    },
    {
        'operationResults' => 'Google::Ads::AdWords::v201206::OperationResult',
    },
    {

        'operationResults' => 'operationResults',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::OperationStreamResult

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
OperationStreamResult from the namespace https://adwords.google.com/api/adwords/cm/v201206.

The result of processing an {@link OperationStream}. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * operationResults




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::OperationStreamResult
   operationResults =>  $a_reference_to, # see Google::Ads::AdWords::v201206::OperationResult
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

