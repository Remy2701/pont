import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/time/timestamp
import pont/serialize
import pont/spec
import pont/value
import taffy
import taffy/value as yaml_value

pub fn serialize_string_decode_test() {
  let result =
    dynamic.string("Hello")
    |> serialize.decode(serialize.string())

  let assert Ok("Hello") = result
}

pub fn serialize_string_encode_test() {
  let result =
    "Hello"
    |> serialize.encode(serialize.string())

  let assert value.String("Hello") = result
}

pub fn serialize_string_spec_test() {
  let result = serialize.string().spec

  let assert spec.String(format: None, ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Bool                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_bool_decode_test() {
  let result =
    dynamic.bool(True)
    |> serialize.decode(serialize.bool())

  let assert Ok(True) = result
}

pub fn serialize_bool_encode_test() {
  let result =
    True
    |> serialize.encode(serialize.bool())

  let assert value.Boolean(True) = result
}

pub fn serialize_bool_spec_test() {
  let result = serialize.bool().spec

  let assert spec.Boolean(..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Null                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_null_decode_test() {
  let result =
    dynamic.nil()
    |> serialize.decode(serialize.null())

  let assert Ok(Nil) = result
}

pub fn serialize_null_encode_test() {
  let result =
    Nil
    |> serialize.encode(serialize.null())

  let assert value.Null = result
}

pub fn serialize_null_spec_test() {
  let result = serialize.null().spec

  let assert spec.Null(..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                              Int                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_int_decode_test() {
  let result =
    dynamic.int(42)
    |> serialize.decode(serialize.int())

  let assert Ok(42) = result
}

pub fn serialize_int_encode_test() {
  let result =
    42
    |> serialize.encode(serialize.int())

  let assert value.Integer(42) = result
}

pub fn serialize_int_spec_test() {
  let result = serialize.int().spec

  let assert spec.Integer(min: None, max: None, ..) = result
}

pub fn serialize_int_within_decode_test() {
  let result =
    dynamic.int(5)
    |> serialize.decode(serialize.int_within(0, 10))

  let assert Ok(5) = result
}

pub fn serialize_int_within_decode_out_of_bounds_test() {
  let result =
    dynamic.int(100)
    |> serialize.decode(serialize.int_within(0, 10))

  let assert Error(_) = result
}

pub fn serialize_int_within_encode_test() {
  let result =
    5
    |> serialize.encode(serialize.int_within(0, 10))

  let assert value.Integer(5) = result
}

pub fn serialize_int_within_spec_test() {
  let result = serialize.int_within(0, 10).spec

  let assert spec.Integer(min: Some(0), max: Some(10), ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Float                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_float_decode_test() {
  let result =
    dynamic.float(3.14)
    |> serialize.decode(serialize.float())

  let assert Ok(3.14) = result
}

pub fn serialize_float_encode_test() {
  let result =
    3.14
    |> serialize.encode(serialize.float())

  let assert value.Float(3.14) = result
}

pub fn serialize_float_spec_test() {
  let result = serialize.float().spec

  let assert spec.Float(min: None, max: None, ..) = result
}

pub fn serialize_float_within_decode_test() {
  let result =
    dynamic.float(0.5)
    |> serialize.decode(serialize.float_within(0.0, 1.0))

  let assert Ok(0.5) = result
}

pub fn serialize_float_within_decode_out_of_bounds_test() {
  let result =
    dynamic.float(5.0)
    |> serialize.decode(serialize.float_within(0.0, 1.0))

  let assert Error(_) = result
}

pub fn serialize_float_within_encode_test() {
  let result =
    0.5
    |> serialize.encode(serialize.float_within(0.0, 1.0))

  let assert value.Float(0.5) = result
}

pub fn serialize_float_within_spec_test() {
  let result = serialize.float_within(0.0, 1.0).spec

  let assert spec.Float(min: Some(0.0), max: Some(1.0), ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             List                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_list_decode_test() {
  let result =
    dynamic.list([dynamic.string("a"), dynamic.string("b")])
    |> serialize.decode(serialize.list(serialize.string()))

  let assert Ok(["a", "b"]) = result
}

pub fn serialize_list_encode_test() {
  let result =
    ["a", "b"]
    |> serialize.encode(serialize.list(serialize.string()))

  let assert value.List([value.String("a"), value.String("b")]) = result
}

pub fn serialize_list_spec_test() {
  let result = serialize.list(serialize.string()).spec

  let assert spec.Array(of: spec.String(..), ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                           Optional                                            //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_optional_decode_some_test() {
  let result =
    dynamic.string("a")
    |> serialize.decode(serialize.optional(serialize.string()))

  let assert Ok(Some("a")) = result
}

pub fn serialize_optional_decode_none_test() {
  let result =
    dynamic.nil()
    |> serialize.decode(serialize.optional(serialize.string()))

  let assert Ok(None) = result
}

pub fn serialize_optional_encode_some_test() {
  let result =
    Some("a")
    |> serialize.encode(serialize.optional(serialize.string()))

  let assert value.String("a") = result
}

pub fn serialize_optional_encode_none_test() {
  let result =
    None
    |> serialize.encode(serialize.optional(serialize.string()))

  let assert value.Null = result
}

pub fn serialize_optional_spec_test() {
  let result = serialize.optional(serialize.string()).spec

  let assert spec.Option(of: spec.String(..), ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                          String enum                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub type Color {
  Red
  Green
  Blue
}

fn color_serializer() -> serialize.Serializer(Color) {
  serialize.string_enum([Red, Green, Blue], fn(color) {
    case color {
      Red -> "red"
      Green -> "green"
      Blue -> "blue"
    }
  })
}

pub fn serialize_string_enum_decode_test() {
  let result =
    dynamic.string("green")
    |> serialize.decode(color_serializer())

  let assert Ok(Green) = result
}

pub fn serialize_string_enum_decode_invalid_test() {
  let result =
    dynamic.string("purple")
    |> serialize.decode(color_serializer())

  let assert Error(_) = result
}

pub fn serialize_string_enum_encode_test() {
  let result =
    Green
    |> serialize.encode(color_serializer())

  let assert value.String("green") = result
}

pub fn serialize_string_enum_spec_test() {
  let result = color_serializer().spec

  let assert spec.String(enum_variants: ["red", "green", "blue"], ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Enum & variant                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub type IntOrString {
  AsInt(Int)
  AsString(String)
}

fn int_or_string_serializer() -> serialize.Serializer(IntOrString) {
  serialize.enum(
    serialize.variant(serialize.int(), AsInt, fn(value) {
      case value {
        AsInt(i) -> Ok(i)
        _ -> Error(Nil)
      }
    }),
    or: [
      serialize.variant(serialize.string(), AsString, fn(value) {
        case value {
          AsString(s) -> Ok(s)
          _ -> Error(Nil)
        }
      }),
    ],
  )
}

pub fn serialize_enum_decode_int_variant_test() {
  let result =
    dynamic.int(5)
    |> serialize.decode(int_or_string_serializer())

  let assert Ok(AsInt(5)) = result
}

pub fn serialize_enum_decode_string_variant_test() {
  let result =
    dynamic.string("hi")
    |> serialize.decode(int_or_string_serializer())

  let assert Ok(AsString("hi")) = result
}

pub fn serialize_enum_encode_int_variant_test() {
  let result =
    AsInt(5)
    |> serialize.encode(int_or_string_serializer())

  let assert value.Integer(5) = result
}

pub fn serialize_enum_encode_string_variant_test() {
  let result =
    AsString("hi")
    |> serialize.encode(int_or_string_serializer())

  let assert value.String("hi") = result
}

pub fn serialize_enum_spec_test() {
  let result = int_or_string_serializer().spec

  let assert spec.Union(variants: [spec.Integer(..), spec.String(..)], ..) =
    result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                           Timestamp                                           //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_timestamp_decode_test() {
  let result =
    dynamic.string("2009-02-13T23:31:30Z")
    |> serialize.decode(serialize.timestamp())

  let assert Ok(decoded) = result
  assert decoded == timestamp.from_unix_seconds(1_234_567_890)
}

pub fn serialize_timestamp_decode_invalid_test() {
  let result =
    dynamic.string("not-a-timestamp")
    |> serialize.decode(serialize.timestamp())

  let assert Error(_) = result
}

pub fn serialize_timestamp_encode_test() {
  let result =
    timestamp.from_unix_seconds(1_234_567_890)
    |> serialize.encode(serialize.timestamp())

  let assert value.String("2009-02-13T23:31:30Z") = result
}

pub fn serialize_timestamp_spec_test() {
  let result = serialize.timestamp().spec

  let assert spec.String(format: Some(spec.DatetimeFormat), ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             Value                                             //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_value_decode_string_test() {
  let result =
    dynamic.string("hi")
    |> serialize.decode(serialize.value())

  let assert Ok(value.String("hi")) = result
}

pub fn serialize_value_decode_int_test() {
  let result =
    dynamic.int(5)
    |> serialize.decode(serialize.value())

  let assert Ok(value.Integer(5)) = result
}

pub fn serialize_value_decode_bool_test() {
  let result =
    dynamic.bool(True)
    |> serialize.decode(serialize.value())

  let assert Ok(value.Boolean(True)) = result
}

pub fn serialize_value_decode_list_test() {
  let result =
    dynamic.list([dynamic.int(1), dynamic.int(2)])
    |> serialize.decode(serialize.value())

  let assert Ok(value.List([value.Integer(1), value.Integer(2)])) = result
}

pub fn serialize_value_decode_object_test() {
  let result =
    dynamic.properties([#(dynamic.string("a"), dynamic.string("b"))])
    |> serialize.decode(serialize.value())

  let assert Ok(value.Object([#("a", value.String("b"))])) = result
}

pub fn serialize_value_encode_test() {
  let result =
    value.String("hi")
    |> serialize.encode(serialize.value())

  let assert value.String("hi") = result
}

pub fn serialize_value_spec_test() {
  let result = serialize.value().spec

  let assert spec.Object(fields: [], ..) = result
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Object & fields                                         //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub type Person {
  Person(name: String, age: Int, is_student: Bool)
}

fn person_serializer() -> serialize.Serializer(Person) {
  serialize.object(fn(context) {
    use context, name <- serialize.field(
      context,
      "name",
      serialize.string(),
      fn(person: Person) { person.name },
    )
    use context, age <- serialize.field(
      context,
      "age",
      serialize.int(),
      fn(person: Person) { person.age },
    )
    use context, is_student <- serialize.field(
      context,
      "is_student",
      serialize.bool(),
      fn(person: Person) { person.is_student },
    )

    serialize.build(context, Person(name:, age:, is_student:))
  })
}

pub fn serialize_object_decode_test() {
  let result =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.string("Alice")),
      #(dynamic.string("age"), dynamic.int(30)),
      #(dynamic.string("is_student"), dynamic.bool(True)),
    ])
    |> serialize.decode(person_serializer())

  let assert Ok(Person(name: "Alice", age: 30, is_student: True)) = result
}

pub fn serialize_object_encode_test() {
  let result =
    Person(name: "Alice", age: 30, is_student: True)
    |> serialize.encode(person_serializer())

  assert result
    == value.Object([
      #("name", value.String("Alice")),
      #("age", value.Integer(30)),
      #("is_student", value.Boolean(True)),
    ])
}

pub fn serialize_object_spec_test() {
  let result = person_serializer().spec

  assert result
    == spec.object([
      spec.ObjectField(name: "name", spec: spec.string(), required: True),
      spec.ObjectField(name: "age", spec: spec.int(), required: True),
      spec.ObjectField(name: "is_student", spec: spec.bool(), required: True),
    ])
}

pub fn serialize_object_json_round_trip_test() {
  let person = Person(name: "Alice", age: 30, is_student: True)

  let encoded =
    person
    |> serialize.encode_json(person_serializer())
    |> json.to_string

  let assert "{\"name\":\"Alice\",\"age\":30,\"is_student\":true}" = encoded

  let assert Ok(decoded) = serialize.decode_json(encoded, person_serializer())

  assert decoded == person
}

pub fn serialize_object_yaml_round_trip_test() {
  let person = Person(name: "Alice", age: 30, is_student: True)

  let encoded =
    person
    |> serialize.encode_yaml(person_serializer())
    |> taffy.to_yaml

  let assert Ok(decoded) = serialize.decode_yaml(encoded, person_serializer())

  assert decoded == person
}

fn person_with_optional_serializer() -> serialize.Serializer(Person) {
  serialize.object(fn(context) {
    use context, name <- serialize.field(
      context,
      "name",
      serialize.string(),
      fn(person: Person) { person.name },
    )
    use context, age <- serialize.field(
      context,
      "age",
      serialize.int(),
      fn(person: Person) { person.age },
    )
    use context, is_student <- serialize.optional_field(
      context: context,
      name: "is_student",
      default: False,
      serializer: serialize.bool(),
      getter: fn(person: Person) { person.is_student },
    )

    serialize.build(context, Person(name:, age:, is_student:))
  })
}

pub fn serialize_optional_field_decode_with_value_test() {
  let result =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.string("Alice")),
      #(dynamic.string("age"), dynamic.int(30)),
      #(dynamic.string("is_student"), dynamic.bool(True)),
    ])
    |> serialize.decode(person_with_optional_serializer())

  let assert Ok(Person(name: "Alice", age: 30, is_student: True)) = result
}

pub fn serialize_optional_field_decode_missing_uses_default_test() {
  let result =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.string("Alice")),
      #(dynamic.string("age"), dynamic.int(30)),
    ])
    |> serialize.decode(person_with_optional_serializer())

  let assert Ok(Person(name: "Alice", age: 30, is_student: False)) = result
}

pub fn serialize_optional_field_spec_test() {
  let result = person_with_optional_serializer().spec

  assert result
    == spec.object([
      spec.ObjectField(name: "name", spec: spec.string(), required: True),
      spec.ObjectField(name: "age", spec: spec.int(), required: True),
      spec.ObjectField(name: "is_student", spec: spec.bool(), required: False),
    ])
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Indexed fields                                        //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

fn indexed_strings_serializer() -> serialize.Serializer(List(String)) {
  serialize.object(fn(context) {
    use context, values <- serialize.indexed_field(
      context,
      "item",
      3,
      serialize.string(),
      fn(values: List(String), index) {
        values
        |> list.index_map(fn(value, index) { #(index, value) })
        |> list.key_find(index)
        |> result.unwrap("")
      },
    )

    serialize.build(context, values)
  })
}

pub fn serialize_indexed_field_decode_test() {
  let result =
    dynamic.properties([
      #(dynamic.string("item[0]"), dynamic.string("a")),
      #(dynamic.string("item[1]"), dynamic.string("b")),
      #(dynamic.string("item[2]"), dynamic.string("c")),
    ])
    |> serialize.decode(indexed_strings_serializer())

  let assert Ok(["a", "b", "c"]) = result
}

pub fn serialize_indexed_field_encode_test() {
  let result =
    ["a", "b", "c"]
    |> serialize.encode(indexed_strings_serializer())

  assert result
    == value.Object([
      #("item[0]", value.String("a")),
      #("item[1]", value.String("b")),
      #("item[2]", value.String("c")),
    ])
}

pub fn serialize_indexed_field_spec_test() {
  let result = indexed_strings_serializer().spec

  assert result
    == spec.object([
      spec.ObjectField(name: "item[0]", spec: spec.string(), required: True),
      spec.ObjectField(name: "item[1]", spec: spec.string(), required: True),
      spec.ObjectField(name: "item[2]", spec: spec.string(), required: True),
    ])
}

fn optional_indexed_strings_serializer() -> serialize.Serializer(List(String)) {
  serialize.object(fn(context) {
    use context, values <- serialize.optional_indexed_field(
      context,
      "item",
      3,
      "z",
      serialize.string(),
      fn(values: List(String), index) {
        values
        |> list.index_map(fn(value, index) { #(index, value) })
        |> list.key_find(index)
        |> result.unwrap("")
      },
    )

    serialize.build(context, values)
  })
}

pub fn serialize_optional_indexed_field_decode_missing_uses_default_test() {
  let result =
    dynamic.properties([
      #(dynamic.string("item[0]"), dynamic.string("a")),
      #(dynamic.string("item[1]"), dynamic.string("b")),
    ])
    |> serialize.decode(optional_indexed_strings_serializer())

  let assert Ok(["a", "b", "z"]) = result
}

pub fn serialize_optional_indexed_field_spec_test() {
  let result = optional_indexed_strings_serializer().spec

  assert result
    == spec.object([
      spec.ObjectField(name: "item[0]", spec: spec.string(), required: False),
      spec.ObjectField(name: "item[1]", spec: spec.string(), required: False),
      spec.ObjectField(name: "item[2]", spec: spec.string(), required: False),
    ])
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                       Encoder & decoder                                       //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn serialize_decoder_test() {
  let wrapped = serialize.decoder(serialize.int())
  let result = decode.run(dynamic.int(5), wrapped.decoder)

  let assert Ok(5) = result
  let assert spec.Integer(..) = wrapped.spec
}

pub fn serialize_encoder_test() {
  let wrapped = serialize.encoder(serialize.int())
  let result = wrapped.encoder(5)

  let assert value.Integer(5) = result
  let assert spec.Integer(..) = wrapped.spec
}

pub fn serialize_encode_json_test() {
  let result = serialize.encode_json("Hello", serialize.string())

  let assert "\"Hello\"" = json.to_string(result)
}

pub fn serialize_encode_yaml_test() {
  let result = serialize.encode_yaml("Hello", serialize.string())

  let assert yaml_value.String("Hello") = result
}
