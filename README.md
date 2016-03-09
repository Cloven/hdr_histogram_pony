**hdr_histogram_pony**

## Description ##

The HDR Histogram library is a Pony native interface wrapper of
Mike Barker's C port of Gil Tene's HDR Histogram utility.

A high dynamic range histogram is one that supports recording and analyzing
sampled data points across a configurable range with configurable precision
within that range. The precision is expressed as a number of significant
figures in the recording.

This HDR histogram implementation is designed for recording histograms of
value measurements in latency sensitive environments.

A distinct advantage of this histogram implementation is constant space and 
recording (time) overhead with an ability to recycle and reset instances 
whilst reclaiming already allocated space for reuse thereby reducing 
allocation cost and garbage collection overhead where repeated or 
continuous usage is likely.

The code is released to the public domain, under the same terms as its sibling
projects, as explained in the LICENSE.txt and COPYING.txt in the root of this
repository, but normatively at:

http://creativecommons.org/publicdomain/zero/1.0/

For users of this code who wish to consume it under the "BSD" license rather
than under the public domain or CC0 contribution text mentioned above, the 
code found under this directory is also provided under the following license
(commonly referred to as the BSD 2-Clause License). This license does not 
detract from the above stated release of the code into the public domain, and
simply represents an additional license granted by:

http://creativecommons.org/publicdomain/zero/1.0/

### Building

Prerequisites:
* [Pony](http://www.ponylang.org/)
* [Pony Stable](https://github.com/jemc/pony-stable)
* mkdocs ( optional )

```bash
$ git clone git://github.com/darach/hdr_histogram_pony
$ cd hdr_histogram_pony
$ ./scripts/build.sh
```

This will:
* Build and run unit tests
* Build and run a simple example
* Generate pony API documents for the hdr package
* If mkdocs is present, convert API documents to a website suitable for running in a web server
  + Example ( cd docs/site && python -m SimpleHTTPServer )
  
To clean out all generated artefacts:

```bash
$ ./scripts/clean.sh
```

### Examples

Capture metrics and produce a histogram using pony:


```pony
use "collections"
use "random"
use "hdr"

actor Main
  new create(env : Env) =>
    let r = MT                              // Use Mersenne Twitter RNG
    let n : U32 = 10000000                  // Take 10 million random samples
    let h = HdrHistogram(1, 1000000, 3)     // Histogram precise to 3 places

    // Generate and record some random values
    for i in Range[U32](0, n) do
      h.record_value(r.int(1000000).i64())
    end

    try report(h,env) end

  fun report(h : HdrHistogram, env : Env) ? =>
    let iter : HdrPercentilesIterator = HdrPercentilesIterator(h, 4)

    env.out.print("Value,Percentile,Total_Count,1/(1-Percentile)")
    while iter.has_next() do
        let current : NativePercentilesIter = iter.next()
        let value = iter.hev().f64() / 1.0
        let percentile = current.pcnt / 100.0
        let total_count = iter.cc()
        let inverted_percentile : F64 = 1.0 / (1.0 - percentile)

        env.out.print(
          value.string() + "," +
          percentile.string() + "," +
          total_count.string() + "," +
          inverted_percentile.string()
          )
      end

      env.out.print("")
      env.out.print(" Samples: " + h.get_total_count().string())
      env.out.print("")
      env.out.print("     Min: " + h.min().string())
      env.out.print("     Max: " + h.max().string())
      env.out.print("    Mean: " + h.mean().string())
      env.out.print("  Median: " + h.median().string())
      env.out.print("  Stddev: " + h.stddev().string())
      env.out.print("")
```

## A note on tuning ##


A common useage example of HdrHistogram is to record response times, in units of microseconds, across a dynamic range stretching from 1 usec to over an hour. We want a good enough resolution to support performing post-recording analysis on the collected data at some future time.

In order to facilitate the accuracy needed for such post-recording activities, we can maintain a resolution of ~1 usec or better for times ranging to ~2 msec in magnitude, while at the same time maintaining a resolution of ~1 msec or better for times ranging to ~2 sec, and a resolution of ~1 second or better for values up to 2,000 seconds, and so on. This sort of dynamic resolution can be thought of as "always accurate to 3 decimal points".

A HDR Histogram works like this. We MUST tune the highest trackable value to 3,600,000,000, and the number of significant value digits of 3. This range is fixed, and occupies a fixed, unchanging memory footprint of around 185KB.

## A note on footprint estimation ##


Due to it's **dynamic range** representation, HDR Histogram is relatively efficient in memory space requirements given the accuracy and dynamic range that it covers.

Still, it is useful to be able to estimate the memory footprint involved for a given highest trackable value and the configured number of significant value digits combination. Beyond a relatively small fixed-size footprint used for internal fields and stats (which can be estimated as "fixed at well less than 1KB"), the bulk of a histogram's storage is taken up by it's data value recording counts array. The total footprint can be conservatively estimated by:

```
 largestValueWithSingleUnitResolution =
        2 * (10 ^ numberOfSignificantValueDigits);
 subBucketSize =
        roundedUpToNearestPowerOf2(largestValueWithSingleUnitResolution);

 expectedHistogramFootprintInBytes = 512 +
      ({primitive type size} / 2) *
      (log2RoundedUp((highestTrackableValue) / subBucketSize) + 2) *
      subBucketSize
```

## A note on concurrent access ##

HdrHistogram does *NOT* have any internal synchronization and the pony wrapper does not
introduce any synchronization. This means that a Histogram reference must not be shared
with other actors as they may now, or in the future, be scheduled to run on different
scheduling threads. 

Under ordinary usage, where an instance is running in the context of an actor this should not
represent a problem.

## Enjoy!
