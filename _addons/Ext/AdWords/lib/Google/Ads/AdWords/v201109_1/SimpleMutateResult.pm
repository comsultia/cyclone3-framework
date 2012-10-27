package Google::Ads::AdWords::v201109_1::SimpleMutateResult;
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

my %results_of :ATTR(:get<results>);
my %errors_of :ATTR(:get<errors>);

__PACKAGE__->_factory(
    [ qw(        results
        errors

    ) ],
    {
        'results' => \%results_of,
        'errors' => \%errors_of,
    },
    {
        'results' => 'Google::Ads::AdWords::v201109_1::Operand',
        'errors' => 'Google::Ads::AdWords::v201109_1::ApiError',
    },
    {

        'results' => 'results',
        'errors' => 'errors',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::SimpleMutateResult

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
SimpleMutateResult from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

The results of a simple mutation job. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * results


=item * errors




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::SimpleMutateResult
   results =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Operand
   errors =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::ApiError
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

