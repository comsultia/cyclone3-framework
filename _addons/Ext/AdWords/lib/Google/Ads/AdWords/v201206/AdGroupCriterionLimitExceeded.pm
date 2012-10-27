package Google::Ads::AdWords::v201206::AdGroupCriterionLimitExceeded;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201206::EntityCountLimitExceeded);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %fieldPath_of :ATTR(:get<fieldPath>);
my %trigger_of :ATTR(:get<trigger>);
my %errorString_of :ATTR(:get<errorString>);
my %ApiError__Type_of :ATTR(:get<ApiError__Type>);
my %reason_of :ATTR(:get<reason>);
my %enclosingId_of :ATTR(:get<enclosingId>);
my %limit_of :ATTR(:get<limit>);
my %limitType_of :ATTR(:get<limitType>);

__PACKAGE__->_factory(
    [ qw(        fieldPath
        trigger
        errorString
        ApiError__Type
        reason
        enclosingId
        limit
        limitType

    ) ],
    {
        'fieldPath' => \%fieldPath_of,
        'trigger' => \%trigger_of,
        'errorString' => \%errorString_of,
        'ApiError__Type' => \%ApiError__Type_of,
        'reason' => \%reason_of,
        'enclosingId' => \%enclosingId_of,
        'limit' => \%limit_of,
        'limitType' => \%limitType_of,
    },
    {
        'fieldPath' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'trigger' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'errorString' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'ApiError__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'reason' => 'Google::Ads::AdWords::v201206::EntityCountLimitExceeded::Reason',
        'enclosingId' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'limit' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
        'limitType' => 'Google::Ads::AdWords::v201206::AdGroupCriterionLimitExceeded::CriteriaLimitType',
    },
    {

        'fieldPath' => 'fieldPath',
        'trigger' => 'trigger',
        'errorString' => 'errorString',
        'ApiError__Type' => 'ApiError.Type',
        'reason' => 'reason',
        'enclosingId' => 'enclosingId',
        'limit' => 'limit',
        'limitType' => 'limitType',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::AdGroupCriterionLimitExceeded

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
AdGroupCriterionLimitExceeded from the namespace https://adwords.google.com/api/adwords/cm/v201206.

Signals that too many criteria were added to some ad group. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * limitType




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::AdGroupCriterionLimitExceeded
   limitType => $some_value, # AdGroupCriterionLimitExceeded.CriteriaLimitType
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

