import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import pont/serialize
import taffy as yaml

pub type Decoder(t) =
  serialize.Decoder(t)

pub fn decode(
  value: dynamic.Dynamic,
  decoder: Decoder(t),
) -> Result(t, List(decode.DecodeError)) {
  serialize.decode_with_decoder(value, decoder)
}

pub fn decode_json(
  json: String,
  decoder: Decoder(t),
) -> Result(t, json.DecodeError) {
  serialize.decode_json_with_decoder(json, decoder)
}

pub fn decode_yaml(
  yaml: String,
  decoder: Decoder(t),
) -> Result(t, yaml.YamlDecodeError) {
  serialize.decode_yaml_with_decoder(yaml, decoder)
}
