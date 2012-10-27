package Google::Ads::AdWords::v201206::AdParamPage;
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

my %entries_of :ATTR(:get<entries>);
my %totalNumEntries_of :ATTR(:get<totalNumEntries>);

__PACKAGE__->_factory(
    [ qw(        entries
        totalNumEntries

    ) ],
    {
        'entries' => \%entries_of,
        'totalNumEntries' => \%totalNumEntries_of,
    },
    {
        'entries' => 'Google::Ads::AdWords::v201206::AdParam',
        'totalNumEntries' => 'SOAP::WSDL::XSD::Typelib::Builtin::int',
    },
    {

        'entries' => 'entries',
        'totalNumEntries' => 'totalNumEntries',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::AdParamPage

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
AdParamPage from the namespace https://adwords.google.com/api/adwords/cm/v201206.

Represents a page of AdParams returned by the {@link AdParamService}. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * entries


=item * totalNumEntries




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::AdParamPage
   entries =>  $a_reference_to, # see Google::Ads::AdWords::v201206::AdParam
   totalNumEntries =>  $some_value, # int
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

