// Copyright (c) 2016 Darach Ennis <darach@gmail.com>
//
// The HDR histogram library is a Pony native interface wrapper of
// Mike Barker's C port of Gil Tene's HDR Histogram utility.
//
// 
// A high dynamic range histogram is one that supports recording and analyzing
// sampled data points across a configurable range with configurable precision
// within that range. The precision is expressed as a number of significant
// figures in the recording.
//
// This HDR histogram implementation is designed for recording histograms of
// value measurements in latency sensitive environments. 
//
// A distinct advantage of this histogram implementation is constant space and
// recording (time) overhead with an ability to recycle and reset instances 
// whilst reclaiming already allocated space for reuse thereby reducing
// allocation cost and garbage collection overhead where repeated or continuous
// usage is likely.
//
// The code is released to the public domain, under the same terms as its
// sibling projects, as explained in the LICENSE.txt and COPYING.txt in the
// root of this repository, but normatively at:
//
// http://creativecommons.org/publicdomain/zero/1.0/
//
// For users of this code who wish to consume it under the "BSD" license
// rather than under the public domain or CC0 contribution text mentioned
// above, the code found under this directory is *also* provided under the
// following license (commonly referred to as the BSD 2-Clause License). This
// license does not detract from the above stated release of the code into
// the public domain, and simply represents an additional license granted by
// http://creativecommons.org/publicdomain/zero/1.0/
//
// -----------------------------------------------------------------------------
// ** Beginning of "BSD 2-Clause License" text. **
//
// Copyright (c) 2012, 2013, 2014 Gil Tene
// Copyright (c) 2014 Michael Barker
// Copyright (c) 2014, 2016 Darach Ennis
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE.
//

use "ponytest"
use "collections"
use "debug"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestHistogramCreate)
    test(_TestHistogramCreateLarge)
    test(_TestHistogramBadSignificantFigures)
    test(_TestHistogramBadInit)
    test(_TestHistogramStateTotalCount)
    test(_TestHistogramStateMin)
    test(_TestHistogramStateMax)
    test(_TestHistogramStatePercentiles)
    test(_TestHistogramIteratorRecordedValues)
    test(_TestHistogramIteratorLinear)
    test(_TestHistogramIteratorLogarithmic)
    test(_TestHistogramStateReset)
    test(_TestHistogramScalingEquivalence)
    test(_TestHistogramStateOutOfRange)
    test(_TestHistogramLinearIterBucketsCorrectly)

class _HdrTestUtil
  var raw : HdrHistogram
  var cor : HdrHistogram
  var sraw : HdrHistogram
  var scor : HdrHistogram

  new create() =>
    let htv : I64 = 3600 * 1000 * 1000
    let sf : I32 = 3
    let interval : I64 = 10000
    let scale : I64 = 512
    let scaled_interval = interval * scale
    raw = HdrHistogram(1, htv, sf)
    cor = HdrHistogram(1, htv, sf)
    sraw = HdrHistogram(1000, htv * 512, sf)
    scor = HdrHistogram(1000, htv * 512, sf)

    for i in Range(0,10000) do
      raw.record_value(1000)
      cor.record_corrected_value(1000, interval)
      sraw.record_value(1000 * scale)
      scor.record_corrected_value(1000 * scale, scaled_interval)
    end

    raw.record_value(100000000)
    cor.record_corrected_value(100000000, 10000)

    sraw.record_value(100000000 * scale)
    scor.record_corrected_value(100000000 * scale, scaled_interval)

class iso _TestHistogramCreate is UnitTest
  """
  Test HDR Histogram creation
  """
  fun name(): String => "hdr/create"

  fun apply(h: TestHelper) ? =>
    let hdr = HdrHistogram(1, 3600000000, 3)
    h.assert_eq[I32](23552, hdr.get_counts_length())
    h.assert_is[HdrAllocationStatus](HdrOk,hdr.allocation_result())

class iso _TestHistogramCreateLarge is UnitTest
  """
  Test HDR Histogram creation with large values
  """
  fun name(): String => "hdr/create/large"

  fun apply(h: TestHelper) ? =>
    let hdr = HdrHistogram(20000000, 100000000, 5)
    h.assert_eq[I32](262144, hdr.get_counts_length())
    h.assert_is[HdrAllocationStatus](HdrOk,hdr.allocation_result())

    hdr.record_value(100000000)
    hdr.record_value(20000000)
    hdr.record_value(30000000)

    let v1 = hdr.value_at_percentile(50.0)
    h.assert_true(hdr.values_are_equivalent(20000000, v1))

    let v2 = hdr.value_at_percentile(83.3)
    h.assert_true(hdr.values_are_equivalent(30000000, v2)) 

    let v3 = hdr.value_at_percentile(83.4)
    h.assert_true(hdr.values_are_equivalent(100000000, v3))    

    let v4 = hdr.value_at_percentile(99.0)
    h.assert_true(hdr.values_are_equivalent(100000000, v4))

