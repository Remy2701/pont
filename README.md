# pont

[![Package Version](https://img.shields.io/hexpm/v/pont)](https://hex.pm/packages/pont)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/pont/)

Two-way serializers for Gleam. Describe the shape of a type once and get a
decoder, an encoder, and a schema from it — decode untyped `Dynamic` data into
your type, encode your type to JSON or YAML, and inspect the generated `Spec`
to build documentation or validation on top.

```sh
gleam add pont@1
```

```gleam
import gleam/dynamic
import gleam/json
import pont/serialize

pub type Person {
  Person(name: String, age: Int)
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

    serialize.build(context, Person(name:, age:))
  })
}

pub fn main() -> Nil {
  let serializer = person_serializer()

  // Decode dynamic data into a typed value.
  let data =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.string("Alice")),
      #(dynamic.string("age"), dynamic.int(30)),
    ])
  let assert Ok(person) = serialize.decode(data, serializer)

  // Encode a typed value straight to JSON.
  person
  |> serialize.encode_json(serializer)
  |> json.to_string
  // -> "{\"name\":\"Alice\",\"age\":30}"
}
```

## Features

- **Primitives** — `string`, `bool`, `int`, `float`, `null`, with bounded
  variants `int_within` and `float_within`.
- **Composition** — `list`, `optional`, and `object` (with required,
  optional, and indexed fields) for building up larger structures from
  smaller serializers.
- **Enums** — `string_enum` for simple string-backed enums, and `enum` /
  `variant` for sum types that serialize differently per variant.
- **Timestamps** — RFC 3339 encoding and decoding via `timestamp`.
- **One definition, three outputs** — every serializer yields a decoder, an
  encoder, and a `Spec` describing its shape (formats, bounds, enum
  variants, object fields), so the schema never drifts out of sync with the
  code that reads and writes the data.
- **JSON and YAML** — encode any serializer's output directly with
  `encode_json` or `encode_yaml`.

Further documentation can be found at <https://hexdocs.pm/pont>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
