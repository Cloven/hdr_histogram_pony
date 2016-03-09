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

use "path:/usr/local/lib"
use "lib:hdr_histogram_static"
use "lib:hdr_histogram_pony_helper"

type _NativeDataPoints is Pointer[I64]
  """
  A pony wrapper of the data points ( counts ) embedded in the
  native C hdr_histogram struct
  """

struct _NativeHdrHistogram
  """
  Pony mapping of the native C hdr_histogram struct:
  
  ```
  struct hdr_histogram
  {
    int64_t lowest_trackable_value;
    int64_t highest_trackable_value;
    int32_t unit_magnitude;
    int32_t significant_figures;
    int32_t sub_bucket_half_count_magnitude;
    int32_t sub_bucket_half_count;
    int64_t sub_bucket_mask;
    int32_t sub_bucket_count;
    int32_t bucket_count;
    int64_t min_value;
    int64_t max_value;
    int32_t normalizing_index_offset;
    double conversion_ratio;
    int32_t counts_len;
    int64_t total_count;
    int64_t counts[0];
  };
  ```
  """
  var ltv   : I64 = 0           // Lowest trackable value
  var htv   : I64 = 0           // Highest trackable value 
  var um    : I32 = 0           // Unit Magnitude
  var sf    : I32 = 0           // Significant Figures
  var sbhcm : I32 = 0           // Sub Bucket Half Count Magnitude
  var sbhc  : I32 = 0           // Sub Bucket Half Count
  var sbm   : I64 = 0           // Sub Bucket Mask
  var sbc   : I32 = 0           // Sub Bucket Count
  var bc    : I32 = 0           // Bucket Count
  var min   : I64 = 0           // Min Value
  var max   : I64 = 0           // Max Value
  var nio   : I32 = 0           // Normalizing Index Offset
  var cr    : F64 = 0           // Conversin Ratio
  var cl    : I32 = 0           // Counts Length
  var tc    : I64 = 0           // Total Count
  var data  : _NativeDataPoints  // Data
    = _NativeDataPoints

struct NativePercentilesIter
  """
  Pony mapping of the native hdr_iter_percentiles struct:

  ```
  struct hdr_iter_percentiles
  {
    bool seen_last_value;
    int32_t ticks_per_half_distance;
    double percentile_to_iterate_to;
    double percentile;
  };
  ```
  """
  var slv   : Bool = false      // Seen Last Value
  var tphd  : I32 = 0           // Ticks per half distance
  var ptit  : F64 = 0           // Percentile to iterate to
  var pcnt  : F64 = 0           // Percentile

struct NativeRecordedIter
  """
  Pony mapping of the native hdr_iter_recorded struct:
  ```
  struct hdr_iter_recorded
  {
    int64_t count_added_in_this_iteration_step;
  };
  ```
  """
  var caitis: I64 = 0           // Count added in this iteration step

struct NativeLinearIter
  """
  Pony mapping of the native hdr_iter_linear struct:
  ```
  struct hdr_iter_linear
  {
    int64_t value_units_per_bucket;
    int64_t count_added_in_this_iteration_step;
    int64_t next_value_reporting_level;
    int64_t next_value_reporting_level_lowest_equivalent;
  };
  ```
  """
  var vupb   : I64 = 0          // Value units per bucket
  var caitis : I64 = 0          // Count added in this iteration step
  var nvrl   : I64 = 0          // Next value reporting level
  var nvrlle : I64 = 0          // next value reporting level lowest equivalent

struct NativeLogIter
  """
  Pony mapping of the native hdr_iter_log struct:
  ```
  struct hdr_iter_log
  {
    double log_base;
    int64_t count_added_in_this_iteration_step;
    int64_t next_value_reporting_level;
    int64_t next_value_reporting_level_lowest_equivalent;
  };
  ```
  """
  var lb     : F64 = 0          // Log base
  var caitis : I64 = 0          // Count added in this iteration step
  var nvrl   : I64 = 0          // Next value reporting level
  var nvrlle : I64 = 0          // Next value reporting level lowest equivalent

// struct _NativeIterSpecifics is (
//   NativePercentilesIter | 
//   NativeRecordedIter | 
//   NativeLinearIter | 
//   NativeLogIter
//   )
// """ An equivalent of the union embedded in the C native hdr_iter """

type _NativeVoidStar is Maybe[Pointer[U8]]
  """ 
  A C void pointer equivalent to support histogram iteration
  """

struct _NativeIter
  """
  Partial pony mapping of the native hdr_iter struct:
  ```
  struct hdr_iter
  {
    const struct hdr_histogram* h;
    int32_t counts_index;
    int64_t count;
    int64_t cumulative_count;
    int64_t value;
    int64_t highest_equivalent_value;
    int64_t lowest_equivalent_value;
    int64_t median_equivalent_value;
    int64_t value_iterated_from;
    int64_t value_iterated_to;

    union
    {
        struct hdr_iter_percentiles percentiles;
        struct hdr_iter_recorded recorded;
        struct hdr_iter_linear linear;
        struct hdr_iter_log log;
    } specifics;

    bool (*_next_fp)(struct hdr_iter* iter);    // NOTE (1)

  };
  ```

  (1) Pony's support for FFI, at the time of writing, does not support
  passing native C ABI function pointers to Pony. As the function
  pointer in the C hdr_iter struct is the *last* struct field, we 
  simply elide the definition in the Pony equivalent mapping thereby
  occluding it from Pony.

  As the C implementation of HDR Histogram provides a generic iteration
  facility for iterating over histogram's, we instead leverage those 
  implementations and can entirely avoid handling or working around
  the Pony C function pointer limitation. The Pony mapping is sufficient
  for these purposes and for providing Pony Iterator's wrapping the
  HDR Histogram native iterators.
  """
  var data   : _NativeHdrHistogram = _NativeHdrHistogram
  var ci     : I32 = 0        // Counts index
  var c      : I64 = 0        // Count
  var cc     : I64 = 0        // Cumulative count
  var v      : I64 = 0        // Current value based on counts index
  var hev    : I64 = 0        // Highest equivalent value
  var lev    : I64 = 0        // Lowest equivalent value
  var mev    : I64 = 0        // Median equivalent value
  var vif    : I64 = 0        // Value iterated from
  var vit    : I64 = 0        // Value iterated to
  var s      : _NativeVoidStar = _NativeVoidStar.none()

