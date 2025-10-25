# frozen_string_literal: true

require 'spec_helper'

describe Date do
  it 'expands to chunk periods' do
    expect(Date.parse('2013-07-04').expand_to_period(:year))
      .to eq Period.new('2013-01-01', '2013-12-31')
    expect(Date.parse('2013-07-04').expand_to_period(:half))
      .to eq Period.new('2013-07-01', '2013-12-31')
    expect(Date.parse('2013-07-04').expand_to_period(:quarter))
      .to eq Period.new('2013-07-01', '2013-09-30')
    expect(Date.parse('2013-07-04').expand_to_period(:bimonth))
      .to eq Period.new('2013-07-01', '2013-08-31')
    expect(Date.parse('2013-07-04').expand_to_period(:month))
      .to eq Period.new('2013-07-01', '2013-07-31')
    expect(Date.parse('2013-07-04').expand_to_period(:semimonth))
      .to eq Period.new('2013-07-01', '2013-07-15')
    expect(Date.parse('2013-07-04').expand_to_period(:biweek))
      .to eq Period.new('2013-06-24', '2013-07-07')
    expect(Date.parse('2013-07-04').expand_to_period(:week))
      .to eq Period.new('2013-07-01', '2013-07-07')
    expect(Date.parse('2013-07-04').expand_to_period(:day))
      .to eq Period.new('2013-07-04', '2013-07-04')
  end
end
