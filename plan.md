# build_ideal_tree Implementation Plan

## Goal

Implement `build_ideal_tree` and `get_diff` for the ABAP global package tree, mirroring
[@npmcli/arborist](https://github.com/npm/cli/tree/latest/workspaces/arborist) with ABAP-specific
adaptations (single global tree, no bundle deps in tree).

## Requirements (confirmed)

| Topic | Decision |
|-------|----------|
| Lifecycle | `build_ideal_tree` calls `load_actual_tree` internally |
| Add input | `ty_add_package` structure `{ name, version }`, exact version |
| Add validation | Throw `/apmg/cx_error` if already installed; throw if version missing in registry |
| Remove validation | Throw `/apmg/cx_error` if not installed |
| Add + remove order | Validate all, apply removes, prune, apply adds, full rebuild |
| Prune | Remove exclusive transitive deps (all `edges_in` from removed nodes) |
| Production flag | `is_production` omits devDependencies |
| Optional deps | Non-fatal; tree still buildable |
| Peer deps | Mark missing with `PEER LOCAL` error |
| Bundle deps | Ignored entirely (not in tree) |
| Version resolution | `max_satisfying_version` for existing deps; conflict → invalid |
| Diff | `get_diff` following [arborist diff.md](https://github.com/npm/cli/blob/latest/workspaces/arborist/docs/diff.md) |
| Diff actions | `ADD`, `CHANGE`, `REMOVE` (+ unchanged identified via `unchanged` list) |
| Node state | `installed` = on system today; `version` = current; `max_satisfying_version` = target |

## Architecture

### Phase 1: Tree container (replace singleton)

- [x] Create `/apmg/cl_arborist_tree` — instance-scoped node store
- [x] Move node registry from `cl_arborist_node` CLASS-DATA to tree instance
- [x] Add `clone`, `remove_node`, `clear_edges_all` on tree
- [x] `cl_arborist` holds `current_tree` and `ideal_tree` instance refs

### Phase 2: Refactor node and edge

- [x] Remove singleton methods from `cl_arborist_node`
- [x] Node creation via `tree->add_node( )`
- [x] `cl_arborist_edge=>resolve( tree )` for tree-scoped lookup
- [x] `set_max_satisfying` — do not mutate `installed`; only set target + errors
- [x] Skip bundle dependencies in edge creation (always)

### Phase 3: Interface

- [x] `ty_add_package` / `ty_add_packages` types
- [x] `c_diff_action` constants
- [x] Update `build_ideal_tree` signature (`is_production`)
- [x] Add `get_diff` returning `REF TO cl_arborist_diff`
- [x] Fix `get_current_tree` / `get_ideal_tree` (remove `get_tree`)

### Phase 4: Diff class

- [x] Create `/apmg/cl_arborist_diff` with `calculate( actual, ideal )`
- [x] Fields: `actual`, `ideal`, `action`, `children`, `leaves`, `unchanged`, `removed`, `parent`
- [x] Walk prod dependency edges; bubble changes per npm diff algorithm

### Phase 5: build_ideal_tree

- [x] `load_actual_tree` → populate `current_tree`
- [x] Clone to `ideal_tree`
- [x] Validate add/remove inputs
- [x] Apply removes + exclusive transitive prune
- [x] Fetch manifests and add new nodes
- [x] Full rebuild: clear edges, process deps, process uninstalled, resolve

### Phase 6: Testing / polish

- [x] Update `arborist_tester` for new API
- [ ] Manual test on SAP system

## Status

Implementation complete. Pending manual verification on SAP system.

## File checklist

| File | Action |
|------|--------|
| `plan.md` | Created |
| `#apmg#cl_arborist_tree.clas.abap` | New |
| `#apmg#cl_arborist_tree.clas.xml` | New |
| `#apmg#cl_arborist_diff.clas.abap` | New |
| `#apmg#cl_arborist_diff.clas.xml` | New |
| `#apmg#if_arborist.intf.abap` | Updated |
| `#apmg#cl_arborist.clas.abap` | Updated |
| `#apmg#cl_arborist_node.clas.abap` | Updated |
| `#apmg#cl_arborist_edge.clas.abap` | Updated |
| `#apmg#arborist_tester.prog.abap` | Updated |

## Diff algorithm (ABAP adaptation)

For global flat tree, packages are keyed by unique `name`. Diff walks **prod dependency**
edges (`edges_out` where `type = prod`), matching npm's hierarchical diff shape:

1. Compare actual vs ideal node by name
2. `get_action`: no ideal → `REMOVE`; no actual → `ADD`; version/target mismatch → `CHANGE`
3. If action set → create Diff node; collect downstream leaf diffs
4. If no action → recurse into prod deps; collect `unchanged` nodes
5. Bubble `leaves`, `unchanged`, `removed` up to parent diffs

## Reify prep (future)

`get_diff` output enables separate install / update / uninstall passes:

| Action | Reify operation |
|--------|-----------------|
| `ADD` | Install new package at `ideal->max_satisfying_version` |
| `CHANGE` | Update to `ideal->max_satisfying_version` |
| `REMOVE` | Uninstall `actual` package |
