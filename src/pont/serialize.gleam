import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/function
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/pair
import gleam/result
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}
import pont/spec
import pont/value
import taffy as yaml
import taffy/value.{type YamlValue as Yaml} as _yaml

pub type RawDecoder(a) =
  decode.Decoder(a)

pub type Decoder(a) {
  Decoder(decoder: RawDecoder(a), spec: spec.Spec)
}

pub type RawEncoder(a) =
  fn(a) -> value.Value

pub type Encoder(a) {
  Encoder(encoder: RawEncoder(a), spec: spec.Spec)
}

pub type Serializer(a) {
  Serializer(decoder: RawDecoder(a), encoder: RawEncoder(a), spec: spec.Spec)
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          Primitives                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn null() -> Serializer(Nil) {
  Serializer(
    decoder: decode.success(Nil),
    encoder: fn(_) { value.null() },
    spec: spec.null(),
  )
}

pub fn string() -> Serializer(String) {
  Serializer(decoder: decode.string, encoder: value.string, spec: spec.string())
}

pub fn bool() -> Serializer(Bool) {
  Serializer(decoder: decode.bool, encoder: value.bool, spec: spec.bool())
}

pub fn int() -> Serializer(Int) {
  Serializer(decoder: decode.int, encoder: value.int, spec: spec.int())
}

fn ensure_within(
  decoder: RawDecoder(a),
  min: a,
  max: a,
  compare: fn(a, a) -> order.Order,
  to_string: fn(a) -> String,
) -> RawDecoder(a) {
  use value <- decode.then(decoder)
  case compare(value, min), compare(value, max) {
    order.Lt, _ | _, order.Gt ->
      decode.failure(
        min,
        "Value not within bounds ["
          <> to_string(min)
          <> "; "
          <> to_string(max)
          <> "]",
      )
    _, _ -> decode.success(value)
  }
}

pub fn int_within(min: Int, max: Int) -> Serializer(Int) {
  Serializer(
    decoder: ensure_within(decode.int, min, max, int.compare, int.to_string),
    encoder: value.int,
    spec: spec.int_within(min, max),
  )
}

pub fn float() -> Serializer(Float) {
  Serializer(decoder: decode.float, encoder: value.float, spec: spec.float())
}

pub fn float_within(min: Float, max: Float) -> Serializer(Float) {
  Serializer(
    decoder: ensure_within(
      decode.float,
      min,
      max,
      float.compare,
      float.to_string,
    ),
    encoder: value.float,
    spec: spec.float_within(min, max),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             List                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn list(of: Serializer(a)) -> Serializer(List(a)) {
  Serializer(
    decoder: decode.list(of.decoder),
    encoder: value.list_of(_, of.encoder),
    spec: spec.array(of.spec),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                           Optional                                            //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn optional(of: Serializer(a)) -> Serializer(Option(a)) {
  Serializer(
    decoder: decode.optional(of.decoder),
    encoder: value.nullable_of(_, of.encoder),
    spec: spec.option(of.spec),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Enum                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn string_enum(
  values: List(a),
  to_string: fn(a) -> String,
) -> Serializer(a) {
  let assert [first, ..] = values
  Serializer(
    decoder: decode.then(decode.string, fn(value) {
      values
      |> list.map(fn(value) { #(to_string(value), value) })
      |> list.key_find(value)
      |> result.map(decode.success)
      |> result.unwrap(decode.failure(first, "Value not in enum"))
    }),
    encoder: fn(value) { value |> to_string |> value.string },
    spec: spec.string_enum(values |> list.map(to_string)),
  )
}

pub type EnumVariant(a) {
  EnumVariant(
    decoder: RawDecoder(a),
    encoder: fn(a) -> Result(value.Value, Nil),
    spec: spec.Spec,
  )
}

pub fn enum(
  first: EnumVariant(t),
  or alternative: List(EnumVariant(t)),
) -> Serializer(t) {
  Serializer(
    decoder: decode.one_of(
      first.decoder,
      list.map(alternative, fn(variant) { variant.decoder }),
    ),
    encoder: fn(data) {
      [first, ..alternative]
      |> list.find_map(fn(variant) { variant.encoder(data) })
      |> result.unwrap(value.null())
    },
    spec: [first, ..alternative]
      |> list.map(fn(variant) { variant.spec })
      |> spec.union(),
  )
}

pub fn variant(
  serializer serializer: Serializer(b),
  mapper mapper: fn(b) -> a,
  inverse_mapper inverse_mapper: fn(a) -> Result(b, Nil),
) -> EnumVariant(a) {
  EnumVariant(
    decoder: decode.map(serializer.decoder, mapper),
    encoder: fn(value) {
      value
      |> inverse_mapper
      |> result.map(serializer.encoder)
    },
    spec: serializer.spec,
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                           Timestamp                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn timestamp() -> Serializer(Timestamp) {
  Serializer(
    decoder: decode.then(decode.string, fn(value) {
      value
      |> timestamp.parse_rfc3339()
      |> result.map(decode.success)
      |> result.unwrap(decode.failure(timestamp.unix_epoch, "Invalid timestamp"))
    }),
    encoder: fn(timestamp) {
      timestamp
      |> timestamp.to_rfc3339(calendar.utc_offset)
      |> value.string
    },
    spec: spec.string() |> spec.with_format(spec.DatetimeFormat),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Value                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn value_decoder() -> RawDecoder(value.Value) {
  use <- decode.recursive
  decode.one_of(decode.string |> decode.map(value.string), [
    decode.int |> decode.map(value.int),
    decode.bool |> decode.map(value.bool),
    decode.float |> decode.map(value.float),
    decode.list(value_decoder()) |> decode.map(value.list),
    decode.dict(decode.string, value_decoder())
      |> decode.map(dict.to_list)
      |> decode.map(value.object),
  ])
}

pub fn value() -> Serializer(value.Value) {
  Serializer(
    decoder: value_decoder(),
    encoder: function.identity,
    spec: spec.object([]),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                        Object & Fields                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

type FieldEncoder(a) =
  #(String, RawEncoder(a))

pub opaque type Context(t) {
  Context(spec: fn() -> spec.Spec, encoders: List(FieldEncoder(t)))
}

pub fn empty_object() -> Serializer(Nil) {
  object(build(_, Nil))
}

pub fn object(
  next: fn(Context(t)) -> RawDecoder(#(Context(t), t)),
) -> Serializer(t) {
  let result = next(Context(spec: fn() { spec.object([]) }, encoders: []))
  Serializer(
    decoder: decode.map(result, pair.second),
    encoder: fn(data) {
      let encoders =
        decode.run(dynamic.nil(), decode.map_errors(result, fn(_) { [] }))
        |> result.map(fn(value) { value.0.encoders })
        |> result.unwrap([])

      value.object(
        encoders
        |> list.reverse
        |> list.map(pair.map_second(_, fn(encoder) { encoder(data) })),
      )
    },
    spec: decode.run(dynamic.nil(), decode.map_errors(result, fn(_) { [] }))
      |> result.map(fn(value) { value.0.spec() })
      |> result.unwrap(spec.object([])),
  )
}

pub fn field(
  context context: Context(final),
  name name: String,
  serializer serializer: Serializer(t),
  getter getter: fn(final) -> t,
  next next: fn(Context(final), t) -> RawDecoder(#(Context(final), final)),
) -> RawDecoder(#(Context(final), final)) {
  use value <- decode.field(name, serializer.decoder)

  next(
    Context(
      spec: fn() {
        let doc = context.spec()
        let property =
          spec.ObjectField(name: name, spec: serializer.spec, required: True)
        case doc {
          spec.Object(..) ->
            spec.Object(..doc, fields: list.append(doc.fields, [property]))
          _ -> spec.object([property])
        }
      },
      encoders: [
        #(name, fn(object) { serializer.encoder(getter(object)) }),
        ..context.encoders
      ],
    ),
    value,
  )
}

pub fn optional_field(
  context context: Context(final),
  name name: String,
  default default: t,
  serializer serializer: Serializer(t),
  getter getter: fn(final) -> t,
  next next: fn(Context(final), t) -> RawDecoder(#(Context(final), final)),
) -> RawDecoder(#(Context(final), final)) {
  use value <- decode.optional_field(name, default, serializer.decoder)

  next(
    Context(
      spec: fn() {
        let spec = context.spec()
        let field =
          spec.ObjectField(name: name, spec: serializer.spec, required: False)
        case spec {
          spec.Object(..) ->
            spec.Object(..spec, fields: list.append(spec.fields, [field]))
          _ -> spec.object([field])
        }
      },
      encoders: [
        #(name, fn(object) { object |> getter |> serializer.encoder }),
        ..context.encoders
      ],
    ),
    value,
  )
}

fn indexed_field_loop(
  context context: Context(final),
  name name: String,
  index index: Int,
  max max: Int,
  serializer serializer: Serializer(t),
  getter getter: fn(final, Int) -> t,
  next next: fn(Context(final), List(t)) -> RawDecoder(#(Context(final), final)),
) -> RawDecoder(#(Context(final), final)) {
  case index {
    0 -> next(context, [])
    _ -> {
      use context, value <- field(
        context,
        name <> "[" <> int.to_string(max - index) <> "]",
        serializer,
        getter(_, max - index),
      )

      use context, rest <- indexed_field_loop(
        context,
        name,
        index - 1,
        max,
        serializer,
        getter,
      )
      next(context, [value, ..rest])
    }
  }
}

pub fn indexed_field(
  context context: Context(final),
  name name: String,
  count count: Int,
  serializer serializer: Serializer(t),
  getter getter: fn(final, Int) -> t,
  next next: fn(Context(final), List(t)) -> RawDecoder(#(Context(final), final)),
) -> RawDecoder(#(Context(final), final)) {
  indexed_field_loop(
    context,
    name,
    count,
    count,
    serializer,
    getter,
    fn(context, values) { next(context, values) },
  )
}

fn optional_indexed_field_loop(
  context context: Context(final),
  name name: String,
  index index: Int,
  max max: Int,
  default default: t,
  serializer serializer: Serializer(t),
  getter getter: fn(final, Int) -> t,
  next next: fn(Context(final), List(t)) -> RawDecoder(#(Context(final), final)),
) -> RawDecoder(#(Context(final), final)) {
  case index {
    0 -> next(context, [])
    _ -> {
      use context, value <- optional_field(
        context,
        name <> "[" <> int.to_string(max - index) <> "]",
        default,
        serializer,
        getter(_, max - index),
      )

      use context, rest <- optional_indexed_field_loop(
        context,
        name,
        index - 1,
        max,
        default,
        serializer,
        getter,
      )
      next(context, [value, ..rest])
    }
  }
}

pub fn optional_indexed_field(
  context context: Context(final),
  name name: String,
  count count: Int,
  default default: t,
  serializer serializer: Serializer(t),
  getter getter: fn(final, Int) -> t,
  next next: fn(Context(final), List(t)) -> RawDecoder(#(Context(final), final)),
) -> RawDecoder(#(Context(final), final)) {
  optional_indexed_field_loop(
    context,
    name,
    count,
    count,
    default,
    serializer,
    getter,
    fn(context, values) { next(context, values) },
  )
}

pub fn build(context: Context(t), value: t) -> RawDecoder(#(Context(t), t)) {
  decode.success(#(context, value))
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                           Modifiers                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn with_default(
  serializer: Serializer(a),
  default: value.Value,
) -> Serializer(a) {
  Serializer(
    decoder: serializer.decoder,
    encoder: serializer.encoder,
    spec: spec.with_default(serializer.spec, default),
  )
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Encoder & Decoder                                       //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn decoder(serializer: Serializer(t)) -> Decoder(t) {
  Decoder(decoder: serializer.decoder, spec: serializer.spec)
}

pub fn encoder(serializer: Serializer(t)) -> Encoder(t) {
  Encoder(encoder: serializer.encoder, spec: serializer.spec)
}

pub fn decode_with_decoder(
  value: dynamic.Dynamic,
  decoder: Decoder(t),
) -> Result(t, List(decode.DecodeError)) {
  decode.run(value, decoder.decoder)
}

pub fn decode(
  value: dynamic.Dynamic,
  serializer: Serializer(t),
) -> Result(t, List(decode.DecodeError)) {
  decode_with_decoder(value, decoder(serializer))
}

pub fn decode_json_with_decoder(
  json: String,
  decoder: Decoder(t),
) -> Result(t, json.DecodeError) {
  json.parse(json, decoder.decoder)
}

pub fn decode_json(
  json: String,
  serializer: Serializer(t),
) -> Result(t, json.DecodeError) {
  decode_json_with_decoder(json, decoder(serializer))
}

pub fn decode_yaml_with_decoder(
  yaml: String,
  decoder: Decoder(t),
) -> Result(t, yaml.YamlDecodeError) {
  yaml.decode(yaml, decoder.decoder)
}

pub fn decode_yaml(
  yaml: String,
  serializer: Serializer(t),
) -> Result(t, yaml.YamlDecodeError) {
  decode_yaml_with_decoder(yaml, decoder(serializer))
}

pub fn encode_with_encoder(value: t, of encoder: Encoder(t)) -> value.Value {
  encoder.encoder(value)
}

pub fn encode(value: t, of serializer: Serializer(t)) -> value.Value {
  encode_with_encoder(value, encoder(serializer))
}

/// Directly encode a value using the given encoder to JSON.
pub fn encode_json_with_encoder(a: a, of encoder: Encoder(a)) -> Json {
  value.to_json(encode_with_encoder(a, of: encoder))
}

/// Directly encode a value using the given serializer to JSON.
pub fn encode_json(a: a, of serializer: Serializer(a)) -> Json {
  encode_json_with_encoder(a, of: encoder(serializer))
}

/// Directly encode a value using the given encoder to JSON.
pub fn encode_yaml_with_encoder(a: a, of encoder: Encoder(a)) -> Yaml {
  value.to_yaml(encode_with_encoder(a, of: encoder))
}

/// Directly encode a value using the given serializer to JSON.
pub fn encode_yaml(a: a, of serializer: Serializer(a)) -> Yaml {
  encode_yaml_with_encoder(a, of: encoder(serializer))
}
