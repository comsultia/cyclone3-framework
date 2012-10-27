package Google::Ads::AdWords::v201109_1::AdGroupExperimentData;
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

my %experimentId_of :ATTR(:get<experimentId>);
my %experimentDeltaStatus_of :ATTR(:get<experimentDeltaStatus>);
my %experimentDataStatus_of :ATTR(:get<experimentDataStatus>);
my %experimentBidMultipliers_of :ATTR(:get<experimentBidMultipliers>);

__PACKAGE__->_factory(
    [ qw(        experimentId
        experimentDeltaStatus
        experimentDataStatus
        experimentBidMultipliers

    ) ],
    {
        'experimentId' => \%experimentId_of,
        'experimentDeltaStatus' => \%experimentDeltaStatus_of,
        'experimentDataStatus' => \%experimentDataStatus_of,
        'experimentBidMultipliers' => \%experimentBidMultipliers_of,
    },
    {
        'experimentId' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'experimentDeltaStatus' => 'Google::Ads::AdWords::v201109_1::ExperimentDeltaStatus',
        'experimentDataStatus' => 'Google::Ads::AdWords::v201109_1::ExperimentDataStatus',
        'experimentBidMultipliers' => 'Google::Ads::AdWords::v201109_1::AdGroupExperimentBidMultipliers',
    },
    {

        'experimentId' => 'experimentId',
        'experimentDeltaStatus' => 'experimentDeltaStatus',
        'experimentDataStatus' => 'experimentDataStatus',
        'experimentBidMultipliers' => 'experimentBidMultipliers',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::AdGroupExperimentData

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
AdGroupExperimentData from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

Data associated with an advertiser experiment for this adgroup. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * experimentId


=item * experimentDeltaStatus


=item * experimentDataStatus


=item * experimentBidMultipliers




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::AdGroupExperimentData
   experimentId =>  $some_value, # long
   experimentDeltaStatus => $some_value, # ExperimentDeltaStatus
   experimentDataStatus => $some_value, # ExperimentDataStatus
   experimentBidMultipliers =>  $a_reference_to, # see Google::Ads::AdWords::v201109_1::AdGroupExperimentBidMultipliers
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

