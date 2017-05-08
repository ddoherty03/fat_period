require 'spec_helper'

describe Period do
  before :each do
    # Pretend it is this date. Not at beg or end of year, quarter,
    # month, or week.  It is a Wednesday
    allow(Date).to receive_messages(today: Date.parse('2012-07-18'))
    allow(Date).to receive_messages(current: Date.parse('2012-07-18'))
  end

  describe 'initialization' do
    it 'should be initializable with date strings' do
      expect(Period.new('2013-01-01', '2013-12-13')).to be_instance_of Period
    end

    it 'should be initializable with Dates' do
      expect(Period.new('2013-01-01', '2013-12-13'))
        .to be_instance_of Period
    end

    it 'should raise a ArgumentError if last > first' do
      expect {
        Period.new('2013-01-01', '2012-12-31')
      }.to raise_error ArgumentError
    end

    it 'should raise a ArgumentError if initialized with invalid date string' do
      expect {
        Period.new('2013-01-01', '2013-12-32')
      }.to raise_error ArgumentError
      expect {
        Period.new('2013-13-01', '2013-12-31')
      }.to raise_error ArgumentError
    end

    it 'should raise a ArgumentError if initialized otherwise' do
      expect {
        Period.new(2013 - 1 - 1, 2013 - 12 - 31)
      }.to raise_error ArgumentError
    end
  end

  describe 'class methods' do
    it 'should be able to parse a period phrase' do
      pd = Period.parse_phrase('from this_year')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from 2012-07 to 2012')
      expect(pd.first).to eq(Date.parse('2012-07-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from 1H')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-06-30'))

      pd = Period.parse_phrase('to 2H')
      expect(pd.first).to eq(Date.parse('2012-07-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from 2Q')
      expect(pd.first).to eq(Date.parse('2012-04-01'))
      expect(pd.last).to eq(Date.parse('2012-06-30'))

      pd = Period.parse_phrase('to 3Q')
      expect(pd.first).to eq(Date.parse('2012-07-01'))
      expect(pd.last).to eq(Date.parse('2012-09-30'))

      pd = Period.parse_phrase('to 2012-2Q')
      expect(pd.first).to eq(Date.parse('2012-04-01'))
      expect(pd.last).to eq(Date.parse('2012-06-30'))

      pd = Period.parse_phrase('from 2012-1Q')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-03-31'))

      pd = Period.parse_phrase('from 2H')
      expect(pd.first).to eq(Date.parse('2012-07-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('to 1H')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-06-30'))

      pd = Period.parse_phrase('to 2012-2H')
      expect(pd.first).to eq(Date.parse('2012-07-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from 2012-1H')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-06-30'))

      pd = Period.parse_phrase('to 2012')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from 2012')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('2012')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('this_year')
      expect(pd.first).to eq(Date.parse('2012-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from last_year to this_year')
      expect(pd.first).to eq(Date.parse('2011-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))

      pd = Period.parse_phrase('from last_year to this_year')
      expect(pd.first).to eq(Date.parse('2011-01-01'))
      expect(pd.last).to eq(Date.parse('2012-12-31'))
    end

    it 'should return nil when parsing never' do
      expect(Period.parse('never')).to be_nil
    end

    it 'should know how to parse a pair of date specs' do
      expect(Period.parse('2014-3Q').first).to eq Date.parse('2014-07-01')
      expect(Period.parse('2014-3Q').last).to eq Date.parse('2014-09-30')
      expect(Period.parse('2014-3Q').last).to eq Date.parse('2014-09-30')
    end

    it 'should know what the valid chunk syms are' do
      expect(Period.chunk_syms.size).to eq(10)
    end

    it 'should know the days in a chunk sym' do
      expect(Period.chunk_sym_to_days(:year)).to eq(365)
      expect(Period.chunk_sym_to_days(:quarter)).to eq(90)
      expect(Period.chunk_sym_to_days(:bimonth)).to eq(60)
      expect(Period.chunk_sym_to_days(:month)).to eq(30)
      expect(Period.chunk_sym_to_days(:semimonth)).to eq(15)
      expect(Period.chunk_sym_to_days(:biweek)).to eq(14)
      expect(Period.chunk_sym_to_days(:week)).to eq(7)
      expect(Period.chunk_sym_to_days(:day)).to eq(1)
      expect(Period.chunk_sym_to_days(:irregular)).to eq(30)
      expect {
        Period.chunk_sym_to_days(:eon)
      }.to raise_error ArgumentError
    end

    it 'should know the maximum days in a chunk sym' do
      expect(Period.chunk_sym_to_max_days(:year)).to eq(366)
      expect(Period.chunk_sym_to_max_days(:quarter)).to eq(92)
      expect(Period.chunk_sym_to_max_days(:bimonth)).to eq(62)
      expect(Period.chunk_sym_to_max_days(:month)).to eq(31)
      expect(Period.chunk_sym_to_max_days(:semimonth)).to eq(16)
      expect(Period.chunk_sym_to_max_days(:biweek)).to eq(14)
      expect(Period.chunk_sym_to_max_days(:week)).to eq(7)
      expect(Period.chunk_sym_to_max_days(:day)).to eq(1)
      expect { Period.chunk_sym_to_max_days(:irregular) }
        .to raise_error ArgumentError
      expect {
        Period.chunk_sym_to_days(:eon)
      }.to raise_error ArgumentError
    end

    it 'should know the chunk sym for given days but only :year, :quarter, :month' do
      (356..376).each { |d| expect(Period.days_to_chunk_sym(d)).to eq(:year) }
      (180..183).each { |d| expect(Period.days_to_chunk_sym(d)).to eq(:half) }
      (86..96).each { |d| expect(Period.days_to_chunk_sym(d)).to eq(:quarter) }
      (28..31).each { |d| expect(Period.days_to_chunk_sym(d)).to eq(:month) }
      expect(Period.days_to_chunk_sym(7)).to eq(:week)
      expect(Period.days_to_chunk_sym(1)).to eq(:day)
    end

    it 'should know what to call a chunk based on its size' do
      expect(Period.new('2011-01-01', '2011-12-31').chunk_name).to eq('Year')
      expect(Period.new('2011-01-01', '2011-06-30').chunk_name).to eq('Half')
      expect(Period.new('2011-01-01', '2011-03-31').chunk_name).to eq('Quarter')
      expect(Period.new('2011-01-01', '2011-02-28').chunk_name)
        .to eq('Bi-month')
      expect(Period.new('2011-01-01', '2011-01-31').chunk_name).to eq('Month')
      expect(Period.new('2011-01-01', '2011-01-15').chunk_name)
        .to eq('Semi-month')
      expect(Period.new('2011-01-09', '2011-01-22').chunk_name).to eq('Bi-week')
      expect(Period.new('2011-01-01', '2011-01-07').chunk_name).to eq('Week')
      expect(Period.new('2011-01-01', '2011-01-01').chunk_name).to eq('Day')
      expect(Period.new('2011-01-01', '2011-01-21').chunk_name).to eq('Period')
      # Only size matters, not whether the period begins and ends on
      # calendar unit boundaries.
      expect(Period.new('2011-02-11', '2011-03-10').chunk_name).to eq('Month')
    end
  end

  describe 'sorting' do
    it 'should sort by first, then size' do
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

    it 'should return nil if comparing incomparables' do
      pd = Period.new('2012-08-01', '2012-08-31')
      rg = (Date.parse('2012-08-01')..Date.parse('2012-08-31'))
      expect(pd <=> rg).to be_nil
    end
  end

  describe 'instance methods' do
    it 'should be able to set first' do
      pp = Period.new('2014-12-07', '2014-12-17')
      pp.first = Date.parse('2014-12-01')
      expect(pp.first).to eq Date.parse('2014-12-01')
    end

    it 'should be able to set last' do
      pp = Period.new('2014-12-07', '2014-12-17')
      pp.last = Date.parse('2014-12-31')
      expect(pp.last).to eq Date.parse('2014-12-31')
    end

    it 'should not be able to set first > last' do
      pp = Period.new('2014-12-07', '2014-12-17')
      expect {
        pp.first = Date.parse('2014-12-31')
      }.to raise_error ArgumentError
    end

    it 'should not be able to set last < first' do
      pp = Period.new('2014-12-07', '2014-12-17')
      expect {
        pp.last = Date.parse('2014-12-01')
      }.to raise_error ArgumentError
    end

    it 'should be able to compare for equality' do
      pp1 = Period.new('2013-01-01', '2013-12-31')
      pp2 = Period.new('2013-01-01', '2013-12-31')
      pp3 = Period.new('2013-01-01', '2013-12-30')
      expect((pp1 == pp2)).to be true
      expect((pp1 == pp3)).to_not be true
      expect((pp1 != pp3)).to be true
    end

    it 'should be able to convert into a Range' do
      pp = Period.new('2013-01-01', '2013-12-31')
      rr = Period.new('2013-01-01', '2013-12-31').to_range
      expect(rr).to be_instance_of Range
      expect(rr.first).to eq(pp.first)
      expect(rr.last).to eq(pp.last)
    end

    it 'should be able to tell if it contains a date' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect(pp.contains?(Date.parse('2013-01-01'))).to be true
      expect(pp.contains?(Date.parse('2013-07-04'))).to be true
      expect(pp.contains?(Date.parse('2013-12-31'))).to be true
      expect(pp.contains?(Date.parse('2012-07-04'))).to be false
    end

    it 'should raise an error if contains? arg is not a date' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect {
        pp.contains?(Period.new('2013-06-01', '2013-06-30'))
      }.to raise_error(/must be a Date/)

      # But not if argument can be converted to date with to_date
      expect {
        pp.contains?(Time.now)
      }.not_to raise_error
    end

    it 'should be able to tell if it contains a date with ===' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect(pp === Date.parse('2013-01-01')).to be true
      expect(pp === Date.parse('2013-07-04')).to be true
      expect(pp === Date.parse('2013-12-31')).to be true
      expect(pp === Date.parse('2012-07-04')).to be false
    end

    it 'should be able to convert itself to days' do
      expect(Period.new('2013-01-01', '2013-01-01').days).to eq(1)
      expect(Period.new('2013-01-01', '2013-12-31').days).to eq(365)
    end

    it 'should be able to convert itself to fractional months' do
      expect(Period.new('2013-01-01', '2013-01-01').months).to eq(1 / 30.436875)
      expect(Period.new('2013-01-01', '2013-12-31').months(30)).to eq(365 / 30.0)
      expect(Period.new('2013-01-01', '2013-06-30').months.round(0)).to eq(6.0)
    end

    it 'should be able to convert itself to fractional years' do
      expect(Period.new('2013-01-01', '2013-01-01').years).to eq(1 / 365.2425)
      expect(Period.new('2013-01-01', '2013-12-31').years(365)).to eq(1.0)
      expect(Period.new('2013-01-01', '2013-06-30').years.round(1)).to eq(0.5)
    end

    it 'should be able to enumerate its days' do
      Period.parse('2014-12').each do |dy|
        expect(dy.class).to eq Date
      end
    end

    it 'should be able to return the trading days within period' do
      tds = Period.parse('2014-12').trading_days
      expect(tds.count).to eq(22)
    end

    it 'should know its size' do
      pp = Period.new('2013-01-01', '2013-12-31')
      expect(pp.size).to eq 365
      expect(pp.length).to eq 365
    end

    it 'should implement the each method' do
      pp = Period.new('2013-12-01', '2013-12-31')
      pp.map(&:iso)
        .each { |s| expect(s).to match(/\d{4}-\d\d-\d\d/) }
    end

    it 'should be able to make a concise period string' do
      expect(Period.new('2013-01-01', '2013-12-31').to_s).to eq('2013')
      expect(Period.new('2013-04-01', '2013-06-30').to_s).to eq('2013-2Q')
      expect(Period.new('2013-03-01', '2013-03-31').to_s).to eq('2013-03')
      expect(Period.new('2013-03-11', '2013-10-31').to_s)
        .to eq('2013-03-11 to 2013-10-31')
    end

    it 'should be able to make a TeX string' do
      expect(Period.new('2013-01-01', '2013-12-31').tex_quote)
        .to eq('2013-01-01--2013-12-31')
    end

    # Note in the following that first period must begin within self.
    it 'should be able to chunk into years' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :year)
      expect(chunks.size).to eq(3)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-12-31')
      expect(chunks[1].first.iso).to eq('2011-01-01')
      expect(chunks[1].last.iso).to eq('2011-12-31')
      expect(chunks[2].first.iso).to eq('2012-01-01')
      expect(chunks[2].last.iso).to eq('2012-12-31')
    end

    it 'should be able to chunk into halves' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :half)
      expect(chunks.size).to eq(6)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-06-30')
      expect(chunks[1].first.iso).to eq('2010-07-01')
      expect(chunks[1].last.iso).to eq('2010-12-31')
      expect(chunks[2].first.iso).to eq('2011-01-01')
      expect(chunks[2].last.iso).to eq('2011-06-30')
      expect(chunks.last.first.iso).to eq('2012-07-01')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'should be able to chunk into quarters' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :quarter)
      expect(chunks.size).to eq(12)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-03-31')
      expect(chunks[1].first.iso).to eq('2010-04-01')
      expect(chunks[1].last.iso).to eq('2010-06-30')
      expect(chunks[2].first.iso).to eq('2010-07-01')
      expect(chunks[2].last.iso).to eq('2010-09-30')
      expect(chunks.last.first.iso).to eq('2012-10-01')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'should be able to chunk into bimonths' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :bimonth)
      expect(chunks.size).to eq(18)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-02-28')
      expect(chunks[1].first.iso).to eq('2010-03-01')
      expect(chunks[1].last.iso).to eq('2010-04-30')
      expect(chunks[2].first.iso).to eq('2010-05-01')
      expect(chunks[2].last.iso).to eq('2010-06-30')
      expect(chunks.last.first.iso).to eq('2012-11-01')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'should be able to chunk into months' do
      chunks = Period.new('2009-12-15', '2013-01-10').chunks(size: :month)
      expect(chunks.size).to eq(36)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-01-31')
      expect(chunks[1].first.iso).to eq('2010-02-01')
      expect(chunks[1].last.iso).to eq('2010-02-28')
      expect(chunks[2].first.iso).to eq('2010-03-01')
      expect(chunks[2].last.iso).to eq('2010-03-31')
      expect(chunks.last.first.iso).to eq('2012-12-01')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'should be able to chunk into semimonths' do
      chunks = Period.new('2009-12-25', '2013-01-10').chunks(size: :semimonth)
      expect(chunks.size).to eq(72)
      expect(chunks[0].first.iso).to eq('2010-01-01')
      expect(chunks[0].last.iso).to eq('2010-01-15')
      expect(chunks[1].first.iso).to eq('2010-01-16')
      expect(chunks[1].last.iso).to eq('2010-01-31')
      expect(chunks[2].first.iso).to eq('2010-02-01')
      expect(chunks[2].last.iso).to eq('2010-02-15')
      expect(chunks.last.first.iso).to eq('2012-12-16')
      expect(chunks.last.last.iso).to eq('2012-12-31')
    end

    it 'should be able to chunk into biweeks' do
      chunks = Period.new('2009-12-29', '2013-01-10').chunks(size: :biweek)
      expect(chunks.size).to be >= (26 * 3)
      expect(chunks[0].first.iso).to eq('2010-01-04')
      expect(chunks[0].last.iso).to eq('2010-01-17')
      expect(chunks[1].first.iso).to eq('2010-01-18')
      expect(chunks[1].last.iso).to eq('2010-01-31')
      expect(chunks[2].first.iso).to eq('2010-02-01')
      expect(chunks[2].last.iso).to eq('2010-02-14')
      expect(chunks.last.first.iso).to eq('2012-12-17')
      expect(chunks.last.last.iso).to eq('2012-12-30')
    end

    it 'should be able to chunk into weeks' do
      chunks = Period.new('2010-01-01', '2012-12-31').chunks(size: :week)
      expect(chunks.size).to be >= (52 * 3)
      expect(chunks[0].first.iso).to eq('2010-01-04')
      expect(chunks[0].last.iso).to eq('2010-01-10')
      expect(chunks[1].first.iso).to eq('2010-01-11')
      expect(chunks[1].last.iso).to eq('2010-01-17')
      expect(chunks[2].first.iso).to eq('2010-01-18')
      expect(chunks[2].last.iso).to eq('2010-01-24')
      expect(chunks.last.first.iso).to eq('2012-12-24')
      expect(chunks.last.last.iso).to eq('2012-12-30')
    end

    it 'should be able to chunk into days' do
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

    it 'should raise error for invalid chunk name' do
      expect {
        Period.new('2012-12-28', '2012-12-31').chunks(size: :wally)
      }.to raise_error /unknown chunk sym/
    end

    it 'should raise error for too large a chunk and no partials allowed' do
      expect {
        Period.new('2012-12-01', '2012-12-31').
          chunks(size: :bimonth, partial_first: false, partial_last: false)
      }.to raise_error /longer than/
    end

    it 'should return period itself for too large chunk if partials allowed' do
      pd = Period.new('2012-12-01', '2012-12-31')
      expect(pd.chunks(size: :bimonth, partial_first: true).first).to eq(pd)
      expect(pd.chunks(size: :bimonth, partial_last: true).first).to eq(pd)
    end

    it 'should not include a partial final chunk by default' do
      chunks = Period.new('2012-01-01', '2012-03-30').chunks(size: :month)
      expect(chunks.size).to eq(2)
    end

    it 'should include a partial final chunk if partial_last' do
      chunks = Period.new('2012-01-01', '2012-03-30')
                 .chunks(size: :month, partial_last: true)
      expect(chunks.size).to eq(3)
      expect(chunks.last.first).to eq(Date.parse('2012-03-01'))
      expect(chunks.last.last).to eq(Date.parse('2012-03-30'))
    end

    it 'should include a final chunk beyond end_date if round_up' do
      chunks = Period.new('2012-01-01', '2012-03-30')
                 .chunks(size: :month, round_up_last: true)
      expect(chunks.size).to eq(3)
      expect(chunks.last.first).to eq(Date.parse('2012-03-01'))
      expect(chunks.last.last).to eq(Date.parse('2012-03-31'))
    end

    it 'should not include a partial initial chunk by default' do
      chunks = Period.new('2012-01-13', '2012-03-31').chunks(size: :month)
      expect(chunks.size).to eq(2)
      expect(chunks[0].first).to eq(Date.parse('2012-02-01'))
      expect(chunks[0].last).to eq(Date.parse('2012-02-29'))
    end

    it 'should include a partial initial chunk by if partial_first' do
      chunks = Period.new('2012-01-13', '2012-03-31')
                 .chunks(size: :month, partial_first: true)
      expect(chunks.size).to eq(3)
      expect(chunks[0].first).to eq(Date.parse('2012-01-13'))
      expect(chunks[0].last).to eq(Date.parse('2012-01-31'))
    end

    it 'should include a final chunk beyond end_date if round_up' do
      chunks = Period.new('2012-01-01', '2012-03-30')
                 .chunks(size: :month, round_up_last: true)
      expect(chunks.size).to eq(3)
      expect(chunks.last.first).to eq(Date.parse('2012-03-01'))
      expect(chunks.last.last).to eq(Date.parse('2012-03-31'))
    end

    it 'should be able to determine its chunk_sym' do
      expect(Period.new('2013-01-01', '2013-12-31').chunk_sym).to eq(:year)
      expect(Period.new('2012-01-01', '2013-12-31').chunk_sym).to_not eq(:year)

      expect(Period.new('2013-01-01', '2013-06-30').chunk_sym).to eq(:half)
      expect(Period.new('2012-01-01', '2013-05-31').chunk_sym).to_not eq(:half)

      expect(Period.new('2013-04-01', '2013-06-30').chunk_sym).to eq(:quarter)
      expect(Period.new('2013-04-01', '2013-09-30').chunk_sym)
        .to_not eq(:quarter)

      expect(Period.new('2013-03-01', '2013-04-30').chunk_sym).to eq(:bimonth)
      expect(Period.new('2013-03-01', '2013-06-30').chunk_sym)
        .to_not eq(:bimonth)

      expect(Period.new('2013-04-01', '2013-04-30').chunk_sym).to eq(:month)
      expect(Period.new('2013-04-01', '2013-05-30').chunk_sym).to_not eq(:month)

      expect(Period.new('2013-05-16', '2013-05-31').chunk_sym).to eq(:semimonth)
      expect(Period.new('2013-05-16', '2013-06-30').chunk_sym)
        .to_not eq(:semimonth)

      expect(Period.new('2013-11-04', '2013-11-17').chunk_sym).to eq(:biweek)
      expect(Period.new('2013-11-04', '2013-11-24').chunk_sym)
        .to_not eq(:biweek)

      expect(Period.new('2013-11-11', '2013-11-17').chunk_sym).to eq(:week)
      expect(Period.new('2013-11-11', '2013-11-24').chunk_sym).to_not eq(:week)

      expect(Period.new('2013-11-10', '2013-11-10').chunk_sym).to eq(:day)
      expect(Period.new('2013-11-10', '2013-11-11').chunk_sym).to_not eq(:day)

      expect(Period.new('2013-11-02', '2013-12-16').chunk_sym).to eq(:irregular)
    end

    it 'should know if it\'s a subset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(month.subset_of?(year)).to be true
      expect(year.subset_of?(year)).to be true
    end

    it 'should know if it\'s a proper subset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(month.proper_subset_of?(year)).to be true
      expect(year.proper_subset_of?(year)).to be false
    end

    it 'should know if it\'s a superset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(year.superset_of?(month)).to be true
      expect(year.superset_of?(year)).to be true
    end

    it 'should know if it\'s a proper superset of another period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(year.proper_superset_of?(month)).to be true
      expect(year.proper_superset_of?(year)).to be false
    end

    it 'should know if it overlaps another period' do
      period1 = Period.parse('2013')
      period2 = Period.parse('2012-10', '2013-03')
      period3 = Period.parse('2014')
      expect(period1.overlaps?(period2)).to be true
      expect(period2.overlaps?(period1)).to be true
      expect(period1.overlaps?(period3)).to be false
    end

    it 'should know whether an array of periods have overlaps within it' do
      months = (1..12).to_a.map { |k| Period.parse("2013-#{k}") }
      year = Period.parse('2013')
      expect(year.has_overlaps_within?(months)).to be false
      months << Period.parse('2013-09-15', '2013-10-02')
      expect(year.has_overlaps_within?(months)).to be true
    end

    it 'should know whether an array of periods span it' do
      months = (1..12).to_a.map { |k| Period.parse("2013-#{k}") }
      year = Period.parse('2013')
      expect(year.spanned_by?(months)).to be true

      months = (2..12).to_a.map { |k| Period.parse("2013-#{k}") }
      expect(year.spanned_by?(months)).to be false
    end

    it 'should know its intersection with other period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      expect(year & month).to eq(month)
      expect(month & year).to eq(month)
      # It should return a Period, not a Range
      expect((month & year).class).to eq(Period)
    end

    it 'should alias narrow_to to intersection' do
      period1 = Period.parse('2014')
      period2 = Period.new('2014-06-01', '2015-02-28')
      period3 = period1.narrow_to(period2)
      expect(period3.first).to eq(period2.first)
      expect(period3.last).to eq(period1.last)
    end

    it 'should return nil if no intersection' do
      year = Period.parse('2014')
      month = Period.parse('2013-05')
      expect(year & month).to be_nil
    end

    it 'should know its union with other period' do
      last_month = Period.parse('last_month')
      month = Period.parse('this_month')
      expect((last_month + month).first).to eq(last_month.first)
      expect((last_month + month).last).to eq(month.last)
      # It should return a Period, not a Range
      expect((last_month + month).class).to eq(Period)
    end

    it 'should know its differences with other period' do
      year = Period.parse('this_year')
      month = Period.parse('this_month')
      # Note: the difference operator returns an Array of Periods resulting
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

    it 'should be able to find gaps from an array of periods' do
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
  end
end
