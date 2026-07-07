.onLoad = function(libname, pkgname) {
  S7::methods_register()
}

# `is(...)` inside package-internal select predicates (e.g. collect_code)
# resolves via the predicate data mask, not the namespace; silence the
# static-analysis note.
utils::globalVariables("is")