class iso _TestHistogramBadSignificantFigures is UnitTest
  """
  Test HDR Histogram creation with bad significant figures
  """
  fun name(): String => "hdr/create/bad/significant_figures"

  fun apply(h: TestHelper) =>
    let hdr1 = HdrHistogram(1, 36000000, -1)
    h.assert_is[HdrAllocationStatus](HdrInvalid,hdr1.allocation_result())

    let hdr2 = HdrHistogram(1, 36000000, 6)
    h.assert_is[HdrAllocationStatus](HdrInvalid,hdr2.allocation_result())

class iso _TestHistogramBadInit is UnitTest
  """
  Test HDR Histogram creation with bad initialization
  """
  fun name(): String => "hdr/create/bad/init"

  fun apply(h: TestHelper) =>
    let hdr1 = HdrHistogram(0, 64*1024, 2)
    h.assert_is[HdrAllocationStatus](HdrInvalid,hdr1.allocation_result())
    // Lowest trackable value MUST be greater than 0

    let hdr2 = HdrHistogram(80, 110, 5)
    h.assert_is[HdrAllocationStatus](HdrInvalid,hdr2.allocation_result())
    // Lowest trackable value MUST be less than 2 * Highest trackable value

class iso _TestHistogramStateTotalCount is UnitTest
  """
  Test HDR Histogram get total count
  """
  fun name(): String => "hdr/state/total_count"

  fun apply(h: TestHelper) ? =>
    let x = _HdrTestUtil
    h.assert_true(x.raw.values_are_equivalent(x.raw.max(), 100000000))
    h.assert_true(x.cor.values_are_equivalent(x.cor.max(), 100000000))

class iso _TestHistogramStateMin is UnitTest
  """
  Test HDR Histogram get minimum
  """
  fun name(): String => "hdr/state/min"

  fun apply(h: TestHelper) ? =>
    let x = _HdrTestUtil
    h.assert_eq[I64](1000, x.raw.min())
    h.assert_eq[I64](1000, x.cor.min())

class iso _TestHistogramStateMax is UnitTest
  """
  Test HDR Histogram get maximum
  """
  fun name(): String => "hdr/state/max"

  fun apply(h: TestHelper) ? =>
    let x = _HdrTestUtil
    h.assert_eq[I64](100000000, x.raw.max())
    h.assert_eq[I64](100000000, x.cor.max())

primitive _HdrAssert
    fun a2_eq(h: TestHelper, a: F64, b: I64, variation: F64):Bool =>
        assert_eq(h, a, b.f64(), variation)

    fun assert_eq(h: TestHelper, a: F64, b: F64, variation: F64):Bool =>
        h.assert_true(@fabs[F64](a - b) < ( b * variation ))

class iso _TestHistogramStatePercentiles is UnitTest
  """
  Test HDR Histogram get percentiles
  """
  fun name(): String => "hdr/state/percentiles"

  fun apply(h: TestHelper) =>
    let x = _HdrTestUtil
    _HdrAssert.a2_eq(h, 1000.0, x.raw.value_at_percentile(30.0), 0.001)
    _HdrAssert.a2_eq(h,1000.0, x.raw.value_at_percentile(99.0), 0.001)
    _HdrAssert.a2_eq(h,1000.0, x.raw.value_at_percentile(99.99), 0.001)
    _HdrAssert.a2_eq(h,100000000.0, x.raw.value_at_percentile(99.999), 0.001)
    _HdrAssert.a2_eq(h,100000000.0, x.raw.value_at_percentile(100.0), 0.001)
    _HdrAssert.a2_eq(h,1000.0, x.cor.value_at_percentile(30.0), 0.001)
    _HdrAssert.a2_eq(h,1000.0, x.cor.value_at_percentile(50.0), 0.001)
    _HdrAssert.a2_eq(h,50000000.0, x.cor.value_at_percentile(75.0), 0.001)
    _HdrAssert.a2_eq(h,80000000.0, x.cor.value_at_percentile(90.0), 0.001)
    _HdrAssert.a2_eq(h,98000000.0, x.cor.value_at_percentile(99.0), 0.001)
    _HdrAssert.a2_eq(h,100000000.0, x.cor.value_at_percentile(99.999), 0.001)
    _HdrAssert.a2_eq(h,100000000.0, x.cor.value_at_percentile(100.0), 0.001)

class iso _TestHistogramIteratorRecordedValues is UnitTest
  """
  Test HDR Histogram recorded values iterator
  """
  fun name(): String => "hdr/iter/recorded"

  fun apply(h: TestHelper) =>
    let x = _HdrTestUtil

    var iter = HdrRecordedIterator(x.raw)
    var index : I32 = 0
    while iter.has_next() do
      let record = iter.next()
      let count = record.caitis
      match index
      | 0 => h.assert_eq[I64](10000, count) 
      end
      h.assert_true( iter.c() != 0)
      h.assert_true(record.caitis == iter.c())
      index = index+1
    end
    h.assert_eq[I32](2, index)

    index = 0
    iter = HdrRecordedIterator(x.cor)
    while iter.has_next() do
      let record = iter.next()
      let count = record.caitis
      match index
      | 0 => h.assert_eq[I64](10000, count) 
      end
      h.assert_true( iter.c() != 0)
      h.assert_true(record.caitis == iter.c())
      index = index+1
    end

