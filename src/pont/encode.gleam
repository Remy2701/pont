import gleam/json.{type Json}
import pont/serialize
import pont/value
import taffy/value.{type YamlValue as Yaml} as _yaml

pub type Encoder(t) =
  serialize.Encoder(t)

pub fn encode(value: t, of encoder: serialize.Encoder(t)) -> value.Value {
  serialize.encode_with_encoder(value, encoder)
}

/// Directly encode a value using the given encoder to JSON.
pub fn encode_json(a: a, of encoder: serialize.Encoder(a)) -> Json {
  serialize.encode_json_with_encoder(a, encoder)
}

/// Directly encode a value using the given encoder to YAML.
pub fn encode_yaml(a: a, of encoder: serialize.Encoder(a)) -> Yaml {
  serialize.encode_yaml_with_encoder(a, encoder)
}

pub fn map(encoder: Encoder(a), mapper: fn(b) -> a) -> Encoder(b) {
  serialize.Encoder(..encoder, encoder: fn(b) { encoder.encoder(mapper(b)) })
}
