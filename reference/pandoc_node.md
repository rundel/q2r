# Virtual parent classes

`pandoc_node` is the abstract root of the AST; every block and inline
extends it. `pandoc_block` and `pandoc_inline` are abstract too;
concrete variants extend one of these.

## Usage

    pandoc_node(source_info = <object>)

    pandoc_block(source_info = <object>)

    pandoc_inline(source_info = <object>)
