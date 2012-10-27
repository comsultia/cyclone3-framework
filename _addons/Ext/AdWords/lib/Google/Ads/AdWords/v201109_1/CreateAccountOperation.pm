package Google::Ads::AdWords::v201109_1::CreateAccountOperation;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/mcm/v201109_1' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201109_1::Operation);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %operator_of :ATTR(:get<operator>);
my %Operation__Type_of :ATTR(:get<Operation__Type>);
my %operand_of :ATTR(:get<operand>);
my %descriptiveName_of :ATTR(:get<descriptiveName>);

__PACKAGE__->_factory(
    [ qw(        operator
        Operation__Type
        operand
        descriptiveName

    ) ],
    {
        'operator' => \%operator_of,
        'Operation__Type' => \%Operation__Type_of,
        'operand' => \%operand_of,
        'descriptiveName' => \%descriptiveName_of,
    },
    {
        'operator' => 'Google::Ads::AdWords::v201109_1::Operator',
        'Operation__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'operand' => 'Google::Ads::AdWords::v201109_1::Account',
        'descriptiveName' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'operator' => 'operator',
        'Operation__Type' => 'Operation.Type',
        'operand' => 'operand',
        'descriptiveName' => 'descriptiveName',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::CreateAccountOperation

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
CreateAccountOperation from the namespace https://adwords.google.com/api/adwords/mcm/v201109_1.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * operand


=item * descriptiveName




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::CreateAccountOperation
   operand =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::Account
   descriptiveName =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

