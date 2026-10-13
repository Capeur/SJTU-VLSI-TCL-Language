# Calibre command status (PRD §10.2)

✅ verified: form appears in public Siemens or industry examples. ⚠️ verify: DRV-Lite's own argument order — check the Calibre DESIGNrev Reference Manual.

| Command (DRV-Lite) | Status | Behaviour |
|---|---|---|
| `layout create ?file.gds? ?-dt_expand? ?-preserveProperties? ?-preserveTextAttributes?` | ✅ (options accepted; may be no-ops) | Returns a handle `layout0`, `layout1`, …; loads GDS if given |
| `$L create cell name` | ✅ | Creates an empty cell |
| `$L create layer L` (`n` or `n.d`) | ✅ | Registers a layer; unregistered use raises `layoutN create: invalid layer L` |
| `$L create polygon cell layer x1 y1 x2 y2 …` | ✅ | Adds a polygon (closed automatically) |
| `$L create text cell layer x y string` | ⚠️ (command ✅, argument order ⚠️) | Adds a text label |
| `$L create wire cell layer width x1 y1 …` | ⚠️ | Adds a path |
| `$L create ref parent child x y ?mirror? ?angle? ?mag?` | ⚠️ | Adds an instance; angle ∈ {0,90,180,270} |
| `$L gdsout file ?cell?` (alias `$L gds out file`) | ✅ (both spellings seen) | Writes GDSII |
| `$L iterator ref cell range first last` | ✅ (command); return format ⚠️ | List of `{child x y mirror angle mag}` |
| `$L iterator poly cell layer range first last` | ✅ (command); return format ⚠️ | List of vertex lists |
| `$L AND l1 l2 lout` | ✅ | Boolean AND (Manhattan only) |
| `$L OR / NOT / XOR l1 l2 lout` | ⚠️ | Boolean ops (Manhattan only) |
| `$L SIZE lin lout BY value` | ⚠️ | Grow/shrink (Manhattan only) |
| `$L cells`, `$L layers`, `$L topcell`, `$L bbox cell` | ⚠️ (DRV-Lite names) | Metadata queries |
| `$L units ?user dbu?` | ⚠️ | Get/set units |
| `$L delete` | ⚠️ | Destroys the handle |
| `drvlite::svg $L cell ?-layers list? ?-width px?` | DRV-Lite only | Returns an SVG string |
| `drvlite::rdb::*` | DRV-Lite only | Results-database writer/reader |

To change a status, use the "Calibre syntax correction" issue template and record the public source.
