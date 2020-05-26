package TOM::Logger;
# constants for logger
require Exporter;
our @ISA    = qw{Exporter};
our @EXPORT = qw{
	LOG_INFO
	LOG_INFO_FORCE
	LOG_INFO_FORCE_NODEPTH
	
	LOG_WARNING
	LOG_WARNING_FORCE
	LOG_WARNING_FORCE_NODEPTH
	
	LOG_ERROR
	LOG_ERROR_FORCE
	LOG_ERROR_FORCE_NODEPTH
};

use constant LOG_INFO => 0;
use constant LOG_INFO_FORCE => 2;
use constant LOG_INFO_FORCE_NODEPTH => 3;

use constant LOG_WARNING  => 5;
use constant LOG_WARNING_FORCE  => 6;
use constant LOG_WARNING_FORCE_NODEPTH  => 7;

use constant LOG_ERROR  => 1;
use constant LOG_ERROR_FORCE  => 1;
use constant LOG_ERROR_FORCE_NODEPTH => 4;


# 2 - INFO
# 4 - WARNING
# 8 - ERROR
# 16 - FORCE
# 32 - NODEPTH
# 64
# 128

1;
