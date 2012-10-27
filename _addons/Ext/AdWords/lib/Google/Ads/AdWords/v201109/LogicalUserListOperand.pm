package Google::Ads::AdWords::v201109::LogicalUserListOperand;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'https://adwords.google.com/api/adwords/cm/v201109' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %UserInterest_of :ATTR(:get<UserInterest>);
my %UserList_of :ATTR(:get<UserList>);

__PACKAGE__->_factory(
    [ qw(        UserInterest
        UserList

    ) ],
    {
        'UserInterest' => \%UserInterest_of,
        'UserList' => \%UserList_of,
    },
    {
        'UserInterest' => 'Google::Ads::AdWords::v201109::UserInterest',
        'UserList' => 'Google::Ads::AdWords::v201109::UserList',
    },
    {

        'UserInterest' => 'UserInterest',
        'UserList' => 'UserList',
    }
);

} # end BLOCK







1;


=pod

=head1 NAME

Google::Ads::AdWords::v201109::LogicalUserListOperand

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
LogicalUserListOperand from the namespace https://adwords.google.com/api/adwords/cm/v201109.

An interface for a logical user list operand. A logical user list is a combination of logical rules. Each rule is defined as a logical operator and a list of operands. Those operands can be of type UserList or UserInterest. 




=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * UserInterest


=item * UserList




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # Google::Ads::AdWords::v201109::LogicalUserListOperand
   # One of the following elements.
   # No occurance checks yet, so be sure to pass just one...
   UserInterest =>  $a_reference_to, # see Google::Ads::AdWords::v201109::UserInterest
   UserList =>  $a_reference_to, # see Google::Ads::AdWords::v201109::UserList
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

