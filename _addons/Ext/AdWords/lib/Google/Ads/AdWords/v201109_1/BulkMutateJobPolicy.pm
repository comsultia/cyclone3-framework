package Google::Ads::AdWords::v201109_1::BulkMutateJobPolicy;
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

my %prerequisiteJobIds_of :ATTR(:get<prerequisiteJobIds>);

__PACKAGE__->_factory(
    [ qw(        prerequisiteJobIds

    ) ],
    {
        'prerequisiteJobIds' => \%prerequisiteJobIds_of,
    },
    {
        'prerequisiteJobIds' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
    },
    {

        'prerequisiteJobIds' => 'prerequisiteJobIds',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::BulkMutateJobPolicy

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
BulkMutateJobPolicy from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

A basic job policy. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * prerequisiteJobIds




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::BulkMutateJobPolicy
   prerequisiteJobIds =>  $some_value, # long
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

