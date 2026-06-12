import Lake
open Lake DSL

package lean4_offline_linux_x86_64 where

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.30.0"

@[default_target]
lean_lib OfflineBundle where

