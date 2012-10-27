package Google::Ads::AdWords::v201109_1::ExternalRemarketingUserList;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109_1' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}


use base qw(Google::Ads::AdWords::v201109_1::UserList);
# Variety: sequence
use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %id_of :ATTR(:get<id>);
my %isReadOnly_of :ATTR(:get<isReadOnly>);
my %name_of :ATTR(:get<name>);
my %description_of :ATTR(:get<description>);
my %status_of :ATTR(:get<status>);
my %accessReason_of :ATTR(:get<accessReason>);
my %accountUserListStatus_of :ATTR(:get<accountUserListStatus>);
my %membershipLifeSpan_of :ATTR(:get<membershipLifeSpan>);
my %size_of :ATTR(:get<size>);
my %sizeRange_of :ATTR(:get<sizeRange>);
my %type_of :ATTR(:get<type>);
my %UserList__Type_of :ATTR(:get<UserList__Type>);

__PACKAGE__->_factory(
    [ qw(        id
        isReadOnly
        name
        description
        status
        accessReason
        accountUserListStatus
        membershipLifeSpan
        size
        sizeRange
        type
        UserList__Type

    ) ],
    {
        'id' => \%id_of,
        'isReadOnly' => \%isReadOnly_of,
        'name' => \%name_of,
        'description' => \%description_of,
        'status' => \%status_of,
        'accessReason' => \%accessReason_of,
        'accountUserListStatus' => \%accountUserListStatus_of,
        'membershipLifeSpan' => \%membershipLifeSpan_of,
        'size' => \%size_of,
        'sizeRange' => \%sizeRange_of,
        'type' => \%type_of,
        'UserList__Type' => \%UserList__Type_of,
    },
    {
        'id' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'isReadOnly' => 'SOAP::WSDL::XSD::Typelib::Builtin::boolean',
        'name' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'description' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
        'status' => 'Google::Ads::AdWords::v201109_1::UserListMembershipStatus',
        'accessReason' => 'Google::Ads::AdWords::v201109_1::AccessReason',
        'accountUserListStatus' => 'Google::Ads::AdWords::v201109_1::AccountUserListStatus',
        'membershipLifeSpan' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'size' => 'SOAP::WSDL::XSD::Typelib::Builtin::long',
        'sizeRange' => 'Google::Ads::AdWords::v201109_1::SizeRange',
        'type' => 'Google::Ads::AdWords::v201109_1::UserList::Type',
        'UserList__Type' => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    },
    {

        'id' => 'id',
        'isReadOnly' => 'isReadOnly',
        'name' => 'name',
        'description' => 'description',
        'status' => 'status',
        'accessReason' => 'accessReason',
        'accountUserListStatus' => 'accountUserListStatus',
        'membershipLifeSpan' => 'membershipLifeSpan',
        'size' => 'size',
        'sizeRange' => 'sizeRange',
        'type' => 'type',
        'UserList__Type' => 'UserList.Type',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109_1::ExternalRemarketingUserList

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
ExternalRemarketingUserList from the namespace https://adwords.google.com/api/adwords/cm/v201109_1.

User lists created in the DoubleClick platform that are mapped from DoubleClick to AdWords. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over



=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109_1::ExternalRemarketingUserList
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

