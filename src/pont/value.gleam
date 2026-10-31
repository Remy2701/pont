import gleam/dynamic
import gleam/json.{type Json}
import gleam/list
import gleam/option
import gleam/pair
import taffy/value.{type YamlValue as Yaml} as yaml

pub type Value {
  String(value: String)
  Integer(value: Int)
  Float(value: Float)
  Boolean(value: Bool)
  Null
  List(values: List(Value))
  Object(properties: List(#(String, Value)))
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Constructors                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn string(value: String) -> Value {
  String(value)
}

pub fn int(value: Int) -> Value {
  Integer(value)
}

pub fn float(value: Float) -> Value {
  Float(value)
}

pub fn bool(value: Bool) -> Value {
  Boolean(value)
}

pub fn null() -> Value {
  Null
}

pub fn list(values: List(Value)) -> Value {
  List(values)
}

pub fn list_of(values: List(a), transform: fn(a) -> Value) -> Value {
  List(list.map(values, transform))
}

pub fn object(properties: List(#(String, Value))) -> Value {
  Object(properties)
}

pub fn object_of(
  properties: List(a),
  transform: fn(a) -> #(String, Value),
) -> Value {
  Object(list.map(properties, transform))
}

pub fn object_of_tuple(
  properties: List(#(String, a)),
  transform: fn(a) -> Value,
) -> Value {
  Object(list.map(properties, pair.map_second(_, transform)))
}

pub fn nullable(value: option.Option(Value)) -> Value {
  case value {
    option.Some(value) -> value
    option.None -> Null
  }
}

pub fn nullable_of(
  value: option.Option(a),
  transform: fn(a) -> Value,
) -> Value {
  case value {
    option.Some(value) -> transform(value)
    option.None -> Null
  }
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                         Manipulators                                          //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn filter_null(value: Value) -> Value {
  case value {
    List(values:) -> List(list.filter(values, fn(value) { value != Null }))
    Object(properties:) ->
      Object(list.filter(properties, fn(property) { property.1 != Null }))
    _ -> value
  }
}

pub fn filter_null_recursive(value: Value) -> Value {
  case value {
    List(values:) ->
      List(
        list.filter_map(values, fn(value) {
          case value {
            Null -> Error(Nil)
            _ -> Ok(filter_null_recursive(value))
          }
        }),
      )
    Object(properties:) ->
      Object(
        list.filter_map(properties, fn(property) {
          case property.1 {
            Null -> Error(Nil)
            _ -> Ok(#(property.0, filter_null_recursive(property.1)))
          }
        }),
      )
    _ -> value
  }
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             JSON                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn to_json(value: Value) -> Json {
  case value {
    String(value:) -> json.string(value)
    Integer(value:) -> json.int(value)
    Float(value:) -> json.float(value)
    Boolean(value:) -> json.bool(value)
    Null -> json.null()
    List(values:) -> json.array(values, to_json)
    Object(properties:) ->
      json.object(list.map(properties, pair.map_second(_, to_json)))
  }
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                             YAML                                              //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn to_yaml(value: Value) -> Yaml {
  case value {
    String(value:) -> yaml.String(value)
    Integer(value:) -> yaml.Int(value)
    Float(value:) -> yaml.Float(value)
    Boolean(value:) -> yaml.Bool(value)
    Null -> yaml.Null
    List(values:) -> yaml.Sequence(list.map(values, to_yaml))
    Object(properties:) ->
      yaml.Mapping(list.map(properties, pair.map_second(_, to_yaml)))
  }
}

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //
//                                            Dynamic                                            //
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––– //

pub fn to_dynamic(value: Value) -> dynamic.Dynamic {
  case value {
    String(value:) -> dynamic.string(value)
    Integer(value:) -> dynamic.int(value)
    Float(value:) -> dynamic.float(value)
    Boolean(value:) -> dynamic.bool(value)
    Null -> dynamic.nil()
    List(values:) -> dynamic.list(list.map(values, to_dynamic))
    Object(properties:) ->
      dynamic.properties(
        properties
        |> list.map(pair.map_second(_, to_dynamic))
        |> list.map(pair.map_first(_, dynamic.string)),
      )
  }
}