class iso _TestHistogramIteratorLinear is UnitTest
  """
  Test HDR Histogram linear iterator
  """
  fun name(): String => "hdr/iter/linear"

  fun apply(h: TestHelper) =>
    let x = _HdrTestUtil

    var iter = HdrLinearIterator(x.raw, 100000)
    var index : I32 = 0
    while iter.has_next() do
      let record = iter.next()
      let count = record.caitis
      match index
      | 0 => h.assert_eq[I64](10000, count) 
      | 999 => h.assert_eq[I64](1, count)
      else
        h.assert_eq[I64](0, count)
      end
      index = index+1
    end
    h.assert_eq[I32](1000, index)

    index = 0
    var total_added : I64 = 0
    iter = HdrLinearIterator(x.cor, 10000)
    while iter.has_next() do
      let record = iter.next()
      let count = record.caitis
      match index
      | 0 => h.assert_eq[I64](10001, count) 
      end
      h.assert_true( iter.c() != 0)
      index = index + 1
      total_added = total_added + count
    end
    h.assert_eq[I32](10000, index)
    h.assert_eq[I64](20000, total_added)

class iso _TestHistogramIteratorLogarithmic is UnitTest
  """
  Test HDR Histogram logarithmic iterator
  """
  fun name(): String => "hdr/iter/log"

  fun apply(h: TestHelper) =>
    let x = _HdrTestUtil

    var iter = HdrLogIterator(x.raw, 10000, 2.0)
    var index : I32 = 0
    while iter.has_next() do
      let record = iter.next()
      let count = record.caitis
      match index
      | 0 => h.assert_eq[I64](10000, count) 
      | 14 => h.assert_eq[I64](1, count)
      else
        h.assert_eq[I64](0, count)
      end
      index = index+1
    end
    h.assert_eq[I32](14, index-1)

    index = 0
    var total_added : I64 = 0
    iter = HdrLogIterator(x.cor, 10000, 2.0)
    while iter.has_next() do
      let record = iter.next()
      let count = record.caitis
      match index
      | 0 => h.assert_eq[I64](10001, count) 
      end
      index = index + 1
      total_added = total_added + count
    end
    h.assert_eq[I32](14, index-1)
    h.assert_eq[I64](20000, total_added)

class iso _TestHistogramStateReset is UnitTest
  """
  Test HDR Histogram state reset 
  """
  fun name(): String => "hdr/state/reset"

  fun apply(h: TestHelper) ? =>
    let x = _HdrTestUtil

    h.assert_true( x.raw.value_at_percentile(99.0) != 0)
    h.assert_true( x.cor.value_at_percentile(99.0) != 0)

    x.raw.reset()
    x.cor.reset()

    h.assert_true( x.raw.get_total_count() == 0 )
    h.assert_true( x.cor.get_total_count() == 0 )
    h.assert_true( x.raw.value_at_percentile(99.0) == 0)
    h.assert_true( x.cor.value_at_percentile(99.0) == 0)

class iso _TestHistogramScalingEquivalence is UnitTest
  """
  Test HDR Histogram state reset 
  """
  fun name(): String => "hdr/scale/equivalence"

  fun apply(h: TestHelper) ? =>
    let x = _HdrTestUtil

    _HdrAssert.assert_eq(h, x.cor.mean() * 512, x.scor.mean(), 0.00001)
    h.assert_eq[I64](x.cor.get_total_count(), x.scor.get_total_count())

    let c99th = x.cor.value_at_percentile(99.0) * 512
    let s99th = x.scor.value_at_percentile(99.0)

    h.assert_eq[I64](
      x.cor.lowest_equivalent_value(c99th), 
      x.scor.lowest_equivalent_value(s99th)
    )

class iso _TestHistogramStateOutOfRange is UnitTest
  """
  Test HDR Histogram state with out of range values 
  """
  fun name(): String => "hdr/state/out_of_range"

  fun apply(h: TestHelper) =>
    let hdr = HdrHistogram(1, 1000, 4)

    h.assert_true(hdr.record_value(32767))
    h.assert_false(hdr.record_value(32769))

class iso _TestHistogramLinearIterBucketsCorrectly is UnitTest
  """
  Test HDR Histogram linear iteration iterates buckets correctly
  """
  fun name(): String => "hdr/iter/linear_buckets"

  fun apply(h: TestHelper) =>
    let hdr = HdrHistogram(1, 255, 2)
    let values : Array[I64] = [ 193, 255, 0, 1, 64, 128]
    for x in values.values() do
      hdr.record_value(x)
    end

    let iter = HdrLinearIterator(hdr, 64)

    var step_count : I64 = 0
    var total_count : I64 = 0

    while iter.has_next() do
      let record = iter.next()
      total_count = total_count + record.caitis
      step_count = step_count+1
    end
    h.assert_eq[I64](4, step_count)
    h.assert_eq[I64](6, total_count)
