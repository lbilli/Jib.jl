using ProtoLite: ProtoLite as PB
using Test

"""
syntax = "proto3";

message TagValue {
  optional string key = 1;
  optional string value = 2;
  }

message Test {
  optional int32 a = 1;
  optional int64 b = 2;
  optional bool c = 3;
  optional double d = 4;
  optional string e = 5;
  optional TagValue f = 6;
  repeated int32 g = 7;
  repeated double h = 8;
  repeated string i = 9;
  repeated TagValue j = 10;
  optional int32 k = 11;
  repeated int32 l = 536870911;
}

{
  "a": -123,
  "b": 12,
  "c": true,
  "d": -123e-5,
  "e": "∈abcα",
  "f": { "key": "key", "value": "val" },
  "g": [ -12, 12, 24 ],
  "h": [ -1e2, 12 ],
  "i": [ "", "a", "∈abcα" ],
  "j": [ { "key": "k1", "value": "v1" }, { "key": "k2", "value": "v2" } ],
  "l": [ 4 ]
}
"""

pbstr = "0885ffffffffffffffff01100c180121d7868a71fe2654bf2a08e28888616263ceb1320a0a036b6579120376616c3a0cf4ffffffffffffffff010c18421000000000000059c000000000000028404a004a01614a08e28888616263ceb152080a026b311202763152080a026b3212027632faffffff0f0104"

pb = parse.(UInt8, Iterators.partition(pbstr, 2), base=16)

@testset "Pool" begin

  @test PB.readprotodir(".")

  @test length(PB.POOL) == 2
end

include("codec.jl")
