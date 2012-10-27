package Google::Ads::AdWords::v201206::LanguageSearchParameter;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/o/v201206' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201206::SearchParameter);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %SearchParameter__Type_of :ATTR(:get<SearchParameter__Type>);
my %languages_of :ATTR(:get<languages>);

__PACKAGE__->_factory(
    [ qw(        SearchParameter__Type
        languages

    ) ],
    {
        'SearchParameter__Type' => \%SearchParameter__Type_of,
        'languages' => \%languages_of,
    },
    {
        'SearchParameter__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'languages' => 'Google::Ads::AdWords::v201206::Language',
    },
    {

        'SearchParameter__Type' => 'SearchParameter.Type',
        'languages' => 'languages',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201206::LanguageSearchParameter

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
LanguageSearchParameter from the namespace https://adwords.google.com/api/adwords/o/v201206.

A {@link SearchParameter} for both {@code PLACEMENT} and {@code KEYWORD} {@link IdeaType}s used to indicate the languages being targeted. This can be used, for example, to search for {@code KEYWORD} {@link IdeaType}s that are best for Japanese and Korean languages. <p>This search parameter can be used in bulk keyword requests through the {@link com.google.ads.api.services.targetingideas.TargetingIdeaService#getBulkKeywordIdeas(TargetingIdeaSelector)} method. It must be single-valued when used in a call to that method. <p>This element is supported by following {@link IdeaType}s: KEYWORD, PLACEMENT. <p>This element is supported by following {@link RequestType}s: IDEAS, STATS. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * languages




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201206::LanguageSearchParameter
   languages =>  $a_reference_to, # see Google::Ads::AdWords::v201206::Language
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

