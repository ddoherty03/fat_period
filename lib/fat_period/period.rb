require 'fat_date'

# The Period class represents a range of Dates and supports a variety of
# operations on those ranges.
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
    @first = Date.ensure_date(first).freeze
    @last = Date.ensure_date(last).freeze
    freeze

    raise ArgumentError, "Period's first date is later than its last date" if @first > @last
  end

  # These need to come after initialize is defined

  # Period from commercial beginning of time to commercial end of time.
  FOREVER = Period.new(Date::BOT, Date::EOT)

  # @group Parsing
  #
  # Return a period based on two date specs passed as strings (see
  # `FatCore::Date.spec`), a 'from' and a 'to' spec. The returned period
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
  # @param from [String] spec ala FatCore::Date.spec
  # @param to [String] spec ala FatCore::Date.spec
  # @return [Period] from beginning of `from` to end of `to`
  def self.parse(from, to = nil)
    raise ArgumentError, 'Period.parse missing argument' unless from

    to ||= from
    first = Date.spec(from, :from)
    second = Date.spec(to, :to)
    Period.new(first, second) if first && second
  end

  # Return a Period either from a given String or other type that can
  # reasonably converted to a Period.
  #
  # @example
  #   Period.ensure('2014-11').inspect    #=> Period('2014-11-01..2014-11-30')
  #   pd = Period.parse('2011')
  #   Period.ensure(pd).inspect           #=> Period('2011-01-01..2011-12-31')
  #
  # @param prd [String|Period] or any candidate for conversion to Period
  # @return Period correspondign to prd parameter
  def self.ensure(prd)
    prd.to_period if prd.respond_to?(:to_period)
    case prd
    when String
      if prd.match?(/from|to/i)
        Period.parse_phrase(prd).first
      else
        Period.parse(prd)
      end
    when Period
      prd
    end
  end

  # Return an Array of Periods from a String phrase in which the from spec is
  # introduced with 'from' and, optionally, the to spec is introduced with
  # 'to' and optionally a 'per' clause is introduced by 'per'.  A phrase with
  # only a to spec is treated the same as one with only a from spec.  If
  # neither 'from' nor 'to' appear in phrase, treat the string before any
  # per-clause as a from spec.
  #
  # @example
  #   Period.parse_phrase('from 2014-11 to 2015-3Q') #=> [Period('2014-11-01..2015-09-30')]
  #   Period.parse_phrase('from 2014-11')            #=> [Period('2014-11-01..2014-11-30')]
  #   Period.parse_phrase('from 2015-3Q')            #=> [Period('2015-09-01..2015-12-31')]
  #   Period.parse_phrase('to 2015-3Q')              #=> [Period('2015-09-01..2015-12-31')]
  #   Period.parse_phrase('2015-3Q')                 #=> [Period('2015-09-01..2015-12-31')]
  #   Period.parse_phrase('to 2015-3Q per week')     #=> [Period('2015-09-01..2015-09-04')...]
  #   Period.parse_phrase('2015-3Q per month')       #=> [Period('2015-09-01..2015-09-30')...]
  #
  # @param phrase [String] with 'from <spec> [to <spec>] [per chunk]'
  # @return [Period] translated from phrase
  def self.parse_phrase(phrase, partial_first: true, partial_last: true, round_up_last: false)
    phrase = phrase.clean
    case phrase
    when /\Afrom\s+([^\s]+)\s+to\s+([^\s]+)(\s+per\s+[^\s]+)?\z/i
      from_phrase = $1
      to_phrase = $2
    when /\Afrom\s+([^\s]+)(\s+per\s+[^\s]+)?\z/, /\Ato\s+([^\s]+)(\s+per\s+[^\s]+)?\z/i
      from_phrase = $1
      to_phrase = nil
    when /\A([^\s]+)(\s+per\s+[^\s]+)?\z/
      from_phrase = $1
      to_phrase = nil
    else
      raise ArgumentError, "unintelligible period phrase: '#{phrase}''"
    end
    # Return an Array of periods divided by chunks if any.
    whole_period = parse(from_phrase, to_phrase)
    if phrase =~ /per\s+(?<chunk>[a-z_]+)/i
      chunk_size = Regexp.last_match[:chunk].downcase.to_sym
      raise ArgumentError, "invalid chunk size #{chunk_size}" unless CHUNKS.include?(chunk_size)

      whole_period.chunks(size: chunk_size, partial_first:, partial_last:, round_up_last:)
    else
      [whole_period]
    end
  end

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
    return unless other.is_a?(Period)

    [first, last] <=> [other.first, other.last]
  end

  # Comparable does not include this.
  def !=(other)
    !(self == other)
  end

  # Return the hash value for this Period.  Make Period's with identical
  # values test eql? so that they may be used as hash keys.
  #
  # @return [Integer]
  def hash
    (first.hash | last.hash)
  end

  def eql?(other)
    return false unless other.is_a?(Period)

    hash == other.hash
  end

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
  # See FatCore::Date for how trading days are determined.
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
  alias_method :length, :size
  alias_method :days, :size

  # Return the fractional number of months in the period.  By default, use the
  # average number of days in a month, but allow the user to override the
  # assumption with a parameter.
  def months(days_in_month = 30.436875)
    (days / days_in_month.to_f).to_f
  end

  # Return the fractional number of years in the period.  By default, use the
  # average number of days in a year, but allow the user to override the
  # assumption with a parameter.
  def years(days_in_year = 365.2425)
    (days / days_in_year.to_f).to_f
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
  CHUNKS = %i[
    day
    week
    biweek
    semimonth
    month
    bimonth
    quarter
    half
    year
  ].freeze

  CHUNK_ORDER = {}
  CHUNKS.each_with_index do |c, i|
    CHUNK_ORDER[c] = i
  end
  CHUNK_ORDER.freeze

  # An Array of Ranges for the number of days that can be covered by each chunk.
  CHUNK_RANGE = {
    day: (1..1),
    week: (7..7),
    biweek: (14..14),
    semimonth: (15..16),
    month: (28..31),
    bimonth: (59..62),
    quarter: (90..92),
    half: (180..183),
    year: (365..366)
  }.freeze

  def self.chunk_cmp(chunk1, chunk2)
    CHUNK_ORDER[chunk1] <=> CHUNK_ORDER[chunk2]
  end

  # Return a period representing a chunk containing a given Date.
  def self.day_containing(date)
    Period.new(date, date)
  end

  def self.week_containing(date)
    Period.new(date.beginning_of_week, date.end_of_week)
  end

  def self.biweek_containing(date)
    Period.new(date.beginning_of_biweek, date.end_of_biweek)
  end

  def self.semimonth_containing(date)
    Period.new(date.beginning_of_semimonth, date.end_of_semimonth)
  end

  def self.month_containing(date)
    Period.new(date.beginning_of_month, date.end_of_month)
  end

  def self.bimonth_containing(date)
    Period.new(date.beginning_of_bimonth, date.end_of_bimonth)
  end

  def self.quarter_containing(date)
    Period.new(date.beginning_of_quarter, date.end_of_quarter)
  end

  def self.half_containing(date)
    Period.new(date.beginning_of_half, date.end_of_half)
  end

  def self.year_containing(date)
    Period.new(date.beginning_of_year, date.end_of_year)
  end

  def self.chunk_containing(date, chunk)
    raise ArgumentError, 'chunk is nil' unless chunk

    chunk = chunk.to_sym
    raise ArgumentError, "unknown chunk name: #{chunk}" unless CHUNKS.include?(chunk)

    date = Date.ensure_date(date)
    method = "#{chunk}_containing".to_sym
    send(method, date)
  end

  # Return a Period representing a chunk containing today.
  def self.this_day
    day_containing(Date.current)
  end

  def self.this_week
    week_containing(Date.current)
  end

  def self.this_biweek
    biweek_containing(Date.current)
  end

  def self.this_semimonth
    semimonth_containing(Date.current)
  end

  def self.this_month
    month_containing(Date.current)
  end

  def self.this_bimonth
    bimonth_containing(Date.current)
  end

  def self.this_quarter
    quarter_containing(Date.current)
  end

  def self.this_half
    half_containing(Date.current)
  end

  def self.this_year
    year_containing(Date.current)
  end

  # Return the chunk symbol represented by this period if it covers a single
  # calendar period; otherwise return :irregular.
  #
  # @example
  #   Period.new('2016-02-01', '2016-02-29').chunk_sym #=> :month
  #   Period.new('2016-02-01', '2016-02-28').chunk_sym #=> :irregular
  #   Period.new('2016-02-01', '2017-02-28').chunk_sym #=> :irregular
  #   Period.new('2016-01-01', '2016-03-31').chunk_sym #=> :quarter
  #   Period.new('2016-01-02', '2016-04-01').chunk_sym #=> :irregular
  #
  # @return [Symbol]
  def chunk_sym
    if first.beginning_of_year? && last.end_of_year? &&
       CHUNK_RANGE[:year].cover?(size)
      :year
    elsif first.beginning_of_half? && last.end_of_half? &&
          CHUNK_RANGE[:half].cover?(size)
      :half
    elsif first.beginning_of_quarter? && last.end_of_quarter? &&
          CHUNK_RANGE[:quarter].cover?(size)
      :quarter
    elsif first.beginning_of_bimonth? && last.end_of_bimonth? &&
          CHUNK_RANGE[:bimonth].cover?(size)
      :bimonth
    elsif first.beginning_of_month? && last.end_of_month? &&
          CHUNK_RANGE[:month].cover?(size)
      :month
    elsif first.beginning_of_semimonth? && last.end_of_semimonth &&
          CHUNK_RANGE[:semimonth].cover?(size)
      :semimonth
    elsif first.beginning_of_biweek? && last.end_of_biweek? &&
          CHUNK_RANGE[:biweek].cover?(size)
      :biweek
    elsif first.beginning_of_week? && last.end_of_week? &&
          CHUNK_RANGE[:week].cover?(size)
      :week
    elsif first == last
      :day
    else
      :irregular
    end
  end

  # Return a string name for this period based solely on the number of days in
  # the period. Any period sufficiently close to 30 days will return the string
  # 'Month', and any period sufficiently close to 90 days will return 'Quarter'.
  # However for the shorter periods, periods less than month, no tolerance is
  # applied.  The amount of tolerance for the longer periods can be controlled
  # with the `tolerance_pct` parameter, which default to 10%.  If no calendar
  # period corresponds to the length of the period, return 'Period'.
  #
  # @example
  #   Period.new('2015-05-15', '2015-06-17').chunk_name    #=> 'Month' (within 10%)
  #   Period.new('2015-05-15', '2015-06-17').chunk_name(8) #=> 'Period' (but not 8%)
  #
  # @param tolerance_pct [Numeric] long period tolerance as a percent, 10 by default
  # @return [String] the name for this period based solely on the number of days
  #   in the period.
  def chunk_name(tolerance_pct = 10)
    case Period.days_to_chunk(length, tolerance_pct)
    when :year
      'Year'
    when :half
      'Half'
    when :quarter
      'Quarter'
    when :bimonth
      'Bimonth'
    when :month
      'Month'
    when :semimonth
      'Semimonth'
    when :biweek
      'Biweek'
    when :week
      'Week'
    when :day
      'Day'
    else
      'Period'
    end
  end

  # Return the chunk symbol represented by the number of days given, but allow
  # a deviation from the minimum and maximum number of days for periods larger
  # than bimonths. The default tolerance is +/-10%, but that can be
  # adjusted. The reason for allowing a bit of tolerance for the larger
  # periods is that financial statements meant to cover a given calendar
  # period are often short or long by a few days due to such things as
  # weekends, holidays, or accounting convenience. For example, a bank might
  # issuer "monthly" statements approximately every 30 days, but issue them
  # earlier or later to avoid having the closing date fall on a weekend or
  # holiday. We still want to be able to recognize them as "monthly", even
  # though the period covered might be a few days shorter or longer than any
  # possible calendar month.  You can eliminate this "fudge factor" by setting
  # the `tolerance_pct` to zero.  If the number of days corresponds to none of
  # the defined calendar periods, return the symbol `:irregular`.
  #
  # @example
  #   Period.days_to_chunk(360)    #=> :year
  #   Period.days_to_chunk(360, 0) #=> :irregular
  #   Period.days_to_chunk(88)     #=> :quarter
  #   Period.days_to_chunk(88, 0)  #=> :irregular
  #
  # @param days [Integer] the number of days in the period under test
  # @param tolerance_pct [Numeric] the percent deviation allowed, e.g. 10 => 10%
  # @return [Symbol] symbol for the period corresponding to days number of days
  def self.days_to_chunk(days, tolerance_pct = 10)
    result = :irregular
    CHUNK_RANGE.each_pair do |chunk, rng|
      if %i[semimonth biweek week day].include?(chunk)
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
  # self are not included unless `partial_first` or `partial_last`,
  # respectively, are set true. The last chunk can be made to extend beyond the
  # end of self to make it a whole chunk if `round_up_last` is set true, in
  # which case, partial_last is ignored.
  #
  # @example
  #   Period.parse('2015').chunks(size: :month) #=>
  #    [Period(2015-01-01..2015-01-31),
  #     Period(2015-02-01..2015-02-28),
  #     Period(2015-03-01..2015-03-31),
  #     Period(2015-04-01..2015-04-30),
  #     Period(2015-05-01..2015-05-31),
  #     Period(2015-06-01..2015-06-30),
  #     Period(2015-07-01..2015-07-31),
  #     Period(2015-08-01..2015-08-31),
  #     Period(2015-09-01..2015-09-30),
  #     Period(2015-10-01..2015-10-31),
  #     Period(2015-11-01..2015-11-30),
  #     Period(2015-12-01..2015-12-31)
  #    ]
  #
  #   Period.parse('2015').chunks(size: :week) #=>
  #    [Period(2015-01-05..2015-01-11), # Note that first week starts after Jan 1.
  #     Period(2015-01-12..2015-01-18),
  #     Period(2015-01-19..2015-01-25),
  #     Period(2015-01-26..2015-02-01),
  #     ...
  #     Period(2015-12-07..2015-12-13),
  #     Period(2015-12-14..2015-12-20),
  #     Period(2015-12-21..2015-12-27)] # Note that last week ends before Dec 31
  #
  #   Period.parse('2015').chunks(size: :week, partial_first: true, partial_last: true) #=>
  #    [Period(2015-01-01..2015-01-04), # Note the partial week starting Jan 1
  #     Period(2015-01-05..2015-01-11),
  #     Period(2015-01-12..2015-01-18),
  #     Period(2015-01-19..2015-01-25),
  #     Period(2015-01-26..2015-02-01),
  #     ...
  #     Period(2015-12-07..2015-12-13),
  #     Period(2015-12-14..2015-12-20),
  #     Period(2015-12-21..2015-12-27)
  #     Period(2015-12-28..2015-12-31) # Note partial week ending Dec 31
  #     ]
  #
  #   Period.parse('2015').chunks(size: :week, partial_first: true, round_up_last: true) #=>
  #    [Period(2015-01-01..2015-01-04), # Note the partial week starting Jan 1
  #     Period(2015-01-05..2015-01-11),
  #     Period(2015-01-12..2015-01-18),
  #     Period(2015-01-19..2015-01-25),
  #     Period(2015-01-26..2015-02-01),
  #     ...
  #     Period(2015-12-07..2015-12-13),
  #     Period(2015-12-14..2015-12-20),
  #     Period(2015-12-21..2015-12-27)
  #     Period(2015-12-28..2016-01-03) # Note full week extending beyond self
  #     ]
  #
  # @raise ArgumentError if size of chunks is larger than self or if an invalid
  #   chunk size.
  # @param size [Symbol] a chunk symbol, :year, :half. :quarter, etc.
  # @param partial_first [Boolean] allow a period less than a full :size period
  #   as the first period in the returned array.
  # @param partial_last [Boolean] allow a period less than a full :size period
  #   as the last period in the returned array.
  # @param round_up_last [Boolean] allow the last period in the returned array
  #   to extend beyond the end of self.
  # @return [Array<Period>] periods that subdivide self into chunks of size, `size`
  def chunks(size: :month, partial_first: true, partial_last: true,
    round_up_last: false)
    chunk_size = size.to_sym
    raise ArgumentError, "unknown chunk size '#{chunk_size}'" unless CHUNKS.include?(chunk_size)

    containing_period = Period.chunk_containing(first, chunk_size)
    return [dup] if self == containing_period

    # Period too small for even a single chunk and is wholly-contained by a
    # single chunk.
    result = []
    if proper_subset_of?(containing_period)
      result =
        if partial_first || partial_last
          if round_up_last
            [containing_period]
          else
            [dup]
          end
        else
          []
        end
      return result
    end

    chunk_start = first.dup
    chunk_end = chunk_start.end_of_chunk(chunk_size)
    if chunk_start.beginning_of_chunk?(chunk_size) || partial_first
      # Keep the first chunk if it's whole or partials allowed
      result << Period.new(chunk_start, chunk_end)
    end
    chunk_start = chunk_end + 1.day
    chunk_end = chunk_start.end_of_chunk(chunk_size)
    # Add Whole chunks
    while chunk_end <= last
      result << Period.new(chunk_start, chunk_end)
      chunk_start = chunk_end + 1.day
      chunk_end = chunk_start.end_of_chunk(chunk_size)
    end
    # Possibly append the final chunk to result
    if chunk_start < last
      if round_up_last
        result << Period.new(chunk_start, chunk_end)
      elsif partial_last
        result << Period.new(chunk_start, last)
      else
        result
      end
    end
    if partial_last && !partial_first && result.empty?
      # Catch the case where the period is too small to make a whole chunk and
      # partial_first is false, so it did not get included as the initial
      # partial chunk, yet a partial_last is allowed, so include the whole
      # period as a partial chunk.
      result << Period.new(first, last)
    end
    result
  end

  # @group Set operations

  # Is this period contained wholly within or coincident with `other`?
  #
  # @example
  #   Period.parse('2015-2Q').subset_of?(Period.parse('2015'))    #=> true
  #   Period.parse('2015-2Q').subset_of?(Period.parse('2015-2Q')) #=> true
  #   Period.parse('2015-2Q').subset_of?(Period.parse('2015-02')) #=> false
  #
  # @param other [Period] other Period
  # @return [Boolean] self within or coincident with `other`?
  def subset_of?(other)
    to_range.subset_of?(other.to_range)
  end

  # Is this period contained wholly within but not coincident with `other`?
  #
  # @example
  #   Period.parse('2015-2Q').proper_subset_of?(Period.parse('2015'))    #=> true
  #   Period.parse('2015-2Q').proper_subset_of?(Period.parse('2015-2Q')) #=> false
  #   Period.parse('2015-2Q').proper_subset_of?(Period.parse('2015-02')) #=> false
  #
  # @param other [Period] other Period
  # @return [Boolean] self within `other`?
  def proper_subset_of?(other)
    to_range.proper_subset_of?(other.to_range)
  end

  # Does this period wholly contain or is coincident with `other`?
  #
  # @example
  #   Period.parse('2015').superset_of?(Period.parse('2015-2Q'))    #=> true
  #   Period.parse('2015-2Q').superset_of?(Period.parse('2015-2Q')) #=> true
  #   Period.parse('2015-02').superset_of?(Period.parse('2015-2Q')) #=> false
  #
  # @param other [Period] other Period
  # @return [Boolean] self contains or coincident with `other`?
  def superset_of?(other)
    to_range.superset_of?(other.to_range)
  end

  # Does this period wholly contain but is not coincident with `other`?
  #
  # @example
  #   Period.parse('2015').proper_superset_of?(Period.parse('2015-2Q'))    #=> true
  #   Period.parse('2015-2Q').proper_superset_of?(Period.parse('2015-2Q')) #=> false
  #   Period.parse('2015-02').proper_superset_of?(Period.parse('2015-2Q')) #=> false
  #
  # @param other [Period] other Period
  # @return [Boolean] self contains `other`?
  def proper_superset_of?(other)
    to_range.proper_superset_of?(other.to_range)
  end

  # Return the Period that is the intersection of self with `other` or nil if
  # there is no intersection.
  #
  # @example
  #   Period.parse('2015-3Q') & Period.parse('2015-2Q') #=> nil
  #   Period.parse('2015') & Period.parse('2015-2Q')    #=> Period(2015-2Q)
  #   pp1 = Period.parse_phrase('from 2015 to 2015-3Q') #=> Period(2015-01-01..2015-09-30)
  #   pp2 = Period.parse_phrase('from 2015-2H')         #=> Period(2015-07-01..2015-12-31)
  #   pp1 & pp2                                         #=> Period(2015-07-01..2015-09-30)
  #
  # @param other [Period] other Period
  # @return [Period, nil] self intersect `other`?
  def intersection(other)
    result = to_range.intersection(other.to_range)
    if result.nil?
      nil
    else
      Period.new(result.first, result.last)
    end
  end
  alias_method :&, :intersection
  alias_method :narrow_to, :intersection

  # Return the Period that is the union of self with `other` or nil if
  # they neither overlap nor are contiguous
  #
  # @example
  #   Period.parse('2015-3Q') + Period.parse('2015-2Q')    #=> Period(2015-04-01..2015-09-30)
  #   Period.parse('2015') + Period.parse('2015-2Q')       #=> Period(2015-01-01..2015-12-31)
  #   Period.parse('2015') + Period.parse('2017')          #=> nil
  #   pp1 = Period.parse_phrase('from 2015-4Q to 2016-1H') #=> Period(2015-10-01-2015..2015-12-31)
  #   pp2 = Period.parse_phrase('from 2015-3Q to 2015-11') #=> Period(2015-07-01-2015..2015-11-30)
  #   pp1 + pp2                                            #=> Period(2015-10-01..2015-11-30)
  #
  # @param other [Period] other Period
  # @return [Period, nil] self union `other`?
  def union(other)
    result = to_range.union(other.to_range)
    return if result.nil?

    Period.new(result.first, result.last)
  end
  alias_method :+, :union

  # Return an array of periods that are this period excluding any overlap with
  # other. If there is no overlap, return an array with a period equal to self
  # as the sole member.
  #
  # @example
  #   Period.parse('2015-1Q') - Period.parse('2015-02')
  #     #=> [Period(2015-01-01..2015-01-31), Period(2015-03-01..2015-03-31)]
  #   Period.parse('2015-2Q') - Period.parse('2015-02')
  #     #=> [Period(2015-04-01..2015-06-30)]
  #
  # @param other [Period] the other period to exclude from self
  # @return [Array<Period>] self less the part of other that overlaps
  def difference(other)
    ranges = to_range.difference(other.to_range)
    ranges.each.map { |r| Period.new(r.first, r.last) }
  end
  alias_method :-, :difference

  # Return whether this period overlaps the `other` period.  To overlap, the
  # periods must have at least one day in common.
  #
  # @example
  #   Period.parse('2012').overlaps?(Period.parse('2016')) #=> false
  #   Period.parse('2016-32W').overlaps?(Period.parse('2016')) #=> true
  #   pp1 = Period.new('2016-03-12', '2016-03-15')
  #   pp2 = Period.new('2016-03-16', '2016-03-25')
  #   pp1.overlaps?(pp2) #=> false (being contiguous is not overlapping)
  #
  # @param other [Period] the other period to test for overlap
  # @return [Boolean] does self overlap with other?
  def overlaps?(other)
    to_range.overlaps?(other.to_range)
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
  alias_method :===, :contains?

  # Return whether any of the given periods overlap any other.
  #
  # @example
  #   pds = []
  #   pds << Period.parse('2015-1H')
  #   pds << Period.parse('2016-2H')
  #   pds << Period.parse('2015-04')
  #   Period.overlaps_among?(pds) #=> true
  #
  # @param periods [Array<Period>] periods to test for overlaps
  # @return [Boolean] true if any one of periods overlaps another
  def self.overlaps_among?(periods)
    Range.overlaps_among?(periods.map(&:to_range))
  end

  # Return whether any of the given periods overlap any other but only if the
  # overlaps occur within the self; overlaps outside self are ignored.
  #
  # @example
  #   pds = []
  #   pds << Period.parse('2015-1H')
  #   pds << Period.parse('2016-2H')
  #   pds << Period.parse('2015-04')
  #   yr2015 = Period.parse('2015')
  #   yr2016 = Period.parse('2016')
  #   yr2015.overlaps_among?(pds) #=> true
  #   yr2016.overlaps_among?(pds) #=> false (overlap is in 2015)
  #
  # @param periods [Array<Period>] periods to test for overlaps
  # @return [Boolean] true if any one of periods overlaps another
  def overlaps_among?(periods)
    to_range.overlaps_among?(periods.map(&:to_range))
  end

  # Return whether the given periods "span" self, that is, do they collectively
  # cover all of self with no overlaps and no gaps?
  #
  # @example
  #   ppds = []
  #   ppds << Period.parse('2016-1Q')
  #   ppds << Period.parse('2016-2Q')
  #   ppds << Period.parse('2016-2H')
  #   Period.parse('2016').spanned_by?(ppds) #=> true
  #
  #   # There's a bit of the year at the beginning that isn't covered by
  #   # one of these weeks:
  #   ppds = Period.parse('2016').chunks(size: :week)
  #   Period.parse('2016').spanned_by?(ppds) #=> false
  #
  # @param periods [Array<Period>] periods to test for spanning self
  # @return [Boolean] do periods span self?
  def spanned_by?(periods)
    to_range.spanned_by?(periods.map(&:to_range))
  end

  # Return an Array of Periods representing the gaps within self not covered by
  # the Array of Periods `periods`.  Overlaps among the periods do not affect
  # the result nor do gaps outside the range of self.  Ordering among the
  # `periods` does not matter.
  #
  # @example
  #   some_qs = []
  #   some_qs << Period.parse('2015-1Q')
  #   some_qs << Period.parse('2015-3Q')
  #   some_qs << Period.parse('2015-11')
  #   some_qs << Period.parse('2015-12')
  #   Period.parse('2015').gaps(some_qs) #=>
  #     [Period(2015-04-01..2015-06-30), Period(2015-10-01..2015-10-31)]
  #
  # @param periods [Array<Period>] periods to examine for coverage of self
  # @return [Array<Periods>] periods that are not covered by `periods`
  def gaps(periods)
    to_range.gaps(periods.map(&:to_range))
      .map { |r| Period.new(r.first, r.last) }
  end
end
