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

#ifndef __HDR_PONY_HELPER_H_
#define __HDR_PONY_HELPER_H_

#include <stdlib.h>
#include <hdr/hdr_histogram.h>

struct hdr_iter* 
ponyx_alloc_hdr_iter();

void 
ponyx_destroy_hdr_iter(struct hdr_iter *mem);

struct hdr_iter* 
ponyx_iter_current(struct hdr_iter*);

struct hdr_iter_percentiles* 
ponyx_iter_percentiles_current(struct hdr_iter*);

struct hdr_iter_recorded* 
ponyx_iter_recorded_current(struct hdr_iter*);

struct hdr_iter_linear* 
ponyx_iter_linear_current(struct hdr_iter*);

struct hdr_iter_log* 
ponyx_iter_log_current(struct hdr_iter*);

#endif
