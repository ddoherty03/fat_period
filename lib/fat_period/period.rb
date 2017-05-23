# -*- coding: utf-8 -*-

require 'fat_core/date'
require 'fat_core/range'
require 'fat_core/string'

class Period
  # Return the first Date of the Period
  #
  # @return [Date]
  attr_reader :first

  # Return the last Date of the Period
  #
  # @return [Date]
  attr_reader :last

  # @group Construction
  #
  # Return a new Period from the Date `first` to the Date `last` inclusive. Both
  # parameters can be either a Date object or a String that can be parsed as a
  # valid Date with `Date.parse`.
  #
  # @param first [Date, String] first date of Period
  # @param last [Date, String] last date of Period
  # @raise [ArgumentError] if string is not parseable as a Date or
  # @raise [ArgumentError] if first date is later than last date
  # @return [Period]
  def initialize(first, last)
    if first.is_a?(Date)
      @first = first
    elsif first.respond_to?(:to_s)
      begin
        @first = Date.parse(first.to_s)
      rescue ArgumentError => ex
        if ex.message =~ /invalid date/
          raise ArgumentError, "you gave an invalid date '#{first}'"
        else
          raise
        end
      end
    else
      raise ArgumentError, 'use Date or String to initialize Period'
    end

    if last.is_a?(Date)
      @last = last
    elsif last.respond_to?(:to_s)
      begin
        @last = Date.parse(last.to_s)
      rescue ArgumentError => ex
        if ex.message =~ /invalid date/
          raise ArgumentError, "you gave an invalid date '#{last}'"
        else
          raise
        end
      end
    else
      raise ArgumentError, 'use Date or String to initialize Period'
    end
    if @first > @last
      raise ArgumentError, "Period's first date is later than its last date"
    end
  end

  # These need to come after initialize is defined

  # Period from commercial beginning of time to today
  TO_DATE = Period.new(Date::BOT, Date.current)

  # Period from commercial beginning of time to commercial end of time.
  FOREVER = Period.new(Date::BOT, Date::EOT)

  # @group Conversion

  # Convert this Period to a Range.
  #
  # @return [Range]
  def to_range
    (first..last)
  end

  # Return a string representing this Period using compact format for years,
  # halves, quarters, or months that represent a whole period; otherwise, just
  # format the period as 'YYYY-MM-DD to YYYY-MM-DD'.
  #
  # @example
  #   Period.new('2016-01-01', '2016-03-31') #=> '2016-1Q'
  #   Period.new('2016-01-01', '2016-12-31') #=> '2016'
  #   Period.new('2016-01-01', '2016-11-30') #=> '2016-01-01 to 2016-11-30'
  #
  # @return [String] concise representation of Period
  def to_s
    if first.beginning_of_year? && last.end_of_year? && first.year == last.year
      first.year.to_s
    elsif first.beginning_of_half? &&
          last.end_of_half? &&
          first.year == last.year &&
          first.half == last.half
      "#{first.year}-#{first.half}H"
    elsif first.beginning_of_quarter? &&
          last.end_of_quarter? &&
          first.year == last.year &&
          first.quarter == last.quarter
      "#{first.year}-#{first.quarter}Q"
    elsif first.beginning_of_month? &&
          last.end_of_month? &&
          first.year == last.year &&
          first.month == last.month
      "#{first.year}-%02d" % first.month
    else
      "#{first.iso} to #{last.iso}"
    end
  end

  # A concise way to print out Periods for inspection as
  # 'Period(YYYY-MM-DD..YYYY-MM-DD)'.
  #
  # @return [String]
  def inspect
    "Period(#{first.iso}..#{last.iso})"
  end

  # Allow erb documents can directly interpolate ranges
  def tex_quote
    "#{first.iso}--#{last.iso}"
  end


  include Comparable

  # @group Comparison
  #
  # Comparable base: periods are compared by first, then by last and are equal
  # only if their first and last dates are equal. Sorting will be by first date,
  # then last, so periods starting on the same date will sort from smallest to
  # largest.
  #
  # @param other [Period] @return [Integer] -1 if self < other; 0 if self ==
  # other; 1 if self > other
  def <=>(other)
    return nil unless other.is_a?(Period)
    [first, last] <=> [other.first, other.last]
  end

  # Comparable does not include this.
  def !=(other)
    !(self == other)
  end

  # Return whether this Period contains the given date.
  #
  # @param date [Date] date to test
  # @return [Boolean] is the given date within this Period?
  def contains?(date)
    date = date.to_date if date.respond_to?(:to_date)
    raise ArgumentError, 'argument must be a Date' unless date.is_a?(Date)
    to_range.cover?(date)
  end
  alias === contains?

  include Enumerable

  # @group Enumeration

  # Yield each day in this Period.
  def each
    d = first
    while d <= last
      yield d
      d += 1.day
    end
  end

  # Return an Array of the days in the Period that are trading days on the NYSE.
  #
  # @return [Array<Date>] trading days in this period
  def trading_days
    select(&:nyse_workday?)
  end

  # @group Size

  # Return the number of days in the period
  def size
    (last - first + 1).to_i
  end
  alias length size
  alias days size

  # Return the fractional number of months in the period.  By default, use the
  # average number of days in a month, but allow the user to override the
  # assumption with a parameter.
  def months(days_in_month = 30.436875)
    (days / days_in_month).to_f
  end

  # Return the fractional number of years in the period.  By default, use the
  # average number of days in a year, but allow the user to override the
  # assumption with a parameter.
  def years(days_in_year = 365.2425)
    (days / days_in_year).to_f
  end

  # @group Parsing
  #
  # Return a period based on two date specs passed as strings (see
  # `FatCore::Date.parse_spec`), a 'from' and a 'to' spec. The returned period
  # begins on the first day of the period given as the `from` spec and ends on
  # the last day given as the `to` spec. If the to spec is not given or is nil,
  # the from spec is used for both the from- and to-spec.
  #
  # @example
  #   Period.parse('2014-11').inspect                  #=> Period('2014-11-01..2014-11-30')
  #   Period.parse('2014-11', '2015-3Q').inspect       #=> Period('2014-11-01..2015-09-30')
  #   # Assuming this executes in December, 2014
  #   Period.parse('last_month', 'this_month').inspect #=> Period('2014-11-01..2014-12-31')
  #
  # @param from [String] spec ala FatCore::Date.parse_spec
  # @param to [String] spec ala FatCore::Date.parse_spec
  # @return [Period] from beginning of `from` to end of `to`
  def self.parse(from, to = nil)
    raise ArgumentError, 'Period.parse missing argument' unless from
    to ||= from
    first = Date.parse_spec(from, :from)
    second = Date.parse_spec(to, :to)
    Period.new(first, second) if first && second
  end

  # Return a period as in `Period.parse` from a String phrase in which the from
  # spec is introduced with 'from' and, optionally, the to spec is introduced
  # with 'to'.  A phrase with only a to spec is treated the same as one with
  # only a from spec.  If neither 'from' nor 'to' appear in phrase, treat the
  # whole string as a from spec.
  #
  # @example
  #   Period.parse_phrase('from 2014-11 to 2015-3Q') #=> Period('2014-11-01..2015-09-30')
  #   Period.parse_phrase('from 2014-11')            #=> Period('2014-11-01..2014-11-30')
  #   Period.parse_phrase('from 2015-3Q')            #=> Period('2015-09-01..2015-12-31')
  #   Period.parse_phrase('to 2015-3Q')              #=> Period('2015-09-01..2015-12-31')
  #   Period.parse_phrase('2015-3Q')                 #=> Period('2015-09-01..2015-12-31')
  #
  # @param phrase [String] with 'from <spec> to <spec>'
  # @return [Period] translated from phrase
  def self.parse_phrase(phrase)
    phrase = phrase.clean
    if phrase =~ /\Afrom (.*) to (.*)\z/
      from_phrase = $1
      to_phrase = $2
    elsif phrase =~ /\Afrom (.*)\z/
      from_phrase = $1
      to_phrase = nil
    elsif phrase =~ /\Ato (.*)\z/
      from_phrase = $1
    else
      from_phrase = phrase
      to_phrase = nil
    end
    parse(from_phrase, to_phrase)
  end

  # Possibly useful class method to take an array of periods and join all the
  # contiguous ones, then return an array of the disjoint periods not
  # contiguous to one another.  An array of periods with no gaps should return
  # an array of only one period spanning all the given periods.
  #
  # Return an array of periods that represent the concatenation of all
  # adjacent periods in the given periods.
  # def self.meld_periods(*periods)
  #   melded_periods = []
  #   while (this_period = periods.pop)
  #     melded_periods.each do |mp|
  #       if mp.overlaps?(this_period)
  #         melded_periods.delete(mp)
  #         melded_periods << mp.union(this_period)
  #         break
  #       elsif mp.contiguous?(this_period)
  #         melded_periods.delete(mp)
  #         melded_periods << mp.join(this_period)
  #         break
  #       end
  #     end
  #   end
  #   melded_periods
  # end
  #
  # @group Chunking
  #
  # An Array of the valid Symbols for calendar chunks plus the Symbol :irregular
  # for other periods.
  #
  # @return [Array<Symbol>]
  def self.chunk_syms
    [:day, :week, :biweek, :semimonth, :month, :bimonth,
     :quarter, :half, :year, :irregular]
  end

  # returns the chunk sym represented by the period
  def chunk_sym
    if first.beginning_of_year? && last.end_of_year? &&
       (365..366) === last - first + 1
      :year
    elsif first.beginning_of_half? && last.end_of_half? &&
          (180..183) === last - first + 1
      :half
    elsif first.beginning_of_quarter? && last.end_of_quarter? &&
          (90..92) === last - first + 1
      :quarter
    elsif first.beginning_of_bimonth? && last.end_of_bimonth? &&
          (58..62) === last - first + 1
      :bimonth
    elsif first.beginning_of_month? && last.end_of_month? &&
          (28..31) === last - first + 1
      :month
    elsif first.beginning_of_semimonth? && last.end_of_semimonth &&
          (13..16) === last - first + 1
      :semimonth
    elsif first.beginning_of_biweek? && last.end_of_biweek? &&
          last - first + 1 == 14
      :biweek
    elsif first.beginning_of_week? && last.end_of_week? &&
          last - first + 1 == 7
      :week
    elsif first == last
      :day
    else
      :irregular
    end
  end

  def self.chunk_sym_to_days(sym)
    case sym
    when :day
      1
    when :week
      7
    when :biweek
      14
    when :semimonth
      15
    when :month
      30
    when :bimonth
      60
    when :quarter
      90
    when :half
      180
    when :year
      365
    when :irregular
      30
    else
      raise ArgumentError, "unknown chunk sym '#{sym}'"
    end
  end

  # Name for a period not necessarily ending on calendar boundaries.  For
  # example, in reporting reconciliation, we want the period from Feb 11,
  # 2014, to March 10, 2014, be called the 'Month ending March 10, 2014,'
  # event though the period is not a calendar month.  Using the stricter
  # Period#chunk_sym, would not allow such looseness.
  def chunk_name
    case Period.days_to_chunk_sym(length)
    when :year
      'Year'
    when :half
      'Half'
    when :quarter
      'Quarter'
    when :bimonth
      'Bi-month'
    when :month
      'Month'
    when :semimonth
      'Semi-month'
    when :biweek
      'Bi-week'
    when :week
      'Week'
    when :day
      'Day'
    else
      'Period'
    end
  end

  # The smallest number of days possible in each chunk
  def self.chunk_sym_to_min_days(sym)
    case sym
    when :semimonth
      15
    when :month
      28
    when :bimonth
      59
    when :quarter
      86
    when :half
      180
    when :year
      365
    when :irregular
      raise ArgumentError, 'no minimum period for :irregular chunk'
    else
      chunk_sym_to_days(sym)
    end
  end

  # The largest number of days possible in each chunk
  def self.chunk_sym_to_max_days(sym)
    case sym
    when :semimonth
      16
    when :month
      31
    when :bimonth
      62
    when :quarter
      92
    when :half
      183
    when :year
      366
    when :irregular
      raise ArgumentError, 'no maximum period for :irregular chunk'
    else
      chunk_sym_to_days(sym)
    end
  end

  # Return the chunk symbol represented by the number of days given, but allow a
  # deviation from the minimum and maximum number of days for periods larger
  # than bimonths. The default tolerance is +/-10%, but that can be adjusted. The
  # reason for allowing a bit of tolerance for the larger periods is that
  # financial statements meant to cover a given calendar period are often short
  # or long by a few days due to such things as weekends, holidays, or
  # accounting convenience. For example, a bank might issuer "monthly"
  # statements approximately every 30 days, but issue them earlier or later to
  # avoid having the closing date fall on a weekend or holiday. We still want to
  # be able to recognize them as "monthly", even though the period covered might
  # be a few days shorter or longer than any possible calendar month.  You can
  # eliminate this "fudge factor" by setting the `tolerance_pct` to zero.  If
  # the number of days corresponds to none of the defined calendar periods,
  # return the symbol `:irregular`.
  #
  # @example
  #   Period.days_to_chunk(360)    #=> :year
  #   Period.days_to_chunk(360, 0) #=> :irregular
  #   Period.days_to_chunk(88)     #=> :quarter
  #   Period.days_to_chunk(88, 0)  #=> :irregular
  #
  # @param days [Integer] the number of days in the period under test
  # @param tolerance_pct [Numberic] the percent deviation allowed, e.g. 10 => 10%
  # @return [Symbol] symbol for the period corresponding to days number of days
  def self.days_to_chunk(days, tolerance_pct = 10)
    result = :irregular
    CHUNK_RANGE.each_pair do |chunk, rng|
      if [:semimonth, :biweek, :week, :day].include?(chunk)
        # Be strict for shorter periods.
        if rng.cover?(days)
          result = chunk
          break
        end
      else
        # Allow some tolerance for longer periods.
        min = (rng.first * ((100.0 - tolerance_pct) / 100.0)).floor
        max = (rng.last * ((100.0 + tolerance_pct) / 100.0)).floor
        if (min..max).cover?(days)
          result = chunk
          break
        end
      end
    end
    result
  end

  # Return an array of Periods wholly-contained within self in chunks of size,
  # defaulting to monthly chunks. Partial chunks at the beginning and end of
  # self are not included unless partial_first or partial_last, respectively,
  # are set true. The last chunk can be made to extend beyond the end of self to
  # make it a whole chunk if round_up_last is set true, in which case,
  # partial_last is ignored.
  def chunks(size: :month, partial_first: false, partial_last: false,
             round_up_last: false)
    size = size.to_sym
    if Period.chunk_sym_to_min_days(size) > length
      if partial_first || partial_last
        return [self]
      else
        raise ArgumentError, "any #{size} is longer than this period's #{length} days"
      end
    end
    result = []
    chunk_start = first.dup
    while chunk_start <= last
      case size
      when :year
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_year?
        end
        chunk_end = chunk_start.end_of_year
      when :half
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_half?
        end
        chunk_end = chunk_start.end_of_half
      when :quarter
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_quarter?
        end
        chunk_end = chunk_start.end_of_quarter
      when :bimonth
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_bimonth?
        end
        chunk_end = (chunk_start.end_of_month + 1.day).end_of_month
      when :month
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_month?
        end
        chunk_end = chunk_start.end_of_month
      when :semimonth
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_semimonth?
        end
        chunk_end = chunk_start.end_of_semimonth
      when :biweek
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_biweek?
        end
        chunk_end = chunk_start.end_of_biweek
      when :week
        unless partial_first
          chunk_start += 1.day until chunk_start.beginning_of_week?
        end
        chunk_end = chunk_start.end_of_week
      when :day
        chunk_end = chunk_start
      else
        raise ArgumentError, "invalid chunk size '#{size}'"
      end
      if chunk_end <= last
        result << Period.new(chunk_start, chunk_end)
      elsif round_up_last
        result << Period.new(chunk_start, chunk_end)
      elsif partial_last
        result << Period.new(chunk_start, last)
      else
        break
      end
      chunk_start = result.last.last + 1.day
    end
    result
  end

  # @group Set operations

  def subset_of?(other)
    to_range.subset_of?(other.to_range)
  end

  def proper_subset_of?(other)
    to_range.proper_subset_of?(other.to_range)
  end

  def superset_of?(other)
    to_range.superset_of?(other.to_range)
  end

  def proper_superset_of?(other)
    to_range.proper_superset_of?(other.to_range)
  end

  def intersection(other)
    result = to_range.intersection(other.to_range)
    if result.nil?
      nil
    else
      Period.new(result.first, result.last)
    end
  end
  alias & intersection
  alias narrow_to intersection

  def union(other)
    result = to_range.union(other.to_range)
    Period.new(result.first, result.last)
  end
  alias + union

  def difference(other)
    ranges = to_range.difference(other.to_range)
    ranges.each.map { |r| Period.new(r.first, r.last) }
  end
  alias - difference

  def overlaps?(other)
    to_range.overlaps?(other.to_range)
  end

  # Return whether any of the Periods that are within self overlap one
  # another
  def has_overlaps_within?(periods)
    to_range.overlaps_among?(periods.map(&:to_range))
  end

  def spanned_by?(periods)
    to_range.spanned_by?(periods.map(&:to_range))
  end

  def gaps(periods)
    to_range.gaps(periods.map(&:to_range))
      .map { |r| Period.new(r.first, r.last) }
  end
end
