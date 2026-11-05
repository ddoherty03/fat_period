- [Version](#org3762cbe)
- [Introduction](#org9157082)
- [Installation](#org4c424d2)
  - [Installing the gem](#org47daed0)
- [Usage](#org1679def)
  - [Constant Period::FOREVER](#org92db99a)
  - [Construction of Periods](#org5204151)
    - [Period.new](#orgfb49567)
    - [Period.parse](#orgae8bb3f)
    - [Period.parse\_phrase](#orgf49412a)
    - [Period.ensure](#org48bf4e5)
  - [Conversion](#org2f49294)
    - [To Range](#org2cbf490)
    - [To String](#orgac36095)
    - [TeX Form](#orgaabdc1f)
  - [Comparison](#orgc2987c9)
  - [Enumeration](#org152949f)
  - [Size](#org168f5ff)
  - [Day-count fractions: Period#year\_fraction](#org5e45035)
    - [Choosing a convention](#orgb2b83e8)
    - [Actual-day conventions and boundaries](#org1df872e)
    - [Sources](#org1cf3195)
  - [Chunking](#org998956a)
  - [Set Operations](#orgfc22b86)
    - [Subset Determination](#orgd84f498)
    - [Superset Determination](#org2dc4617)
    - [Intersection](#org43f50d8)
    - [Difference](#org3240a3e)
    - [Union](#org56eb4ed)
  - [Coverage](#org6e5b2c7)
    - [Contains?](#orgbccc251)
    - [Overlapping](#org4d4fbd7)
    - [Spanning](#orga88110c)
    - [Gaps](#org2b6ee06)
- [Development](#org520cea9)
- [Contributing](#org8a96eec)

[![CI](https://github.com/ddoherty03/fat_period/actions/workflows/ruby.yml/badge.svg?branch=master)](https://github.com/ddoherty03/fat_period/actions/workflows/ruby.yml)


<a id="org3762cbe"></a>

# Version

```ruby
"Current version is: #{FatPeriod::VERSION}"
```

```
Current version is: 3.1.0
```


<a id="org9157082"></a>

# Introduction

`FatPeriod` provides a Ruby `Period` class for dealing with time periods of days, that is ranges whose endpoints are of class `Date`. It's target is financial applications, but it serves well for any application where periods of time are useful. It builds on the [fat\_date](https://github.com/ddoherty03/fat_date) gem, which provides enhancements to the `Date` class, especially its class method `Date.spec` for interpreting a rich set of "specs" as the beginning or end of a variety of calendar-related periods.

In addition, set operations are provided for Period, as well as methods for breaking a larger periods into an array of smaller periods of various 'chunk' sizes that correspond to calendar-related periods such as days, weeks, months, and so forth.


<a id="org4c424d2"></a>

# Installation


<a id="org47daed0"></a>

## Installing the gem

Add this line to your application's Gemfile:

```ruby
gem 'fat_period'
```

```
true
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install fat_period
```


<a id="org1679def"></a>

# Usage


<a id="org92db99a"></a>

## Constant Period::FOREVER

The `Period` class depends on the extensions to `Date` made by the `fat_core` gem, which you can read about [here](https://github.com/ddoherty03/fat_core). It defines a constant, `Period::FOREVER`, which is defined as extending from `Date::BOT` to `Date::EOT`, which are defined in `fat_date` as 1900-01-01 and 3000-12-31, respectively and define the beginning of time and end of time for practical commercial purposes. The constant is not frozen, so you can re-define it to your liking.


<a id="org5204151"></a>

## Construction of Periods


<a id="orgfb49567"></a>

### Period.new

A Period is constructed with two arguments for the begin and end date. The begin date must be on or before the end date. Each argument can be (1) a Date, (2) a string parseable as a Date by the Date.parse method, or (3) an object that responds to `#to_s` and can be parsed as a Date by Date.parse:

```ruby
p1 = Period.new(Date.today, Date.today + 30)
p2 = Period.new('Nov 22, 1963', Date.today)
p3 = Period.new('1961-01-21', '1963-11-22')
[[p1.to_s], [p2.to_s], [p3.to_s]]
```

```
| 2026-11-04 to 2026-12-04 |
| 1963-11-22 to 2026-11-04 |
| 1961-01-21 to 1963-11-22 |
```

```ruby
["Camelot lasted #{p3.length} days"]
```

```
| Camelot lasted 1036 days |
```


<a id="orgae8bb3f"></a>

### Period.parse

A more convenient way to construct a period is provided by `Period.parse`. It takes two strings as its arguments, a mandatory "from-spec" and an optional "to-spec":

A "spec" is a string designating some period of time. There are many ways of specifying a period, which are detailed below.

1.  With Only a From-Spec

    If only a from-spec is given, it defines both the beginning and end of the overall period:
    
    ```ruby
    tab = []
    tab << ['From Spec', 'Result']
    tab << nil
    froms = ['2020', '2020-2Q', '2020-W15', '2020-09', '2020-09-A', '2020-09-iii']
    froms.each do |f|
      tab << [f, Period.parse(f).inspect]
    end
    tab
    ```
    
    ```
    | From Spec   | Result                         |
    |-------------+--------------------------------|
    | 2020        | Period(2020-01-01..2020-12-31) |
    | 2020-2Q     | Period(2020-04-01..2020-06-30) |
    | 2020-W15    | Period(2020-04-06..2020-04-12) |
    | 2020-09     | Period(2020-09-01..2020-09-30) |
    | 2020-09-A   | Period(2020-09-01..2020-09-15) |
    | 2020-09-iii | Period(2020-09-14..2020-09-20) |
    ```
    
    ```
    | From Spec   | Result                         |
    |-------------+--------------------------------|
    | 2020        | Period(2020-01-01..2020-12-31) |
    | 2020-2Q     | Period(2020-04-01..2020-06-30) |
    | 2020-W15    | Period(2020-04-06..2020-04-12) |
    | 2020-09     | Period(2020-09-01..2020-09-30) |
    | 2020-09-A   | Period(2020-09-01..2020-09-15) |
    | 2020-09-iii | Period(2020-09-14..2020-09-20) |
    ```

2.  With Both a From-Spec and To-Spec

    But, if a to-spec is also given, the from-spec defines the beginning of the period and the to-spec defines the end of the period. In particular, the beginning of the period is the first day of the from-spec and the end of the period is the last day of the to-spec:
    
    ```ruby
    tab = []
    tab << ['From Spec', 'To Spec', 'Result']
    tab << nil
    from_tos = [['2020', '2020-2Q'], ['2020-2Q', '2020-W15'], ['2020-W15', '2020-09'], ['2020-09', '2020-09-A'], ['2020-09-A', '2020-09-iii']]
    from_tos.each do |f, t|
      tab << [f, t, Period.parse(f, t).inspect]
    end
    tab
    ```
    
    ```
    | From Spec | To Spec     | Result                         |
    |-----------+-------------+--------------------------------|
    | 2020      | 2020-2Q     | Period(2020-01-01..2020-06-30) |
    | 2020-2Q   | 2020-W15    | Period(2020-04-01..2020-04-12) |
    | 2020-W15  | 2020-09     | Period(2020-04-06..2020-09-30) |
    | 2020-09   | 2020-09-A   | Period(2020-09-01..2020-09-15) |
    | 2020-09-A | 2020-09-iii | Period(2020-09-01..2020-09-20) |
    ```
    
    ```
    | From Spec | To Spec     | Result                         |
    |-----------+-------------+--------------------------------|
    | 2020      | 2020-2Q     | Period(2020-01-01..2020-06-30) |
    | 2020-2Q   | 2020-W15    | Period(2020-04-01..2020-04-12) |
    | 2020-W15  | 2020-09     | Period(2020-04-06..2020-09-30) |
    | 2020-09   | 2020-09-A   | Period(2020-09-01..2020-09-15) |
    | 2020-09-A | 2020-09-iii | Period(2020-09-01..2020-09-20) |
    ```

3.  Using Skip Modifiers

    One new feature of FatDate is the ability to add a "skip modifier" to the end of a date spec to skip forward or backward to the first day-of-week either on or before/after the date given by the spec. For example, the following demonstrates that one can set the 'to' spec to the *last* Wednesday of 2025 or the last Wednesday *before* the end of 2025. Using '>' or '>=' specified skipping forward instead.
    
    ```ruby
    tab = []
    tab << ['From Spec', 'To Spec', 'Result', 'Description']
    tab << nil
    from_to_descs = [['2025-2Q', '2025<=Wed', 'From 2q to last Wednesday of 2025'],
                     ['2025-2Q', '2025<Wed', 'From 2q to last Wednesday /before/ the end of 2025'],
                     ['2012-11', '2012-11<=Thur', 'November 2012 through last Thursday'],
                     ['2012-11', '2012-11-4Thur', 'And through Thanksgiving (not always the /last/ Thursday!)']
                    ]
    from_to_descs.each do |f, t, d|
      tab << [f, t, Period.parse(f, t).inspect, d]
    end
    tab
    ```
    
    ```
    | From Spec | To Spec       | Result                         | Description                                                |
    |-----------+---------------+--------------------------------+------------------------------------------------------------|
    | 2025-2Q   | 2025<=Wed     | Period(2025-04-01..2025-12-31) | From 2q to last Wednesday of 2025                          |
    | 2025-2Q   | 2025<Wed      | Period(2025-04-01..2025-12-31) | From 2q to last Wednesday /before/ the end of 2025         |
    | 2012-11   | 2012-11<=Thur | Period(2012-11-01..2012-11-29) | November 2012 through last Thursday                        |
    | 2012-11   | 2012-11-4Thur | Period(2012-11-01..2012-11-22) | And through Thanksgiving (not always the /last/ Thursday!) |
    ```
    
    ```
    | From Spec | To Spec       | Result                         | Description                                                |
    |-----------+---------------+--------------------------------+------------------------------------------------------------|
    | 2025-2Q   | 2025<=Wed     | Period(2025-04-01..2025-12-31) | From 2q to last Wednesday of 2025                          |
    | 2025-2Q   | 2025<Wed      | Period(2025-04-01..2025-12-31) | From 2q to last Wednesday /before/ the end of 2025         |
    | 2012-11   | 2012-11<=Thur | Period(2012-11-01..2012-11-29) | November 2012 through last Thursday                        |
    | 2012-11   | 2012-11-4Thur | Period(2012-11-01..2012-11-22) | And through Thanksgiving (not always the /last/ Thursday!) |
    ```


<a id="orgf49412a"></a>

### Period.parse\_phrase

For example:

The `Period.parse_phrase` method will take a string having a 'from', 'to', and 'per' clause and return an Array of Periods encompassing the same period as `Period.parse`, but optionally broken into sub-periods each having the length specified by the 'per' clause. `Period.parse_phrase` always returns an Array of Periods even if there is no 'per' clause and the Array has only one member. If there is no 'to' clause, the returned period is from the start of the 'from' period to its end. If there is neither a 'from' or a 'to' clause, it tries to interpret the beginning of the phrase as a valid spec and uses it as a 'from' clause.

```ruby
tab = []
tab << ['k', 'Sub Period']
tab << nil
pds = Period.parse_phrase('from 2025 to 2025-3Q per month')
pds.each_with_index do |pd, k|
  tab << [k, pd.inspect]
end
tab
```

```
| k | Sub Period                     |
|---+--------------------------------|
| 0 | Period(2025-01-01..2025-01-31) |
| 1 | Period(2025-02-01..2025-02-28) |
| 2 | Period(2025-03-01..2025-03-31) |
| 3 | Period(2025-04-01..2025-04-30) |
| 4 | Period(2025-05-01..2025-05-31) |
| 5 | Period(2025-06-01..2025-06-30) |
| 6 | Period(2025-07-01..2025-07-31) |
| 7 | Period(2025-08-01..2025-08-31) |
| 8 | Period(2025-09-01..2025-09-30) |
```

```
| k | Sub Period                     |
|---+--------------------------------|
| 0 | Period(2025-01-01..2025-01-31) |
| 1 | Period(2025-02-01..2025-02-28) |
| 2 | Period(2025-03-01..2025-03-31) |
| 3 | Period(2025-04-01..2025-04-30) |
| 4 | Period(2025-05-01..2025-05-31) |
| 5 | Period(2025-06-01..2025-06-30) |
| 6 | Period(2025-07-01..2025-07-31) |
| 7 | Period(2025-08-01..2025-08-31) |
| 8 | Period(2025-09-01..2025-09-30) |
```

The period named in the 'per' clause is called a 'chunk' and there are several valid chunk names in `FatPeriod`:

| Chunk Name |
|---------- |
| year       |
| half       |
| quarter    |
| bimonth    |
| month      |
| semimonth  |
| biweek     |
| week       |
| day        |

Here is the same period broken into weeks. Notice that the first and last "weeks" are not whole weeks because parts of them fall outside the boundaries of the overall period.

```ruby
tab = []
tab << ['k', 'Sub Period']
tab << nil
pds = Period.parse_phrase('from 2025 to 2025-3Q per week')
pds.each_with_index do |pd, k|
  tab << [k, pd.inspect]
end
tab
```

```
|  k | Sub Period                     |
|----+--------------------------------|
|  0 | Period(2025-01-01..2025-01-05) |
|  1 | Period(2025-01-06..2025-01-12) |
|  2 | Period(2025-01-13..2025-01-19) |
|  3 | Period(2025-01-20..2025-01-26) |
|  4 | Period(2025-01-27..2025-02-02) |
|  5 | Period(2025-02-03..2025-02-09) |
|  6 | Period(2025-02-10..2025-02-16) |
|  7 | Period(2025-02-17..2025-02-23) |
|  8 | Period(2025-02-24..2025-03-02) |
|  9 | Period(2025-03-03..2025-03-09) |
| 10 | Period(2025-03-10..2025-03-16) |
| 11 | Period(2025-03-17..2025-03-23) |
| 12 | Period(2025-03-24..2025-03-30) |
| 13 | Period(2025-03-31..2025-04-06) |
| 14 | Period(2025-04-07..2025-04-13) |
| 15 | Period(2025-04-14..2025-04-20) |
| 16 | Period(2025-04-21..2025-04-27) |
| 17 | Period(2025-04-28..2025-05-04) |
| 18 | Period(2025-05-05..2025-05-11) |
| 19 | Period(2025-05-12..2025-05-18) |
| 20 | Period(2025-05-19..2025-05-25) |
| 21 | Period(2025-05-26..2025-06-01) |
| 22 | Period(2025-06-02..2025-06-08) |
| 23 | Period(2025-06-09..2025-06-15) |
| 24 | Period(2025-06-16..2025-06-22) |
| 25 | Period(2025-06-23..2025-06-29) |
| 26 | Period(2025-06-30..2025-07-06) |
| 27 | Period(2025-07-07..2025-07-13) |
| 28 | Period(2025-07-14..2025-07-20) |
| 29 | Period(2025-07-21..2025-07-27) |
| 30 | Period(2025-07-28..2025-08-03) |
| 31 | Period(2025-08-04..2025-08-10) |
| 32 | Period(2025-08-11..2025-08-17) |
| 33 | Period(2025-08-18..2025-08-24) |
| 34 | Period(2025-08-25..2025-08-31) |
| 35 | Period(2025-09-01..2025-09-07) |
| 36 | Period(2025-09-08..2025-09-14) |
| 37 | Period(2025-09-15..2025-09-21) |
| 38 | Period(2025-09-22..2025-09-28) |
| 39 | Period(2025-09-29..2025-09-30) |
```

```
|  k | Sub Period                     |
|----+--------------------------------|
|  0 | Period(2025-01-01..2025-01-05) |
|  1 | Period(2025-01-06..2025-01-12) |
|  2 | Period(2025-01-13..2025-01-19) |
|  3 | Period(2025-01-20..2025-01-26) |
|  4 | Period(2025-01-27..2025-02-02) |
|  5 | Period(2025-02-03..2025-02-09) |
|  6 | Period(2025-02-10..2025-02-16) |
|  7 | Period(2025-02-17..2025-02-23) |
|  8 | Period(2025-02-24..2025-03-02) |
|  9 | Period(2025-03-03..2025-03-09) |
| 10 | Period(2025-03-10..2025-03-16) |
| 11 | Period(2025-03-17..2025-03-23) |
| 12 | Period(2025-03-24..2025-03-30) |
| 13 | Period(2025-03-31..2025-04-06) |
| 14 | Period(2025-04-07..2025-04-13) |
| 15 | Period(2025-04-14..2025-04-20) |
| 16 | Period(2025-04-21..2025-04-27) |
| 17 | Period(2025-04-28..2025-05-04) |
| 18 | Period(2025-05-05..2025-05-11) |
| 19 | Period(2025-05-12..2025-05-18) |
| 20 | Period(2025-05-19..2025-05-25) |
| 21 | Period(2025-05-26..2025-06-01) |
| 22 | Period(2025-06-02..2025-06-08) |
| 23 | Period(2025-06-09..2025-06-15) |
| 24 | Period(2025-06-16..2025-06-22) |
| 25 | Period(2025-06-23..2025-06-29) |
| 26 | Period(2025-06-30..2025-07-06) |
| 27 | Period(2025-07-07..2025-07-13) |
| 28 | Period(2025-07-14..2025-07-20) |
| 29 | Period(2025-07-21..2025-07-27) |
| 30 | Period(2025-07-28..2025-08-03) |
| 31 | Period(2025-08-04..2025-08-10) |
| 32 | Period(2025-08-11..2025-08-17) |
| 33 | Period(2025-08-18..2025-08-24) |
| 34 | Period(2025-08-25..2025-08-31) |
| 35 | Period(2025-09-01..2025-09-07) |
| 36 | Period(2025-09-08..2025-09-14) |
| 37 | Period(2025-09-15..2025-09-21) |
| 38 | Period(2025-09-22..2025-09-28) |
| 39 | Period(2025-09-29..2025-09-30) |
```


<a id="org48bf4e5"></a>

### Period.ensure

`Period.ensure` tries to interpret its argument as a `Period` and returns it; otherwise it throws an `ArgumentError` exception:

-   if the argument responds to the `to_period` method, it invokes that on the argument and returns it;
-   if the argument is a `String`, it uses `Period.parse_phrase` to try to interepret it as a `Period`;
-   if it is already a `Period`, it just returns the argument;
-   otherwise, it throws an `ArgumentError` exception.

```ruby
class ContainingMonth
  def initialize(dat)
    @dat = Date.ensure(dat)
  end

  def to_period
    Period.month_containing(@dat)
  end
end

cm = ContainingMonth.new('2025-09-22')
Period.ensure(cm)
```

```
Period(2025-09-01..2025-09-30)
```

```
Period(2025-09-01..2025-09-30)
```

```ruby
Period.ensure('from 2016 to 2018-3Q')
```

```
Period(2016-01-01..2018-09-30)
```

```
Period(2016-01-01..2018-09-30)
```

```ruby
Period.ensure(Period.new('2016-01-02', '2017-09-29'))
```

```
Period(2016-01-02..2017-09-29)
```

```
Period(2016-01-02..2017-09-29)
```


<a id="org2f49294"></a>

## Conversion


<a id="org2cbf490"></a>

### To Range


<a id="orgac36095"></a>

### To String


<a id="orgaabdc1f"></a>

### TeX Form


<a id="orgc2987c9"></a>

## Comparison


<a id="org152949f"></a>

## Enumeration


<a id="org168f5ff"></a>

## Size


<a id="org5e45035"></a>

## Day-count fractions: Period#year\_fraction

`year_fraction` returns a `BigDecimal` factor for calculating interest from `first` to a payment or settlement date. Usually this is a fraction of a year: multiply the principal by the annual rate and this factor to calculate accrued interest. The default convention is **30/360 US** (`convention: 1`).

```
period.year_fraction(date2, convention: 1, eom: true, maturity_date: nil)
```

The dates correspond to the notation in Wikipedia's [Day count convention](https://en.wikipedia.org/wiki/Day_count_convention) article:

-   `first` is Date1, the start of accrual.
-   `date2` is Date2, the payment or settlement date, supplied as a `Date` or a date string. It must fall within the Period, including its endpoints.
-   `last` is Date3, the next coupon payment date. For ICMA, construct the Period with consecutive coupon boundaries.

Day counts use elapsed days, without adding one as `Period#size` does. For example, January 1 to July 1 is the reference period for a coupon paid on July 1; use July 1 as `last`, rather than June 30. Passing `last` as the settlement date calculates the full coupon's factor.

```ruby
coupon = Period.new('2024-01-01', '2024-07-01')
factor = coupon.year_fraction('2024-04-01')
interest = BigDecimal('1000') * BigDecimal('0.05') * factor
[factor.to_s('F'), interest.to_s('F')]
```

```
| 0.25 | 12.5 |
```


<a id="orgb2b83e8"></a>

### Choosing a convention

The convention numbers are specific to `fat_period`; they are not Excel's `YEARFRAC` basis numbers. Supply `convention: 0` explicitly for Bond Basis. The ISDA references below are to Section 4.16 of the *2006 ISDA Definitions*.

| Convention | Name                | Reference                       |
|---------- |------------------- |------------------------------- |
| 0          | 30/360 Bond Basis   | ISDA 4.16(f)                    |
| 1          | 30/360 US (default) | 4.16(f), plus US February rules |
| 2          | 30E/360             | ISDA 4.16(g)                    |
| 3          | 30E/360 ISDA        | ISDA 4.16(h)                    |
| 4          | Actual/Actual ICMA  | ISDA 4.16(c); ICMA Rule 251     |
| 5          | Actual/Actual ISDA  | ISDA 4.16(b)                    |
| 6          | Actual/365 Fixed    | ISDA 4.16(d)                    |
| 7          | Actual/360          | ISDA 4.16(e)                    |
| 8          | Actual/364          | Wikipedia's Actual/364 section  |
| 9          | Actual/365L         | Wikipedia's Actual/365L section |
| 10         | Actual/Actual AFB   | Wikipedia's AFB discussion      |
| 11         | 1/1                 | ISDA 4.16(a)                    |

For convention 1, `eom: true` applies the February end-of-month rules for investments that pay at month end. Set `eom: false` to omit those February adjustments. The remaining 30/360 adjustments still apply.

For convention 3, `maturity_date:` accepts a `Date` or date string and identifies the investment's final maturity. When settlement is that date and is the last day of February, its day number is left unchanged. Otherwise the usual month-end adjustment applies. Maturity is not inferred from `last`.

```ruby
final_coupon = Period.new('2023-08-31', '2024-02-29')
ordinary = final_coupon.year_fraction('2024-02-29', convention: 3)
at_maturity = final_coupon.year_fraction(
  '2024-02-29', convention: 3, maturity_date: '2024-02-29'
)
[ordinary.to_s('F'), at_maturity.round(10).to_s('F')]
```

```
| 0.5 | 0.4972222222 |
```


<a id="org1df872e"></a>

### Actual-day conventions and boundaries

ICMA (4) divides elapsed days by the product of payment frequency and elapsed days in the full coupon period. Frequency is inferred from the full period's length. For example, both a full 181-day half-year coupon and a full 184-day half-year coupon have a factor of 0.5, but their daily accruals differ.

```ruby
coupon = Period.new('2024-01-01', '2024-07-01')
partial = coupon.year_fraction('2024-04-01', convention: 4)
full = coupon.year_fraction(coupon.last, convention: 4)
[partial.to_s('F'), full.to_s('F')]
```

```
| 0.25 | 0.5 |
```

ICMA supports regular coupon periods only; it does not construct notional coupon schedules for irregular first or final coupons. Frequency inference allows the same 10% length tolerance as `chunk_name` for monthly and longer periods. An unrecognizable length raises `ArgumentError` for conventions that require frequency (4 and 9).

ISDA Actual/Actual (5) splits the elapsed interval at calendar-year boundaries, using 365 or 366 for each portion. Conventions 6, 7, and 8 use fixed denominators of 365, 360, and 364 respectively.

Actual/365L (9) follows the Wikipedia article's settlement-date rule: for annual payments, it uses 366 if February 29 falls after `first` and on or before settlement, otherwise 365. For other frequencies, it uses the number of days in the settlement year. The full period determines frequency, not the leap-day test interval.

AFB (10) counts complete years backwards from settlement, then calculates the remaining initial fraction. It uses the ISDA backward-counting February adjustment described in the article: a February 28 anniversary moves to February 29 when the preceding year is a leap year. The remaining fraction uses 366 only when it includes February 29, counting its start but excluding its end.

Equal start and settlement dates return zero for conventions 0 through 10. Convention 11 (1/1) always returns one, even for equal dates: it applies the full contractual rate without prorating for time. Invalid convention numbers or settlement dates outside the Period raise `ArgumentError`.


<a id="org1cf3195"></a>

### Sources

-   [Wikipedia: Day count convention](https://en.wikipedia.org/wiki/Day_count_convention) gives the formulas, naming variants, and discussion of the conventions implemented here.
-   [2006 ISDA Definitions](https://www.isda.org/book/2006-isda-definitions/), Section 4.16, *Day Count Fraction*, is the primary source for most of these rules. A [PDF copy hosted by Standard Chartered](https://www.sc.com/en/uploads/sites/66/content/docs/2006-ISDA-Definitions.pdf) contains the section on printed pages 11-13. Section 4.16(f) defines Bond Basis; the additional US February rules are described in the Wikipedia article rather than that clause.


<a id="org998956a"></a>

## Chunking


<a id="orgfc22b86"></a>

## Set Operations


<a id="orgd84f498"></a>

### Subset Determination


<a id="org2dc4617"></a>

### Superset Determination


<a id="org43f50d8"></a>

### Intersection


<a id="org3240a3e"></a>

### Difference


<a id="org56eb4ed"></a>

### Union


<a id="org6e5b2c7"></a>

## Coverage


<a id="orgbccc251"></a>

### Contains?


<a id="org4d4fbd7"></a>

### Overlapping


<a id="orga88110c"></a>

### Spanning


<a id="org2b6ee06"></a>

### Gaps


<a id="org520cea9"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To release a new version, update the version number in \`version.rb\`, and then run \`bundle exec rake release\`, which will create a git tag for the version, push git commits and tags, and push the \`.gem\` file to [rubygems.org](<https://rubygems.org>).


<a id="org8a96eec"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/fat_table>.
