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