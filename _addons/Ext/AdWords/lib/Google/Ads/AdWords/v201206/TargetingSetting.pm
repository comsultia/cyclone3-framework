package Google::Ads::AdWords::v201206::TargetingSetting;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201206::Setting);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Setting__Type_of :ATTR(:get<Setting__Type>);
my %details_of :ATTR(:get<details>);

__PACKAGE__->_factory(
    [ qw(        Setting__Type
        details

    ) ],
    {
        'Setting__Type' => \%Setting__Type_of,
        'details' => \%details_of,
    },
    {
        'Setting__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'details' => 'Google::Ads::AdWords::v201206::TargetingSettingDetail',
    },
    {

        'Setting__Type' => 'Setting.Type',
        'details' => 'details',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::TargetingSetting

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
TargetingSetting from the namespace https://adwords.google.com/api/adwords/cm/v201206.

Setting for targeting related features. This is applicable at Campaign and AdGroup level. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * details




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::TargetingSetting
   details =>  $a_reference_to, # see Google::Ads::AdWords::v201206::TargetingSettingDetail
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

