# -*- coding: utf-8 -*-

class Period
  include Enumerable
  include Comparable

  attr_reader :first, :last

  def initialize(first, last)
    case first
    when String
      begin
        first = Date.parse(first)
      rescue ArgumentError => ex
        if ex.message =~ /invalid date/
          raise ArgumentError, "you gave an invalid date '#{first}'"
        else
          raise
        end
      end
    when Date
      first = first
    else
      raise ArgumentError, 'use Date or String to initialize Period'
    end

    case last
    when String
      begin
        last = Date.parse(last)
      rescue ArgumentError => ex
        if ex.message =~ /invalid date/
          raise ArgumentError, "you gave an invalid date '#{last}'"
        else
          raise
        end
      end
    when Date
      last = last
    else
      raise ArgumentError, 'use Date or String to initialize Period'
    end

    @first = first
    @last = last
    if @first > @last
      raise ArgumentError, "Period's first date is later than its last date"
    end
  end

  # These need to come after initialize is defined
  TO_DATE = Period.new(Date::BOT, Date.current)
  FOREVER = Period.new(Date::BOT, Date::EOT)

  # Need custom setters to ensure first <= last
  def first=(new_first)
    unless new_first.is_a?(Date)
      raise ArgumentError, "can't set Period#first to non-date"
    end
    unless new_first <= last
      raise ArgumentError, 'cannot make Period#first > Period#last'
    end
    @first = new_first
  end

  def last=(new_last)
    unless new_last.is_a?(Date)
      raise ArgumentError, 'cannot set Period#last to non-date'
    end
    unless new_last >= first
      raise ArgumentError, 'cannot make Period#last < Period#first'
    end
    @last = new_last
  end

  # Comparable base: periods are equal only if their first and last dates are
  # equal.  Sorting will be by first date, then last, so periods starting on
  # the same date will sort by last date, thus, from smallest to largest in
  # size.
  def <=>(other)
    [first, size] <=> [other.first, other.size]
  end

  # Comparable does not include this.
  def !=(other)
    !(self == other)
  end

  # Enumerable base.  Yield each day in the period.
  def each
    d = first
    while d <= last
      yield d
      d += 1.day
    end
  end

  # Case equality checks for inclusion of date in period.
  def ===(other)
    contains?(other)
  end

  # Return the number of days in the period
  def days
    last - first + 1
  end

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

  def trading_days
    select(&:nyse_workday?)
  end

  # Return a period based on two date specs passed as strings (see
  # Date.parse_spec), a '''from' and a 'to' spec.  If the to-spec is not given
  # or is nil, the from-spec is used for both the from- and to-spec.
  #
  # Period.parse('2014-11') => Period.new('2014-11-01', 2014-11-30')
  # Period.parse('2014-11', '2015-3Q')
  #  => Period.new('2014-11-01', 2015-09-30')
  def self.parse(from, to = nil)
    raise ArgumentError, 'Period.parse missing argument' unless from
    to ||= from
    first = Date.parse_spec(from, :from)
    second = Date.parse_spec(to, :to)
    Period.new(first, second) if first && second
  end

  # Return a period from a phrase in which the from date is introduced with
  # 'from' and, optionally, the to-date is introduced with 'to'.
  #
  # Period.parse_phrase('from 2014-11 to 2015-3Q')
  #  => Period('2014-11-01', '2015-09-30')
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
    end
    parse(from_phrase, to_phrase)
  end

  # Possibly useful class method to take an array of periods and join all the
  # contiguous ones, then return an array of the disjoint periods not
  # contiguous to one another.  An array of periods with no gaps should return
  # an array of only one period spanning all the given periods.

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

  def self.chunk_syms
    [:day, :week, :biweek, :semimonth, :month, :bimonth,
     :quarter, :half, :year, :irregular]
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

  # Distinguishing between :semimonth and :biweek is impossible in
  # some cases since a :semimonth can be 14 days just like a :biweek.
  # This ignores that possiblity and requires a :semimonth to be at
  # least 15 days.
  def self.days_to_chunk_sym(days)
    case days
    when 356..376
      :year
    when 180..183
      :half
    when 86..96
      :quarter
    when 59..62
      :bimonth
    when 26..33
      :month
    when 15..16
      :semimonth
    when 14
      :biweek
    when 7
      :week
    when 1
      :day
    else
      :irregular
    end
  end

  def to_range
    (first..last)
  end

  def to_s
    if first.beginning_of_year? && last.end_of_year? && first.year == last.year
      first.year.to_s
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

  # Allow erb documents can directly interpolate ranges
  def tex_quote
    "#{first.iso}--#{last.iso}"
  end

  # Days in period
  def size
    (last - first + 1).to_i
  end

  def length
    size
  end

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

  def contains?(date)
    date = date.to_date if date.respond_to?(:to_date)
    raise ArgumentError, 'argument must be a Date' unless date.is_a?(Date)
    to_range.cover?(date)
  end

  def overlaps?(other)
    to_range.overlaps?(other.to_range)
  end

  # Return whether any of the Periods that are within self overlap one
  # another
  def has_overlaps_within?(periods)
    to_range.has_overlaps_within?(periods.map(&:to_range))
  end

  def spanned_by?(periods)
    to_range.spanned_by?(periods.map(&:to_range))
  end

  def gaps(periods)
    to_range.gaps(periods.map(&:to_range))
      .map { |r| Period.new(r.first, r.last) }
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
end
