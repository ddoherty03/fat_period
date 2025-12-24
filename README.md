- [Version](#org6e3eea4)
- [Introduction](#orgda50e5d)
- [Installation](#org52c5a52)
  - [Installing the gem](#orgbdb3c5b)
- [Usage](#org68d3eb4)
  - [Constant Period::FOREVER](#orgbbfdac9)
  - [Construction of Periods](#org395dc2a)
    - [Period.new](#org39e22c3)
    - [Period.parse](#orge274e41)
    - [Period.parse\_phrase](#orgdd5d397)
    - [Period.ensure](#orgf1c5f7b)
  - [Conversion](#org39bf064)
    - [To Range](#org648004f)
    - [To String](#org23d848a)
    - [TeX Form](#orgb6494de)
  - [Comparison](#org1d65777)
  - [Enumeration](#orgee8282d)
  - [Size](#orgb2c8964)
  - [Chunking](#orgaf69a05)
  - [Set Operations](#orge88433b)
    - [Subset Determination](#org7d1e633)
    - [Superset Determination](#org71a5fde)
    - [Intersection](#org4712bc1)
    - [Difference](#org98e2d12)
    - [Union](#org5b3f969)
  - [Coverage](#org7cd8008)
    - [Contains?](#org86ac33c)
    - [Overlapping](#orgd46b493)
    - [Spanning](#org5cb04f9)
    - [Gaps](#org7fad67d)
- [Development](#org9d1a830)
- [Contributing](#org002487e)

[![CI](https://github.com/ddoherty03/fat_period/actions/workflows/ruby.yml/badge.svg?branch=master)](https://github.com/ddoherty03/fat_period/actions/workflows/ruby.yml)


<a id="org6e3eea4"></a>

# Version

```ruby
"Current version is: #{FatPeriod::VERSION}"
```

```
Current version is: 3.0.1
```

```
Current version is: 3.0.0
```


<a id="orgda50e5d"></a>

# Introduction

`FatPeriod` provides a Ruby `Period` class for dealing with time periods of days, that is ranges whose endpoints are of class `Date`. It's target is financial applications, but it serves well for any application where periods of time are useful. It builds on the [fat\_date](https://github.com/ddoherty03/fat_date) gem, which provides enhancements to the `Date` class, especially its class method `Date.spec` for interpreting a rich set of "specs" as the beginning or end of a variety of calendar-related periods.

In addition, set operations are provided for Period, as well as methods for breaking a larger periods into an array of smaller periods of various 'chunk' sizes that correspond to calendar-related periods such as days, weeks, months, and so forth.


<a id="org52c5a52"></a>

# Installation


<a id="orgbdb3c5b"></a>

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


<a id="org68d3eb4"></a>

# Usage


<a id="orgbbfdac9"></a>

## Constant Period::FOREVER

The `Period` class depends on the extensions to `Date` made by the `fat_core` gem, which you can read about [here](https://github.com/ddoherty03/fat_core). It defines a constant, `Period::FOREVER`, which is defined as extending from `Date::BOT` to `Date::EOT`, which are defined in `fat_date` as 1900-01-01 and 3000-12-31, respectively and define the beginning of time and end of time for practical commercial purposes. The constant is not frozen, so you can re-define it to your liking.


<a id="org395dc2a"></a>

## Construction of Periods


<a id="org39e22c3"></a>

### Period.new

A Period is constructed with two arguments for the begin and end date. The begin date must be on or before the end date. Each argument can be (1) a Date, (2) a string parseable as a Date by the Date.parse method, or (3) an object that responds to `#to_s` and can be parsed as a Date by Date.parse:

```ruby
p1 = Period.new(Date.today, Date.today + 30)
p2 = Period.new('Nov 22, 1963', Date.today)
p3 = Period.new('1961-01-21', '1963-11-22')
[[p1.to_s], [p2.to_s], [p3.to_s]]
```

```
| 2025-12-24 to 2026-01-23 |
| 1963-11-22 to 2025-12-24 |
| 1961-01-21 to 1963-11-22 |
```

```ruby
["Camelot lasted #{p3.length} days"]
```

```
| Camelot lasted 1036 days |
```


<a id="orge274e41"></a>

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


<a id="orgdd5d397"></a>

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


<a id="orgf1c5f7b"></a>

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


<a id="org39bf064"></a>

## Conversion


<a id="org648004f"></a>

### To Range


<a id="org23d848a"></a>

### To String


<a id="orgb6494de"></a>

### TeX Form


<a id="org1d65777"></a>

## Comparison


<a id="orgee8282d"></a>

## Enumeration


<a id="orgb2c8964"></a>

## Size


<a id="orgaf69a05"></a>

## Chunking


<a id="orge88433b"></a>

## Set Operations


<a id="org7d1e633"></a>

### Subset Determination


<a id="org71a5fde"></a>

### Superset Determination


<a id="org4712bc1"></a>

### Intersection


<a id="org98e2d12"></a>

### Difference


<a id="org5b3f969"></a>

### Union


<a id="org7cd8008"></a>

## Coverage


<a id="org86ac33c"></a>

### Contains?


<a id="orgd46b493"></a>

### Overlapping


<a id="org5cb04f9"></a>

### Spanning


<a id="org7fad67d"></a>

### Gaps


<a id="org9d1a830"></a>

# Development

After checking out the repo, run \`bin/setup\` to install dependencies. Then, run \`rake spec\` to run the tests. You can also run \`bin/console\` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run \`bundle exec rake install\`. To release a new version, update the version number in \`version.rb\`, and then run \`bundle exec rake release\`, which will create a git tag for the version, push git commits and tags, and push the \`.gem\` file to [rubygems.org](<https://rubygems.org>).


<a id="org002487e"></a>

# Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/ddoherty03/fat_table>.
