import OfflineBundle.BundleImports

#check Real
#check Finset

example : (2 : Nat) + 2 = 4 := by
  rfl

example (p q : Prop) : And p q -> And q p := by
  intro h
  exact And.intro h.right h.left
