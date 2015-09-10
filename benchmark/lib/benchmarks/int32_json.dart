// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protoc.benchmark.int32_json;

import '../benchmark.dart';
import '../generated/benchmark.pb.dart' show BenchmarkID, Request, Params, Sample;
import '../generated/intgrid.pb.dart' as pb;

/// A benchmark that deserializes a grid of int fields.
class Int32Benchmark extends Benchmark {
  final int width;
  final int height;
  String json;
  int lastFieldTag;

  Int32Benchmark(this.width, this.height) : super($id);

  @override
  get summary => "${id.name}($width x $height ints)";

  @override
  Params makeParams() => new Params()
    ..int32FieldCount = width
    ..messageCount = height;

  @override
  void setup() {
    var grid = _makeGrid(width, height);
    json = grid.writeToJson();
    lastFieldTag = getTagForColumn(new pb.Line10(), width - 1);
  }

  // makes a rectangle of the of the form:
  // 0 1 2 3
  // 1 2 3 4
  // 2 3 4 5
  static pb.Grid10 _makeGrid(int width, int height) {
    if (width > 10) throw new ArgumentError("width out of range: ${width}");
    var grid = new pb.Grid10();

    for (int y = 0; y < height; y++) {
      var line = new pb.Line10();
      for (int x = 0; x < width; x++) {
        int tag = getTagForColumn(line, x);
        line.setField(tag, x + y);
      }
      grid.lines.add(line);
    }

    return grid;
  }

  static int getTagForColumn(pb.Line10 line, int x) {
    return line.getTagNumber('cell${x+1}'); // assume x start from 1
  }

  @override
  void run() {
    pb.Grid10 grid = new pb.Grid10.fromJson(json);
    var actual = grid.lines[height - 1].getField(lastFieldTag);
    if (actual != width + height - 2) throw "failed; got ${actual}";
  }

  @override
  void setCounts(Sample s) {
    s.counts.int32Reads = width * height * s.loopCount;
  }

  static const $id = BenchmarkID.READ_INT32_FIELDS_JSON;
  static final $type = new BenchmarkType($id, $create);

  static $create(Request r) {
    assert(r.params.hasInt32FieldCount());
    assert(r.params.hasMessageCount());
    return new Int32Benchmark(r.params.int32FieldCount, r.params.messageCount);
  }
}