# Shortcode

`positional_args` and `keyword_args` are lists of arg records. Each arg
record is a list with `kind` ∈ `"string"`, `"number"`, `"boolean"`,
`"shortcode"`, `"kv"`, `"kv_group"`. `string`/`number`/`boolean` carry a
`value`; `shortcode` carries a nested `pandoc_shortcode` in `value`;
`kv` carries `key` (character) and `value` (another arg record);
`kv_group` carries `value` as a list of `kv` records (used for
positional KeyValue bundles).

## Usage

    pandoc_shortcode(
      source_info = <object>,
      name = "",
      is_escaped = FALSE,
      positional_args = list(),
      keyword_args = list()
    )
