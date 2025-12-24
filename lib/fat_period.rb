# frozen_string_literal: true

require 'date'
require 'active_support'

require 'fat_core/range'
require 'fat_core/string'
require 'fat_date'

# Gem Overview (extracted from README.org by gem_docs)
#
# * Introduction
# ~FatPeriod~ provides a Ruby ~Period~ class for dealing with time periods of
# days, that is ranges whose endpoints are of class ~Date~.  It's target is
# financial applications, but it serves well for any application where periods
# of time are useful.  It builds on the [[https://github.com/ddoherty03/fat_date][fat_date]] gem, which provides
# enhancements to the ~Date~ class, especially its class method ~Date.spec~ for
# interpreting a rich set of "specs" as the beginning or end of a variety of
# calendar-related periods.
#
# In addition, set operations are provided for Period, as well as methods for
# breaking a larger periods into an array of smaller periods of various 'chunk'
# sizes that correspond to calendar-related periods such as days, weeks, months,
# and so forth.
module FatPeriod
  require 'fat_period/version'
  require 'fat_period/date'
  require 'fat_period/period'
end
