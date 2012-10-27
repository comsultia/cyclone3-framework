package Google::Ads::AdWords::v201109_1::AdGroupCriterionExperimentBidMultiplier;
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

my %AdGroupCriterionExperimentBidMultiplier__Type_of :ATTR(:get<AdGroupCriterionExperimentBidMultiplier__Type>);

__PACKAGE__->_factory(
    [ qw(        AdGroupCriterionExperimentBidMultiplier__Type

    ) ],
    {
        'AdGroupCriterionExperimentBidMultiplier__Type' => \%AdGroupCriterionExperimentBidMultiplier__Type_of,
    },
    {
        'AdGroupCriterionExperimentBidMultiplier__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'AdGroupCriterionExperimentBidMultiplier__Type' => 'AdGroupCriterionExperimentBidMultiplier.Type',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::AdGroupCriterionExperimentBidMultiplier

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
AdGroupCriterionExperimentBidMultiplier from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

Bid multiplier used to modify the bid of a criterion while running an experiment. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * AdGroupCriterionExperimentBidMultiplier__Type

Note: The name of this property has been altered, because it didn't match
perl's notion of variable/subroutine names. The altered name is used in
perl code only, XML output uses the original name:

 AdGroupCriterionExperimentBidMultiplier.Type




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::AdGroupCriterionExperimentBidMultiplier
   AdGroupCriterionExperimentBidMultiplier__Type =>  $some_value, # string
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

