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

class HdrPercentilesIterator is Iterator[NativePercentilesIter]
  """
  This class is an interator over HDR Histogram's by percentile
  """
  let _h : HdrHistogram
  let _tphd : I32
  let _iter : _NativeVoidStar = @ponyx_alloc_hdr_iter[_NativeVoidStar]()

  new create(h : HdrHistogram, ticks_per_half_distance : I32) =>
    """
    Create a new instance of a HDR Histogram Percentile's Iterator
    """
    _h = h
    _tphd = ticks_per_half_distance
    @hdr_iter_percentile_init[None](_iter, _h.data, ticks_per_half_distance)

  fun has_next(): Bool =>
    """
    If there are more values, returns true. False, otherwise.
    """
    let result = @hdr_iter_next[Bool](_iter)
    result

  fun cc(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.cc

  fun hev(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.hev

  fun next(): NativePercentilesIter =>
    """
    Returns the current percentile being iterated
    """
    let current = @ponyx_iter_current[_NativeIter](_iter)
    @ponyx_iter_percentiles_current[NativePercentilesIter](current)

  fun _final() =>
  """
  Free the underlying hdr histogram Iterator
  """
  @ponyx_destroy_hdr_iter[None](_iter)

class HdrRecordedIterator
  """
  This class is an interator over HDR Histogram's by recorded value
  """
  let _h : HdrHistogram
  var _iter : _NativeVoidStar = @ponyx_alloc_hdr_iter[_NativeVoidStar]()
  var _next : Bool = true

  new create(h : HdrHistogram) =>
    """
    Create a new instance of a HDR Histogram Recorded value Iterator
    """
    _h = h
    @hdr_iter_recorded_init[None](_iter, _h.data)

  fun ref has_next(): Bool =>
    """
    If there are more values, returns true. False, otherwise.
    """
    _next = @hdr_iter_next[Bool](_iter)
    _next

  fun c(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.c

  fun cc(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.cc

  fun hev(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.hev

  fun ref next(): NativeRecordedIter =>
    """
    Returns the current record being iterated
    """
    @ponyx_iter_recorded_current[NativeRecordedIter](_iter)

  fun _final() =>
  """
  Free the underlying hdr histogram Iterator
  """
  @ponyx_destroy_hdr_iter[None](_iter)

class HdrLinearIterator is Iterator[NativeLinearIter]
  """
  This class is an linear iterator over HDR Histogram's
  """
  let _h : HdrHistogram
  let _vupb : I64
  let _iter : _NativeVoidStar = @ponyx_alloc_hdr_iter[_NativeVoidStar]()
  var _next : Bool = true

  new create(h : HdrHistogram, value_units_per_bucket : I64) =>
    """
    Create a new instance of a HDR Histogram Linear Iterator
    """
    _h = h
    _vupb = value_units_per_bucket
    @hdr_iter_linear_init[None](_iter, _h.data, _vupb)

  fun ref has_next(): Bool =>
    """
    If there are more values, returns true. False, otherwise.
    """
   _next = @hdr_iter_next[Bool](_iter) ; _next

  fun c(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.c

  fun cc(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.cc

  fun ref next(): NativeLinearIter =>
    """
    Returns the current record being iterated
    """
    @ponyx_iter_linear_current[NativeLinearIter](_iter)

  fun _final() =>
  """
  Free the underlying hdr histogram Iterator
  """
  @ponyx_destroy_hdr_iter[None](_iter)

class HdrLogIterator is Iterator[NativeLogIter]
  """
  This class is an log iterator over HDR Histogram's
  """
  let _h : HdrHistogram
  let _vufb : I64
  let _lb : F64
  let _iter : _NativeVoidStar = @ponyx_alloc_hdr_iter[_NativeVoidStar]()
  var _next : Bool = true

  new create(h : HdrHistogram, value_units_first_bucket : I64, log_base : F64) =>
    """
    Create a new instance of a HDR Histogram Log Iterator
    """
    _h = h
    _vufb = value_units_first_bucket
    _lb = log_base
    @hdr_iter_log_init[None](_iter, _h.data, value_units_first_bucket, log_base)

  fun ref has_next(): Bool =>
    """
    If there are more values, returns true. False, otherwise.
    """
    _next = @hdr_iter_next[Bool](_iter) ; _next


  fun c(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.c

  fun cc(): I64 =>
    let current = @ponyx_iter_current[_NativeIter](_iter)
    current.cc

  fun ref next(): NativeLogIter =>
    """
    Returns the current record being iterated
    """
    @ponyx_iter_log_current[NativeLogIter](_iter)

  fun _final() =>
  """
  Free the underlying hdr histogram Iterator
  """
  @ponyx_destroy_hdr_iter[None](_iter)
