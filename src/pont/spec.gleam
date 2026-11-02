import gleam/option.{type Option, None, Some}
import pont/value

pub type Format {
  DateFormat
  DatetimeFormat
  I32Format
  I64Format
  F32Format
  F64Format
  PasswordFormat
  ByteFormat
  BinaryFormat
  CustomFormat(format: String)
}

pub type Spec {
  String(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    enum_variants: List(String),
    pattern: Option(String),
  )
  Integer(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    min: Option(Int),
    max: Option(Int),
  )
  Float(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    min: Option(Float),
    max: Option(Float),
  )
  Boolean(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
  )
  Null(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
  )
  Array(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    of: Spec,
  )
  Option(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    of: Spec,
  )
  Object(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    fields: List(ObjectField),
  )
  Union(
    format: Option(Format),
    default: Option(value.Value),
    example: List(value.Value),
    variants: List(Spec),
  )
}

pub type ObjectField {
  ObjectField(name: String, spec: Spec, required: Bool)
}

pub fn null() -> Spec {
  Null(format: None, default: None, example: [])
}

pub fn string() -> Spec {
  String(
    format: None,
    default: None,
    example: [],
    enum_variants: [],
    pattern: None,
  )
}

pub fn string_enum(variants: List(String)) -> Spec {
  String(
    format: None,
    default: None,
    example: [],
    enum_variants: variants,
    pattern: None,
  )
}

pub fn bool() -> Spec {
  Boolean(format: None, default: None, example: [])
}

pub fn int() -> Spec {
  Integer(format: None, default: None, example: [], min: None, max: None)
}

pub fn int_within(min: Int, max: Int) -> Spec {
  Integer(
    format: None,
    default: None,
    example: [],
    min: Some(min),
    max: Some(max),
  )
}

pub fn float() -> Spec {
  Float(format: None, default: None, example: [], min: None, max: None)
}

pub fn float_within(min: Float, max: Float) -> Spec {
  Float(
    format: None,
    default: None,
    example: [],
    min: Some(min),
    max: Some(max),
  )
}

pub fn array(of: Spec) -> Spec {
  Array(format: None, default: None, example: [], of: of)
}

pub fn option(of: Spec) -> Spec {
  Option(format: None, default: None, example: [], of: of)
}

pub fn object(fields: List(ObjectField)) -> Spec {
  Object(format: None, default: None, example: [], fields: fields)
}

pub fn union(variants: List(Spec)) -> Spec {
  Union(format: None, default: None, example: [], variants: variants)
}

pub fn with_format(spec: Spec, format: Format) -> Spec {
  case spec {
    String(..) -> String(..spec, format: Some(format))
    Integer(..) -> Integer(..spec, format: Some(format))
    Float(..) -> Float(..spec, format: Some(format))
    Boolean(..) -> Boolean(..spec, format: Some(format))
    Null(..) -> Null(..spec, format: Some(format))
    Array(..) -> Array(..spec, format: Some(format))
    Option(..) -> Option(..spec, format: Some(format))
    Object(..) -> Object(..spec, format: Some(format))
    Union(..) -> Union(..spec, format: Some(format))
  }
}

pub fn with_default(spec: Spec, default: value.Value) -> Spec {
  case spec {
    String(..) -> String(..spec, default: Some(default))
    Integer(..) -> Integer(..spec, default: Some(default))
    Float(..) -> Float(..spec, default: Some(default))
    Boolean(..) -> Boolean(..spec, default: Some(default))
    Null(..) -> Null(..spec, default: Some(default))
    Array(..) -> Array(..spec, default: Some(default))
    Option(..) -> Option(..spec, default: Some(default))
    Object(..) -> Object(..spec, default: Some(default))
    Union(..) -> Union(..spec, default: Some(default))
  }
}
