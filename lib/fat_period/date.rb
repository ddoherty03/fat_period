require 'date'

module FatPeriod
  # An extension of Date for methods useful with respect to FatPeriod::Periods.
  module Date
    # Return the Period of the given chunk size that contains this Date. Chunk
    # can be one of :year, :half, :quarter, :bimonth, :month, :semimonth,
    # :biweek, :week, or :day.
    #
    # @example
    #   date = Date.parse('2015-06-13')
    #   date.expand_to_period(:week)      #=> Period(2015-06-08..2015-06-14)
    #   date.expand_to_period(:semimonth) #=> Period(2015-06-01..2015-06-15)
    #   date.expand_to_period(:quarter)   #=> Period(2015-04-01..2015-06-30)
    #
    # @param chunk [Symbol] one of :year, :half, :quarter, :bimonth, :month,
    #    :semimonth, :biweek, :week, or :day
    # @return [Period] Period of size `chunk` containing self
    def expand_to_period(chunk)
      require 'fat_period'
      Period.new(beginning_of_chunk(chunk), end_of_chunk(chunk))
    end
  end
end

# An extension Date for methods useful with respect to FatPeriod::Periods.
class Date
  include FatPeriod::Date
  # @!parse include FatPeriod::Date
  # @!parse extend FatPeriod::Date::ClassMethods
end
