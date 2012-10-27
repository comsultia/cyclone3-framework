package Google::Ads::AdWords::v201206::AdExtension;
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

my %id_of :ATTR(:get<id>);
my %AdExtension__Type_of :ATTR(:get<AdExtension__Type>);

__PACKAGE__->_factory(
    [ qw(        id
        AdExtension__Type

    ) ],
    {
        'id' => \%id_of,
        'AdExtension__Type' => \%AdExtension__Type_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'AdExtension__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'id' => 'id',
        'AdExtension__Type' => 'AdExtension.Type',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::AdExtension

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
AdExtension from the namespace https://adwords.google.com/api/adwords/cm/v201206.

Base class for AdExtension objects. An AdExtension is an extension to an existing ad or metadata that will process into an extension. The class is concrete, so ad extensions can be added/removed to campaigns by referring to the id. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * id


=item * AdExtension__Type

Note: The name of this property has been altered, because it didn't match
perl's notion of variable/subroutine names. The altered name is used in
perl code only, XML output uses the original name:

 AdExtension.Type




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::AdExtension
   id =>  $some_value, # long
   AdExtension__Type =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

