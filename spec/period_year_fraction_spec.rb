# frozen_string_literal: true

require 'spec_helper'

describe Period do
  describe '#freq_per_year' do
    {
      365 => 1,
      182 => 2,
      91 => 4,
      61 => 6,
      31 => 12,
      15 => 24,
      14 => 26,
      7 => 52,
      1 => 365
    }.each do |days, frequency|
      it "infers #{frequency} payments for #{days} days" do
        first = Date.new(2023, 1, 1)
        expect(Period.new(first, first + days - 1).freq_per_year).to eq(frequency)
      end
    end

    it 'uses 366 for daily payments in a leap year' do
      expect(Period.new('2024-01-01', '2024-01-01').freq_per_year).to eq(366)
    end

    it 'rejects indeterminate frequency' do
      expect { Period.new('2023-01-01', '2023-01-03').freq_per_year }
        .to raise_error(ArgumentError, /indeterminate/)
    end
  end

  describe '#year_fraction' do
    def fraction(first, settlement, convention, last: settlement, **options)
      Period.new(first, last).year_fraction(settlement, convention: convention, **options)
    end

    it 'defaults to US 30/360 and returns a decimal' do
      period = Period.new('2023-02-28', '2023-03-31')
      result = period.year_fraction('2023-03-31')
      expect(result).to be_a(BigDecimal)
      expect(result).to eq(BigDecimal(30) / 360)
      expect(result).to eq(period.year_fraction('2023-03-31', convention: 1))
      expect(period.year_fraction('2023-03-31', convention: 0)).to eq(BigDecimal(33) / 360)
    end

    [0, 1, 2, 3].each do |convention|
      it "adjusts month ends for convention #{convention}" do
        expect(fraction('2023-01-31', '2023-03-31', convention)).to eq(BigDecimal(60) / 360)
      end
    end

    it 'distinguishes Bond, US, European, and ISDA February rules' do
      [33, 30, 32, 30].each_with_index do |days, convention|
        expect(fraction('2023-02-28', '2023-03-31', convention)).to eq(BigDecimal(days) / 360)
      end
      expect(fraction('2023-02-28', '2023-03-31', 1, eom: false)).to eq(BigDecimal(33) / 360)
      expect(fraction('2023-02-28', '2024-02-29', 1)).to eq(1)
    end

    # Expected adjusted day counts, in order: Bond, US, European, ISDA.
    # Keep these explicit so the expectations do not reproduce the implementation.
    [
      ['2023-01-15', '2023-03-15', [60, 60, 60, 60]],
      ['2023-01-29', '2023-03-31', [62, 62, 61, 61]],
      ['2023-01-30', '2023-03-31', [60, 60, 60, 60]],
      ['2023-01-31', '2023-03-29', [59, 59, 59, 59]],
      ['2023-01-31', '2023-02-28', [28, 28, 28, 30]],
      ['2024-01-31', '2024-02-28', [28, 28, 28, 28]],
      ['2024-01-31', '2024-02-29', [29, 29, 29, 30]],
      ['2023-02-28', '2023-03-15', [17, 15, 17, 15]],
      ['2024-02-28', '2024-03-31', [33, 33, 32, 32]],
      ['2024-02-29', '2024-03-31', [32, 30, 31, 30]],
      ['2023-02-28', '2024-02-29', [361, 360, 361, 360]],
      ['2024-02-29', '2025-02-28', [359, 360, 359, 360]],
      ['2023-04-30', '2023-05-31', [30, 30, 30, 30]],
      ['2023-12-29', '2024-01-31', [32, 32, 31, 31]]
    ].each do |first, settlement, counts|
      counts.each_with_index do |days, convention|
        it "counts #{days} adjusted days from #{first} to #{settlement} for convention #{convention}" do
          expect(fraction(first, settlement, convention)).to eq(BigDecimal(days) / 360)
        end
      end
    end

    it 'disables both February rules for US when eom is false' do
      expect(fraction('2023-02-28', '2024-02-29', 1, eom: false)).to eq(BigDecimal(361) / 360)
      expect(fraction('2024-02-29', '2025-02-28', 1, eom: false)).to eq(BigDecimal(359) / 360)
      expect(fraction('2023-01-30', '2023-03-31', 1, eom: false)).to eq(BigDecimal(60) / 360)
    end

    [
      ['2022-08-31', '2023-02-28', '2023-02-28', 178],
      ['2022-08-31', '2023-02-28', '2023-08-31', 180],
      ['2023-08-31', '2024-02-29', '2024-08-31', 180],
      ['2023-04-30', '2023-05-31', '2023-05-31', 30],
      ['2023-08-31', '2024-02-28', '2024-02-28', 178]
    ].each do |first, settlement, maturity, days|
      it "applies the ISDA maturity exception only to February month end: #{settlement}, maturity #{maturity}" do
        expect(fraction(first, settlement, 3, maturity_date: maturity)).to eq(BigDecimal(days) / 360)
      end
    end

    it 'preserves February maturity dates for ISDA, including string input' do
      expect(fraction('2023-08-31', '2024-02-29', 3)).to eq(BigDecimal('0.5'))
      ['2024-02-29', Date.new(2024, 2, 29)].each do |maturity|
        expect(fraction('2023-08-31', '2024-02-29', 3, maturity_date: maturity))
          .to eq(BigDecimal(179) / 360)
      end
    end

    it 'calculates partial and full regular ICMA coupons' do
      expect(fraction('2024-01-01', '2024-04-01', 4, last: '2024-07-01')).to eq(BigDecimal('0.25'))
      expect(fraction('2024-01-01', '2024-07-01', 4)).to eq(BigDecimal('0.5'))
      expect(fraction('2023-01-01', '2023-02-01', 4)).to eq(BigDecimal(1) / 12)
    end

    it 'infers short ICMA coupon frequencies from elapsed days' do
      { 1 => 366, 7 => 52, 14 => 26, 15 => 24 }.each do |days, frequency|
        first = Date.new(2024, 1, 1)
        expect(fraction(first, first + days, 4)).to eq(BigDecimal(1) / frequency)
      end
    end

    [
      ['2023-01-01', '2023-02-01', '2023-07-01', 31, 362],
      ['2023-07-01', '2023-08-01', '2024-01-01', 31, 368],
      ['2023-02-01', '2023-02-15', '2023-03-01', 14, 336],
      ['2024-02-01', '2024-02-15', '2024-03-01', 14, 348],
      ['2023-12-01', '2024-01-01', '2024-03-01', 31, 364],
      ['2024-01-01', '2024-07-01', '2025-01-01', 182, 366]
    ].each do |first, settlement, last, days, denominator|
      it "uses the actual ICMA coupon length from #{first} to #{last}" do
        period = Period.new(first, last)
        expect(period.year_fraction(settlement, convention: 4)).to eq(BigDecimal(days) / denominator)
      end
    end

    # Boundary values for the documented +/-10% length tolerance (rounded down).
    # These pin down the inference policy, not support for irregular ICMA schedules.
    [[25, 34, 12], [53, 68, 6], [81, 101, 4], [162, 201, 2], [328, 402, 1]].each do |lower, upper, frequency|
      [lower, upper].each do |days|
        it "accepts the ICMA frequency tolerance boundary of #{days} elapsed days" do
          first = Date.new(2023, 1, 1)
          period = Period.new(first, first + days)
          expect(period.year_fraction(first + 1, convention: 4)).to eq(BigDecimal(1) / (frequency * days))
        end
      end

      [lower - 1, upper + 1].each do |days|
        it "rejects an indeterminate ICMA frequency at #{days} elapsed days" do
          first = Date.new(2023, 1, 1)
          period = Period.new(first, first + days)
          expect { period.year_fraction(first + 1, convention: 4) }.to raise_error(ArgumentError, /indeterminate/)
        end
      end
    end

    it 'splits ISDA at year boundaries and stops at settlement' do
      result = fraction('2023-12-31', '2024-01-02', 5, last: '2024-06-30')
      expect(result).to eq(BigDecimal(1) / 365 + BigDecimal(1) / 366)
      expect(fraction('2023-01-01', '2025-01-01', 5)).to eq(2)
      expect(fraction('2024-02-28', '2024-03-01', 5)).to eq(BigDecimal(2) / 366)
    end

    { 6 => 365, 7 => 360, 8 => 364 }.each do |convention, denominator|
      it "uses actual days over #{denominator} without requiring a regular period" do
        expect(fraction('2024-02-28', '2024-03-01', convention)).to eq(BigDecimal(2) / denominator)
      end
    end

    it 'uses the elapsed annual coupon interval for Actual/365L' do
      expect(fraction('2023-07-01', '2023-08-01', 9, last: '2024-07-01')).to eq(BigDecimal(31) / 365)
      expect(fraction('2022-07-01', '2022-08-01', 9, last: '2023-07-01')).to eq(BigDecimal(31) / 365)
      expect(fraction('2023-02-28', '2024-02-29', 9)).to eq(1)
      expect(fraction('2024-02-29', '2025-02-28', 9)).to eq(1)
    end

    it 'uses the settlement year for nonannual Actual/365L' do
      expect(fraction('2023-10-01', '2023-11-01', 9, last: '2024-04-01')).to eq(BigDecimal(31) / 365)
      expect(fraction('2024-10-01', '2024-11-01', 9, last: '2025-04-01')).to eq(BigDecimal(31) / 366)
    end

    it 'calculates AFB whole years and the residual leap-year fraction' do
      expect(fraction('2023-01-01', '2025-01-01', 10)).to eq(2)
      expect(fraction('2024-02-28', '2024-03-01', 10)).to eq(BigDecimal(2) / 366)
      expect(fraction('2024-02-29', '2025-02-28', 10)).to eq(1)
      expect(fraction('2024-02-28', '2025-02-28', 10)).to eq(1 + BigDecimal(1) / 365)
      expect(fraction('2023-12-31', '2025-07-01', 10)).to eq(1 + BigDecimal(183) / 366)
    end

    # AFB includes February 29 at the start but excludes it at the residual end.
    # Whole years use the documented ISDA/QuantLib backward February adjustment.
    [
      ['2024-02-28', '2024-02-29', 0, 1, 365],
      ['2024-02-29', '2024-03-01', 0, 1, 366],
      ['2023-03-01', '2024-02-29', 0, 365, 365],
      ['2024-02-28', '2026-02-28', 2, 1, 365],
      ['2004-02-29', '2012-02-28', 8, 0, 365],
      ['2003-03-01', '2012-02-29', 8, 365, 365],
      ['2000-02-28', '2000-03-01', 0, 2, 366],
      ['2100-02-28', '2100-03-01', 0, 1, 365]
    ].each do |first, settlement, years, days, denominator|
      it "handles the AFB leap boundary from #{first} to #{settlement}" do
        expect(fraction(first, settlement, 10)).to eq(years + BigDecimal(days) / denominator)
      end
    end

    (0..10).each do |convention|
      it "returns decimal zero for equal dates with convention #{convention}" do
        result = fraction('2024-02-29', '2024-02-29', convention)
        expect(result).to be_a(BigDecimal)
        expect(result).to eq(0)
      end
    end

    it 'returns decimal one for 1/1 regardless of elapsed time or frequency' do
      ['2024-02-29', '2024-03-01', '2024-03-02'].each do |settlement|
        result = fraction('2024-02-29', settlement, 11, last: '2024-03-02')
        expect(result).to be_a(BigDecimal)
        expect(result).to eq(1)
      end
      expect(fraction('2023-01-01', '2025-01-01', 11)).to eq(1)
    end

    it 'includes settlement but excludes the start when testing leap days for Actual/365L' do
      expect(fraction('2023-07-01', '2024-02-28', 9, last: '2024-07-01')).to eq(BigDecimal(242) / 365)
      expect(fraction('2023-07-01', '2024-02-29', 9, last: '2024-07-01')).to eq(BigDecimal(243) / 366)
      expect(fraction('2024-02-29', '2024-03-01', 9, last: '2025-02-28')).to eq(BigDecimal(1) / 365)
    end

    it 'matches the reference AFB example spanning several years' do
      expect(fraction('1994-02-10', '1997-06-30', 10)).to eq(3 + BigDecimal(140) / 365)
    end

    it 'rejects invalid conventions' do
      [-1, 12, 0.5, 1.0, '0', nil].each do |convention|
        expect { fraction('2024-01-01', '2024-02-01', convention) }
          .to raise_error(ArgumentError, /convention must be an integer/)
      end
    end

    it 'rejects settlement outside the period' do
      ['2023-12-31', '2024-02-02'].each do |settlement|
        expect { fraction('2024-01-01', settlement, 0, last: '2024-02-01') }
          .to raise_error(ArgumentError, /settlement date/)
      end
    end
  end
end
