package Google::Ads::AdWords::v201206::MonthlySearchVolumeAttribute;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/o/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201206::Attribute);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Attribute__Type_of :ATTR(:get<Attribute__Type>);
my %value_of :ATTR(:get<value>);

__PACKAGE__->_factory(
    [ qw(        Attribute__Type
        value

    ) ],
    {
        'Attribute__Type' => \%Attribute__Type_of,
        'value' => \%value_of,
    },
    {
        'Attribute__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'value' => 'Google::Ads::AdWords::v201206::MonthlySearchVolume',
    },
    {

        'Attribute__Type' => 'Attribute.Type',
        'value' => 'value',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::MonthlySearchVolumeAttribute

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
MonthlySearchVolumeAttribute from the namespace https://adwords.google.com/api/adwords/o/v201206.

{@link Attribute} type that contains a list of {@link MonthlySearchVolume} values. The list contains the past 12 {@link MonthlySearchVolume}s (excluding the current month). The first item is the data for the most recent month and the last item is the data for the oldest month. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * value




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::MonthlySearchVolumeAttribute
   value =>  $a_reference_to, # see Google::Ads::AdWords::v201206::MonthlySearchVolume
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

