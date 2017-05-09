require 'date'

module FatPeriod
  module Date
    def expand_to_period(sym)
      require 'fat_period'
      Period.new(beginning_of_chunk(sym), end_of_chunk(sym))
    end
  end
end

Date.include(FatPeriod::Date)
