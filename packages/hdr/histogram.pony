"""
Copyright (c) 2016 Darach Ennis <darach@gmail.com>

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
simply represents an additional license granted by 
http://creativecommons.org/publicdomain/zero/1.0/

-----------------------------------------------------------------------------
** Beginning of "BSD 2-Clause License" text. **


Copyright (c) 2012, 2013, 2014 Gil Tene

Copyright (c) 2014 Michael Barker

Copyright (c) 2014, 2016 Darach Ennis

All rights reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:


1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.


2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

"""

primitive HdrOk
primitive HdrInvalid
primitive HdrOOM
primitive HdrUnknown

type HdrAllocationStatus is ( 
  HdrOk | HdrInvalid | HdrOOM | HdrUnknown
  )

class ref HdrHistogram 
  """
  The HdrHistogram class is the primary mapping of the underlying
  C HdrHistogram API histogram functions to the Pony language.
  """
  var data : Maybe[_NativeHdrHistogram] = Maybe[_NativeHdrHistogram].none()
  let allocation_status : HdrAllocationStatus

  new create(
    lowest_trackable_value : I64,
    highest_trackable_value : I64, 
    significant_figures : I32) =>
    """
      Allocate a native HDR Histogram structure with:
      * htv - Highest Trackable Value
      * sf - Significant Decimal Figures
    """
    let status = @hdr_init[I32](
      lowest_trackable_value,
      highest_trackable_value, 
      significant_figures, 
      addressof data
      )
    allocation_status = match status
      | 0 => HdrOk
      | 22 => HdrInvalid
      | 12 => HdrOOM
    else
      HdrUnknown
    end

  fun allocation_result(): HdrAllocationStatus =>
    allocation_status

  fun get_counts_length(): I32 ? =>
    data().cl

  fun reset() =>
    """
    Reset and reinitialize the histogram
    """
    @hdr_reset[None](data)

  fun get_unit_magnitude(): I32 ? =>
    """
    Get the histogram unit magnitude
    """
    data().um

  fun get_significant_figures(): I32 ? =>
    """
    Get the histogram significant figures
    """
    data().sf

  fun get_total_count(): I64 ? =>
    """
    Get the histogram total count
    """
    data().tc

  fun get_memory_size(): I64 =>
    """
    Get the memory size of the histogram in bytes
    """
    @hdr_get_memory_size[I64](data)

  fun record_value(value : I64) : Bool =>
    """
    Record a value rounded to significant figures precision
    """
    @hdr_record_value[Bool](data, value)

  fun record_values(value : I64, count : I64) : Bool =>
    """
    Record count values rounded to significant figures precision
    """
    @hdr_record_value[Bool](data, value, count)

  fun record_corrected_value(value : I64, expected : I64) : Bool =>
    """
    Record a value rounded to significant figures precision.

    If the value is larger than the **expected** interval then
    the latency recording system has experienced co-ordinated
    ommission. This function corrects the record to what would
    have occurred had the load *not* been blocked.
    """
    @hdr_record_corrected_value[Bool](data, value, expected)

  fun record_corrected_values(value : I64, count : I64, expected : I64) : Bool =>
    """
    Record count values rounded to significant figures precision.


    If the value is larger than the **expected** interval then
    the latency recording system has experienced co-ordinated
    ommission. This function corrects the record to what would
    have occurred had the load *not* been blocked.
    """
    @hdr_record_corrected_value[Bool](data, count, value, expected)

  fun add(from : HdrHistogram): I64 =>
    """
    Add all values in the from histogram to this one.

    The number of values dropped whilst copying will be returned.

    The values will be dropped if they are outside the highest 
    trackable value range.
    """
    @hdr_add[I64](data, from.data)

  fun add_corrected(from : HdrHistogram, expected: I64): I64 =>
    """
    Add all values in the from histogram to this one.

    The number of values dropped whilst copying will be returned.

    The values will be dropped if they are outside the highest 
    trackable value range.

    If the value is larger than the **expected** interval then
    the latency recording system has experienced co-ordinated
    ommission. This function corrects the record to what would
    have occurred had the load *not* been blocked.
    """
    @hdr_add_while_correcting_for_coordinated_ommission[I64](data, from.data, expected)

  fun min(): I64 ? =>
    """
    Get the minimum value recorded by the histogram.
    Will return 2^63-1 if the histogram is empty.
    """
    data().min

  fun max(): I64 ? =>
    """
    Get the maximum value recorded by the histogram.
    Will return 0 if the histogram is empty.
    """
    data().max

  fun mean(): F64 =>
    """
    Get the mean for the values recorded by the histogram.
    """
    @hdr_mean[F64](data)
  
  fun median(): I64 =>
    """
    Get the median for the values recorded by the histogram.
    """
    value_at_percentile(0.5)

  fun stddev(): F64 =>
    """
    Get the standard deviation for the values recorded by the histogram.
    """
    @hdr_stddev[F64](data)

  fun value_at_percentile(percentile : F64) : I64 =>
    """
    Get the value at a specific percentile
    """
    @hdr_value_at_percentile[I64](data, percentile)

  fun values_are_equivalent(a : I64, b : I64) : Bool =>
    """
    Determine if two values are equivalent given the resolution
    of the histogram. Equivalent means that the samples are
    counted in a common total count.
    """
    @hdr_values_are_equivalent[Bool](data, a, b)

  fun lowest_equivalent_value(value : I64) : I64 =>
    """
    Get the lowest value that is equivalent to the sample value.
    Equivalent means that the samples are counted in the common
    total count.
    """
    @hdr_lowest_equivalent_value[I64](data, value)

  fun count_at_value(value : I64) : I64 =>
    """
    Get the count of recorded values at a specific value to
    within the histogram resolution at that value level
    """
    @hdr_count_at_value[I64](data, value)

  fun count_at_index(index: I32) : I64 =>
    """
    Get the count of recorded values at a specific index to
    within the histogram resolution at that index's value level
    """
    @hdr_count_at_index[I64](data, index)


  fun value_at_index(index: I32) : I64 =>
    """
    Get the recorded value at a specific index to within the
    histogram resolution
    """
    @hdr_value_at_index[I64](data, index)
