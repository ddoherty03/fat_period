require 'spec_helper'

describe Period do
  before do
    # Pretend it is this date. Not at beg or end of year, quarter,
    # month, or week.  It is a Wednesday
    allow(Date).to receive_messages(today: Date.parse('2012-07-18'))
    allow(Date).to receive_messages(current: Date.parse('2012-07-18'))
    Date.beginning_of_week = :sunday
  end

  describe 'initialization' do
    it 'initializes with date strings' do
      expect(Period.new('2013-01-01', '2013-12-13')).to be_instance_of Period
    end

    it 'initializes with DateTime' do
      dt1 = DateTime.new(2013, 1, 1, 4, 13, 8)
      dt2 = DateTime.new(2015, 1, 1, 4, 13, 8)
      expect(Period.new(dt1, dt2))
        .to be_instance_of Period
    end

    it 'initializes with Time' do
      t1 = Time.new(2013, 1, 1, 4, 13, 8)
      t2 = Time.new(2015, 1, 1, 4, 13, 8)
      expect(Period.new(t1, t2))
        .to be_instance_of Period
    end

    it 'raises a ArgumentError if last > first' do
      expect {
        Period.new('2013-01-01', '2012-12-31')
      }.to raise_error ArgumentError, /first date is later/
    end

    it 'raises a ArgumentError if initialized with invalid date string' do
      expect {
        Period.new('2013-01-01', '2013-12-32')
      }.to raise_error ArgumentError, /cannot convert/
      expect {
        Period.new('2013-13-01', '2013-12-31')
      }.to raise_error ArgumentError, /cannot convert/
    end

    it 'raises a ArgumentError if initialized otherwise' do
      expect {
        Period.new(2013 - 1 - 1, 2013 - 12 - 31)
      }.to raise_error ArgumentError
    end
  end

  describe 'equality' do
    it 'is == if dates are the same' do
      a = Period.new('2013-01-01', '2013-12-31')
      b = Period.new('2013-01-01', '2013-12-31')
      expect(a == b).to be_truthy
    end

    it 'is not == if dates differ' do
      a = Period.new('2013-01-01', '2013-12-30')
      b = Period.new('2013-01-01', '2013-12-31')
      expect(a == b).not_to be_truthy
    end

    it 'is != if dates differ' do
      a = Period.new('2013-01-01', '2013-12-30')
      b = Period.new('2013-01-01', '2013-12-31')
      expect(a != b).to be_truthy
    end

    it 'returns the same hash value if date the same' do
      a = Period.new('2013-01-01', '2013-12-31')
      b = Period.new('2013-01-01', '2013-12-31')
      expect(a.hash).to eq(b.hash)
    end

    it 'does not return the same hash value if dates differ' do
      a = Period.new('2013-01-02', '2013-12-31')
      b = Period.new('2013-01-01', '2013-12-31')
      expect(a.hash).not_to eq(b.hash)
    end

    it 'eql?s another with same dates' do
      a = Period.new('2013-01-01', '2013-12-31')
      b = Period.new('2013-01-01', '2013-12-31')
      expect(a.eql?(b)).to be true
    end

    it 'does not eql? another if dates differ' do
      a = Period.new('2013-01-01', '2013-12-31')
      b = Period.new('2013-01-01', '2013-12-30')
      expect(a.eql?(b)).not_to be true
    end

    it 'tells if it contains a date with ===' do
      # rubocop:disable Style/CaseEquality
      pp = Period.new('2013-01-01', '2013-12-31')
      expect(pp === Date.parse('2013-01-01')).to be true
      expect(pp === Date.parse('2013-07-04')).to be true
      expect(pp === Date.parse('2013-12-31')).to be true
      expect(pp === Date.parse('2012-07-04')).to be false
      # rubocop:enable Style/CaseEquality
    end
  end

  describe 'chunk-level methods' do
    it 'compares chunk symbols' do
      expect(Period.chunk_cmp(:year, :half)).to eq(1)
      expect(Period.chunk_cmp(:half, :year)).to eq(-1)
      expect(Period.chunk_cmp(:year, :year)).to eq(0)
    end

    it 'knows what the valid chunk syms are' do
      expect(Period::CHUNKS.size).to eq(9)
    end

    it 'gets the chunk sym for given days' do
      (365..366).each { |d| expect(Period.days_to_chunk(d)).to eq(:year) }
      (180..183).each { |d| expect(Period.days_to_chunk(d)).to eq(:half) }
      (90..92).each { |d| expect(Period.days_to_chunk(d)).to eq(:quarter) }
      (59..62).each { |d| expect(Period.days_to_chunk(d)).to eq(:bimonth) }
      (28..31).each { |d| expect(Period.days_to_chunk(d)).to eq(:month) }
      (15..16).each { |d| expect(Period.days_to_chunk(d)).to eq(:semimonth) }
      expect(Period.days_to_chunk(14)).to eq(:biweek)
      expect(Period.days_to_chunk(7)).to eq(:week)
      expect(Period.days_to_chunk(1)).to eq(:day)
    end

    it 'gets chunk name based on its size' do
      expect(Period.new('2011-01-01', '2011-12-31').chunk_name).to eq('Year')
      expect(Period.new('2011-01-01', '2011-06-30').chunk_name).to eq('Half')
      expect(Period.new('2011-01-01', '2011-03-31').chunk_name).to eq('Quarter')
      expect(Period.new('2011-01-01', '2011-02-28').chunk_name)
        .to eq('Bimonth')
      expect(Period.new('2011-01-01', '2011-01-31').chunk_name).to eq('Month')
      expect(Period.new('2011-01-01', '2011-01-15').chunk_name)
        .to eq('Semimonth')
      expect(Period.new('2011-01-09', '2011-01-22').chunk_name).to eq('Biweek')
      expect(Period.new('2011-01-01', '2011-01-07').chunk_name).to eq('Week')
      expect(Period.new('2011-01-01', '2011-01-01').chunk_name).to eq('Day')
      expect(Period.new('2011-01-01', '2011-01-21').chunk_name).to eq('Period')
      # Only size matters, not whether the period begins and ends on
      # calendar unit boundaries.
      expect(Period.new('2011-02-11', '2011-03-10').chunk_name).to eq('Month')
    end
  end

  describe '.parse a for a single Period' do
    it 'returns nil when parsing never' do
      expect(Period.parse('never')).to be_nil
    end

    it 'parses a pair of date specs' do
      expect(Period.parse('2014-3Q').first).to eq Date.parse('2014-07-01')
      expect(Period.parse('2014-3Q').last).to eq Date.parse('2014-09-30')
      expect(Period.parse('2014-3Q').last).to eq Date.parse('2014-09-30')
    end
  end

  describe '.parse_phrase for an Array of Periods' do
    it 'parses a period phrase with this_year' do
      pds = Period.parse_phrase('from this_year')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))

      pds = Period.parse_phrase('this_year')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))
    end

    it 'parses.first.last_year as well' do
      pds = Period.parse_phrase('from last_year to this_year')
      expect(pds.first.first).to eq(Date.parse('2011-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))

      pds = Period.parse_phrase('from last_year to this_year')
      expect(pds.first.first).to eq(Date.parse('2011-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))
    end

    it 'parses a period phrase with half-month' do
      pds = Period.parse_phrase('from 2010-05-I')
      expect(pds.first.first).to eq(Date.parse('2010-05-01'))
      expect(pds.first.last).to eq(Date.parse('2010-05-15'))

      pds = Period.parse_phrase('from 2010-05-II')
      expect(pds.first.first).to eq(Date.parse('2010-05-16'))
      expect(pds.first.last).to eq(Date.parse('2010-05-31'))
    end

    it 'parses month-only and year only' do
      pds = Period.parse_phrase('from 2012-07 to 2012')
      expect(pds.first.first).to eq(Date.parse('2012-07-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))
    end

    it 'parses lone year-half' do
      pds = Period.parse_phrase('from 1H')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-06-30'))
      pds = Period.parse_phrase('to 2H')
      expect(pds.first.first).to eq(Date.parse('2012-07-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))
    end

    it 'parses year-half' do
      pds = Period.parse_phrase('from 2012-1H')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-06-30'))

      pds = Period.parse_phrase('from 2012-2H')
      expect(pds.first.first).to eq(Date.parse('2012-07-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))
    end

    it 'parses lone quarter' do
      pds = Period.parse_phrase('from 2Q')
      expect(pds.first.first).to eq(Date.parse('2012-04-01'))
      expect(pds.first.last).to eq(Date.parse('2012-06-30'))

      pds = Period.parse_phrase('to 3Q')
      expect(pds.first.first).to eq(Date.parse('2012-07-01'))
      expect(pds.first.last).to eq(Date.parse('2012-09-30'))
    end

    it 'parses year-quarter' do
      pds = Period.parse_phrase('to 2012-2Q')
      expect(pds.first.first).to eq(Date.parse('2012-04-01'))
      expect(pds.first.last).to eq(Date.parse('2012-06-30'))

      pds = Period.parse_phrase('from 2012-1Q')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-03-31'))
    end

    it 'parses lone year' do
      pds = Period.parse_phrase('to 2012')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))

      pds = Period.parse_phrase('from 2012')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))

      pds = Period.parse_phrase('2012')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-12-31'))
    end

    it 'parses year-weeknum' do
      pds = Period.parse_phrase('from 2012-W5 to 2013-14W')
      expect(pds.first.first).to eq(Date.parse('2012-01-30'))
      expect(pds.first.last).to eq(Date.parse('2013-04-07'))
    end

    it 'raises error on non-sense phrase' do
      expect { Period.parse_phrase('for score and seven') }.to raise_error(/unintelligible/)
    end
  end

  describe '.parse_phrase with chunks for an Array of Periods' do
    it 'parses a period phrase with this_year' do
      pds = Period.parse_phrase('from this_year per month')
      expect(pds.first.first).to eq(Date.parse('2012-01-01'))
      expect(pds.first.last).to eq(Date.parse('2012-01-31'))
      expect(pds.last.first).to eq(Date.parse('2012-12-01'))
      expect(pds.last.last).to eq(Date.parse('2012-12-31'))
      expect(pds.size).to eq(12)
    end

    it 'parses from last_year as well' do
      pds = Period.parse_phrase('from last_year to this_year per month')
      expect(pds.first.first).to eq(Date.parse('2011-01-01'))
      expect(pds.first.last).to eq(Date.parse('2011-01-31'))
      expect(pds.last.first).to eq(Date.parse('2012-12-01'))
      expect(pds.last.last).to eq(Date.parse('2012-12-31'))
      expect(pds.size).to eq(24)
    end

    it 'parses from-per phrase' do
      pds = Period.parse_phrase('from last_year per month')
      expect(pds.first.first).to eq(Date.parse('2011-01-01'))
      expect(pds.first.last).to eq(Date.parse('2011-01-31'))
      expect(pds.last.first).to eq(Date.parse('2011-12-01'))
      expect(pds.last.last).to eq(Date.parse('2011-12-31'))
      expect(pds.size).to eq(12)
    end

    it 'parses to-per phrase' do
      pds = Period.parse_phrase('to last_year per month')
      expect(pds.first.first).to eq(Date.parse('2011-01-01'))
      expect(pds.first.last).to eq(Date.parse('2011-01-31'))
      expect(pds.last.first).to eq(Date.parse('2011-12-01'))
      expect(pds.last.last).to eq(Date.parse('2011-12-31'))
      expect(pds.size).to eq(12)
    end

    it 'parses bare from with per phrase' do
      pds = Period.parse_phrase('last_year per month')
      expect(pds.first.first).to eq(Date.parse('2011-01-01'))
      expect(pds.first.last).to eq(Date.parse('2011-01-31'))
      expect(pds.last.first).to eq(Date.parse('2011-12-01'))
      expect(pds.last.last).to eq(Date.parse('2011-12-31'))
      expect(pds.size).to eq(12)
    end

    it 'parses a period phrase with half-month' do
      pds = Period.parse_phrase('from 2010-05-I per day')
      expect(pds.first.first).to eq(Date.parse('2010-05-01'))
      expect(pds.last.last).to eq(Date.parse('2010-05-15'))
      expect(pds.size).to eq(15)
    end
  end

  describe 'sorting' do
    it 'sorts by first, then size' do
      periods = []
      periods << Period.new('2012-07-01', '2012-07-31')
      periods << Period.new('2012-06-01', '2012-06-30')
      periods << Period.new('2012-08-01', '2012-08-31')
      periods.sort!
      # First by start_date, then shortest period to longest
      expect(periods[0].first).to eq(Date.parse('2012-06-01'))
      expect(periods[1].first).to eq(Date.parse('2012-07-01'))
      expect(periods[2].first).to eq(Date.parse('2012-08-01'))
      expect(periods[0].last).to eq(Date.parse('2012-06-30'))
      expect(periods[1].last).to eq(Date.parse('2012-07-31'))
      expect(periods[2].last).to eq(Date.parse('2012-08-31'))
    end

    it 'returns nil if comparing incomparables' do
      pd = Period.new('2012-08-01', '2012-08-31')
      rg = (Date.parse('2012-08-01')..Date.parse('2012-08-31'))
      expect(pd <=> rg).to be_nil
    end
  end

  describe 'instance methods' do
    it 'is able to compare for equality' do
      pp1 = Period.new('2013-01-01', '2013-12-31')
      pp2 = Period.new('2013-01-01', '2013-12-31')
      pp3 = Period.new('2013-01-01', '2013-12-30')
      expect((pp1 == pp2)).to be true
      expect((pp1 == pp3)).not_to be true
      expect((pp1 != pp3)).to be true
    end

    it 'converts into a Range' do
      pp = Period.new('2013-01-01', '2013-12-31')
      rr = Period.new('2013-01-01', '2013-12-31').to_range
      expect(rr).to be_instance_of Range
      expect(rr.first).to eq(pp.first)
      expect(rr.last).to eq(pp.last)
    end

    it 'tells if it contains a date' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect(pp.contains?(Date.parse('2013-01-01'))).to be true
      expect(pp.contains?(Date.parse('2013-07-04'))).to be true
      expect(pp.contains?(Date.parse('2013-12-31'))).to be true
      expect(pp.contains?(Date.parse('2012-07-04'))).to be false
    end

    it 'raises an error if contains? arg is not a date' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect {
        pp.contains?(Period.new('2013-06-01', '2013-06-30'))
      }.to raise_error(/must be a Date/)

      # But not if argument can be converted to date with to_date
      expect {
        pp.contains?(Time.now)
      }.not_to raise_error
    end

    it 'converts itself to days' do
      expect(Period.new('2013-01-01', '2013-01-01').days).to eq(1)
      expect(Period.new('2013-01-01', '2013-12-31').days).to eq(365)
    end

    it 'converts itself to fractional months' do
      expect(Period.new('2013-01-01', '2013-01-01').months).to eq(1 / 30.436875)
      expect(Period.new('2013-01-01', '2013-12-31').months(30)).to eq(365 / 30.0)
      expect(Period.new('2013-01-01', '2013-06-30').months.round(0)).to eq(6.0)
    end

    it 'converts itself to fractional years' do
      expect(Period.new('2013-01-01', '2013-01-01').years).to eq(1 / 365.2425)
      expect(Period.new('2013-01-01', '2013-12-31').years(365)).to eq(1.0)
      expect(Period.new('2013-01-01', '2013-06-30').years.round(1)).to eq(0.5)
    end

    it 'enumerates its days' do
      Period.parse('2014-12').each do |dy|
        expect(dy.class).to eq Date
      end
    end

    it 'returns the trading days within period' do
      tds = Period.parse('2014-12').trading_days
      expect(tds.count).to eq(22)
    end

    it 'knows its size' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect(pp.size).to eq 365
      expect(pp.length).to eq 365
    end

    it 'implements the each method' do
      pp = Period.new('2013-12-01', '2013-12-31')
      expect(pp.map(&:iso)).to all match(/\d{4}-\d\d-\d\d/)
    end

    it 'makes a concise period string' do
      expect(Period.new('2013-01-01', '2013-12-31').to_s).to eq('2013')
      expect(Period.new('2013-04-01', '2013-06-30').to_s).to eq('2013-2Q')
      expect(Period.new('2013-03-01', '2013-03-31').to_s).to eq('2013-03')
      expect(Period.new('2013-03-11', '2013-10-31').to_s)
        .to eq('2013-03-11 to 2013-10-31')
    end

    it 'makes a TeX string' do
      expect(Period.new('2013-01-01', '2013-12-31').tex_quote)
        .to eq('2013-01-01--2013-12-31')
    end

    # Note in the following that first period must begin within self.
    it 'chunks into years' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :year)
      expect(chunks.size).to eq(5)
      expect(chunks[0].first.iso).to eq('2009-12-15')
      expect(chunks[0].last.iso).to eq('2009-12-31')
      expect(chunks[1].first.iso).to eq('2010-01-01')
      expect(chunks[1].last.iso).to eq('2010-12-31')
      expect(chunks[2].first.iso).to eq('2011-01-01')
      expect(chunks[2].last.iso).to eq('2011-12-31')
      expect(chunks[4].last.iso).to eq('2013-01-10')
    end

    it 'chunks into halves' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :half)
      expect(chunks.size).to eq(8)
      expect(chunks[0].first.iso).to eq('2009-12-15')
      expect(chunks[0].last.iso).to eq('2009-12-31')
      expect(chunks[1].first.iso).to eq('2010-01-01')
      expect(chunks[1].last.iso).to eq('2010-06-30')
      expect(chunks[2].first.iso).to eq('2010-07-01')
      expect(chunks[2].last.iso).to eq('2010-12-31')
      expect(chunks[3].first.iso).to eq('2011-01-01')
      expect(chunks[3].last.iso).to eq('2011-06-30')
      expect(chunks.last.first.iso).to eq('2013-01-01')
      expect(chunks.last.last.iso).to eq('2013-01-10')
    end

    it 'chunks into quarters' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :quarter)
      expect(chunks.size).to eq(14)
      expect(chunks[0].first.iso).to eq('2009-12-15')
      expect(chunks[0].last.iso).to eq('2009-12-31')
      expect(chunks[1].first.iso).to eq('2010-01-01')
      expect(chunks[1].last.iso).to eq('2010-03-31')
      expect(chunks[2].first.iso).to eq('2010-04-01')
      expect(chunks[2].last.iso).to eq('2010-06-30')
      expect(chunks[3].first.iso).to eq('2010-07-01')
      expect(chunks[3].last.iso).to eq('2010-09-30')
      expect(chunks.last.first.iso).to eq('2013-01-01')
      expect(chunks.last.last.iso).to eq('2013-01-10')
    end

    it 'chunks into bimonths' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :bimonth)
      expect(chunks.size).to eq(20)
      expect(chunks[0].first.iso).to eq('2009-12-15')
      expect(chunks[0].last.iso).to eq('2009-12-31')
      expect(chunks[1].first.iso).to eq('2010-01-01')
      expect(chunks[1].last.iso).to eq('2010-02-28')
      expect(chunks[2].first.iso).to eq('2010-03-01')
      expect(chunks[2].last.iso).to eq('2010-04-30')
      expect(chunks[3].first.iso).to eq('2010-05-01')
      expect(chunks[3].last.iso).to eq('2010-06-30')
      expect(chunks.last.first.iso).to eq('2013-01-01')
      expect(chunks.last.last.iso).to eq('2013-01-10')
    end

    it 'chunks into months' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :month)
      expect(chunks.size).to eq(38)
      expect(chunks[0].first.iso).to eq('2009-12-15')
      expect(chunks[0].last.iso).to eq('2009-12-31')
      expect(chunks[1].first.iso).to eq('2010-01-01')
      expect(chunks[1].last.iso).to eq('2010-01-31')
      expect(chunks[2].first.iso).to eq('2010-02-01')
      expect(chunks[2].last.iso).to eq('2010-02-28')
      expect(chunks[3].first.iso).to eq('2010-03-01')
      expect(chunks[3].last.iso).to eq('2010-03-31')
      expect(chunks.last.first.iso).to eq('2013-01-01')
      expect(chunks.last.last.iso).to eq('2013-01-10')
    end

    it 'chunks quarter into months with partial last' do
      chunks =
        Period.new('2020-01-01', '2020-03-31')
          .chunks(size: :month, partial_last: true)
      expect(chunks.size).to eq(3)
      expect(chunks[0].first.iso).to eq('2020-01-01')
      expect(chunks[0].last.iso).to eq('2020-01-31')
      expect(chunks[1].first.iso).to eq('2020-02-01')
      expect(chunks[1].last.iso).to eq('2020-02-29')
      expect(chunks[2].first.iso).to eq('2020-03-01')
      expect(chunks[2].last.iso).to eq('2020-03-31')
    end

    it 'chunks partial month into months with partial last' do
      chunks =
        Period.new('2020-03-18', '2020-03-31')
          .chunks(size: :month, partial_last: true)
      expect(chunks.size).to eq(1)
      expect(chunks[0].first.iso).to eq('2020-03-18')
      expect(chunks[0].last.iso).to eq('2020-03-31')
    end

    it 'chunks partial month into months with partial first' do
      chunks =
        Period.new('2020-03-18', '2020-03-31')
          .chunks(size: :month, partial_first: true)
      expect(chunks.size).to eq(1)
      expect(chunks[0].first.iso).to eq('2020-03-18')
      expect(chunks[0].last.iso).to eq('2020-03-31')
    end

    it 'chunks a partial month into a single months' do
      chunks =
        Period.new('2017-05-01', '2017-05-31')
          .chunks(size: :month, partial_first: false, partial_last: false)
      expect(chunks.size).to eq(1)
      expect(chunks[0].first.iso).to eq('2017-05-01')
      expect(chunks[0].last.iso).to eq('2017-05-31')
      chunks =
        Period.new('2017-05-01', '2017-05-31')
          .chunks(size: :month, partial_first: true, partial_last: false)
      expect(chunks.size).to eq(1)
      expect(chunks[0].first.iso).to eq('2017-05-01')
      expect(chunks[0].last.iso).to eq('2017-05-31')
      chunks =
        Period.new('2017-05-01', '2017-05-31')
          .chunks(size: :month, partial_first: false, partial_last: true)
      expect(chunks.size).to eq(1)
      expect(chunks[0].first.iso).to eq('2017-05-01')
      expect(chunks[0].last.iso).to eq('2017-05-31')
      chunks =
        Period.new('2017-05-01', '2017-05-31')
          .chunks(size: :month, partial_first: true, partial_last: true)
      expect(chunks.size).to eq(1)
      expect(chunks[0].first.iso).to eq('2017-05-01')
      expect(chunks[0].last.iso).to eq('2017-05-31')
    end

    it 'chunks into semimonths' do
      chunks = Period.new('2009-12-25', '2013-01-10').chunks(size: :semimonth)
      expect(chunks.size).to eq(74)
      expect(chunks[0].first.iso).to eq('2009-12-25')
      expect(chunks[0].last.iso).to eq('2009-12-31')
      expect(chunks[1].first.iso).to eq('2010-01-01')
      expect(chunks[1].last.iso).to eq('2010-01-15')
      expect(chunks[2].first.iso).to eq('2010-01-16')
      expect(chunks[2].last.iso).to eq('2010-01-31')
      expect(chunks[3].first.iso).to eq('2010-02-01')
      expect(chunks[3].last.iso).to eq('2010-02-15')
      expect(chunks.last.first.iso).to eq('2013-01-01')
      expect(chunks.last.last.iso).to eq('2013-01-10')
    end

    it 'chunks into biweeks' do
      chunks = Period.new('2009-12-29', '2013-01-10').chunks(size: :biweek)
      expect(chunks.size).to be >= (26 * 3)
      expect(chunks[0].first.iso).to eq('2009-12-29')
      expect(chunks[0].last.iso).to eq('2010-01-02')
      expect(chunks[1].first.iso).to eq('2010-01-03')
      expect(chunks[1].last.iso).to eq('2010-01-16')
      expect(chunks[2].first.iso).to eq('2010-01-17')
      expect(chunks[2].last.iso).to eq('2010-01-30')
      expect(chunks.last.first.iso).to eq('2012-12-30')
      expect(chunks.last.last.iso).to eq('2013-01-10')
    end

    it 'chunks into weeks' do
      chunks = Period.new('2010-01-01', '2012-12-31').chunks(size: :week)
      expect(chunks.size).to be >= (52 * 3)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-01-02')
      expect(chunks[1].first.iso).to eq('2010-01-03')
      expect(chunks[1].last.iso).to eq('2010-01-09')
      expect(chunks[2].first.iso).to eq('2010-01-10')
      expect(chunks[2].last.iso).to eq('2010-01-16')
      expect(chunks[3].first.iso).to eq('2010-01-17')
      expect(chunks[3].last.iso).to eq('2010-01-23')
      expect(chunks.last.first.iso).to eq('2012-12-30')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'chunks into days' do
      chunks = Period.new('2012-12-28', '2012-12-31').chunks(size: :day)
      expect(chunks.size).to eq(4)
      expect(chunks[0].first.iso).to eq('2012-12-28')
      expect(chunks[0].last.iso).to eq('2012-12-28')
      expect(chunks[1].first.iso).to eq('2012-12-29')
      expect(chunks[1].last.iso).to eq('2012-12-29')
      expect(chunks[2].first.iso).to eq('2012-12-30')
      expect(chunks[2].last.iso).to eq('2012-12-30')
      expect(chunks.last.first.iso).to eq('2012-12-31')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'raises error for invalid chunk name' do
      expect {
        Period.new('2012-12-28', '2012-12-31').chunks(size: :wally)
      }.to raise_error(/unknown chunk size/)
    end

    it 'returns an empty array for too large a chunk and no partials allowed' do
      expect(Period.new('2012-12-01', '2012-12-31')
               .chunks(size: :bimonth,
                       partial_first: false,
                       partial_last: false)).to be_empty
    end

    it 'returns self for too large chunk if partials allowed' do
      pd = Period.new('2012-12-01', '2012-12-31')
      expect(pd.chunks(size: :bimonth, partial_first: true).first).to eq(pd)
      expect(pd.chunks(size: :bimonth, partial_last: true).first).to eq(pd)
    end

    it 'returns self for too small chunk if partials allowed' do
      pd = Period.new('2012-02-01', '2012-02-06')
      chunks = pd.chunks(size: :month, partial_first: true)
      expect(chunks.size).to eq(1)
      expect(chunks.first).to eq(pd)
      chunks = pd.chunks(size: :month, partial_last: true)
      expect(chunks.first).to eq(pd)
      expect(chunks.first).to eq(pd)
    end

    it 'includes a partial final chunk by default' do
      chunks = Period.new('2012-01-01', '2012-03-30').chunks(size: :month)
      expect(chunks.size).to eq(3)
    end

    it 'does not include a partial final chunk if partial_last false' do
      chunks = Period.new('2012-01-01', '2012-03-30')
                 .chunks(size: :month, partial_last: false)
      expect(chunks.size).to eq(2)
      expect(chunks.last.first).to eq(Date.parse('2012-02-01'))
      expect(chunks.last.last).to eq(Date.parse('2012-02-29'))
    end

    it 'includes a final chunk beyond end_date if round_up' do
      chunks = Period.new('2012-01-01', '2012-03-30')
                 .chunks(size: :month, round_up_last: true)
      expect(chunks.size).to eq(3)
      expect(chunks.last.first).to eq(Date.parse('2012-03-01'))
      expect(chunks.last.last).to eq(Date.parse('2012-03-31'))
    end

    it 'does not includes a partial initial chunk if partial_first false' do
      chunks = Period.new('2012-01-13', '2012-03-31').chunks(size: :month, partial_first: false)
      expect(chunks.size).to eq(2)
      expect(chunks[0].first).to eq(Date.parse('2012-02-01'))
      expect(chunks[0].last).to eq(Date.parse('2012-02-29'))
    end

    it 'includes a partial initial chunk by if partial_first true' do
      chunks = Period.new('2012-01-13', '2012-03-31')
                 .chunks(size: :month, partial_first: true)
      expect(chunks.size).to eq(3)
      expect(chunks[0].first).to eq(Date.parse('2012-01-13'))
      expect(chunks[0].last).to eq(Date.parse('2012-01-31'))
    end

    it 'determines its chunk_sym' do
      expect(Period.new('2013-01-01', '2013-12-31').chunk_sym).to eq(:year)
      expect(Period.new('2012-01-01', '2013-12-31').chunk_sym).not_to eq(:year)

      expect(Period.new('2013-01-01', '2013-06-30').chunk_sym).to eq(:half)
      expect(Period.new('2012-01-01', '2013-05-31').chunk_sym).not_to eq(:half)

      expect(Period.new('2013-04-01', '2013-06-30').chunk_sym).to eq(:quarter)
      expect(Period.new('2013-04-01', '2013-09-30').chunk_sym)
        .not_to eq(:quarter)

      expect(Period.new('2013-03-01', '2013-04-30').chunk_sym).to eq(:bimonth)
      expect(Period.new('2013-03-01', '2013-06-30').chunk_sym)
        .not_to eq(:bimonth)

      expect(Period.new('2013-04-01', '2013-04-30').chunk_sym).to eq(:month)
      expect(Period.new('2013-04-01', '2013-05-30').chunk_sym).not_to eq(:month)

      expect(Period.new('2013-05-16', '2013-05-31').chunk_sym).to eq(:semimonth)
      expect(Period.new('2013-05-16', '2013-06-30').chunk_sym)
        .not_to eq(:semimonth)

      expect(Period.new('2013-11-10', '2013-11-23').chunk_sym).to eq(:biweek)
      expect(Period.new('2013-11-04', '2013-11-24').chunk_sym).not_to eq(:biweek)

      expect(Period.new('2013-11-10', '2013-11-16').chunk_sym).to eq(:week)
      expect(Period.new('2013-11-11', '2013-11-24').chunk_sym).not_to eq(:week)

      expect(Period.new('2013-11-10', '2013-11-10').chunk_sym).to eq(:day)
      expect(Period.new('2013-11-10', '2013-11-11').chunk_sym).not_to eq(:day)

      expect(Period.new('2013-11-02', '2013-12-16').chunk_sym).to eq(:irregular)
    end

    it 'knows if it is a subset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(month.subset_of?(year)).to be true
      expect(year.subset_of?(year)).to be true
    end

    it 'knows if it is a proper subset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(month.proper_subset_of?(year)).to be true
      expect(year.proper_subset_of?(year)).to be false
    end

    it 'knows if it is a superset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(year.superset_of?(month)).to be true
      expect(year.superset_of?(year)).to be true
    end

    it 'knows if it is a proper superset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(year.proper_superset_of?(month)).to be true
      expect(year.proper_superset_of?(year)).to be false
    end

    it 'knows if it overlaps another period' do
      period1 = Period.parse('2013')
      period2 = Period.parse('2012-10', '2013-03')
      period3 = Period.parse('2014')
      expect(period1.overlaps?(period2)).to be true
      expect(period2.overlaps?(period1)).to be true
      expect(period1.overlaps?(period3)).to be false
    end

    it 'knows whether an array of periods have overlaps within it' do
      months = (1..12).to_a.map { |k| Period.parse("2013-#{k}") }
      year = Period.parse('2013')
      expect(year.overlaps_among?(months)).to be false
      months << Period.parse('2013-09-15', '2013-10-02')
      expect(year.overlaps_among?(months)).to be true
    end

    it 'knows whether an array of periods span it' do
      months = (1..12).to_a.map { |k| Period.parse("2013-#{k}") }
      year = Period.parse('2013')
      expect(year.spanned_by?(months)).to be true

      months = (2..12).to_a.map { |k| Period.parse("2013-#{k}") }
      expect(year.spanned_by?(months)).to be false
    end

    it 'knows its intersection with other period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(year & month).to eq(month)
      expect(month & year).to eq(month)
      # It should return a Period, not a Range
      expect((month & year).class).to eq(Period)
    end

    it 'aliases narrow_to to intersection' do
      period1 = Period.parse('2014')
      period2 = Period.new('2014-06-01', '2015-02-28')
      period3 = period1.narrow_to(period2)
      expect(period3.first).to eq(period2.first)
      expect(period3.last).to eq(period1.last)
    end

    it 'returns nil if no intersection' do
      year = Period.parse('2014')
      month = Period.parse('2013-05')
      expect(year & month).to be_nil
    end

    it 'knows its union with other period' do
      last_month = Period.parse('last_month')
      month = Period.parse('this_month')
      expect((last_month + month).first).to eq(last_month.first)
      expect((last_month + month).last).to eq(month.last)
      # It should return a Period, not a Range
      expect((last_month + month).class).to eq(Period)
      # Disjoint periods
      expect(Period.parse('2015-2Q') + Period.parse('2015-4Q')).to be_nil
    end

    it 'knows its differences with other period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      # NOTE: the difference operator returns an Array of Periods resulting
      # from removing other from self.
      expect((year - month).first)
        .to eq(Period.new(year.first, month.first - 1.day))
      expect((year - month).last)
        .to eq(Period.new(month.last + 1.day, year.last))
      # It should return an Array of Periods, not a Ranges
      (year - month).each do |p|
        expect(p.class).to eq(Period)
      end

      last_year = Period.parse('last_year')
      month = Period.parse('this_month')
      expect(last_year - month).to eq([last_year])
    end

    it 'finds gaps from an array of periods' do
      pp = Period.parse('2014-2Q')
      periods = [
        Period.parse('2013-11', '2013-12-20'),
        Period.parse('2014-01', '2014-04-20'),
        # Gap 2014-04-21 to 2014-04-30
        Period.parse('2014-05', '2014-05-11'),
        # Gap 2014-05-12 to 2014-05-24
        Period.parse('2014-05-25', '2014-07-11'),
        Period.parse('2014-09')
      ]
      gaps = pp.gaps(periods)
      expect(gaps.size).to eq(2)
      expect(gaps.first.first).to eq(Date.parse('2014-04-21'))
      expect(gaps.first.last).to eq(Date.parse('2014-04-30'))
      expect(gaps.last.first).to eq(Date.parse('2014-05-12'))
      expect(gaps.last.last).to eq(Date.parse('2014-05-24'))
    end

    it 'expands a date to a chunk' do
      # These should also exercise the chunk_containing methods, since they
      # are called by the this_chunk methods
      expect(Period.this_day.first).to eq(Date.current)
      expect(Period.this_day.last).to eq(Date.current)

      Period::CHUNKS.each do |chunk|
        next if chunk == :irregular

        expect(Period.send(:"this_#{chunk}").first)
          .to eq(Date.current.send(:"beginning_of_#{chunk}").to_date)
        expect(Period.send(:"this_#{chunk}").last)
          .to eq(Date.current.send(:"end_of_#{chunk}").to_date)
      end
    end

    it 'expands a date to an arbitrary chunk' do
      date = Date.parse('2020-03-16')
      expect(Period.chunk_containing(date, :week))
        .to eq(Period.week_containing(date))
      expect(Period.chunk_containing(date, :month))
        .to eq(Period.month_containing(date))
      expect(Period.chunk_containing(date, :quarter))
        .to eq(Period.quarter_containing(date))
    end
  end
end
