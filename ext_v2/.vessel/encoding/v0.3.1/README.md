# Encoding

[![Docs](https://img.shields.io/badge/dfx-0.8.0-yellow)](https://dfinity.org/developers)

## Base32

Implements base32 encoding as specified by RFC 4648.

## Binary

Provides simple translation between numbers and byte sequences.

### Usage

```motoko
Binary.LittleEndian.fromNat16(0xFF)
// [255, 0]

Binary.BigEndian.fromNat16(0xFF)
// [0, 255]
```

## Hex

Provides hexadecimal encoding and decoding methods for Motoko.

### Usage

Encode an array of unsigned 8-bit integers in hexadecimal format.

```motoko
encode(ns : [Nat8]) : Text
```

Decode an array of unsigned 8-bit integers in hexadecimal format.

```motoko
decode(t : Text) : Result<[Nat8],Text>
```
