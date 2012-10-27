package Google::Ads::AdWords::v201109_1::Polygon;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109_1' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201109_1::Criterion);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %type_of :ATTR(:get<type>);
my %Criterion__Type_of :ATTR(:get<Criterion__Type>);
my %vertices_of :ATTR(:get<vertices>);

__PACKAGE__->_factory(
    [ qw(        id
        type
        Criterion__Type
        vertices

    ) ],
    {
        'id' => \%id_of,
        'type' => \%type_of,
        'Criterion__Type' => \%Criterion__Type_of,
        'vertices' => \%vertices_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'type' => 'Google::Ads::AdWords::v201109_1::Criterion::Type',
        'Criterion__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'vertices' => 'Google::Ads::AdWords::v201109_1::GeoPoint',
    },
    {

        'id' => 'id',
        'type' => 'type',
        'Criterion__Type' => 'Criterion.Type',
        'vertices' => 'vertices',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::Polygon

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Polygon from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

Represents a Polygon Criterion. A polygon is described by a list of at least three points, where each point is a (<var>latitude</var>, <var>longitude</var>) ordered pair. No point can be more than 400km from the center of the polygon. The points are specified in microdegrees, the precison for the value is 1 second of angle which is equal to 277 microdegrees.<p> <p>Please note that Polygons are deprecated. This means that Polygon targets cannot be added through the API, though existing targets can be retrieved and deleted. <p> 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * vertices




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::Polygon
   vertices =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::GeoPoint
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

